// =========================================================
// DJAWAL V2 — Edge Function : ai-assistant
// RAG pipeline : embed question → vector search → Gemini Flash → réponse
// =========================================================

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')!

const EMBED_MODEL = 'gemini-embedding-001'
const EMBED_DIM = 768
const GEN_MODEL = 'gemini-2.5-flash-lite'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': '*',
  'Access-Control-Max-Age': '86400'
}

interface ResourceMatch {
  resource_type: string
  resource_id: string
  name: string
  description: string
  destination_id: string
  destination_name: string
  similarity: number
}

interface DestinationMatch {
  id: string
  name: string
  wilaya: string
  cultural_theme: string
  description: string
  similarity: number
}

interface TripMatch {
  id: string
  title: string
  duration_days: number
  price_da: number
  description: string
  destination_name: string
  similarity: number
}

// === Génération d'embedding ===
async function embed(text: string): Promise<number[]> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${EMBED_MODEL}:embedContent?key=${GEMINI_API_KEY}`
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: `models/${EMBED_MODEL}`,
      content: { parts: [{ text }] },
      outputDimensionality: EMBED_DIM
    })
  })
  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Gemini embed error: ${err}`)
  }
  const json = await res.json()
  return json.embedding.values
}

// === Génération de texte ===
async function generate(prompt: string): Promise<{ text: string; tokens: number }> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEN_MODEL}:generateContent?key=${GEMINI_API_KEY}`
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.35,
        maxOutputTokens: 1024,
        topP: 0.85
      }
    })
  })
  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Gemini generate error: ${err}`)
  }
  const json = await res.json()
  const text = json.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
  const tokens = json.usageMetadata?.totalTokenCount ?? 0
  return { text, tokens }
}

// === Génération JSON strict (pour extraction de critères) ===
async function generateJson(prompt: string): Promise<any> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEN_MODEL}:generateContent?key=${GEMINI_API_KEY}`
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 512,
        responseMimeType: 'application/json'
      }
    })
  })
  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Gemini JSON gen error: ${err}`)
  }
  const json = await res.json()
  const text = json.candidates?.[0]?.content?.parts?.[0]?.text ?? '{}'
  // En cas où Gemini ajoute du markdown malgré responseMimeType
  let clean = text.trim()
  if (clean.startsWith('```')) {
    clean = clean.replace(/^```(?:json)?\s*/, '').replace(/\s*```$/, '')
  }
  // Extraire le premier objet JSON valide trouvé
  const match = clean.match(/\{[\s\S]*\}/)
  if (match) clean = match[0]
  return JSON.parse(clean)
}

// === Anti-hallucination : valider que la réponse n'invente pas de noms ===
function validateAnswer(answer: string, contextNames: string[]): { passed: boolean; notes: string } {
  // Détection grossière : noms propres dans la réponse qui ne sont pas dans le contexte
  // Pour rester pragmatique : on regarde si la réponse mentionne des "lieux" ou "hôtels"
  // qui ne figurent pas du tout dans contextNames
  const lowerAnswer = answer.toLowerCase()
  const known = contextNames.map(n => n.toLowerCase())

  // Liste de mots-clés qui souvent introduisent un nom propre
  const suspectPatterns = [
    /hôtel\s+([A-ZÀ-Ÿ][a-zà-ÿ]+(?:\s[A-ZÀ-Ÿ][a-zà-ÿ]+){0,2})/g,
    /restaurant\s+([A-ZÀ-Ÿ][a-zà-ÿ]+(?:\s[A-ZÀ-Ÿ][a-zà-ÿ]+){0,2})/g
  ]
  const flagged: string[] = []
  for (const pattern of suspectPatterns) {
    const matches = [...answer.matchAll(pattern)]
    for (const m of matches) {
      const name = m[1].toLowerCase()
      if (!known.some(k => k.includes(name) || name.includes(k))) {
        flagged.push(m[0])
      }
    }
  }
  if (flagged.length > 0) {
    return { passed: false, notes: `Noms propres suspects non présents dans le contexte : ${flagged.join(', ')}` }
  }
  return { passed: true, notes: '' }
}

// =========================================================
// ANALYSE DES CRITÈRES — extrait les 4 prérequis depuis le prompt utilisateur
// 1. dates/durée  2. composition groupe  3. centres d'intérêt  4. budget
// =========================================================
interface CriteriaAnalysis {
  hasDates: boolean
  hasGroup: boolean
  hasInterests: boolean
  hasBudget: boolean
  detected: {
    dates: string | null
    group: string | null
    interests: string[] | null
    budget: string | null
  }
  isTooVague: boolean
  reformulated: string  // version reformulée propre du besoin
}

