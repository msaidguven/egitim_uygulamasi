-- Link weekly questions directly to outcomes so weeks with multiple topics
-- can fetch questions from the active topic/outcome set.

CREATE TABLE IF NOT EXISTS public.question_outcomes (
  question_id bigint NOT NULL,
  outcome_id bigint NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT question_outcomes_pkey PRIMARY KEY (question_id, outcome_id),
  CONSTRAINT question_outcomes_question_id_fkey
    FOREIGN KEY (question_id) REFERENCES public.questions(id) ON DELETE CASCADE,
  CONSTRAINT question_outcomes_outcome_id_fkey
    FOREIGN KEY (outcome_id) REFERENCES public.outcomes(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_question_outcomes_outcome_id
  ON public.question_outcomes (outcome_id);

CREATE INDEX IF NOT EXISTS idx_question_outcomes_question_id
  ON public.question_outcomes (question_id);

-- Backfill for legacy weekly questions:
-- if a weekly question was assigned to (topic, week), connect it to all
-- outcomes of that topic covering that week.
INSERT INTO public.question_outcomes (question_id, outcome_id)
SELECT DISTINCT
  qu.question_id,
  o.id AS outcome_id
FROM public.question_usages qu
JOIN public.outcomes o
  ON o.topic_id = qu.topic_id
JOIN public.outcome_weeks ow
  ON ow.outcome_id = o.id
WHERE qu.usage_type = 'weekly'
  AND qu.curriculum_week IS NOT NULL
  AND qu.curriculum_week BETWEEN ow.start_week AND ow.end_week
ON CONFLICT (question_id, outcome_id) DO NOTHING;

-- Weekly selector preferring outcome-linked questions.
-- Falls back to legacy week-based question_usages when no outcome mapping exists.
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
