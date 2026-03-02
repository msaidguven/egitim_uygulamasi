-- Cleanup migration after single-grade-unit transition.
-- Goal: remove runtime dependency on unit_grades relation from core RPCs.

BEGIN;

CREATE OR REPLACE FUNCTION public.start_unit_test(
  p_client_id uuid,
  p_unit_id bigint,
  p_user_id uuid
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_session_id bigint;
  v_question_ids bigint[];
  v_lesson_id bigint;
  v_grade_id bigint;
BEGIN
  SELECT ts.id
  INTO v_session_id
  FROM public.test_sessions ts
  WHERE ts.user_id = p_user_id
    AND ts.unit_id = p_unit_id
    AND ts.completed_at IS NULL
    AND ts.settings->>'type' = 'unit_test'
  LIMIT 1;

  IF v_session_id IS NOT NULL THEN
    RETURN v_session_id;
  END IF;

  WITH unit_questions AS (
    SELECT DISTINCT q.id,
      CASE WHEN qu.usage_type = 'topic_end' THEN 0 ELSE 1 END AS priority
    FROM public.questions q
    JOIN public.question_usages qu ON qu.question_id = q.id
    JOIN public.topics t ON t.id = qu.topic_id
    WHERE t.unit_id = p_unit_id
  ),
  prioritized_pool AS (
    SELECT uq.id
    FROM unit_questions uq
    LEFT JOIN public.user_unit_seen_questions uusq
      ON uusq.question_id = uq.id
     AND uusq.user_id = p_user_id
     AND uusq.unit_id = p_unit_id
    WHERE uusq.question_id IS NULL
    ORDER BY uq.priority, random()
    LIMIT 10
  )
  SELECT array_agg(pp.id)
  INTO v_question_ids
  FROM prioritized_pool pp;

  IF v_question_ids IS NULL OR array_length(v_question_ids, 1) = 0 THEN
    RETURN NULL;
  END IF;

  SELECT u.lesson_id, u.grade_id
  INTO v_lesson_id, v_grade_id
  FROM public.units u
  WHERE u.id = p_unit_id
  LIMIT 1;

  INSERT INTO public.test_sessions (
    user_id,
    unit_id,
    lesson_id,
    grade_id,
    client_id,
    question_ids,
    settings
  )
  VALUES (
    p_user_id,
    p_unit_id,
    v_lesson_id,
    v_grade_id,
    p_client_id,
    v_question_ids,
    jsonb_build_object('type', 'unit_test')
  )
  RETURNING id INTO v_session_id;

  INSERT INTO public.test_session_questions (test_session_id, question_id, order_no)
  SELECT
    v_session_id,
    q.question_id,
    q.ord::integer
  FROM unnest(v_question_ids) WITH ORDINALITY AS q(question_id, ord);

  RETURN v_session_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.start_weekly_test_session(
  p_user_id uuid,
  p_unit_id bigint,
  p_curriculum_week integer,
  p_client_id uuid
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_session_id bigint;
  v_question_ids bigint[];
  v_lesson_id bigint;
  v_grade_id bigint;
BEGIN
  SELECT ts.id
  INTO v_session_id
  FROM public.test_sessions ts
  WHERE ts.user_id = p_user_id
    AND ts.unit_id = p_unit_id
    AND ts.completed_at IS NULL
    AND ts.settings->>'type' = 'weekly'
    AND (ts.settings->>'curriculum_week')::integer = p_curriculum_week
  LIMIT 1;

  IF v_session_id IS NOT NULL THEN
    RETURN v_session_id;
  END IF;

  WITH topic_scope AS (
    SELECT t.id
    FROM public.topics t
    WHERE t.unit_id = p_unit_id
  ),
  weekly_by_outcome AS (
    SELECT DISTINCT qo.question_id
    FROM public.question_outcomes qo
    JOIN public.outcomes o
      ON o.id = qo.outcome_id
    JOIN public.outcome_weeks ow
      ON ow.outcome_id = o.id
     AND p_curriculum_week BETWEEN ow.start_week AND ow.end_week
    JOIN public.question_usages qu
      ON qu.question_id = qo.question_id
     AND qu.topic_id = o.topic_id
     AND qu.usage_type = 'weekly'
     AND qu.curriculum_week = p_curriculum_week
    JOIN topic_scope ts
      ON ts.id = o.topic_id
  ),
  weekly_fallback AS (
    SELECT DISTINCT qu.question_id
    FROM public.question_usages qu
    JOIN topic_scope ts
      ON ts.id = qu.topic_id
    WHERE qu.usage_type = 'weekly'
      AND qu.curriculum_week = p_curriculum_week
  ),
  chosen_pool AS (
    SELECT question_id FROM weekly_by_outcome
    UNION ALL
    SELECT question_id
    FROM weekly_fallback
    WHERE NOT EXISTS (SELECT 1 FROM weekly_by_outcome)
  ),
  unseen_pool AS (
    SELECT cp.question_id
    FROM (
      SELECT DISTINCT question_id FROM chosen_pool
    ) cp
    LEFT JOIN public.user_curriculum_week_seen_questions uwqp
      ON uwqp.question_id = cp.question_id
     AND uwqp.user_id = p_user_id
     AND uwqp.unit_id = p_unit_id
     AND uwqp.curriculum_week = p_curriculum_week
    WHERE uwqp.id IS NULL
  ),
  randomized AS (
    SELECT up.question_id
    FROM unseen_pool up
    ORDER BY random()
    LIMIT 10
  )
  SELECT array_agg(r.question_id)
  INTO v_question_ids
  FROM randomized r;

  IF v_question_ids IS NULL OR array_length(v_question_ids, 1) = 0 THEN
    RETURN NULL;
  END IF;

  SELECT u.lesson_id, u.grade_id
  INTO v_lesson_id, v_grade_id
  FROM public.units u
  WHERE u.id = p_unit_id
  LIMIT 1;

  INSERT INTO public.test_sessions (
    user_id,
    unit_id,
    lesson_id,
    grade_id,
    client_id,
    question_ids,
    settings
  )
  VALUES (
    p_user_id,
    p_unit_id,
    v_lesson_id,
    v_grade_id,
    p_client_id,
    v_question_ids,
    jsonb_build_object('type', 'weekly', 'curriculum_week', p_curriculum_week)
  )
  RETURNING id INTO v_session_id;

  INSERT INTO public.test_session_questions (test_session_id, question_id, order_no)
  SELECT
    v_session_id,
    q.question_id,
    q.ord::integer
  FROM unnest(v_question_ids) WITH ORDINALITY AS q(question_id, ord);

  RETURN v_session_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.start_weekly_test_session_by_outcomes(
  p_user_id uuid,
  p_unit_id bigint,
  p_topic_id bigint,
  p_curriculum_week integer,
  p_outcome_ids bigint[],
  p_client_id uuid,
  p_limit integer DEFAULT 10
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_session_id bigint;
  v_question_ids bigint[];
  v_lesson_id bigint;
  v_grade_id bigint;
  v_effective_limit integer := GREATEST(COALESCE(p_limit, 10), 1);
  v_outcome_ids bigint[];
BEGIN
  IF p_outcome_ids IS NULL OR array_length(p_outcome_ids, 1) IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT array_agg(o.id ORDER BY o.id)
  INTO v_outcome_ids
  FROM public.outcomes o
  JOIN public.topics t ON t.id = o.topic_id
  WHERE t.unit_id = p_unit_id
    AND o.id = ANY(p_outcome_ids);

  IF v_outcome_ids IS NULL OR array_length(v_outcome_ids, 1) IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT ts.id
  INTO v_session_id
  FROM public.test_sessions ts
  WHERE ts.user_id = p_user_id
    AND ts.unit_id = p_unit_id
    AND ts.completed_at IS NULL
    AND ts.settings->>'type' = 'weekly_outcome'
    AND (ts.settings->>'curriculum_week')::integer = p_curriculum_week
    AND ts.settings->'outcome_ids' = to_jsonb(v_outcome_ids)
  LIMIT 1;

  IF v_session_id IS NOT NULL THEN
    RETURN v_session_id;
  END IF;

  WITH eligible_pool AS (
    SELECT DISTINCT qu.question_id
    FROM public.question_usages qu
    JOIN public.question_outcomes qo
      ON qo.question_id = qu.question_id
     AND qo.outcome_id = ANY(v_outcome_ids)
    JOIN public.topics t ON t.id = qu.topic_id
    WHERE t.unit_id = p_unit_id
      AND qu.usage_type = 'weekly'
      AND qu.curriculum_week = p_curriculum_week
  ),
  unseen_pool AS (
    SELECT ep.question_id
    FROM eligible_pool ep
    LEFT JOIN public.user_curriculum_week_seen_questions uwqp
      ON uwqp.question_id = ep.question_id
     AND uwqp.user_id = p_user_id
     AND uwqp.unit_id = p_unit_id
     AND uwqp.curriculum_week = p_curriculum_week
    WHERE uwqp.id IS NULL
  ),
  randomized AS (
    SELECT up.question_id
    FROM unseen_pool up
    ORDER BY random()
    LIMIT v_effective_limit
  )
  SELECT array_agg(r.question_id)
  INTO v_question_ids
  FROM randomized r;

  IF v_question_ids IS NULL OR array_length(v_question_ids, 1) = 0 THEN
    RETURN NULL;
  END IF;

  SELECT u.lesson_id, u.grade_id
  INTO v_lesson_id, v_grade_id
  FROM public.units u
  WHERE u.id = p_unit_id
  LIMIT 1;

  INSERT INTO public.test_sessions (
    user_id,
    unit_id,
    lesson_id,
    grade_id,
    client_id,
    question_ids,
    settings
  )
  VALUES (
    p_user_id,
    p_unit_id,
    v_lesson_id,
    v_grade_id,
    p_client_id,
    v_question_ids,
    jsonb_build_object(
      'type', 'weekly_outcome',
      'curriculum_week', p_curriculum_week,
      'outcome_ids', v_outcome_ids
    )
  )
  RETURNING id INTO v_session_id;

  INSERT INTO public.test_session_questions (test_session_id, question_id, order_no)
  SELECT
    v_session_id,
    q.question_id,
    q.ord::integer
  FROM unnest(v_question_ids) WITH ORDINALITY AS q(question_id, ord);

  RETURN v_session_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_available_weeks(
  p_grade_id bigint,
  p_lesson_id bigint
)
RETURNS TABLE(curriculum_week integer)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
    SELECT DISTINCT
      generate_series(ow.start_week, ow.end_week)::integer AS curriculum_week
    FROM public.outcome_weeks ow
    JOIN public.outcomes o ON o.id = ow.outcome_id
    JOIN public.topics t ON t.id = o.topic_id
    JOIN public.units u ON u.id = t.unit_id
    WHERE
      u.grade_id = p_grade_id
      AND u.lesson_id = p_lesson_id
      AND u.is_active = true
      AND t.is_active = true
      AND ow.start_week IS NOT NULL
      AND ow.end_week IS NOT NULL
    ORDER BY curriculum_week;
END;
$$;

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
)
LANGUAGE plpgsql
AS $$
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
        WHERE tc.topic_id = t.id
          AND (p_is_admin OR tc.is_published = true)
          AND EXISTS (
            SELECT 1
            FROM public.topic_content_outcomes tco
            JOIN public.outcomes o2
              ON o2.id = tco.outcome_id
             AND o2.topic_id = t.id
            JOIN public.outcome_weeks ow2
              ON ow2.outcome_id = o2.id
            WHERE tco.topic_content_id = tc.id
              AND p_curriculum_week BETWEEN ow2.start_week AND ow2.end_week
          )
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
      (uw.end_week = p_curriculum_week) AS is_last_week_of_unit,
      CASE
        WHEN (uw.end_week = p_curriculum_week)
          THEN public.get_unit_summary(p_user_id, u.id, v_client_id)
        ELSE NULL
      END AS unit_summary
    FROM public.outcomes o
    JOIN public.topics t ON t.id = o.topic_id
    JOIN public.units u ON u.id = t.unit_id
    LEFT JOIN LATERAL (
      SELECT MAX(ow.end_week)::integer AS end_week
      FROM public.outcomes o3
      JOIN public.topics t3 ON t3.id = o3.topic_id
      JOIN public.outcome_weeks ow ON ow.outcome_id = o3.id
      WHERE t3.unit_id = u.id
    ) uw ON true
    WHERE u.lesson_id = p_lesson_id
      AND u.grade_id = p_grade_id
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
$$;

DROP FUNCTION IF EXISTS public.get_weekly_dashboard_agenda(uuid, integer, integer);
CREATE OR REPLACE FUNCTION public.get_weekly_dashboard_agenda(
  p_user_id uuid,
  p_grade_id int,
  p_curriculum_week int
)
RETURNS TABLE (
    lesson_id bigint,
    lesson_name text,
    total_questions bigint,
    solved_questions bigint,
    correct_answers bigint,
    grade_id bigint,
    grade_name text,
    current_topic_title text,
    current_unit_id bigint,
    current_curriculum_week int
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH weekly_total_questions AS (
        SELECT
            l.id AS lesson_id,
            sum(cwqc.total_questions)::bigint AS total_questions
        FROM lessons l
        JOIN units u ON l.id = u.lesson_id
        JOIN curriculum_week_question_counts cwqc ON u.id = cwqc.unit_id
        WHERE u.grade_id = p_grade_id
          AND cwqc.curriculum_week = p_curriculum_week
        GROUP BY l.id
    ),
    weekly_user_stats AS (
        SELECT
            u.lesson_id,
            sum(s.correct_count) AS correct_answers,
            sum(s.correct_count + s.wrong_count) AS solved_questions
        FROM (
            SELECT DISTINCT ON (user_id, unit_id, curriculum_week)
                unit_id,
                correct_count,
                wrong_count
            FROM user_curriculum_week_run_summary
            WHERE user_id = p_user_id AND curriculum_week = p_curriculum_week
            ORDER BY user_id, unit_id, curriculum_week, run_no DESC
        ) s
        JOIN units u ON s.unit_id = u.id
        GROUP BY u.lesson_id
    ),
    weekly_focus AS (
        SELECT DISTINCT ON (u.lesson_id)
            u.lesson_id,
            t.title AS topic_title,
            t.unit_id,
            tcw.curriculum_week
        FROM topic_content_weeks tcw
        JOIN topic_contents tc ON tcw.topic_content_id = tc.id
        JOIN topics t ON tc.topic_id = t.id
        JOIN units u ON t.unit_id = u.id
        WHERE tcw.curriculum_week = p_curriculum_week
          AND u.grade_id = p_grade_id
    )
    SELECT
        l.id AS lesson_id,
        l.name AS lesson_name,
        COALESCE(wtq.total_questions, 0) AS total_questions,
        COALESCE(wus.solved_questions, 0) AS solved_questions,
        COALESCE(wus.correct_answers, 0) AS correct_answers,
        g.id AS grade_id,
        g.name AS grade_name,
        wf.topic_title AS current_topic_title,
        wf.unit_id AS current_unit_id,
        wf.curriculum_week AS current_curriculum_week
    FROM lessons l
    INNER JOIN (
        SELECT DISTINCT u.lesson_id
        FROM units u
        WHERE u.grade_id = p_grade_id
    ) AS lessons_for_grade ON l.id = lessons_for_grade.lesson_id
    JOIN grades g ON p_grade_id = g.id
    LEFT JOIN weekly_total_questions wtq ON l.id = wtq.lesson_id
    LEFT JOIN weekly_user_stats wus ON l.id = wus.lesson_id
    LEFT JOIN weekly_focus wf ON l.id = wf.lesson_id
    WHERE l.is_active = true
    ORDER BY l.order_no;
END;
$$;

-- After single-grade transition unit week range is derived from outcomes/content.
-- Keep compatibility function names, but make write path a no-op.
CREATE OR REPLACE FUNCTION public.refresh_unit_weeks_for_unit(
  p_unit_id bigint
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION public.refresh_unit_weeks(
  p_unit_id bigint
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM public.refresh_unit_weeks_for_unit(p_unit_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.refresh_unit_weeks(
  p_old_unit_id bigint,
  p_new_unit_id bigint
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_old_unit_id IS NOT NULL THEN
    PERFORM public.refresh_unit_weeks_for_unit(p_old_unit_id);
  END IF;

  IF p_new_unit_id IS NOT NULL AND p_new_unit_id IS DISTINCT FROM p_old_unit_id THEN
    PERFORM public.refresh_unit_weeks_for_unit(p_new_unit_id);
  END IF;
END;
$$;

DROP FUNCTION IF EXISTS public.clone_unit_to_grade_legacy(bigint, bigint, text);
DROP FUNCTION IF EXISTS public.split_multi_grade_units_legacy();

COMMIT;
