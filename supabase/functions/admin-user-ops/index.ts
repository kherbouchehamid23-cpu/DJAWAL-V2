// =========================================================
// DJAWAL V2 — Edge Function : admin-user-ops
// Opérations admin sensibles sur les utilisateurs :
//   - get_email      : récupère l'email d'un user (auth.users)
//   - count_cascade  : preview des contributions qui seront supprimées
//   - delete_user    : supprime définitivement un user (cascade DB auto)
// Accès : super_admin uniquement (vérification JWT + role)
// =========================================================

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Max-Age': '86400'
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  })
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })
  if (req.method !== 'POST')   return json({ error: 'POST only' }, 405)

  // === 1. Auth : extraire user depuis JWT ===
  const authHeader = req.headers.get('Authorization') || ''
  const token = authHeader.replace(/^Bearer\s+/i, '')
  if (!token) return json({ error: 'Missing Authorization' }, 401)

  // Client "anon + jwt utilisateur" pour récupérer auth.uid()
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${token}` } }
  })
  const { data: { user: caller }, error: callerErr } = await userClient.auth.getUser()
  if (callerErr || !caller) return json({ error: 'Invalid JWT' }, 401)

  // Client service-role pour les opérations admin
  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  // === 2. Vérifier que le caller est super_admin ===
  const { data: callerProfile, error: profErr } = await admin
    .from('profiles')
    .select('role')
    .eq('id', caller.id)
    .maybeSingle()
  if (profErr || callerProfile?.role !== 'super_admin') {
    return json({ error: 'Forbidden — super_admin only' }, 403)
  }

  // === 3. Parser body ===
  let body: { action?: string; user_id?: string; confirm?: boolean }
  try {
    body = await req.json()
  } catch {
    return json({ error: 'Invalid JSON body' }, 400)
  }
  const { action, user_id, confirm } = body
  if (!action || !user_id) return json({ error: 'Missing action or user_id' }, 400)
  if (!/^[0-9a-f-]{36}$/i.test(user_id)) return json({ error: 'Invalid user_id format' }, 400)

  // Garde-fou : on ne peut pas se supprimer soi-même
  if (action === 'delete_user' && user_id === caller.id) {
    return json({ error: 'Vous ne pouvez pas supprimer votre propre compte admin.' }, 400)
  }

  // === 4. Router actions ===
  try {
    if (action === 'get_email') {
      const { data, error } = await admin.auth.admin.getUserById(user_id)
      if (error || !data?.user) return json({ error: error?.message || 'User not found' }, 404)
      return json({
        email: data.user.email,
        email_confirmed_at: data.user.email_confirmed_at,
        last_sign_in_at: data.user.last_sign_in_at,
        created_at: data.user.created_at
      })
    }

    if (action === 'count_cascade') {
      // Compter ce qui sera supprimé en cascade si on delete ce user
      const [trips, memories, accommodations, restaurants, activities, sites, favorites, reviews] = await Promise.all([
        admin.from('trips').select('id', { count: 'exact', head: true }).eq('created_by', user_id),
        admin.from('memories').select('id', { count: 'exact', head: true }).eq('author_id', user_id),
        admin.from('accommodations').select('id', { count: 'exact', head: true }).eq('created_by', user_id),
        admin.from('restaurants').select('id', { count: 'exact', head: true }).eq('created_by', user_id),
        admin.from('activities').select('id', { count: 'exact', head: true }).eq('created_by', user_id),
        admin.from('sites').select('id', { count: 'exact', head: true }).eq('created_by', user_id),
        admin.from('user_favorites').select('user_id', { count: 'exact', head: true }).eq('user_id', user_id),
        admin.from('user_reviews').select('id', { count: 'exact', head: true }).eq('user_id', user_id)
      ])
      return json({
        trips: trips.count || 0,
        memories: memories.count || 0,
        accommodations: accommodations.count || 0,
        restaurants: restaurants.count || 0,
        activities: activities.count || 0,
        sites: sites.count || 0,
        favorites: favorites.count || 0,
        reviews: reviews.count || 0
      })
    }

    if (action === 'delete_user') {
      if (!confirm) return json({ error: 'Missing confirm:true flag' }, 400)
      // Supprimer auth.user → cascade automatique sur profiles → cascade sur trips/memories/etc.
      const { error } = await admin.auth.admin.deleteUser(user_id)
      if (error) return json({ error: error.message }, 500)
      return json({ success: true, deleted_user_id: user_id })
    }

    return json({ error: `Unknown action: ${action}` }, 400)

  } catch (e) {
    return json({ error: (e as Error).message || 'Internal error' }, 500)
  }
})