async function extractCriteria(question: string): Promise<CriteriaAnalysis> {
  const prompt = `Analyse cette demande de voyage en Algérie et retourne UN OBJET JSON STRICT.

Demande utilisateur : "${question}"

Extrais les 4 critères suivants s'ils sont mentionnés :
1. dates ou durée (mois, saison, dates précises, nombre de jours)
2. composition du groupe (nombre de personnes, enfants, famille, amis, solo, couple)
3. activités ou centres d'intérêt (sahara, casbah, aurès, gastronomie, trek, culture, mer, montagne, 4x4, bivouac…) — un seul suffit
4. budget (somme approximative, fourchette, économique/moyen/premium)

isTooVague = true SEULEMENT si demande purement générale ("voyage en Algérie", "vacances algérie") sans AUCUN autre indice.

Retourne UNIQUEMENT ce JSON, sans markdown, sans texte autour :
{"hasDates":false,"hasGroup":false,"hasInterests":false,"hasBudget":false,"detected":{"dates":null,"group":null,"interests":null,"budget":null},"isTooVague":false,"reformulated":""}`

  const safeFallback: CriteriaAnalysis = {
    hasDates: false, hasGroup: false, hasInterests: false, hasBudget: false,
    detected: { dates: null, group: null, interests: null, budget: null },
    isTooVague: false,
    reformulated: question
  }

  try {
    const parsed = await generateJson(prompt)
    // Validation defensive : merge avec safeFallback pour éviter undefined
    return {
      hasDates: Boolean(parsed.hasDates),
      hasGroup: Boolean(parsed.hasGroup),
      hasInterests: Boolean(parsed.hasInterests),
      hasBudget: Boolean(parsed.hasBudget),
      detected: {
        dates: parsed.detected?.dates ?? null,
        group: parsed.detected?.group ?? null,
        interests: Array.isArray(parsed.detected?.interests) ? parsed.detected.interests : null,
        budget: parsed.detected?.budget ?? null
      },
      isTooVague: Boolean(parsed.isTooVague),
      reformulated: typeof parsed.reformulated === 'string' ? parsed.reformulated : question
    }
  } catch (e: any) {
    console.warn('[extractCriteria] failed, falling back to direct RAG:', e?.message || e)
    return safeFallback
  }
}

