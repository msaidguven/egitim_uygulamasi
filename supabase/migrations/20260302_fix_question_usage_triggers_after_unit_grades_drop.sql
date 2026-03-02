-- Fix question_usages insert/delete triggers after removing unit_grades view.
-- Keeps only the single-grade-safe trigger logic (units.grade_id based).

BEGIN;

-- Remove legacy insert-only trigger/function if present.
DROP TRIGGER IF EXISTS on_question_usage_created ON public.question_usages;
DROP FUNCTION IF EXISTS public.handle_new_question_usage();

-- Recreate canonical trigger function (safe for single-grade model).
CREATE OR REPLACE FUNCTION public.handle_question_usage_change()
RETURNS TRIGGER AS $$
DECLARE
  v_unit_id bigint;
  v_lesson_id bigint;
  rec RECORD;
  modifier integer;
BEGIN
  IF (TG_OP = 'DELETE') THEN
    rec := OLD;
    modifier := -1;
  ELSE
    rec := NEW;
    modifier := 1;
  END IF;

  SELECT t.unit_id, u.lesson_id
  INTO v_unit_id, v_lesson_id
  FROM public.topics t
  JOIN public.units u ON u.id = t.unit_id
  WHERE t.id = rec.topic_id;

  IF v_unit_id IS NULL THEN
    RETURN NULL;
  END IF;

  UPDATE public.units
  SET question_count = question_count + modifier
  WHERE id = v_unit_id;

  UPDATE public.lesson_grades lg
  SET question_count = lg.question_count + modifier
  FROM public.units u
  WHERE u.id = v_unit_id
    AND lg.grade_id = u.grade_id
    AND lg.lesson_id = v_lesson_id;

  UPDATE public.grades g
  SET question_count = g.question_count + modifier
  FROM public.units u
  WHERE u.id = v_unit_id
    AND u.grade_id = g.id;

  IF rec.curriculum_week IS NOT NULL THEN
    IF (TG_OP = 'INSERT') THEN
      INSERT INTO public.curriculum_week_question_counts (unit_id, curriculum_week, total_questions)
      VALUES (v_unit_id, rec.curriculum_week, 1)
      ON CONFLICT ON CONSTRAINT curriculum_week_question_counts_unique_key
      DO UPDATE SET total_questions = curriculum_week_question_counts.total_questions + 1;
    ELSE
      UPDATE public.curriculum_week_question_counts
      SET total_questions = total_questions - 1
      WHERE unit_id = v_unit_id
        AND curriculum_week = rec.curriculum_week;
    END IF;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Keep exactly one trigger for this job.
DROP TRIGGER IF EXISTS on_question_usage_change ON public.question_usages;
CREATE TRIGGER on_question_usage_change
AFTER INSERT OR DELETE ON public.question_usages
FOR EACH ROW
EXECUTE FUNCTION public.handle_question_usage_change();

COMMIT;
