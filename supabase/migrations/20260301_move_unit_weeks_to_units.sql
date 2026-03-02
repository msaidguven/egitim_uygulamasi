-- Move unit week range to units table.
-- Adds units.start_week/end_week, backfills from curriculum sources,
-- and keeps compatibility view unit_grades working from units columns.

BEGIN;

ALTER TABLE public.units
ADD COLUMN IF NOT EXISTS start_week integer,
ADD COLUMN IF NOT EXISTS end_week integer;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'units_start_week_check'
      AND conrelid = 'public.units'::regclass
  ) THEN
    ALTER TABLE public.units
    ADD CONSTRAINT units_start_week_check
    CHECK (start_week IS NULL OR start_week >= 1);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'units_end_week_check'
      AND conrelid = 'public.units'::regclass
  ) THEN
    ALTER TABLE public.units
    ADD CONSTRAINT units_end_week_check
    CHECK (end_week IS NULL OR end_week >= 1);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'units_week_range_check'
      AND conrelid = 'public.units'::regclass
  ) THEN
    ALTER TABLE public.units
    ADD CONSTRAINT units_week_range_check
    CHECK (
      start_week IS NULL
      OR end_week IS NULL
      OR start_week <= end_week
    );
  END IF;
END
$$;

-- Initial backfill from canonical week sources.
UPDATE public.units u
SET
  start_week = src.start_week,
  end_week = src.end_week
FROM (
  SELECT
    uu.id AS unit_id,
    MIN(w.week_no)::integer AS start_week,
    MAX(w.week_no)::integer AS end_week
  FROM public.units uu
  LEFT JOIN LATERAL (
    SELECT generate_series(ow.start_week, ow.end_week)::integer AS week_no
    FROM public.outcomes o
    JOIN public.outcome_weeks ow ON ow.outcome_id = o.id
    JOIN public.topics t ON t.id = o.topic_id
    WHERE t.unit_id = uu.id

    UNION

    SELECT qu.curriculum_week::integer AS week_no
    FROM public.question_usages qu
    JOIN public.topics t ON t.id = qu.topic_id
    WHERE t.unit_id = uu.id
      AND qu.curriculum_week IS NOT NULL

    UNION

    SELECT tcw.curriculum_week::integer AS week_no
    FROM public.topic_content_weeks tcw
    JOIN public.topic_contents tc ON tc.id = tcw.topic_content_id
    JOIN public.topics t ON t.id = tc.topic_id
    WHERE t.unit_id = uu.id
      AND tcw.curriculum_week IS NOT NULL
  ) AS w ON true
  GROUP BY uu.id
) AS src
WHERE src.unit_id = u.id
  AND (
    u.start_week IS DISTINCT FROM src.start_week
    OR u.end_week IS DISTINCT FROM src.end_week
  );

CREATE INDEX IF NOT EXISTS idx_units_lesson_grade_week_range
ON public.units (lesson_id, grade_id, start_week, end_week);

-- Keep compatibility API name, but persist week range on units.
CREATE OR REPLACE FUNCTION public.refresh_unit_weeks_for_unit(
  p_unit_id bigint
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_start integer;
  v_end integer;
BEGIN
  IF p_unit_id IS NULL THEN
    RETURN;
  END IF;

  WITH unit_weeks AS (
    SELECT generate_series(ow.start_week, ow.end_week)::integer AS week_no
    FROM public.outcomes o
    JOIN public.outcome_weeks ow ON ow.outcome_id = o.id
    JOIN public.topics t ON t.id = o.topic_id
    WHERE t.unit_id = p_unit_id

    UNION

    SELECT qu.curriculum_week::integer AS week_no
    FROM public.question_usages qu
    JOIN public.topics t ON t.id = qu.topic_id
    WHERE t.unit_id = p_unit_id
      AND qu.curriculum_week IS NOT NULL

    UNION

    SELECT tcw.curriculum_week::integer AS week_no
    FROM public.topic_content_weeks tcw
    JOIN public.topic_contents tc ON tc.id = tcw.topic_content_id
    JOIN public.topics t ON t.id = tc.topic_id
    WHERE t.unit_id = p_unit_id
      AND tcw.curriculum_week IS NOT NULL
  )
  SELECT MIN(week_no), MAX(week_no)
  INTO v_start, v_end
  FROM unit_weeks;

  UPDATE public.units u
  SET
    start_week = v_start,
    end_week = v_end,
    updated_at = NOW()
  WHERE u.id = p_unit_id;
END;
$$;

-- Ensure compatibility view returns values from units table.
CREATE OR REPLACE VIEW public.unit_grades AS
SELECT
  u.id AS unit_id,
  u.grade_id,
  u.end_week::smallint AS end_week,
  u.start_week
FROM public.units u;

GRANT SELECT ON public.unit_grades TO authenticated;
GRANT SELECT ON public.unit_grades TO anon;
GRANT SELECT ON public.unit_grades TO service_role;

-- Re-sync all units once using the new refresher.
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT id FROM public.units
  LOOP
    PERFORM public.refresh_unit_weeks_for_unit(r.id);
  END LOOP;
END
$$;

COMMIT;
