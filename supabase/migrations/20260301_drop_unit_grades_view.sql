-- Remove compatibility view unit_grades after full migration to units.grade_id + units.start_week/end_week.
-- Safety: abort if any public function still references 'unit_grades'.

BEGIN;

DO $$
DECLARE
  v_refs text[];
BEGIN
  SELECT ARRAY_AGG(p.proname ORDER BY p.proname)
  INTO v_refs
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  JOIN pg_get_functiondef(p.oid) f(def) ON true
  WHERE n.nspname = 'public'
    AND f.def ILIKE '%unit_grades%';

  IF v_refs IS NOT NULL THEN
    RAISE EXCEPTION 'Drop blocked: functions still reference unit_grades. functions=%', v_refs;
  END IF;
END
$$;

DROP VIEW IF EXISTS public.unit_grades;

COMMIT;
