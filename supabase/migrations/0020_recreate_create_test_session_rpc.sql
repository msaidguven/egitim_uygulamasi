-- Fonksiyonun eski versiyonlarını temizle
DROP FUNCTION IF EXISTS create_test_session_and_get_questions(bigint, integer, integer, integer);

CREATE OR REPLACE FUNCTION create_test_session_and_get_questions(
    p_topic_id BIGINT,
    p_week_no INT,
    p_test_number INT,
    p_questions_per_test INT
)
RETURNS TABLE (
    session_id BIGINT,
    id BIGINT,
    question_type_id SMALLINT,
    question_text TEXT,
    difficulty SMALLINT,
    score SMALLINT,
    created_at TIMESTAMP,
    choices JSONB,
    blank_options JSONB,
    matching_pairs JSONB
) AS $$
DECLARE
    new_session_id BIGINT;
    user_id UUID := auth.uid();
BEGIN
    -- 1. Yeni bir test oturumu oluştur
    INSERT INTO public.test_sessions (user_id, unit_id, settings)
    VALUES (
        user_id,
        (SELECT t.unit_id FROM public.topics t WHERE t.id = p_topic_id LIMIT 1),
        jsonb_build_object(
            'topic_id', p_topic_id,
            'week_no', p_week_no,
            'test_number', p_test_number,
            'type', 'weekly_test'
        )
    ) RETURNING test_sessions.id INTO new_session_id;

    -- 2. Bu haftanın konusu için uygun soruları seç ve döndür
    RETURN QUERY
    WITH available_questions AS (
        -- Belirtilen konu ve hafta için rastgele N tane soru ID'si seç
        SELECT q.id
        FROM public.questions q
        JOIN public.question_usages qu ON q.id = qu.question_id
        WHERE qu.topic_id = p_topic_id AND qu.display_week = p_week_no
        ORDER BY random()
        LIMIT p_questions_per_test
    )
    -- Seçilen soruların tüm detaylarını, ilişkili seçenekleriyle birlikte getir
    SELECT
        new_session_id AS session_id,
        q.id,
        q.question_type_id,
        q.question_text,
        q.difficulty,
        q.score,
        q.created_at,
        (SELECT jsonb_agg(c) FROM public.question_choices c WHERE c.question_id = q.id) AS choices,
        (SELECT jsonb_agg(b) FROM public.question_blank_options b WHERE b.question_id = q.id) AS blank_options,
        (SELECT jsonb_agg(m) FROM public.question_matching_pairs m WHERE m.question_id = q.id) AS matching_pairs
    FROM
        public.questions q
    -- Ambiguity (belirsizlik) hatasını önlemek için IN yerine JOIN kullan
    JOIN
        available_questions aq ON q.id = aq.id;
END;
$$ LANGUAGE plpgsql;
