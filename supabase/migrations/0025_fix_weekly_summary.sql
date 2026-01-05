-- This single, definitive migration fixes the 'null is not a subtype of type int' error
-- that occurs when fetching weekly test summaries.
-- IT DOES NOT ALTER THE DATABASE SCHEMA IN ANY WAY.

-- Drop any previous, faulty versions of the function to ensure a clean state.
DROP FUNCTION IF EXISTS public.get_user_test_summary_for_week(uuid, bigint, integer);

-- This is the final, correct, and self-contained function.
-- It uses COALESCE to ensure that numeric fields never return null, preventing crashes in the Dart code.
CREATE OR REPLACE FUNCTION public.get_user_test_summary_for_week(
    p_user_id uuid,
    p_topic_id bigint,
    p_week_no integer
)
RETURNS TABLE(
    test_number integer,
    latest_session_id bigint,
    correct_count integer,
    incorrect_count integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH weekly_questions AS (
        -- Get all questions for the given week and topic
        SELECT
            q.id,
            qu.order_no
        FROM
            public.questions q
        JOIN
            public.question_usages qu ON q.id = qu.question_id
        WHERE
            qu.topic_id = p_topic_id
            AND qu.usage_type = 'weekly'
            AND qu.display_week = p_week_no
    ),
    test_definitions AS (
        -- Define the tests based on question order (e.g., 1-10 is Test 1, 11-20 is Test 2)
        SELECT
            wq.id AS question_id,
            floor((wq.order_no - 1) / 10) + 1 AS test_number
        FROM
            weekly_questions wq
    ),
    user_sessions AS (
        -- Get all completed test sessions for the user for this topic/week
        SELECT
            ts.id AS session_id,
            (ts.settings->>'test_number')::int AS test_number
        FROM
            public.test_sessions ts
        WHERE
            ts.user_id = p_user_id
            AND (ts.settings->>'topic_id')::bigint = p_topic_id
            AND (ts.settings->>'week_no')::int = p_week_no
            AND ts.completed_at IS NOT NULL
    ),
    ranked_sessions AS (
        -- Find the latest session for each test number
        SELECT
            us.session_id,
            us.test_number,
            ROW_NUMBER() OVER(PARTITION BY us.test_number ORDER BY ts.created_at DESC) as rn
        FROM
            user_sessions us
        JOIN
            public.test_sessions ts ON us.session_id = ts.id
    ),
    latest_sessions AS (
        -- Filter to get only the very latest session for each test
        SELECT
            rs.session_id,
            rs.test_number
        FROM
            ranked_sessions rs
        WHERE
            rs.rn = 1
    ),
    session_stats AS (
        -- Calculate the stats for those latest sessions
        SELECT
            ls.test_number,
            ls.session_id,
            -- THIS IS THE FIX: Use COALESCE to return 0 instead of NULL
            COALESCE(SUM(CASE WHEN ua.is_correct THEN 1 ELSE 0 END)::int, 0) AS correct_count,
            COALESCE(SUM(CASE WHEN NOT ua.is_correct THEN 1 ELSE 0 END)::int, 0) AS incorrect_count
        FROM
            latest_sessions ls
        JOIN
            public.user_answers ua ON ls.session_id = ua.session_id
        GROUP BY
            ls.test_number, ls.session_id
    )
    -- Final result
    SELECT
        ss.test_number,
        ss.session_id AS latest_session_id,
        ss.correct_count,
        ss.incorrect_count
    FROM
        session_stats ss
    ORDER BY
        ss.test_number;
END;
$$;
