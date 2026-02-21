-- Avoid PostgREST overload ambiguity by exposing a single, unique RPC name.

CREATE OR REPLACE FUNCTION public.get_outcome_scope_stats_v2(
  p_user_id uuid,
  p_unit_id bigint,
  p_curriculum_week integer,
  p_outcome_ids bigint[],
  p_question_ids bigint[]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_outcome_ids bigint[];
  v_session_ids bigint[];
  v_solved_unique integer := 0;
  v_correct_count integer := 0;
  v_wrong_count integer := 0;
BEGIN
  IF p_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'solved_unique', 0,
      'correct_count', 0,
      'wrong_count', 0
    );
  END IF;

  IF p_question_ids IS NULL OR array_length(p_question_ids, 1) IS NULL THEN
    RETURN jsonb_build_object(
      'solved_unique', 0,
      'correct_count', 0,
      'wrong_count', 0
    );
  END IF;

  SELECT array_agg(o.id ORDER BY o.id)
  INTO v_outcome_ids
  FROM public.outcomes o
  JOIN public.topics t ON t.id = o.topic_id
  WHERE t.unit_id = p_unit_id
    AND o.id = ANY(p_outcome_ids);

  IF v_outcome_ids IS NULL OR array_length(v_outcome_ids, 1) IS NULL THEN
    RETURN jsonb_build_object(
      'solved_unique', 0,
      'correct_count', 0,
      'wrong_count', 0
    );
  END IF;

  WITH candidate_sessions AS (
    SELECT ts.id, ts.settings
    FROM public.test_sessions ts
    WHERE ts.user_id = p_user_id
      AND ts.unit_id = p_unit_id
      AND (ts.settings->>'curriculum_week')::integer = p_curriculum_week
      AND ts.settings->>'type' = 'weekly_outcome'
  ),
  matched_sessions AS (
    SELECT cs.id
    FROM candidate_sessions cs
    WHERE (
      SELECT array_agg(v::bigint ORDER BY v::bigint)
      FROM jsonb_array_elements_text(
        COALESCE(cs.settings->'outcome_ids', '[]'::jsonb)
      ) AS x(v)
    ) = v_outcome_ids
  )
  SELECT array_agg(ms.id)
  INTO v_session_ids
  FROM matched_sessions ms;

  IF v_session_ids IS NULL OR array_length(v_session_ids, 1) IS NULL THEN
    RETURN jsonb_build_object(
      'solved_unique', 0,
      'correct_count', 0,
      'wrong_count', 0
    );
  END IF;

  WITH latest_answers AS (
    SELECT DISTINCT ON (tsa.question_id)
      tsa.question_id,
      COALESCE(tsa.is_correct, false) AS is_correct
    FROM public.test_session_answers tsa
    WHERE tsa.test_session_id = ANY(v_session_ids)
      AND tsa.question_id = ANY(p_question_ids)
    ORDER BY tsa.question_id, tsa.created_at DESC, tsa.id DESC
  )
  SELECT
    COUNT(*)::integer,
    COUNT(*) FILTER (WHERE la.is_correct)::integer,
    COUNT(*) FILTER (WHERE NOT la.is_correct)::integer
  INTO
    v_solved_unique,
    v_correct_count,
    v_wrong_count
  FROM latest_answers la;

  RETURN jsonb_build_object(
    'solved_unique', COALESCE(v_solved_unique, 0),
    'correct_count', COALESCE(v_correct_count, 0),
    'wrong_count', COALESCE(v_wrong_count, 0)
  );
END;
$$;
