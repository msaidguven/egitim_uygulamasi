-- PostgREST compatibility wrappers for bulk_create_questions.
-- Rationale: named-arg RPC calls that include p_outcome_ids but skip middle
-- optional args (p_start_week/p_end_week) may fail signature matching.

CREATE OR REPLACE FUNCTION public.bulk_create_questions(
    p_topic_id BIGINT,
    p_usage_type TEXT,
    p_questions_json JSONB,
    p_curriculum_week INTEGER,
    p_outcome_ids BIGINT[]
)
RETURNS JSONB
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT public.bulk_create_questions(
    p_topic_id := p_topic_id,
    p_usage_type := p_usage_type,
    p_questions_json := p_questions_json,
    p_curriculum_week := p_curriculum_week,
    p_start_week := NULL,
    p_end_week := NULL,
    p_outcome_ids := p_outcome_ids
  );
$$;

CREATE OR REPLACE FUNCTION public.bulk_create_questions(
    p_topic_id BIGINT,
    p_usage_type TEXT,
    p_questions_json JSONB,
    p_curriculum_week INTEGER
)
RETURNS JSONB
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT public.bulk_create_questions(
    p_topic_id := p_topic_id,
    p_usage_type := p_usage_type,
    p_questions_json := p_questions_json,
    p_curriculum_week := p_curriculum_week,
    p_start_week := NULL,
    p_end_week := NULL,
    p_outcome_ids := NULL
  );
$$;
