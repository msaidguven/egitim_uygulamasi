-- Drop the function if it exists
DROP FUNCTION IF EXISTS public.get_weekly_question_counts_by_difficulty(bigint, integer);

-- Create the function to get question counts by difficulty for a specific topic and week
-- Fixed: Return type for difficulty matches table column type (SMALLINT)
CREATE OR REPLACE FUNCTION public.get_weekly_question_counts_by_difficulty(
    p_topic_id BIGINT,
    p_week_no INT
)
RETURNS TABLE (
    difficulty SMALLINT,
    question_count INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        q.difficulty,
        COUNT(DISTINCT qu.question_id)::INT
    FROM
        public.question_usages qu
    JOIN
        public.questions q ON qu.question_id = q.id
    WHERE
        qu.topic_id = p_topic_id
        AND qu.display_week = p_week_no
    GROUP BY
        q.difficulty;
END;
$$;
