-- =========================================================
-- DJAWAL V2 — Sprint B : Opérateurs Touristiques — Partie 4
-- Mise à jour du trigger handle_new_user pour propager
-- operator_type et company_name à la création du profil
-- =========================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_role app_role;
  user_display_name TEXT;
  user_operator_type operator_type;
  user_company_name TEXT;
BEGIN
  -- Parse role (fallback voyageur si invalide)
  BEGIN
    user_role := COALESCE(
      (NEW.raw_user_meta_data->>'role')::app_role,
      'voyageur'::app_role
    );
  EXCEPTION WHEN OTHERS THEN
    user_role := 'voyageur'::app_role;
  END;

  -- display_name avec fallback
  user_display_name := COALESCE(
    NULLIF(trim(NEW.raw_user_meta_data->>'display_name'), ''),
    split_part(COALESCE(NEW.email, 'user@unknown'), '@', 1)
  );

  -- Parse operator_type uniquement si role = tourist_operator
  IF user_role = 'tourist_operator' THEN
    BEGIN
      user_operator_type := (NEW.raw_user_meta_data->>'operator_type')::operator_type;
    EXCEPTION WHEN OTHERS THEN
      user_operator_type := NULL;
    END;
    user_company_name := NULLIF(trim(NEW.raw_user_meta_data->>'company_name'), '');
  ELSE
    user_operator_type := NULL;
    user_company_name := NULL;
  END IF;

  -- Insertion du profile
  -- KYC pending pour guides ET opérateurs (les deux nécessitent validation admin)
  INSERT INTO public.profiles (
    id, display_name, role, kyc_status,
    operator_type, company_name
  )
  VALUES (
    NEW.id,
    user_display_name,
    user_role,
    CASE
      WHEN user_role IN ('guide_senior', 'guide_junior', 'tourist_operator') THEN 'pending'::kyc_status
      ELSE 'not_required'::kyc_status
    END,
    user_operator_type,
    user_company_name
  );

  RETURN NEW;

EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'handle_new_user error: % %', SQLSTATE, SQLERRM;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

COMMENT ON FUNCTION public.handle_new_user IS 'Création automatique du profile à l''inscription. Propage role, operator_type, company_name. KYC pending pour guides et opérateurs.';
