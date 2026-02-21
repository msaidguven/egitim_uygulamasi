-- Guest weekly test alternative for multi-content weeks:
-- strictly filters by selected outcomes + curriculum week (topic-independent).

CREATE OR REPLACE FUNCTION public.start_guest_test_by_outcomes(
  p_unit_id bigint,
  p_topic_id bigint,
  p_curriculum_week integer,
  p_outcome_ids bigint[],
  p_limit integer DEFAULT 10
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_question_ids bigint[];
  v_effective_limit integer := GREATEST(COALESCE(p_limit, 10), 1);
  v_outcome_ids bigint[];
BEGIN
  IF p_outcome_ids IS NULL OR array_length(p_outcome_ids, 1) IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  -- Keep only valid outcomes that belong to selected unit.
  SELECT array_agg(o.id ORDER BY o.id)
  INTO v_outcome_ids
  FROM public.outcomes o
  JOIN public.topics t ON t.id = o.topic_id
  WHERE o.id = ANY(p_outcome_ids)
    AND t.unit_id = p_unit_id;

  IF v_outcome_ids IS NULL OR array_length(v_outcome_ids, 1) IS NULL THEN
    RETURN '[]'::jsonb;
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
  randomized AS (
    SELECT ep.question_id
    FROM eligible_pool ep
    ORDER BY random()
    LIMIT v_effective_limit
  )
  SELECT array_agg(r.question_id)
  INTO v_question_ids
  FROM randomized r;

  IF v_question_ids IS NULL OR array_length(v_question_ids, 1) = 0 THEN
    RETURN '[]'::jsonb;
  END IF;

  RETURN public.get_questions_details(v_question_ids);
END;
$$;
