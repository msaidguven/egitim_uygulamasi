-- Drop the function if it exists to avoid conflicts
DROP FUNCTION IF EXISTS public.get_weekly_question_count(bigint, integer);

-- Create the function to count questions for a specific topic and week
CREATE OR REPLACE FUNCTION public.get_weekly_question_count(
    p_topic_id BIGINT,
    p_week_no INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    question_count INT;
BEGIN
    SELECT COUNT(DISTINCT qu.question_id)
    INTO question_count
    FROM public.question_usages qu
    WHERE qu.topic_id = p_topic_id
      AND qu.display_week = p_week_no;

    RETURN question_count;
END;
$$;
