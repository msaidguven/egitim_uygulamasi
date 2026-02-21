-- Update unit test session creation with stable ordering and seen-question filtering.

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
  -- 1) Reuse active unit test session if exists.
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

  -- 2) Select unseen questions for this user+unit.
  -- Prefers topic_end-marked items if present; otherwise falls back to any unit question.
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

  -- 3) Resolve lesson/grade metadata.
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
    jsonb_build_object('type', 'unit_test')
  )
  RETURNING id INTO v_session_id;

  -- 5) Persist ordered session question rows.
  INSERT INTO public.test_session_questions (test_session_id, question_id, order_no)
  SELECT
    v_session_id,
    q.question_id,
    q.ord::integer
  FROM unnest(v_question_ids) WITH ORDINALITY AS q(question_id, ord);

  RETURN v_session_id;
END;
$$;
