-- Return canonical week ranges for a topic (not expanded single weeks).
-- This aligns topic week inspection with outcome_weeks(start_week, end_week).

DROP FUNCTION IF EXISTS public.get_weeks_for_topic(bigint);

CREATE OR REPLACE FUNCTION public.get_weeks_for_topic(p_topic_id bigint)
RETURNS TABLE (
  id integer,
  start_week integer,
  end_week integer,
  outcome_id bigint
)
LANGUAGE sql
AS $$
  SELECT
    row_number() OVER (
      ORDER BY ow.start_week, ow.end_week, o.order_index NULLS LAST, o.id
    )::integer AS id,
    ow.start_week,
    ow.end_week,
    o.id AS outcome_id
  FROM public.outcomes o
  JOIN public.outcome_weeks ow
    ON ow.outcome_id = o.id
  WHERE o.topic_id = p_topic_id
  ORDER BY ow.start_week, ow.end_week, o.order_index NULLS LAST, o.id;
$$;
