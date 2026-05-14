import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

/**
 * Upload d'un fichier dans un bucket Supabase Storage.
 * Renvoie l'URL publique pour les buckets publics, ou le chemin pour les privés.
 */
export type StorageBucket = 'avatars' | 'hero-images' | 'panoramas' | 'kyc-documents' | 'ambient-sounds' | 'trip-covers' | 'memory-photos' | 'operator-avatars' | 'operator-gallery'

export function useStorageUpload(bucket: StorageBucket) {
  const uploading = ref(false)
  const progress = ref(0)
  const error = ref<string | null>(null)

  async function uploadFile(file: File, path?: string): Promise<string | null> {
    uploading.value = true
    progress.value = 0
    error.value = null

    try {
      // Validation taille par bucket
      const sizeLimits: Record<string, number> = {
        'avatars': 5,
        'hero-images': 25,
        'panoramas': 50,
        'kyc-documents': 10,
        'ambient-sounds': 10,
        'trip-covers': 25,
        'memory-photos': 25,
        'operator-avatars': 5,
        'operator-gallery': 10
      }
      const maxSize = sizeLimits[bucket] ?? 25
      if (file.size > maxSize * 1024 * 1024) {
        error.value = `Fichier trop volumineux (${maxSize} Mo max)`
        return null
      }

      const ext = file.name.split('.').pop()?.toLowerCase() || 'jpg'
      let filename = path || `${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`

      // Préfixe user_id requis par la RLS des buckets opérateurs
      // (storage.foldername(name)[1] = auth.uid()::TEXT)
      if (bucket === 'operator-gallery' || bucket === 'operator-avatars') {
        const { data: { user } } = await supabase.auth.getUser()
        if (!user) {
          error.value = 'Authentification requise pour uploader.'
          return null
        }
        // Ne pas re-préfixer si l'appelant a déjà fourni un path avec user_id
        if (!filename.startsWith(user.id + '/')) {
          filename = `${user.id}/${filename}`
        }
      }

      const { data, error: upErr } = await supabase.storage
        .from(bucket)
        .upload(filename, file, { cacheControl: '3600', upsert: false })

      if (upErr) {
        error.value = upErr.message
        return null
      }

      // URL publique (uniquement pour buckets publics)
      const { data: { publicUrl } } = supabase.storage
        .from(bucket)
        .getPublicUrl(data.path)

      return publicUrl
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Erreur d\'upload'
      return null
    } finally {
      uploading.value = false
      progress.value = 100
    }
  }

  async function deleteFile(path: string): Promise<boolean> {
    const { error: delErr } = await supabase.storage.from(bucket).remove([path])
    if (delErr) {
      error.value = delErr.message
      return false
    }
    return true
  }

  return { uploadFile, deleteFile, uploading, progress, error }
}
