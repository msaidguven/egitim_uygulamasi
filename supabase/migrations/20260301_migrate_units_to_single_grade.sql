-- Units are now single-grade entities.
-- Migration steps:
-- 1) Add units.grade_id and backfill from unit_grades
-- 2) Enforce FK + NOT NULL
-- 3) Replace unit_grades table with a compatibility view
-- 4) Re-create compatibility RPCs used by app-side forms

BEGIN;

ALTER TABLE public.units
ADD COLUMN IF NOT EXISTS grade_id bigint;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'unit_grades'
  ) THEN
    IF EXISTS (
      SELECT 1
      FROM public.unit_grades ug
      GROUP BY ug.unit_id
      HAVING COUNT(DISTINCT ug.grade_id) > 1
    ) THEN
      RAISE EXCEPTION 'Migration blocked: some units are linked to multiple grade_id values in unit_grades.';
    END IF;

    UPDATE public.units u
    SET grade_id = ug.grade_id
    FROM (
      SELECT unit_id, MIN(grade_id) AS grade_id
      FROM public.unit_grades
      GROUP BY unit_id
    ) ug
    WHERE u.id = ug.unit_id
      AND u.grade_id IS NULL;
  END IF;
END
$$;

-- Fallback: if a lesson belongs to exactly one grade, assign that grade to unmapped units.
UPDATE public.units u
SET grade_id = lg.grade_id
FROM (
  SELECT lesson_id, MIN(grade_id) AS grade_id
  FROM public.lesson_grades
  GROUP BY lesson_id
  HAVING COUNT(*) = 1
) lg
WHERE u.lesson_id = lg.lesson_id
  AND u.grade_id IS NULL;

DO $$
DECLARE
  v_missing bigint[];
BEGIN
  SELECT ARRAY_AGG(id ORDER BY id)
  INTO v_missing
  FROM public.units
  WHERE grade_id IS NULL;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'Migration blocked: units without grade_id remain. unit_ids=%', v_missing;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_units_grade'
      AND conrelid = 'public.units'::regclass
  ) THEN
    ALTER TABLE public.units
    ADD CONSTRAINT fk_units_grade
    FOREIGN KEY (grade_id) REFERENCES public.grades(id);
  END IF;
END
$$;

ALTER TABLE public.units
ALTER COLUMN grade_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_units_grade_id
ON public.units(grade_id);

CREATE INDEX IF NOT EXISTS idx_units_lesson_grade_active_order
ON public.units(lesson_id, grade_id, is_active, order_no);

-- Replace relation table with a compatibility view.
DROP TABLE IF EXISTS public.unit_grades;

CREATE VIEW public.unit_grades AS
SELECT
  u.id AS unit_id,
  u.grade_id,
  week_bounds.end_week,
  week_bounds.start_week
FROM public.units u
LEFT JOIN LATERAL (
  SELECT
    MIN(ow.start_week)::integer AS start_week,
    MAX(ow.end_week)::smallint AS end_week
  FROM public.topics t
  JOIN public.outcomes o ON o.topic_id = t.id
  JOIN public.outcome_weeks ow ON ow.outcome_id = o.id
  WHERE t.unit_id = u.id
) AS week_bounds ON true;

GRANT SELECT ON public.unit_grades TO authenticated;
GRANT SELECT ON public.unit_grades TO anon;
GRANT SELECT ON public.unit_grades TO service_role;

-- Compatibility RPCs (UI still calls these names).
DROP FUNCTION IF EXISTS public.get_units_for_grade_and_lesson(bigint, bigint);
DROP FUNCTION IF EXISTS public.get_units_for_lesson_and_grade(bigint, bigint);
DROP FUNCTION IF EXISTS public.get_unit_details(bigint);
DROP FUNCTION IF EXISTS public.transactional_create_unit(text, bigint, bigint);
DROP FUNCTION IF EXISTS public.transactional_update_unit(bigint, text, bigint, bigint);
DROP FUNCTION IF EXISTS public.get_lessons_by_grade(bigint);
DROP FUNCTION IF EXISTS public.add_weekly_curriculum(bigint, bigint, jsonb, jsonb, integer, text[], text);

CREATE OR REPLACE FUNCTION public.get_units_for_grade_and_lesson(
  p_grade_id bigint,
  p_lesson_id bigint
)
RETURNS SETOF public.units
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT u.*
  FROM public.units u
  WHERE u.grade_id = p_grade_id
    AND u.lesson_id = p_lesson_id
    AND u.is_active = true
  ORDER BY u.order_no, u.id;
$$;

