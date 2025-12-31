-- Creates a new, atomic function to handle the entire content creation process.
-- This ensures that if any step fails, the entire transaction is rolled back.
CREATE OR REPLACE FUNCTION add_weekly_curriculum(
    p_grade_id BIGINT,
    p_lesson_id BIGINT,
    p_unit_selection JSONB,
    p_topic_selection JSONB,
    p_display_week INTEGER,
    p_outcomes_text TEXT[],
    p_content_text TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_unit_id BIGINT;
    v_topic_id BIGINT;
    v_outcome_desc TEXT;
    v_new_outcome_id BIGINT;
    v_new_content_id BIGINT;
BEGIN
    -- Step 1: Resolve Unit ID
    IF p_unit_selection->>'type' = 'existing' THEN
        v_unit_id := (p_unit_selection->>'unit_id')::BIGINT;
    ELSE
        -- Insert the new unit and get its ID
        INSERT INTO public.units (lesson_id, title)
        VALUES (p_lesson_id, p_unit_selection->>'new_unit_title')
        RETURNING id INTO v_unit_id;
    END IF;

    -- Associate unit with grade
    INSERT INTO public.unit_grades (unit_id, grade_id)
    VALUES (v_unit_id, p_grade_id)
    ON CONFLICT (unit_id, grade_id) DO NOTHING;

    -- Step 2: Resolve Topic ID
    IF p_topic_selection->>'type' = 'existing' THEN
        v_topic_id := (p_topic_selection->>'topic_id')::BIGINT;
    ELSE
        -- Insert the new topic and get its ID
        INSERT INTO public.topics (unit_id, title, slug)
        VALUES (v_unit_id, p_topic_selection->>'new_topic_title', lower(regexp_replace(p_topic_selection->>'new_topic_title', '\s+', '-', 'g')))
        RETURNING id INTO v_topic_id;
    END IF;

    -- Step 3: Create Content (if provided)
    IF p_content_text IS NOT NULL AND length(p_content_text) > 0 THEN
        INSERT INTO public.topic_contents (topic_id, title, content)
        VALUES (v_topic_id, 'İçerik', p_content_text)
        RETURNING id INTO v_new_content_id;

        -- CRITICAL LINE: Insert using ONLY the columns that exist.
        INSERT INTO public.topic_content_weeks (topic_content_id, display_week)
        VALUES (v_new_content_id, p_display_week);
    END IF;

    -- Step 4: Create Outcomes
    FOREACH v_outcome_desc IN ARRAY p_outcomes_text
    LOOP
        INSERT INTO public.outcomes (topic_id, description)
        VALUES (v_topic_id, v_outcome_desc)
        RETURNING id INTO v_new_outcome_id;

        -- Use start_week and end_week for outcome_weeks as per its correct schema
        INSERT INTO public.outcome_weeks (outcome_id, start_week, end_week)
        VALUES (v_new_outcome_id, p_display_week, p_display_week);
    END LOOP;

    RETURN jsonb_build_object('status', 'success', 'unit_id', v_unit_id, 'topic_id', v_topic_id);
END;
$$;
