-- Hotfix: resolve ambiguous question_count references in trigger function.

BEGIN;

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

COMMIT;
