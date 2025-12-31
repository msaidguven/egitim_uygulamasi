-- =================================================================
-- FUNCTION: create_full_content_tree
--
-- DESCRIPTION:
-- This function performs a comprehensive operation to create a new content
-- structure, including units, topics, outcomes, and topic contents,
-- within a single transaction. It is designed to be called from the
-- 'Smart Content Addition' page in the application.
--
-- It intelligently handles either creating new units/topics or using
-- existing ones based on the `p_unit_selection` and `p_topic_selection`
-- parameters.
--
-- It now uses a single 'display_week' for both topic_contents and outcomes,
-- reflecting the unified schema of their respective week tables.
--
-- PARAMETERS:
-- p_grade_id: The ID of the grade.
-- p_lesson_id: The ID of the lesson.
-- p_unit_selection: JSONB object indicating whether to use an 'existing'
--                   unit or create a 'new' one.
-- p_topic_selection: JSONB object indicating whether to use an 'existing'
--                    topic or create a 'new' one.
-- p_display_week: The specific week for both the topic contents and outcomes.
-- p_items: JSONB array containing the outcomes and their associated contents.
--
-- RETURNS:
-- A JSONB object confirming the IDs of the unit and topic, and the
-- count of created outcomes and contents.
-- =================================================================

CREATE OR REPLACE FUNCTION public.create_full_content_tree(
    p_grade_id BIGINT,
    p_lesson_id BIGINT,
    p_unit_selection JSONB,
    p_topic_selection JSONB,
    p_display_week INTEGER,
    p_items JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_unit_id BIGINT;
    v_topic_id BIGINT;
    v_item JSONB;
    v_content JSONB;
    v_order_no INTEGER;
    v_outcomes_created_count INTEGER := 0;
    v_contents_created_count INTEGER := 0;
    v_new_unit_title TEXT;
    v_new_topic_title TEXT;
    v_new_content_id BIGINT;
    v_new_outcome_id BIGINT;
BEGIN
    -- Step 1: Resolve the Unit.
    IF p_unit_selection->>'type' = 'existing' THEN
        v_unit_id := (p_unit_selection->>'unit_id')::BIGINT;
    ELSE
        v_new_unit_title := p_unit_selection->>'new_unit_title';
        SELECT u.id INTO v_unit_id
        FROM public.units u
        JOIN public.unit_grades ug ON u.id = ug.unit_id
        WHERE u.lesson_id = p_lesson_id
          AND ug.grade_id = p_grade_id
          AND u.title = v_new_unit_title;

        IF NOT FOUND THEN
            INSERT INTO units (lesson_id, title)
            VALUES (p_lesson_id, v_new_unit_title)
            RETURNING id INTO v_unit_id;
        END IF;
    END IF;

    INSERT INTO unit_grades (unit_id, grade_id)
    VALUES (v_unit_id, p_grade_id)
    ON CONFLICT (unit_id, grade_id) DO NOTHING;

    -- Step 2: Resolve the Topic.
    IF p_topic_selection->>'type' = 'existing' THEN
        v_topic_id := (p_topic_selection->>'topic_id')::BIGINT;
    ELSE
        v_new_topic_title := p_topic_selection->>'new_topic_title';
        SELECT id INTO v_topic_id
        FROM public.topics
        WHERE unit_id = v_unit_id AND title = v_new_topic_title;

        IF NOT FOUND THEN
            INSERT INTO topics (unit_id, title, slug)
            VALUES (
                v_unit_id,
                v_new_topic_title,
                lower(regexp_replace(v_new_topic_title, '\s+', '-', 'g'))
            )
            RETURNING id INTO v_topic_id;
        END IF;
    END IF;

    -- Step 3: Create the Topic Content and associate the week.
    IF jsonb_array_length(p_items) > 0 THEN
        FOR v_content IN SELECT * FROM jsonb_array_elements(p_items->0->'contents')
        LOOP
            SELECT COALESCE(MAX(order_no), -1) + 1
            INTO v_order_no
            FROM topic_contents
            WHERE topic_id = v_topic_id;

            INSERT INTO topic_contents (
                topic_id,
                title,
                content,
                order_no
            )
            VALUES (
                v_topic_id,
                v_content->>'title',
                v_content->>'content',
                v_order_no
            )
            RETURNING id INTO v_new_content_id;

            -- Insert the week into the separate 'topic_content_weeks' table.
            INSERT INTO topic_content_weeks (topic_content_id, display_week)
            VALUES (v_new_content_id, p_display_week);

            v_contents_created_count := v_contents_created_count + 1;
        END LOOP;
    END IF;

    -- Step 4: Create the Outcomes and associate the week.
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO outcomes (
            topic_id,
            description
        )
        VALUES (
            v_topic_id,
            v_item->'outcome'->>'description'
        )
        RETURNING id INTO v_new_outcome_id;

        -- Insert the week into the separate 'outcome_weeks' table.
        INSERT INTO outcome_weeks (outcome_id, start_week, end_week)
        VALUES (v_new_outcome_id, p_display_week, p_display_week);
        
        v_outcomes_created_count := v_outcomes_created_count + 1;
    END LOOP;

    -- Step 5: Return a success confirmation.
    RETURN jsonb_build_object(
        'unit_id', v_unit_id,
        'topic_id', v_topic_id,
        'outcomes_created', v_outcomes_created_count,
        'contents_created', v_contents_created_count
    );
END;
$$;