-- Make content-week data robust and introduce canonical content<->outcome mapping.

-- 1) Harden topic_content_weeks
DELETE FROM public.topic_content_weeks
WHERE curriculum_week IS NULL;

WITH d AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY topic_content_id, curriculum_week
      ORDER BY id
    ) AS rn
  FROM public.topic_content_weeks
)
DELETE FROM public.topic_content_weeks t
USING d
WHERE t.id = d.id
  AND d.rn > 1;

ALTER TABLE public.topic_content_weeks
  ALTER COLUMN curriculum_week SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'topic_content_weeks_curriculum_week_check'
      AND conrelid = 'public.topic_content_weeks'::regclass
  ) THEN
    ALTER TABLE public.topic_content_weeks
      ADD CONSTRAINT topic_content_weeks_curriculum_week_check
      CHECK (curriculum_week >= 1);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_topic_content_weeks_content_week
  ON public.topic_content_weeks (topic_content_id, curriculum_week);

-- 2) Canonical mapping: topic_content_outcomes
CREATE TABLE IF NOT EXISTS public.topic_content_outcomes (
  topic_content_id bigint NOT NULL,
  outcome_id bigint NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT topic_content_outcomes_pkey PRIMARY KEY (topic_content_id, outcome_id),
  CONSTRAINT topic_content_outcomes_topic_content_id_fkey
    FOREIGN KEY (topic_content_id) REFERENCES public.topic_contents(id) ON DELETE CASCADE,
  CONSTRAINT topic_content_outcomes_outcome_id_fkey
    FOREIGN KEY (outcome_id) REFERENCES public.outcomes(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_topic_content_outcomes_outcome_id
  ON public.topic_content_outcomes (outcome_id);

-- 3) Sync helpers
CREATE OR REPLACE FUNCTION public.refresh_topic_content_outcomes_for_content(
  p_topic_content_id bigint
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM public.topic_content_outcomes
  WHERE topic_content_id = p_topic_content_id;

  INSERT INTO public.topic_content_outcomes (topic_content_id, outcome_id)
  SELECT DISTINCT
    tc.id,
    o.id
  FROM public.topic_contents tc
  JOIN public.topic_content_weeks tcw
    ON tcw.topic_content_id = tc.id
  JOIN public.outcomes o
    ON o.topic_id = tc.topic_id
  JOIN public.outcome_weeks ow
    ON ow.outcome_id = o.id
   AND tcw.curriculum_week BETWEEN ow.start_week AND ow.end_week
  WHERE tc.id = p_topic_content_id
  ON CONFLICT DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION public.refresh_topic_content_outcomes_for_topic(
  p_topic_id bigint
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM public.topic_content_outcomes tco
  USING public.topic_contents tc
  WHERE tco.topic_content_id = tc.id
    AND tc.topic_id = p_topic_id;

  INSERT INTO public.topic_content_outcomes (topic_content_id, outcome_id)
  SELECT DISTINCT
    tc.id,
    o.id
  FROM public.topic_contents tc
  JOIN public.topic_content_weeks tcw
    ON tcw.topic_content_id = tc.id
  JOIN public.outcomes o
    ON o.topic_id = tc.topic_id
  JOIN public.outcome_weeks ow
    ON ow.outcome_id = o.id
   AND tcw.curriculum_week BETWEEN ow.start_week AND ow.end_week
  WHERE tc.topic_id = p_topic_id
  ON CONFLICT DO NOTHING;
END;
$$;

-- 4) Backfill initial mappings
INSERT INTO public.topic_content_outcomes (topic_content_id, outcome_id)
SELECT DISTINCT
  tc.id,
  o.id
FROM public.topic_contents tc
JOIN public.topic_content_weeks tcw
  ON tcw.topic_content_id = tc.id
JOIN public.outcomes o
  ON o.topic_id = tc.topic_id
JOIN public.outcome_weeks ow
  ON ow.outcome_id = o.id
 AND tcw.curriculum_week BETWEEN ow.start_week AND ow.end_week
ON CONFLICT DO NOTHING;

-- 5) Keep mappings fresh on changes
CREATE OR REPLACE FUNCTION public.trg_refresh_tco_on_tcw_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM public.refresh_topic_content_outcomes_for_content(OLD.topic_content_id);
    RETURN OLD;
  END IF;

  PERFORM public.refresh_topic_content_outcomes_for_content(NEW.topic_content_id);

  IF TG_OP = 'UPDATE' AND OLD.topic_content_id IS DISTINCT FROM NEW.topic_content_id THEN
    PERFORM public.refresh_topic_content_outcomes_for_content(OLD.topic_content_id);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_refresh_tco_on_tcw_change ON public.topic_content_weeks;
CREATE TRIGGER trg_refresh_tco_on_tcw_change
AFTER INSERT OR UPDATE OR DELETE ON public.topic_content_weeks
FOR EACH ROW
EXECUTE FUNCTION public.trg_refresh_tco_on_tcw_change();

CREATE OR REPLACE FUNCTION public.trg_refresh_tco_on_outcome_weeks_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_topic_id bigint;
BEGIN
  IF TG_OP = 'DELETE' THEN
    SELECT topic_id INTO v_topic_id
    FROM public.outcomes
    WHERE id = OLD.outcome_id;
  ELSE
    SELECT topic_id INTO v_topic_id
    FROM public.outcomes
    WHERE id = NEW.outcome_id;
  END IF;

  IF v_topic_id IS NOT NULL THEN
    PERFORM public.refresh_topic_content_outcomes_for_topic(v_topic_id);
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_refresh_tco_on_outcome_weeks_change ON public.outcome_weeks;
CREATE TRIGGER trg_refresh_tco_on_outcome_weeks_change
AFTER INSERT OR UPDATE OR DELETE ON public.outcome_weeks
FOR EACH ROW
EXECUTE FUNCTION public.trg_refresh_tco_on_outcome_weeks_change();

CREATE OR REPLACE FUNCTION public.trg_refresh_tco_on_outcomes_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_topic_id bigint;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_topic_id := OLD.topic_id;
  ELSE
    v_topic_id := NEW.topic_id;
  END IF;

  IF v_topic_id IS NOT NULL THEN
    PERFORM public.refresh_topic_content_outcomes_for_topic(v_topic_id);
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.topic_id IS DISTINCT FROM NEW.topic_id THEN
    PERFORM public.refresh_topic_content_outcomes_for_topic(OLD.topic_id);
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_refresh_tco_on_outcomes_change ON public.outcomes;
CREATE TRIGGER trg_refresh_tco_on_outcomes_change
AFTER INSERT OR UPDATE OR DELETE ON public.outcomes
FOR EACH ROW
EXECUTE FUNCTION public.trg_refresh_tco_on_outcomes_change();
