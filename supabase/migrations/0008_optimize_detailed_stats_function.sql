-- Drop the old function if it exists
DROP FUNCTION IF EXISTS public.get_detailed_statistics(p_user_id uuid);

-- Create the new, optimized function using user_unit_summary
CREATE OR REPLACE FUNCTION public.get_detailed_statistics(p_user_id uuid)
RETURNS json
LANGUAGE plpgsql
AS $$
DECLARE
    result JSON;
BEGIN
    -- This function now calculates lesson-based statistics using the user_unit_summary table
    -- for significantly better performance. Topic-based stats have been removed as requested.

    WITH lesson_stats_from_summary AS (
        SELECT
            l.name AS lesson_name,
            SUM(uus.correct_count) AS total_correct,
            SUM(uus.wrong_count) AS total_wrong,
            SUM(uus.correct_count + uus.wrong_count) AS total_questions
        FROM public.user_unit_summary uus
        JOIN public.units u ON u.id = uus.unit_id
        JOIN public.lessons l ON l.id = u.lesson_id
        WHERE uus.user_id = p_user_id
        GROUP BY l.id, l.name
    )
    SELECT json_build_object(
        'lesson_stats', (
            SELECT COALESCE(json_agg(json_build_object(
                'lesson_name', ls.lesson_name,
                'total_questions', ls.total_questions,
                'correct_answers', ls.total_correct,
                'incorrect_answers', ls.total_wrong,
                'success_rate', CASE
                                    WHEN ls.total_questions = 0 THEN 0
                                    ELSE (ls.total_correct * 100.0 / ls.total_questions)
                                END
            )), '[]'::json)
            FROM lesson_stats_from_summary ls
        )
        -- 'weakest_topics' has been removed.
    ) INTO result;

    RETURN result;
END;
$$;
