-- Weekly test session alternative for multi-content weeks:
-- strictly filters by selected outcomes + curriculum week (topic-independent).

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

  -- Keep only valid outcomes that belong to selected unit; sort for stable matching.
  SELECT array_agg(o.id ORDER BY o.id)
  INTO v_outcome_ids
  FROM public.outcomes o
  JOIN public.topics t ON t.id = o.topic_id
  WHERE t.unit_id = p_unit_id
    AND o.id = ANY(p_outcome_ids);

  IF v_outcome_ids IS NULL OR array_length(v_outcome_ids, 1) IS NULL THEN
    RETURN NULL;
  END IF;

  -- Reuse active session only when filter context is exactly the same.
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

  SELECT u.lesson_id, ug.grade_id
  INTO v_lesson_id, v_grade_id
  FROM public.units u
  JOIN public.unit_grades ug ON ug.unit_id = u.id
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
