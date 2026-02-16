-- Ensure add_weekly_curriculum links created content to created outcomes.

CREATE OR REPLACE FUNCTION public.add_weekly_curriculum(
  p_grade_id bigint,
  p_lesson_id bigint,
  p_unit_selection jsonb,
  p_topic_selection jsonb,
  p_curriculum_week integer,
  p_outcomes_text text[],
  p_content_text text
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_unit_id BIGINT;
    v_topic_id BIGINT;
    v_outcome_desc TEXT;
    v_new_outcome_id BIGINT;
    v_new_content_id BIGINT;
BEGIN
    IF p_unit_selection->>'type' = 'existing' THEN
        v_unit_id := (p_unit_selection->>'unit_id')::BIGINT;
    ELSE
        INSERT INTO public.units (lesson_id, title)
        VALUES (p_lesson_id, p_unit_selection->>'new_unit_title')
        RETURNING id INTO v_unit_id;
    END IF;

    INSERT INTO public.unit_grades (unit_id, grade_id)
    VALUES (v_unit_id, p_grade_id)
    ON CONFLICT (unit_id, grade_id) DO NOTHING;

    IF p_topic_selection->>'type' = 'existing' THEN
        v_topic_id := (p_topic_selection->>'topic_id')::BIGINT;
    ELSE
        INSERT INTO public.topics (unit_id, title, slug)
        VALUES (
            v_unit_id,
            p_topic_selection->>'new_topic_title',
            lower(regexp_replace(p_topic_selection->>'new_topic_title', '\s+', '-', 'g'))
        )
        RETURNING id INTO v_topic_id;
    END IF;

    IF p_content_text IS NOT NULL AND length(btrim(p_content_text)) > 0 THEN
        INSERT INTO public.topic_contents (topic_id, title, content)
        VALUES (v_topic_id, 'İçerik', p_content_text)
        RETURNING id INTO v_new_content_id;

        INSERT INTO public.topic_content_weeks (topic_content_id, curriculum_week)
        VALUES (v_new_content_id, p_curriculum_week)
        ON CONFLICT (topic_content_id, curriculum_week) DO NOTHING;
    END IF;

    FOREACH v_outcome_desc IN ARRAY p_outcomes_text
    LOOP
        IF v_outcome_desc IS NULL OR btrim(v_outcome_desc) = '' THEN
            CONTINUE;
        END IF;

        INSERT INTO public.outcomes (topic_id, description)
        VALUES (v_topic_id, btrim(v_outcome_desc))
        RETURNING id INTO v_new_outcome_id;

        INSERT INTO public.outcome_weeks (outcome_id, start_week, end_week)
        VALUES (v_new_outcome_id, p_curriculum_week, p_curriculum_week)
        ON CONFLICT (outcome_id, start_week, end_week) DO NOTHING;

        IF v_new_content_id IS NOT NULL THEN
          INSERT INTO public.topic_content_outcomes (topic_content_id, outcome_id)
          VALUES (v_new_content_id, v_new_outcome_id)
          ON CONFLICT DO NOTHING;
        END IF;
    END LOOP;

    RETURN jsonb_build_object(
        'status', 'success',
        'unit_id', v_unit_id,
        'topic_id', v_topic_id
    );
END;
$$;
