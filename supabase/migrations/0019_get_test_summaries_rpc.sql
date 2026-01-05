CREATE OR REPLACE FUNCTION get_test_summaries_for_topic(p_topic_id BIGINT, p_user_id UUID)
RETURNS TABLE (
    test_number INT,
    last_session_id BIGINT,
    correct_count INT,
    incorrect_count INT,
    total_questions INT
) AS $$
BEGIN
    RETURN QUERY
    WITH latest_sessions AS (
        -- 1. Kullanıcının bu konudaki her bir test için çözdüğü en son oturumu bul
        SELECT
            (ts.settings->>'test_number')::INT AS test_number,
            MAX(ts.id) AS last_session_id
        FROM
            public.test_sessions ts
        JOIN
            public.question_usages qu ON (ts.settings->>'topic_id')::BIGINT = qu.topic_id
                                        AND (ts.settings->>'test_number')::INT = qu.order_no
        WHERE
            ts.user_id = p_user_id
            AND (ts.settings->>'topic_id')::BIGINT = p_topic_id
            AND ts.completed_at IS NOT NULL
        GROUP BY
            (ts.settings->>'test_number')::INT
    )
    -- 2. Bu en son oturumlardaki doğru/yanlış sayılarını hesapla
    SELECT
        ls.test_number,
        ls.last_session_id,
        CAST(SUM(CASE WHEN ua.is_correct THEN 1 ELSE 0 END) AS INT) AS correct_count,
        CAST(SUM(CASE WHEN NOT ua.is_correct THEN 1 ELSE 0 END) AS INT) AS incorrect_count,
        CAST(COUNT(ua.id) AS INT) AS total_questions
    FROM
        latest_sessions ls
    JOIN
        public.user_answers ua ON ls.last_session_id = ua.session_id
    GROUP BY
        ls.test_number, ls.last_session_id
    ORDER BY
        ls.test_number;
END;
$$ LANGUAGE plpgsql;
