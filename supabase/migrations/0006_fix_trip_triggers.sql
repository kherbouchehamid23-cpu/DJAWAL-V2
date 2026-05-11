-- =========================================================
-- DJAWAL V2 — Fix triggers trip_status + current_user_role
-- Évite le bug "SECURITY DEFINER sans search_path"
-- =========================================================

-- 1. Helper current_user_role : ajouter SET search_path
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS app_role
LANGUAGE SQL STABLE
SECURITY DEFINER
SET search_path = public
AS $$ SELECT role FROM profiles WHERE id = auth.uid() $$;

-- 2. Trigger enforce_trip_status_by_role : ajouter SET search_path + EXCEPTION
DROP TRIGGER IF EXISTS trip_status_enforcement ON trips;
DROP FUNCTION IF EXISTS public.enforce_trip_status_by_role() CASCADE;

CREATE OR REPLACE FUNCTION public.enforce_trip_status_by_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller_role app_role;
BEGIN
  BEGIN
    caller_role := public.current_user_role();
  EXCEPTION WHEN OTHERS THEN
    caller_role := 'voyageur'::app_role;
  END;

  IF TG_OP = 'INSERT' THEN
    -- guide_junior ne peut jamais auto-publier
    IF caller_role = 'guide_junior' AND NEW.status = 'published' THEN
      NEW.status := 'pending_review';
    END IF;
    -- guide_senior peut auto-publier
    IF caller_role = 'guide_senior' AND NEW.status = 'published' THEN
      NEW.published_at := NOW();
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trip_status_enforcement
  BEFORE INSERT OR UPDATE ON trips
  FOR EACH ROW EXECUTE FUNCTION public.enforce_trip_status_by_role();