// Construire les questions à poser pour les critères manquants
function buildClarificationQuestions(criteria: CriteriaAnalysis): { key: string; question: string; suggestions: string[] }[] {
  const questions = []
  if (!criteria.hasDates) {
    questions.push({
      key: 'dates',
      question: 'Quand souhaitez-vous voyager ?',
      suggestions: ['Printemps (mars-mai)', 'Été (juin-août)', 'Automne (sept-nov)', 'Hiver (déc-fév)', '1 semaine', '2 semaines', '10 jours']
    })
  }
  if (!criteria.hasGroup) {
    questions.push({
      key: 'group',
      question: 'Vous voyagez en combien et avec qui ?',
      suggestions: ['Solo', 'Couple (2 personnes)', 'En famille avec enfants', 'Entre amis (3-4)', 'Grand groupe (5+)']
    })
  }
  if (!criteria.hasInterests) {
    questions.push({
      key: 'interests',
      question: "Qu'est-ce qui vous tente ?",
      suggestions: ['Sahara & désert', 'Casbah & médinas', 'Aurès & montagnes', 'Côte méditerranéenne', 'Gastronomie', 'Trek & randonnée', 'Sites archéologiques']
    })
  }
  if (!criteria.hasBudget) {
    questions.push({
      key: 'budget',
      question: 'Quel est votre budget approximatif par personne ?',
      suggestions: ['< 50 000 DA (économique)', '50 000 - 150 000 DA (moyen)', '150 000 - 300 000 DA (confort)', '> 300 000 DA (premium)']
    })
  }
  return questions
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const startTime = Date.now()

  try {
    const { question, user_id, destination_id, skip_analysis } = await req.json()

    if (!question || typeof question !== 'string' || question.length < 3) {
      return new Response(JSON.stringify({ error: 'Question requise (min. 3 caractères).' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }
    if (question.length > 500) {
      return new Response(JSON.stringify({ error: 'Question trop longue (max. 500 caractères).' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // === ÉTAPE PRÉLIMINAIRE : analyse des critères (sauf si skip_analysis=true) ===
    if (!skip_analysis) {
      let criteria: CriteriaAnalysis | null = null
      try {
        criteria = await extractCriteria(question)
      } catch (e: any) {
        // Si l'analyse plante, on continue le RAG normal au lieu de planter toute la requête
        console.warn('[ai-assistant] criteria extraction failed, falling through to RAG:', e?.message || e)
        criteria = null
      }

      if (criteria) {
        // Cas 1 : demande trop vague → redirection vers formulaire structuré
        if (criteria.isTooVague) {
          return new Response(JSON.stringify({
            mode: 'too-vague',
            answer: 'Votre demande est très large. Pour vous proposer un voyage qui vous correspond vraiment, je vous invite à utiliser notre composeur de voyage personnalisé qui posera quelques questions précises.',
            redirect_to: '/composer?from=ai-vague',
            criteria
          }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
        }

        // Cas 2 : critères manquants → poser les questions ciblées
        const allPresent = criteria.hasDates && criteria.hasGroup && criteria.hasInterests && criteria.hasBudget
        if (!allPresent) {
          const questions = buildClarificationQuestions(criteria)
          return new Response(JSON.stringify({
            mode: 'needs-clarification',
            answer: `Très bien, j'ai bien noté ${criteria.reformulated ? `« ${criteria.reformulated} »` : 'votre envie'}. Pour vous proposer le voyage parfait, j'ai juste besoin de quelques précisions :`,
            questions,
            detected: criteria.detected,
            original_question: question
          }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
        }
        // Cas 3 : tout est présent → on continue le RAG normal ci-dessous
      }
    }

    // 1. Embed la question
    const queryEmbedding = await embed(question)

    // 2. Recherche vectorielle parallèle
    const [resourcesRes, destinationsRes, tripsRes] = await Promise.all([
      supabase.rpc('match_resources', {
        query_embedding: queryEmbedding,
        match_count: 6,
        destination_filter: destination_id || null
      }),
      supabase.rpc('match_destinations', {
        query_embedding: queryEmbedding,
        match_count: 3
      }),
      supabase.rpc('match_trips', {
        query_embedding: queryEmbedding,
        match_count: 3
      })
    ])

    const SIMILARITY_THRESHOLD = 0.4
    const resources: ResourceMatch[] = (resourcesRes.data || []).filter((r: ResourceMatch) => r.similarity >= SIMILARITY_THRESHOLD)
    const destinations: DestinationMatch[] = (destinationsRes.data || []).filter((d: DestinationMatch) => d.similarity >= SIMILARITY_THRESHOLD)
    const trips: TripMatch[] = (tripsRes.data || []).filter((t: TripMatch) => t.similarity >= SIMILARITY_THRESHOLD)

    // 3. Si rien trouvé : réponse honnête sans inventer
    if (resources.length === 0 && destinations.length === 0 && trips.length === 0) {
      const fallback = "Je n'ai pas la connaissance précise pour répondre à ça. Reformule autrement ou jette un œil au menu Voyages — il y a peut-être déjà l'inspiration que tu cherches."

      await supabase.from('ai_conversations').insert({
        user_id: user_id || null,
        user_query: question,
        retrieved_resource_ids: [],
        llm_response: { text: fallback, fallback: true },
        validation_passed: true,
        validation_notes: 'Aucune ressource pertinente.',
        tokens_used: 0,
        latency_ms: Date.now() - startTime
      })

      return new Response(JSON.stringify({
        answer: fallback,
        resources: [], destinations: [], trips: []
      }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // 4. Construction du contexte pour le LLM
    const contextNames: string[] = []
    let context = ''
    if (destinations.length > 0) {
      context += '## Destinations algériennes pertinentes :\n'
      for (const d of destinations) {
        contextNames.push(d.name)
        context += `- **${d.name}** (${d.wilaya}, thème ${d.cultural_theme}) : ${d.description}\n`
      }
      context += '\n'
    }
    if (resources.length > 0) {
      context += '## Ressources concrètes (hôtels, sites, restaurants) :\n'
      for (const r of resources) {
        contextNames.push(r.name)
        context += `- [${r.resource_type}] **${r.name}** à ${r.destination_name} : ${r.description}\n`
      }
      context += '\n'
    }
    if (trips.length > 0) {
      context += '## Parcours déjà composés par nos guides :\n'
      for (const t of trips) {
        contextNames.push(t.title)
        context += `- **${t.title}** (${t.duration_days}j, ${t.price_da} DA, ${t.destination_name}) : ${t.description}\n`
      }
    }

    // 5. Prompt système
    const prompt = `Tu es Djawal, un guide de voyage algérien chaleureux et passionné.

INFOS INTERNES (NE JAMAIS LES CITER DANS TA RÉPONSE) :
${context}

QUESTION DU VOYAGEUR :
${question}

INSTRUCTIONS :
- Réponds comme un ami qui partage des recommandations autour d'un thé
- Tu peux mentionner les lieux par leur nom si tu les recommandes vraiment
- Ne dis jamais "d'après notre catalogue", "selon les données"
- Pas de listes mécaniques (les cartes en bas font le travail)
- 3-5 phrases max, texte fluide
- Ton chaleureux mais pas excessif

# TA RÉPONSE :`

    const { text: answer, tokens } = await generate(prompt)
    const validation = validateAnswer(answer, contextNames)

    const resourceIds = [
      ...resources.map(r => r.resource_id),
      ...destinations.map(d => d.id),
      ...trips.map(t => t.id)
    ]
    await supabase.from('ai_conversations').insert({
      user_id: user_id || null,
      user_query: question,
      retrieved_resource_ids: resourceIds,
      llm_response: { text: answer, model: GEN_MODEL },
      validation_passed: validation.passed,
      validation_notes: validation.notes || null,
      tokens_used: tokens,
      latency_ms: Date.now() - startTime
    })

    return new Response(JSON.stringify({
      answer,
      resources: resources.slice(0, 4),
      destinations: destinations.slice(0, 3),
      trips: trips.slice(0, 3),
      validation_passed: validation.passed
    }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

  } catch (err: any) {
    console.error('[ai-assistant] error:', err)
    return new Response(JSON.stringify({ error: err.message || 'Erreur interne.' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
