CREATE OR REPLACE FUNCTION get_user_stats(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
    total_tests BIGINT;
    total_questions BIGINT;
    correct_answers BIGINT;
    incorrect_answers BIGINT;
    success_rate NUMERIC;
    lesson_stats JSONB;
BEGIN
    -- 1. Calculate overall stats
    SELECT
        COUNT(DISTINCT ua.session_id),
        COUNT(ua.id),
        COUNT(CASE WHEN ua.is_correct THEN 1 END),
        COUNT(CASE WHEN NOT ua.is_correct THEN 1 END)
    INTO
        total_tests,
        total_questions,
        correct_answers,
        incorrect_answers
    FROM
        public.user_answers ua
    WHERE
        ua.user_id = p_user_id;

    -- 2. Calculate success rate, avoiding division by zero
    IF total_questions > 0 THEN
        success_rate := (correct_answers::NUMERIC / total_questions) * 100;
    ELSE
        success_rate := 0;
    END IF;

    -- 3. Calculate stats per lesson
    SELECT
        jsonb_agg(
            jsonb_build_object(
                'lesson_id', l.id,
                'lesson_name', l.name,
                'total_questions', ls.total_questions,
                'correct_answers', ls.correct_answers,
                'success_rate', ls.success_rate
            )
        )
    INTO
        lesson_stats
    FROM
        public.lessons l
    JOIN (
        SELECT
            u.lesson_id,
            COUNT(ua.id) AS total_questions,
            COUNT(CASE WHEN ua.is_correct THEN 1 END) AS correct_answers,
            (COUNT(CASE WHEN ua.is_correct THEN 1 END)::NUMERIC / COUNT(ua.id)) * 100 AS success_rate
        FROM
            public.user_answers ua
        JOIN
            public.questions q ON ua.question_id = q.id
        JOIN
            public.test_sessions ts ON ua.session_id = ts.id
        JOIN
            public.units u ON ts.unit_id = u.id
        WHERE
            ua.user_id = p_user_id
        GROUP BY
            u.lesson_id
    ) ls ON l.id = ls.lesson_id;

    -- 4. Combine all stats into a single JSONB object
    RETURN jsonb_build_object(
        'total_tests', total_tests,
        'total_questions', total_questions,
        'correct_answers', correct_answers,
        'incorrect_answers', incorrect_answers,
        'success_rate', success_rate,
        'lesson_stats', COALESCE(lesson_stats, '[]'::jsonb)
    );
END;
$$ LANGUAGE plpgsql;
