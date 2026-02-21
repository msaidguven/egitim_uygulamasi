-- Fix weekly selector: by_outcome branch must also respect curriculum_week
-- on question_usages to avoid pulling questions from other weeks.

CREATE OR REPLACE FUNCTION public.get_weekly_question_ids(
  p_topic_id bigint,
  p_curriculum_week integer,
  p_limit integer DEFAULT 10
)
RETURNS TABLE(question_id bigint, source text)
LANGUAGE sql
STABLE
AS $$
WITH by_outcome AS (
  SELECT DISTINCT qo.question_id
  FROM public.question_outcomes qo
  JOIN public.outcomes o
    ON o.id = qo.outcome_id
  JOIN public.outcome_weeks ow
    ON ow.outcome_id = o.id
  JOIN public.question_usages qu
    ON qu.question_id = qo.question_id
   AND qu.usage_type = 'weekly'
   AND qu.topic_id = p_topic_id
   AND qu.curriculum_week = p_curriculum_week
  WHERE o.topic_id = p_topic_id
    AND p_curriculum_week BETWEEN ow.start_week AND ow.end_week
),
by_week AS (
  SELECT DISTINCT qu.question_id
  FROM public.question_usages qu
  WHERE qu.topic_id = p_topic_id
    AND qu.usage_type = 'weekly'
    AND qu.curriculum_week = p_curriculum_week
),
chosen AS (
  SELECT bo.question_id, 'outcome'::text AS source
  FROM by_outcome bo

  UNION ALL

  SELECT bw.question_id, 'week_fallback'::text AS source
  FROM by_week bw
  WHERE NOT EXISTS (SELECT 1 FROM by_outcome)
),
randomized AS (
  SELECT c.question_id, c.source
  FROM chosen c
  ORDER BY random()
  LIMIT GREATEST(COALESCE(p_limit, 10), 0)
)
SELECT question_id, source
FROM randomized;
$$;
