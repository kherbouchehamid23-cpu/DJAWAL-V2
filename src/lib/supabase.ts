import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn(
      '[Djawal] VITE_SUPABASE_URL ou VITE_SUPABASE_ANON_KEY manquant. ' +
          'Copier .env.example vers .env.local et renseigner les valeurs.'
            )
            }

            /**
             * Client Supabase non type strict pour Sprint 2 — sera regenere au Sprint 3
              * via : npx supabase gen types typescript --linked > src/types/database.ts
               */
               export const supabase = createClient(
                 supabaseUrl ?? 'http://localhost:54321',
                   supabaseAnonKey ?? 'anon-key-placeholder',
                     {
                         auth: {
                               persistSession: true,
                                     autoRefreshToken: true,
                                           detectSessionInUrl: true
                                               },
                                                   db: { schema: 'public' },
                                                       global: { headers: { 'x-djawal-client': 'web-v2' } }
                                                         }
                                                         )
                                                         