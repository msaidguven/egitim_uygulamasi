-- Restore outcome_weeks mapping table used by weekly curriculum functions.
-- This migration is idempotent and includes backfill from legacy outcomes.curriculum_week.

CREATE TABLE IF NOT EXISTS public.outcome_weeks (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  outcome_id bigint NOT NULL,
  start_week integer NOT NULL,
  end_week integer NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT outcome_weeks_pkey PRIMARY KEY (id),
  CONSTRAINT outcome_weeks_outcome_id_fkey
    FOREIGN KEY (outcome_id) REFERENCES public.outcomes(id) ON DELETE CASCADE,
  CONSTRAINT outcome_weeks_start_week_check CHECK (start_week >= 1),
  CONSTRAINT outcome_weeks_end_week_check CHECK (end_week >= 1),
  CONSTRAINT outcome_weeks_range_check CHECK (start_week <= end_week)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_outcome_weeks_unique_range
  ON public.outcome_weeks (outcome_id, start_week, end_week);

CREATE INDEX IF NOT EXISTS idx_outcome_weeks_outcome_id
  ON public.outcome_weeks (outcome_id);

CREATE INDEX IF NOT EXISTS idx_outcome_weeks_start_end
  ON public.outcome_weeks (start_week, end_week);

-- Backfill from legacy outcomes.curriculum_week with span merge.
-- If the old system stored the same logical outcome in multiple week rows,
-- we merge those rows into one range (start_week..end_week) and map only one
-- canonical outcome_id (minimum id in the group).
--
-- Group key heuristic:
--   topic_id + normalized(description) + order_index
-- This reduces accidental merges compared to description-only matching.
WITH normalized_outcomes AS (
  SELECT
    MIN(o.id) AS canonical_outcome_id,
    o.topic_id,
    COALESCE(o.order_index, -1) AS order_index_key,
    LOWER(REGEXP_REPLACE(TRIM(o.description), '\s+', ' ', 'g')) AS description_key,
    MIN(o.curriculum_week) AS start_week,
    MAX(o.curriculum_week) AS end_week
  FROM public.outcomes o
  WHERE o.curriculum_week IS NOT NULL
  GROUP BY
    o.topic_id,
    COALESCE(o.order_index, -1),
    LOWER(REGEXP_REPLACE(TRIM(o.description), '\s+', ' ', 'g'))
)
INSERT INTO public.outcome_weeks (outcome_id, start_week, end_week)
SELECT n.canonical_outcome_id, n.start_week, n.end_week
FROM normalized_outcomes n
WHERE NOT EXISTS (
  SELECT 1
  FROM public.outcome_weeks ow
  WHERE ow.outcome_id = n.canonical_outcome_id
    AND ow.start_week = n.start_week
    AND ow.end_week = n.end_week
);
