-- Drop the function to ensure a clean slate, avoiding any signature conflicts.
DROP FUNCTION IF EXISTS public.get_questions_for_test(bigint, integer, integer);

-- This function retrieves questions for a specific test within a unit.
-- It is the source of truth for question data structure.
-- This final version ensures consistent and correct column names and types.
CREATE OR REPLACE FUNCTION public.get_questions_for_test(
    p_unit_id BIGINT,
    p_test_number INT,
    p_questions_per_test INT
)
RETURNS TABLE (
    id BIGINT,
    text TEXT,
    score SMALLINT,
    question_type_code TEXT,
    choices JSONB,
    blank_options JSONB,
    matching_pairs JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset INT;
BEGIN
    -- Calculate the offset to skip questions from previous tests.
    v_offset := (p_test_number - 1) * p_questions_per_test;

    RETURN QUERY
    SELECT
        q.id,
        q.text, -- Standardized column name
        q.score,
        qt.code AS question_type_code,
        (
            SELECT jsonb_agg(qo.*)
            FROM public.question_options qo
            WHERE qo.question_id = q.id
        ) AS choices, -- Standardized column name
        (
            SELECT jsonb_agg(qbo.*)
            FROM public.question_blank_options qbo
            WHERE qbo.question_id = q.id
        ) AS blank_options, -- Standardized column name
        (
            SELECT jsonb_agg(qmp.*)
            FROM public.question_matching_pairs qmp
            WHERE qmp.question_id = q.id
        ) AS matching_pairs
    FROM
        public.questions q
    JOIN
        public.question_types qt ON q.question_type_id = qt.id
    JOIN
        public.question_usages qu ON q.id = qu.question_id
    JOIN
        public.topics t ON qu.topic_id = t.id
    WHERE
        t.unit_id = p_unit_id
    ORDER BY
        q.id -- Consistent ordering is crucial for pagination
    LIMIT p_questions_per_test
    OFFSET v_offset;
END;
$$;
