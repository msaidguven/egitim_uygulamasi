-- Post-migration helper for single-grade model.
-- Requires units.grade_id column (run after 20260301_migrate_units_to_single_grade.sql).

BEGIN;

CREATE OR REPLACE FUNCTION public.clone_unit_to_grade(
  p_source_unit_id bigint,
  p_target_grade_id bigint,
  p_new_title text DEFAULT NULL
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_source_unit public.units%ROWTYPE;
  v_new_unit_id bigint;
  v_new_unit_order_no integer;

  v_old_topic_id bigint;
  v_new_topic_id bigint;

  v_old_outcome_id bigint;
  v_new_outcome_id bigint;

  v_old_content_id bigint;
  v_new_content_id bigint;
BEGIN
  SELECT *
  INTO v_source_unit
  FROM public.units
  WHERE id = p_source_unit_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Source unit not found. unit_id=%', p_source_unit_id;
  END IF;

  IF v_source_unit.grade_id = p_target_grade_id THEN
    RAISE EXCEPTION 'Source unit is already in target grade_id=%', p_target_grade_id;
  END IF;

  -- Avoid unique conflict on (lesson_id, order_no).
  SELECT COALESCE(MAX(u.order_no), -1) + 1
  INTO v_new_unit_order_no
  FROM public.units u
  WHERE u.lesson_id = v_source_unit.lesson_id;

  INSERT INTO public.units (
    lesson_id,
    grade_id,
    title,
    description,
    order_no,
    is_active,
    created_at,
    updated_at,
    slug,
    question_count
  )
  VALUES (
    v_source_unit.lesson_id,
    p_target_grade_id,
    COALESCE(NULLIF(btrim(p_new_title), ''), v_source_unit.title || ' (Kopya)'),
    v_source_unit.description,
    v_new_unit_order_no,
    v_source_unit.is_active,
    now(),
    now(),
    NULL,
    0
  )
  RETURNING id INTO v_new_unit_id;

  CREATE TEMP TABLE IF NOT EXISTS tmp_topic_map (
    old_id bigint PRIMARY KEY,
    new_id bigint NOT NULL
  ) ON COMMIT DROP;

  CREATE TEMP TABLE IF NOT EXISTS tmp_outcome_map (
    old_id bigint PRIMARY KEY,
    new_id bigint NOT NULL
  ) ON COMMIT DROP;

  CREATE TEMP TABLE IF NOT EXISTS tmp_content_map (
    old_id bigint PRIMARY KEY,
    new_id bigint NOT NULL
  ) ON COMMIT DROP;

  TRUNCATE tmp_topic_map;
  TRUNCATE tmp_outcome_map;
  TRUNCATE tmp_content_map;

  FOR v_old_topic_id IN
    SELECT t.id
    FROM public.topics t
    WHERE t.unit_id = p_source_unit_id
    ORDER BY t.order_no, t.id
  LOOP
    INSERT INTO public.topics (
      unit_id,
      title,
      slug,
      order_no,
      is_active,
      order_status,
      pending_order_no,
      created_at,
      question_count
    )
    SELECT
      v_new_unit_id,
      t.title,
      t.slug,
      t.order_no,
      t.is_active,
      t.order_status,
      t.pending_order_no,
      now(),
      0
    FROM public.topics t
    WHERE t.id = v_old_topic_id
    RETURNING id INTO v_new_topic_id;

    INSERT INTO tmp_topic_map (old_id, new_id)
    VALUES (v_old_topic_id, v_new_topic_id);
  END LOOP;

  FOR v_old_outcome_id IN
    SELECT o.id
    FROM public.outcomes o
    JOIN tmp_topic_map tm ON tm.old_id = o.topic_id
    ORDER BY o.id
  LOOP
    INSERT INTO public.outcomes (topic_id, description, order_index)
    SELECT tm.new_id, o.description, o.order_index
    FROM public.outcomes o
    JOIN tmp_topic_map tm ON tm.old_id = o.topic_id
    WHERE o.id = v_old_outcome_id
    RETURNING id INTO v_new_outcome_id;

    INSERT INTO tmp_outcome_map (old_id, new_id)
    VALUES (v_old_outcome_id, v_new_outcome_id);

    INSERT INTO public.outcome_weeks (outcome_id, start_week, end_week)
    SELECT v_new_outcome_id, ow.start_week, ow.end_week
    FROM public.outcome_weeks ow
    WHERE ow.outcome_id = v_old_outcome_id
    ON CONFLICT (outcome_id, start_week, end_week) DO NOTHING;
  END LOOP;

  FOR v_old_content_id IN
    SELECT tc.id
    FROM public.topic_contents tc
    JOIN tmp_topic_map tm ON tm.old_id = tc.topic_id
    ORDER BY tc.order_no, tc.id
  LOOP
    INSERT INTO public.topic_contents (
      topic_id,
      title,
      content,
      order_no,
      created_at,
      is_published
    )
    SELECT
      tm.new_id,
      tc.title,
      tc.content,
      tc.order_no,
      now(),
      tc.is_published
    FROM public.topic_contents tc
    JOIN tmp_topic_map tm ON tm.old_id = tc.topic_id
    WHERE tc.id = v_old_content_id
    RETURNING id INTO v_new_content_id;

    INSERT INTO tmp_content_map (old_id, new_id)
    VALUES (v_old_content_id, v_new_content_id);
  END LOOP;

  INSERT INTO public.topic_content_weeks (topic_content_id, curriculum_week)
  SELECT cm.new_id, tcw.curriculum_week
  FROM public.topic_content_weeks tcw
  JOIN tmp_content_map cm ON cm.old_id = tcw.topic_content_id
  ON CONFLICT (topic_content_id, curriculum_week) DO NOTHING;

  INSERT INTO public.topic_content_outcomes (topic_content_id, outcome_id)
  SELECT cm.new_id, om.new_id
  FROM public.topic_content_outcomes tco
  JOIN tmp_content_map cm ON cm.old_id = tco.topic_content_id
  JOIN tmp_outcome_map om ON om.old_id = tco.outcome_id
  ON CONFLICT DO NOTHING;

  INSERT INTO public.question_usages (
    question_id,
    topic_id,
    usage_type,
    created_at,
    order_no,
    curriculum_week
  )
  SELECT
    qu.question_id,
    tm.new_id,
    qu.usage_type,
    qu.created_at,
    qu.order_no,
    qu.curriculum_week
  FROM public.question_usages qu
  JOIN tmp_topic_map tm ON tm.old_id = qu.topic_id;

  INSERT INTO public.question_outcomes (question_id, outcome_id)
  SELECT DISTINCT
    qo.question_id,
    om.new_id
  FROM public.question_outcomes qo
  JOIN tmp_outcome_map om ON om.old_id = qo.outcome_id
  ON CONFLICT DO NOTHING;

  INSERT INTO public.unit_videos (title, video_url, order_no, created_at, unit_id)
  SELECT uv.title, uv.video_url, uv.order_no, now(), v_new_unit_id
  FROM public.unit_videos uv
  WHERE uv.unit_id = p_source_unit_id;

  UPDATE public.topics t
  SET question_count = q.cnt
  FROM (
    SELECT qu.topic_id, COUNT(*)::int AS cnt
    FROM public.question_usages qu
    GROUP BY qu.topic_id
  ) q
  WHERE t.id = q.topic_id
    AND t.unit_id = v_new_unit_id;

  UPDATE public.units u
  SET question_count = COALESCE(q.cnt, 0)
  FROM (
    SELECT t.unit_id, COUNT(*)::int AS cnt
    FROM public.question_usages qu
    JOIN public.topics t ON t.id = qu.topic_id
    GROUP BY t.unit_id
  ) q
  WHERE u.id = v_new_unit_id
    AND q.unit_id = v_new_unit_id;

  RETURN v_new_unit_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.clone_unit_to_grade(bigint, bigint, text) TO authenticated;

COMMIT;
