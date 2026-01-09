-- Drop the function if it exists
DROP FUNCTION IF EXISTS public.get_questions_for_weekly_test(bigint, integer, integer, integer);

-- Create the function to retrieve questions for a weekly test
CREATE OR REPLACE FUNCTION public.get_questions_for_weekly_test(
    p_topic_id BIGINT,
    p_week_no INT,
    p_test_number INT,
    p_questions_per_test INT
)
RETURNS TABLE (
    id BIGINT,
    question_text TEXT,
    score SMALLINT,
    difficulty SMALLINT,
    question_type_id SMALLINT,
    question_type_code TEXT,
    choices JSONB,
    blank_options JSONB,
    matching_pairs JSONB,
    classical_answer TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset INT;
BEGIN
    -- Calculate the offset
    v_offset := (p_test_number - 1) * p_questions_per_test;

    RETURN QUERY
    SELECT
        q.id,
        q.question_text,
        q.score,
        q.difficulty,
        q.question_type_id,
        qt.code AS question_type_code,
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'id', qc.id,
                        'choice_text', qc.choice_text,
                        'is_correct', qc.is_correct
                    )
                )
                FROM public.question_choices qc
                WHERE qc.question_id = q.id
            ),
            '[]'::jsonb
        ) AS choices,
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'id', qbo.id,
                        'question_id', qbo.question_id,
                        'option_text', qbo.option_text,
                        'is_correct', qbo.is_correct,
                        'order_no', qbo.order_no
                    )
                )
                FROM public.question_blank_options qbo
                WHERE qbo.question_id = q.id
            ),
            '[]'::jsonb
        ) AS blank_options,
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'id', qmp.id,
                        'left_text', qmp.left_text,
                        'right_text', qmp.right_text
                    )
                )
                FROM public.question_matching_pairs qmp
                WHERE qmp.question_id = q.id
            ),
            '[]'::jsonb
        ) AS matching_pairs,
        (
            SELECT qcl.model_answer
            FROM public.question_classical qcl
            WHERE qcl.question_id = q.id
            LIMIT 1
        ) AS classical_answer
    FROM
        public.questions q
    JOIN
        public.question_types qt ON q.question_type_id = qt.id
    JOIN
        public.question_usages qu ON q.id = qu.question_id
    WHERE
        qu.topic_id = p_topic_id
        AND qu.display_week = p_week_no
    ORDER BY
        q.difficulty ASC, -- Order by difficulty: Easy -> Medium -> Hard
        q.id ASC
    LIMIT p_questions_per_test
    OFFSET v_offset;
END;
$$;
