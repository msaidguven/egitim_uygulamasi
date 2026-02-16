-- Deduplicate legacy repeated outcomes.
-- Strategy:
-- 1) Group logical duplicates by topic_id + normalized(description) + order_index.
-- 2) Pick canonical row as MIN(id).
-- 3) Move outcome_weeks rows from duplicate IDs to canonical ID.
-- 4) Remove duplicate outcomes rows.

WITH normalized_outcomes AS (
  SELECT
    MIN(o.id) AS canonical_outcome_id,
    o.topic_id,
    COALESCE(o.order_index, -1) AS order_index_key,
    LOWER(REGEXP_REPLACE(TRIM(o.description), '\s+', ' ', 'g')) AS description_key
  FROM public.outcomes o
  GROUP BY
    o.topic_id,
    COALESCE(o.order_index, -1),
    LOWER(REGEXP_REPLACE(TRIM(o.description), '\s+', ' ', 'g'))
), duplicate_map AS (
  SELECT
    o.id AS duplicate_outcome_id,
    n.canonical_outcome_id
  FROM public.outcomes o
  JOIN normalized_outcomes n
    ON n.topic_id = o.topic_id
   AND n.order_index_key = COALESCE(o.order_index, -1)
   AND n.description_key = LOWER(REGEXP_REPLACE(TRIM(o.description), '\s+', ' ', 'g'))
  WHERE o.id <> n.canonical_outcome_id
)
INSERT INTO public.outcome_weeks (outcome_id, start_week, end_week)
SELECT
  dm.canonical_outcome_id,
  ow.start_week,
  ow.end_week
FROM duplicate_map dm
JOIN public.outcome_weeks ow
  ON ow.outcome_id = dm.duplicate_outcome_id
ON CONFLICT (outcome_id, start_week, end_week) DO NOTHING;

WITH normalized_outcomes AS (
  SELECT
    MIN(o.id) AS canonical_outcome_id,
    o.topic_id,
    COALESCE(o.order_index, -1) AS order_index_key,
    LOWER(REGEXP_REPLACE(TRIM(o.description), '\s+', ' ', 'g')) AS description_key
  FROM public.outcomes o
  GROUP BY
    o.topic_id,
    COALESCE(o.order_index, -1),
    LOWER(REGEXP_REPLACE(TRIM(o.description), '\s+', ' ', 'g'))
), duplicate_map AS (
  SELECT
    o.id AS duplicate_outcome_id,
    n.canonical_outcome_id
  FROM public.outcomes o
  JOIN normalized_outcomes n
    ON n.topic_id = o.topic_id
   AND n.order_index_key = COALESCE(o.order_index, -1)
   AND n.description_key = LOWER(REGEXP_REPLACE(TRIM(o.description), '\s+', ' ', 'g'))
  WHERE o.id <> n.canonical_outcome_id
)
DELETE FROM public.outcome_weeks ow
USING duplicate_map dm
WHERE ow.outcome_id = dm.duplicate_outcome_id;

WITH normalized_outcomes AS (
  SELECT
    MIN(o.id) AS canonical_outcome_id,
    o.topic_id,
    COALESCE(o.order_index, -1) AS order_index_key,
    LOWER(REGEXP_REPLACE(TRIM(o.description), '\s+', ' ', 'g')) AS description_key
  FROM public.outcomes o
  GROUP BY
    o.topic_id,
    COALESCE(o.order_index, -1),
    LOWER(REGEXP_REPLACE(TRIM(o.description), '\s+', ' ', 'g'))
), duplicate_map AS (
  SELECT
    o.id AS duplicate_outcome_id,
    n.canonical_outcome_id
  FROM public.outcomes o
  JOIN normalized_outcomes n
    ON n.topic_id = o.topic_id
   AND n.order_index_key = COALESCE(o.order_index, -1)
   AND n.description_key = LOWER(REGEXP_REPLACE(TRIM(o.description), '\s+', ' ', 'g'))
  WHERE o.id <> n.canonical_outcome_id
)
DELETE FROM public.outcomes o
USING duplicate_map dm
WHERE o.id = dm.duplicate_outcome_id;
