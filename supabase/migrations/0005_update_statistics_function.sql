-- Drop the old function if it exists
DROP FUNCTION IF EXISTS public.get_user_statistics_v3(p_user_id uuid, p_period text);

-- Create the new, simplified function for detailed stats
CREATE OR REPLACE FUNCTION public.get_detailed_statistics(p_user_id uuid)
RETURNS json
LANGUAGE plpgsql
AS $$
DECLARE
    result JSON;
BEGIN
    -- This function calculates detailed statistics for ALL TIME.
    -- It is intended to be used for lesson-based and topic-based analysis,
    -- while periodic summaries are handled by the 'user_time_based_stats' table.

    WITH lesson_stats AS (
        SELECT
            l.name as lesson_name,
            COUNT(DISTINCT uqs.question_id) as total_questions,
            SUM(CASE WHEN uqs.last_answer_correct THEN 1 ELSE 0 END) as correct_answers,
            COUNT(DISTINCT uqs.question_id) - SUM(CASE WHEN uqs.last_answer_correct THEN 1 ELSE 0 END) as incorrect_answers,
            CASE
                WHEN COUNT(DISTINCT uqs.question_id) = 0 THEN 0
                ELSE (SUM(CASE WHEN uqs.last_answer_correct THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT uqs.question_id))
            END as success_rate
        FROM user_question_stats uqs
        JOIN questions q ON q.id = uqs.question_id
        JOIN topics t ON t.id = q.topic_id
        JOIN units u ON u.id = t.unit_id
        JOIN lessons l ON l.id = u.lesson_id
        WHERE uqs.user_id = p_user_id
        GROUP BY l.id, l.name
        ORDER BY success_rate DESC
    ),
    weakest_topics AS (
        SELECT
            t.id as topic_id,
            t.name as topic_name,
            u.id as unit_id,
            COUNT(DISTINCT uqs.question_id) as total_questions,
            SUM(CASE WHEN uqs.last_answer_correct THEN 1 ELSE 0 END) as correct_answers,
            CASE
                WHEN COUNT(DISTINCT uqs.question_id) = 0 THEN 0
                ELSE (SUM(CASE WHEN uqs.last_answer_correct THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT uqs.question_id))
            END as success_rate
        FROM user_question_stats uqs
        JOIN questions q ON q.id = uqs.question_id
        JOIN topics t ON t.id = q.topic_id
        JOIN units u ON u.id = t.unit_id
        WHERE uqs.user_id = p_user_id
        GROUP BY t.id, t.name, u.id
        HAVING COUNT(DISTINCT uqs.question_id) >= 5  -- Only consider topics with at least 5 questions
        ORDER BY success_rate ASC
        LIMIT 5
    )
    SELECT json_build_object(
        'lesson_stats', (SELECT COALESCE(json_agg(row_to_json(lesson_stats)), '[]'::json) FROM lesson_stats),
        'weakest_topics', (SELECT COALESCE(json_agg(row_to_json(weakest_topics)), '[]'::json) FROM weakest_topics)
    ) INTO result;

    RETURN result;
END;
$$;
