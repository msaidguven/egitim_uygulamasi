-- Cleanup: remove legacy unit RPC aliases after app migration to
-- get_units_for_lesson_and_grade / get_units_for_grade_and_lesson.

BEGIN;

DROP FUNCTION IF EXISTS public.get_units_by_lesson_and_grade(bigint, bigint);
DROP FUNCTION IF EXISTS public.get_units_by_grade(bigint);

COMMIT;
