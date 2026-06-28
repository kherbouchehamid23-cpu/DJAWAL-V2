/**
 * Coach Djawal — calcul de qualité d'une fiche voyage (déterministe, côté front).
 * Aucune dépendance réseau : instantané et gratuit. L'IA ne sert qu'à rédiger.
 * Barème aligné sur la spec (01-spec-fonctionnelle.md §4.3).
 */

export interface TripQualityInput {
  title_fr: string
  title_ar: string
  title_en: string
  description_fr: string
  description_ar: string
  description_en: string
  destinationId: string
  durationDays: number
  priceDa: number
  difficulty: string
  tags: string            // saisie brute "a, b, c"
  hasCover: boolean
  days: string[]          // résumé/étapes par journée
}

export interface QualityCheck { label: string; ok: boolean }
export interface QualityResult {
  score: number                 // 0..100
  musts: QualityCheck[]         // exigences bloquantes
  mustsOk: boolean
  suggestions: string[]
  canPublish: boolean           // mustsOk && score >= threshold
}

const VOWELS = /[aeiouyàâäéèêëïîôöùûü]/i

/** Détecte une chaîne "données de test" (charabia, placeholder). */
export function looksLikeTestData(s: string): boolean {
  const t = (s || '').trim()
  if (!t) return false
  if (/^(test|aaa+|xxx+|asdf|qwerty|lorem)/i.test(t)) return true
  // mot long sans aucune voyelle => charabia type "bhmsdbfgj"
  const compact = t.replace(/\s+/g, '')
  if (compact.length >= 6 && !VOWELS.test(compact)) return true
  return false
}

function wordCount(s: string): number {
  return (s || '').trim().split(/\s+/).filter(Boolean).length
}

export function scoreTrip(input: TripQualityInput, threshold = 70): QualityResult {
  const dur = Math.max(1, Number(input.durationDays) || 1)
  const days = input.days || []
  const daysOk = days.length === dur && days.every(d => (d || '').trim().length >= 8)

  const triOk = !!(input.title_fr && input.description_fr &&
                   input.title_ar && input.description_ar &&
                   input.title_en && input.description_en)

  const allText = [input.title_fr, input.title_ar, input.title_en,
                   input.description_fr, input.description_ar, input.description_en, ...days]
  const noTest = !allText.some(looksLikeTestData)

  const tagList = (input.tags || '').split(',').map(t => t.trim()).filter(Boolean)

  // ----- exigences bloquantes -----
  const musts: QualityCheck[] = [
    { label: 'Trilingue FR + AR + EN (titre & description)', ok: triOk },
    { label: 'Image de couverture', ok: !!input.hasCover },
    { label: `Programme : ${dur} journée(s), chacune étoffée`, ok: daysOk },
    { label: 'Aucune donnée de test', ok: noTest },
  ]
  const mustsOk = musts.every(m => m.ok)

  // ----- score /100 -----
  let s = 0
  const tFr = (input.title_fr || '').trim()
  if (tFr.length >= 25 && tFr.length <= 70) s += 15
  if (wordCount(input.description_fr) >= 80) s += 25
  if (daysOk) s += 25
  if (input.hasCover) s += 10
  if (Number(input.priceDa) > 0 && dur >= 1) s += 10
  if ((input.difficulty || '').trim()) s += 5
  if (tagList.length >= 2) s += 5
  if (triOk) s += 5
  const score = Math.min(100, s)

  // ----- suggestions (non bloquantes) -----
  const suggestions: string[] = []
  if (!input.hasCover) suggestions.push('Ajoute une photo de couverture (première impression).')
  if (!triOk) suggestions.push("Complète les 3 langues — c'est obligatoire pour publier.")
  if (wordCount(input.description_fr) < 80) suggestions.push("Étoffe la description : une rencontre, un repas, une lumière.")
  if (!daysOk) suggestions.push('Détaille chaque journée (au moins une étape nommée).')
  if (tagList.length < 2) suggestions.push('Ajoute 2-3 tags (UNESCO, oasis…).')
  if (!noTest) suggestions.push('Du texte ressemble à des données de test — corrige avant de publier.')
  if (!suggestions.length) suggestions.push('Fiche complète et solide — prête à publier.')

  return { score, musts, mustsOk, suggestions, canPublish: mustsOk && score >= threshold }
}
