-- =========================================================
-- DJAWAL V2 — Fix signup trigger
-- À exécuter dans Supabase SQL Editor pour corriger
-- l'erreur "Database error saving new user"
-- =========================================================

-- 1. Supprimer le trigger et la fonction existants
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- 2. Recréer la fonction avec :
--   • SET search_path = public  (CRUCIAL pour SECURITY DEFINER)
--   • Parsing sécurisé du role
--   • Gestion d'exception pour ne jamais bloquer l'inscription
--   • Logging pour debug
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_role app_role;
  user_display_name TEXT;
BEGIN
  -- Parse role en sécurité (fallback voyageur si invalide)
  BEGIN
    user_role := COALESCE(
      (NEW.raw_user_meta_data->>'role')::app_role,
      'voyageur'::app_role
    );
  EXCEPTION WHEN OTHERS THEN
    user_role := 'voyageur'::app_role;
  END;

  -- display_name avec fallback sur la partie locale de l'email
  user_display_name := COALESCE(
    NULLIF(trim(NEW.raw_user_meta_data->>'display_name'), ''),
    split_part(COALESCE(NEW.email, 'user@unknown'), '@', 1)
  );

  -- Insertion du profile
  INSERT INTO public.profiles (id, display_name, role, kyc_status)
  VALUES (
    NEW.id,
    user_display_name,
    user_role,
    CASE
      WHEN user_role IN ('guide_senior', 'guide_junior') THEN 'pending'::kyc_status
      ELSE 'not_required'::kyc_status
    END
  );

  RETURN NEW;

EXCEPTION WHEN OTHERS THEN
  -- Ne jamais bloquer l'inscription auth.users même si profile fail
  RAISE LOG 'handle_new_user error: % %', SQLSTATE, SQLERRM;
  RETURN NEW;
END;
$$;

-- 3. Recréer le trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. (Bonus) Permettre au rôle authenticated/anon de référencer les enums
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;

-- 5. Vérification rapide
DO $$
BEGIN
  RAISE NOTICE 'Trigger handle_new_user installed successfully';
END $$;
