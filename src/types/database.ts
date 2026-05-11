/**
 * Types TypeScript synchronisés avec le schéma Supabase.
 * À régénérer après chaque migration :
 *   npx supabase gen types typescript --linked > src/types/database.ts
 *
 * Le fichier est stub pour le Sprint 1 — sera remplacé par la génération auto au Sprint 2.
 */
export type CulturalTheme = 'saharien' | 'mauresque' | 'aures'
export type AppRole = 'super_admin' | 'guide_senior' | 'guide_junior' | 'voyageur'
export type KycStatus = 'not_required' | 'pending' | 'approved' | 'rejected'
export type TripStatus = 'draft' | 'pending_review' | 'published' | 'rejected'
export type ResourceType = 'hotel' | 'site' | 'restaurant'

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          role: AppRole
          display_name: string
          bio: string | null
          region: string | null
          avatar_url: string | null
          kyc_status: KycStatus
          kyc_reviewed_by: string | null
          kyc_reviewed_at: string | null
          is_active: boolean
          created_at: string
        }
        Insert: Partial<Database['public']['Tables']['profiles']['Row']> & { id: string; display_name: string }
        Update: Partial<Database['public']['Tables']['profiles']['Row']>
      }
      destinations: {
        Row: {
          id: string
          name: string
          name_ar: string | null
          wilaya: string
          cultural_theme: CulturalTheme
          description: string
          hero_image_url: string | null
          coordinates: unknown
          created_at: string
        }
        Insert: Partial<Database['public']['Tables']['destinations']['Row']> & { name: string; wilaya: string; cultural_theme: CulturalTheme; description: string }
        Update: Partial<Database['public']['Tables']['destinations']['Row']>
      }
      // Tables hotels, sites, restaurants ont la même structure de base — voir migration SQL
      trips: {
        Row: {
          id: string
          created_by: string
          title: string
          title_ar: string | null
          destination_id: string
          duration_days: number
          price_da: number
          description: string
          cover_image_url: string | null
          status: TripStatus
          reviewed_by: string | null
          reviewed_at: string | null
          review_notes: string | null
          published_at: string | null
          created_at: string
        }
        Insert: Partial<Database['public']['Tables']['trips']['Row']> & {
          created_by: string; title: string; destination_id: string; duration_days: number; price_da: number; description: string
        }
        Update: Partial<Database['public']['Tables']['trips']['Row']>
      }
    }
  }
}
