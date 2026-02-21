-- Update weekly member session creation to prefer outcome-linked weekly questions.
-- Keeps existing behavior: reuse active session, exclude already seen questions.

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
  -- 1) Reuse active weekly session for this unit/week if exists.
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

  -- 2) Build weekly question pool (outcome-first, then legacy fallback),
  -- then remove already seen questions for this user/unit/week.
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

  -- 3) Resolve lesson/grade for session metadata.
  SELECT u.lesson_id, ug.grade_id
  INTO v_lesson_id, v_grade_id
  FROM public.units u
  JOIN public.unit_grades ug ON ug.unit_id = u.id
  WHERE u.id = p_unit_id
  LIMIT 1;

  -- 4) Create session.
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

  -- 5) Persist ordered question rows.
  INSERT INTO public.test_session_questions (test_session_id, question_id, order_no)
  SELECT
    v_session_id,
    q.question_id,
    q.ord::integer
  FROM unnest(v_question_ids) WITH ORDINALITY AS q(question_id, ord);

  RETURN v_session_id;
END;
$$;
