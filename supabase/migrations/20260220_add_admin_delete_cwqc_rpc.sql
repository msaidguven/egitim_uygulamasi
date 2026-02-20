-- Delete curriculum_week_question_counts with elevated privileges.
-- Admin check is enforced inside function.

CREATE OR REPLACE FUNCTION public.admin_delete_cwqc_for_units(
  p_unit_ids bigint[]
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_deleted_count integer := 0;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  IF p_unit_ids IS NULL OR array_length(p_unit_ids, 1) IS NULL THEN
    RETURN 0;
  END IF;

  DELETE FROM public.curriculum_week_question_counts cwqc
  WHERE cwqc.unit_id = ANY(p_unit_ids);

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RETURN v_deleted_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_delete_cwqc_for_units(bigint[]) TO authenticated;
