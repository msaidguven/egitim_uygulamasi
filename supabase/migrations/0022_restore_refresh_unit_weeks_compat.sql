-- Restore compatibility for legacy triggers expecting refresh_unit_weeks(bigint, bigint).
-- Also keeps unit_grades.start_week/end_week in sync with current curriculum sources.

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
    -- Curriculum weeks from outcomes (canonical source)
    SELECT generate_series(ow.start_week, ow.end_week)::integer AS week_no
    FROM public.outcomes o
    JOIN public.outcome_weeks ow ON ow.outcome_id = o.id
    JOIN public.topics t ON t.id = o.topic_id
    WHERE t.unit_id = p_unit_id

    UNION

    -- Keep compatibility with question usage week references.
    SELECT qu.curriculum_week::integer AS week_no
    FROM public.question_usages qu
    JOIN public.topics t ON t.id = qu.topic_id
    WHERE t.unit_id = p_unit_id
      AND qu.curriculum_week IS NOT NULL

    UNION

    -- Legacy/derived content week references (auxiliary)
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

  UPDATE public.unit_grades ug
  SET start_week = v_start,
      end_week = v_end
  WHERE ug.unit_id = p_unit_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.refresh_unit_weeks(
  p_unit_id bigint
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM public.refresh_unit_weeks_for_unit(p_unit_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.refresh_unit_weeks(
  p_old_unit_id bigint,
  p_new_unit_id bigint
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_old_unit_id IS NOT NULL THEN
    PERFORM public.refresh_unit_weeks_for_unit(p_old_unit_id);
  END IF;

  IF p_new_unit_id IS NOT NULL AND p_new_unit_id IS DISTINCT FROM p_old_unit_id THEN
    PERFORM public.refresh_unit_weeks_for_unit(p_new_unit_id);
  END IF;
END;
$$;
