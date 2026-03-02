-- Fix RPC parameter-name compatibility for admin panel calls.
-- Some screens call get_units_by_lesson_and_grade with params {lid, gid}.

BEGIN;

-- Recreate to avoid 42P13 (cannot change input parameter name).
DROP FUNCTION IF EXISTS public.get_units_by_lesson_and_grade(bigint, bigint);
CREATE FUNCTION public.get_units_by_lesson_and_grade(
  lid bigint,
  gid bigint
)
RETURNS SETOF public.units
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT u.*
  FROM public.units u
  WHERE u.lesson_id = lid
    AND u.grade_id = gid
    AND u.is_active = true
  ORDER BY u.order_no, u.id;
$$;

-- Legacy helper kept for broad compatibility.
DROP FUNCTION IF EXISTS public.get_units_by_grade(bigint);
CREATE FUNCTION public.get_units_by_grade(
  gid bigint
)
RETURNS SETOF public.units
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT u.*
  FROM public.units u
  WHERE u.grade_id = gid
    AND u.is_active = true
  ORDER BY u.lesson_id, u.order_no, u.id;
$$;

GRANT EXECUTE ON FUNCTION public.get_units_by_lesson_and_grade(bigint, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_units_by_grade(bigint) TO authenticated;

COMMIT;
