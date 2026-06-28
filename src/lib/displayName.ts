/**
 * Embellit un nom d'affichage quand il ressemble à un identifiant (username).
 * Correctif de surface pour D-04 : certains profils ont un display_name égal à
 * leur username (ex. "ahmedstitten06", "hanane.abd.ms2"). Le vrai correctif est
 * en base (renseigner un display_name propre) ; ceci évite d'afficher du brut.
 *
 * Règle prudente : on ne transforme QUE si le nom a tout l'air d'un username
 * (pas d'espace ET (contient un chiffre OU un point/underscore)). Un nom humain
 * normal ("Karim", "Amira B.") est laissé intact.
 */
export function prettyName(name?: string | null, fallback = 'Guide Djawal'): string {
  const raw = (name || '').trim()
  if (!raw) return fallback
  const looksLikeUsername = !/\s/.test(raw) && (/\d/.test(raw) || /[._]/.test(raw))
  if (!looksLikeUsername) return raw
  const cleaned = raw
    .replace(/[._]+/g, ' ')        // séparateurs -> espaces
    .replace(/\d+/g, ' ')          // retire les chiffres
    .replace(/\s+/g, ' ')
    .trim()
  if (!cleaned) return fallback
  return cleaned
    .split(' ')
    .map(w => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ')
}