CREATE OR REPLACE FUNCTION public.get_units_for_lesson_and_grade(
  lesson_id_param bigint,
  grade_id_param bigint
)
RETURNS TABLE(
  id bigint,
  title text,
  question_count integer,
  order_no integer
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT
    u.id,
    u.title,
    COALESCE(u.question_count, 0) AS question_count,
    u.order_no
  FROM public.units u
  WHERE u.lesson_id = lesson_id_param
    AND u.grade_id = grade_id_param
    AND u.is_active = true
  ORDER BY u.order_no, u.id;
$$;

CREATE OR REPLACE FUNCTION public.get_unit_details(uid bigint)
RETURNS TABLE(
  unit_id bigint,
  lesson_id bigint,
  grade_id bigint,
  title text
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT u.id, u.lesson_id, u.grade_id, u.title
  FROM public.units u
  WHERE u.id = uid
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.transactional_create_unit(
  p_title text,
  p_lesson_id bigint,
  p_grade_id bigint
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_unit_id bigint;
BEGIN
  INSERT INTO public.units (title, lesson_id, grade_id)
  VALUES (TRIM(p_title), p_lesson_id, p_grade_id)
  RETURNING id INTO v_unit_id;

  RETURN v_unit_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.transactional_update_unit(
  p_unit_id bigint,
  p_title text,
  p_lesson_id bigint,
  p_grade_id bigint
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.units
  SET
    title = TRIM(p_title),
    lesson_id = p_lesson_id,
    grade_id = p_grade_id,
    updated_at = NOW()
  WHERE id = p_unit_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_lessons_by_grade(gid bigint)
RETURNS SETOF public.lessons
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT l.*
  FROM public.lessons l
  JOIN public.lesson_grades lg ON lg.lesson_id = l.id
  WHERE lg.grade_id = gid
    AND l.is_active = true
  ORDER BY l.order_no, l.id;
$$;

CREATE OR REPLACE FUNCTION public.add_weekly_curriculum(
  p_grade_id bigint,
  p_lesson_id bigint,
  p_unit_selection jsonb,
  p_topic_selection jsonb,
  p_curriculum_week integer,
  p_outcomes_text text[],
  p_content_text text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_unit_id BIGINT;
    v_topic_id BIGINT;
    v_outcome_desc TEXT;
    v_new_outcome_id BIGINT;
    v_new_content_id BIGINT;
BEGIN
    IF p_unit_selection->>'type' = 'existing' THEN
        v_unit_id := (p_unit_selection->>'unit_id')::BIGINT;

        PERFORM 1
        FROM public.units u
        WHERE u.id = v_unit_id
          AND u.lesson_id = p_lesson_id
          AND u.grade_id = p_grade_id;

        IF NOT FOUND THEN
          RAISE EXCEPTION 'Selected unit does not belong to given grade/lesson';
        END IF;
    ELSE
        INSERT INTO public.units (lesson_id, grade_id, title)
        VALUES (p_lesson_id, p_grade_id, p_unit_selection->>'new_unit_title')
        RETURNING id INTO v_unit_id;
    END IF;

    IF p_topic_selection->>'type' = 'existing' THEN
        v_topic_id := (p_topic_selection->>'topic_id')::BIGINT;
    ELSE
        INSERT INTO public.topics (unit_id, title, slug)
        VALUES (
            v_unit_id,
            p_topic_selection->>'new_topic_title',
            public.slugify_tr(p_topic_selection->>'new_topic_title')
        )
        RETURNING id INTO v_topic_id;
    END IF;

    IF p_content_text IS NOT NULL AND length(btrim(p_content_text)) > 0 THEN
        INSERT INTO public.topic_contents (topic_id, title, content)
        VALUES (v_topic_id, 'İçerik', p_content_text)
        RETURNING id INTO v_new_content_id;

        INSERT INTO public.topic_content_weeks (topic_content_id, curriculum_week)
        VALUES (v_new_content_id, p_curriculum_week)
        ON CONFLICT (topic_content_id, curriculum_week) DO NOTHING;
    END IF;

    FOREACH v_outcome_desc IN ARRAY p_outcomes_text
    LOOP
        IF v_outcome_desc IS NULL OR btrim(v_outcome_desc) = '' THEN
            CONTINUE;
        END IF;

        INSERT INTO public.outcomes (topic_id, description)
        VALUES (v_topic_id, btrim(v_outcome_desc))
        RETURNING id INTO v_new_outcome_id;

        INSERT INTO public.outcome_weeks (outcome_id, start_week, end_week)
        VALUES (v_new_outcome_id, p_curriculum_week, p_curriculum_week)
        ON CONFLICT (outcome_id, start_week, end_week) DO NOTHING;

        IF v_new_content_id IS NOT NULL THEN
          INSERT INTO public.topic_content_outcomes (topic_content_id, outcome_id)
          VALUES (v_new_content_id, v_new_outcome_id)
          ON CONFLICT DO NOTHING;
        END IF;
    END LOOP;

    RETURN jsonb_build_object(
        'status', 'success',
        'unit_id', v_unit_id,
        'topic_id', v_topic_id
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_units_for_grade_and_lesson(bigint, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_units_for_lesson_and_grade(bigint, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_unit_details(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.transactional_create_unit(text, bigint, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.transactional_update_unit(bigint, text, bigint, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_lessons_by_grade(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_weekly_curriculum(bigint, bigint, jsonb, jsonb, integer, text[], text) TO authenticated;

COMMIT;
