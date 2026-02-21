-- Update guest test selection logic to support outcome-linked weekly questions.
-- Weekly flow now prefers question_outcomes + outcome_weeks; falls back to legacy weekly usages.

CREATE OR REPLACE FUNCTION public.start_guest_test(
  p_unit_id bigint,
  p_type text,
  p_curriculum_week integer DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_question_ids bigint[];
  v_questions_json jsonb;
BEGIN
  IF p_type = 'weekly' THEN
    IF p_curriculum_week IS NULL THEN
      RAISE EXCEPTION 'Haftalık testler için "p_curriculum_week" parametresi gereklidir.';
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
    chosen AS (
      SELECT question_id FROM weekly_by_outcome
      UNION ALL
      SELECT question_id
      FROM weekly_fallback
      WHERE NOT EXISTS (SELECT 1 FROM weekly_by_outcome)
    ),
    randomized AS (
      SELECT d.question_id
      FROM (
        SELECT DISTINCT c.question_id
        FROM chosen c
      ) d
      ORDER BY random()
      LIMIT 10
    )
    SELECT array_agg(r.question_id)
    INTO v_question_ids
    FROM randomized r;

  ELSIF p_type = 'unit' THEN
    -- Unit guest test: keep broad selection from unit scope.
    SELECT array_agg(sub.id)
    INTO v_question_ids
    FROM (
      SELECT q.id
      FROM public.questions q
      JOIN public.question_usages qu ON q.id = qu.question_id
      JOIN public.topics t ON qu.topic_id = t.id
      WHERE t.unit_id = p_unit_id
      ORDER BY random()
      LIMIT 10
    ) sub;

  ELSE
    RAISE EXCEPTION 'Geçersiz test tipi: %. Geçerli tipler ''weekly'' veya ''unit'' olabilir.', p_type;
  END IF;

  IF v_question_ids IS NULL OR array_length(v_question_ids, 1) IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  SELECT public.get_questions_details(v_question_ids)
  INTO v_questions_json;

  RETURN COALESCE(v_questions_json, '[]'::jsonb);
END;
$$;
