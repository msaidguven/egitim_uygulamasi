-- Align weekly curriculum RPCs with outcome_weeks model.

CREATE OR REPLACE FUNCTION public.get_available_weeks(
  p_grade_id bigint,
  p_lesson_id bigint
)
RETURNS TABLE(curriculum_week integer) AS $$
BEGIN
  RETURN QUERY
    SELECT DISTINCT
      q.curriculum_week
    FROM (
      SELECT
        generate_series(ow.start_week, ow.end_week)::integer AS curriculum_week
      FROM public.outcome_weeks ow
      JOIN public.outcomes o ON o.id = ow.outcome_id
      JOIN public.topics t ON t.id = o.topic_id
      JOIN public.units u ON u.id = t.unit_id
      JOIN public.unit_grades ug ON ug.unit_id = u.id
      WHERE
        ug.grade_id = p_grade_id
        AND u.lesson_id = p_lesson_id
        AND u.is_active = true
        AND t.is_active = true
        AND ow.start_week IS NOT NULL
        AND ow.end_week IS NOT NULL

      UNION

      SELECT
        tcw.curriculum_week
      FROM public.topic_content_weeks tcw
      JOIN public.topic_contents tc ON tc.id = tcw.topic_content_id
      JOIN public.topics t ON t.id = tc.topic_id
      JOIN public.units u ON u.id = t.unit_id
      JOIN public.unit_grades ug ON ug.unit_id = u.id
      WHERE
        ug.grade_id = p_grade_id
        AND u.lesson_id = p_lesson_id
        AND u.is_active = true
        AND t.is_active = true
        AND tcw.curriculum_week IS NOT NULL
    ) AS q
    ORDER BY q.curriculum_week;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.get_weekly_curriculum(
    p_user_id uuid,
    p_grade_id int,
    p_lesson_id int,
    p_curriculum_week int,
    p_is_admin boolean
)
RETURNS TABLE (
    outcome_id bigint,
    outcome_description text,
    unit_id bigint,
    unit_title text,
    topic_id bigint,
    topic_title text,
    contents jsonb,
    mini_quiz_questions jsonb,
    is_last_week_of_unit boolean,
    unit_summary jsonb
) AS $$
DECLARE
    v_client_id uuid;
BEGIN
    IF p_user_id IS NOT NULL THEN
      SELECT id INTO v_client_id
      FROM public.profiles
      WHERE id = p_user_id;
    END IF;

    RETURN QUERY
    SELECT
      o.id AS outcome_id,
      o.description AS outcome_description,
      u.id AS unit_id,
      u.title AS unit_title,
      t.id AS topic_id,
      t.title AS topic_title,
      (
        SELECT COALESCE(
          jsonb_agg(
            jsonb_build_object(
              'id', tc.id,
              'topic_id', tc.topic_id,
              'title', tc.title,
              'content', tc.content,
              'order_no', tc.order_no,
              'is_published', tc.is_published
            )
            ORDER BY tc.order_no
          ),
          '[]'::jsonb
        )
        FROM public.topic_contents tc
        JOIN public.topic_content_weeks tcw
          ON tc.id = tcw.topic_content_id
        WHERE tc.topic_id = t.id
          AND tcw.curriculum_week = p_curriculum_week
          AND (p_is_admin OR tc.is_published = true)
      ) AS contents,
      (
        SELECT jsonb_agg(public.get_question_details(q.id, p_user_id))
        FROM (
          SELECT q_inner.id
          FROM public.questions q_inner
          JOIN public.question_usages qu
            ON q_inner.id = qu.question_id
          WHERE qu.curriculum_week = p_curriculum_week
            AND qu.topic_id = t.id
            AND q_inner.question_type_id IN (1, 2)
          ORDER BY random()
          LIMIT 5
        ) q
      ) AS mini_quiz_questions,
      (ug.end_week = p_curriculum_week) AS is_last_week_of_unit,
      CASE
        WHEN (ug.end_week = p_curriculum_week)
          THEN public.get_unit_summary(p_user_id, u.id, v_client_id)
        ELSE NULL
      END AS unit_summary
    FROM public.outcomes o
    JOIN public.topics t ON t.id = o.topic_id
    JOIN public.units u ON u.id = t.unit_id
    JOIN public.unit_grades ug ON ug.unit_id = u.id
      AND ug.grade_id = p_grade_id
    WHERE u.lesson_id = p_lesson_id
      AND u.is_active = true
      AND t.is_active = true
      AND EXISTS (
        SELECT 1
        FROM public.outcome_weeks ow
        WHERE ow.outcome_id = o.id
          AND p_curriculum_week BETWEEN ow.start_week AND ow.end_week
      )
    ORDER BY o.order_index;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.get_weeks_for_topic(p_topic_id bigint)
RETURNS TABLE (
  id integer,
  start_week integer,
  outcome_id bigint
)
LANGUAGE sql
AS $$
  WITH expanded AS (
    SELECT
      o.id AS outcome_id,
      generate_series(ow.start_week, ow.end_week)::integer AS week_no
    FROM public.outcomes o
    JOIN public.outcome_weeks ow
      ON ow.outcome_id = o.id
    WHERE o.topic_id = p_topic_id
  )
  SELECT
    row_number() OVER (ORDER BY week_no)::integer AS id,
    week_no AS start_week,
    min(outcome_id) AS outcome_id
  FROM expanded
  GROUP BY week_no
  ORDER BY week_no;
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
    ELSE
        INSERT INTO public.units (lesson_id, title)
        VALUES (p_lesson_id, p_unit_selection->>'new_unit_title')
        RETURNING id INTO v_unit_id;
    END IF;

    INSERT INTO public.unit_grades (unit_id, grade_id)
    VALUES (v_unit_id, p_grade_id)
    ON CONFLICT (unit_id, grade_id) DO NOTHING;

    IF p_topic_selection->>'type' = 'existing' THEN
        v_topic_id := (p_topic_selection->>'topic_id')::BIGINT;
    ELSE
        INSERT INTO public.topics (unit_id, title, slug)
        VALUES (
            v_unit_id,
            p_topic_selection->>'new_topic_title',
            lower(regexp_replace(p_topic_selection->>'new_topic_title', '\s+', '-', 'g'))
        )
        RETURNING id INTO v_topic_id;
    END IF;

    IF p_content_text IS NOT NULL AND length(btrim(p_content_text)) > 0 THEN
        INSERT INTO public.topic_contents (topic_id, title, content)
        VALUES (v_topic_id, 'İçerik', p_content_text)
        RETURNING id INTO v_new_content_id;

        INSERT INTO public.topic_content_weeks (topic_content_id, curriculum_week)
        VALUES (v_new_content_id, p_curriculum_week);
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
    END LOOP;

    RETURN jsonb_build_object(
        'status', 'success',
        'unit_id', v_unit_id,
        'topic_id', v_topic_id
    );
END;
$$;
