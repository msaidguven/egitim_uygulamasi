-- 1. test_sessions tablosuna question_ids kolonu ekle (Resuming için gerekli)
ALTER TABLE public.test_sessions
ADD COLUMN IF NOT EXISTS question_ids BIGINT[];

-- 2. Kullanıcının belirli bir konu/ünite için tamamlanmamış testini getiren RPC
DROP FUNCTION IF EXISTS public.get_active_test_session(uuid, bigint, bigint, integer);

CREATE OR REPLACE FUNCTION public.get_active_test_session(
    p_user_id UUID,
    p_topic_id BIGINT DEFAULT NULL,
    p_unit_id BIGINT DEFAULT NULL,
    p_week_no INT DEFAULT NULL
)
RETURNS TABLE (
    session_id BIGINT,
    created_at TIMESTAMPTZ,
    test_number INT,
    question_ids BIGINT[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ts.id,
        ts.created_at,
        (ts.settings->>'test_number')::INT,
        ts.question_ids
    FROM
        public.test_sessions ts
    WHERE
        ts.user_id = p_user_id
        AND ts.completed_at IS NULL
        AND (
            -- Topic bazlı kontrol (Haftalık test)
            (p_topic_id IS NOT NULL AND (ts.settings->>'topic_id')::BIGINT = p_topic_id AND (ts.settings->>'week_no')::INT = p_week_no)
            OR
            -- Unit bazlı kontrol (Ünite testi)
            (p_unit_id IS NOT NULL AND ts.unit_id = p_unit_id AND ts.settings->>'topic_id' IS NULL)
        )
    ORDER BY
        ts.created_at DESC
    LIMIT 1;
END;
$$;

-- 3. Resume (Devam etme) için gerekli verileri getiren RPC
-- Bu, hem soruları hem de varsa kullanıcının daha önce verdiği cevapları getirir.
DROP FUNCTION IF EXISTS public.get_session_resume_data(bigint);

CREATE OR REPLACE FUNCTION public.get_session_resume_data(
    p_session_id BIGINT
)
RETURNS TABLE (
    question_data JSONB,
    user_answer_data JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_question_ids BIGINT[];
BEGIN
    -- Session'dan soru ID'lerini al
    SELECT question_ids INTO v_question_ids
    FROM public.test_sessions
    WHERE id = p_session_id;

    RETURN QUERY
    SELECT
        -- Sorunun detayları
        public.get_question_details(q.id) AS question_data,
        -- Kullanıcının bu soruya verdiği cevap (varsa)
        (
            SELECT jsonb_build_object(
                'selected_option_id', ua.selected_option_id,
                'answer_text', ua.answer_text,
                'is_correct', ua.is_correct
            )
            FROM public.user_answers ua
            WHERE ua.session_id = p_session_id AND ua.question_id = q.id
            LIMIT 1
        ) AS user_answer_data
    FROM
        public.questions q
    JOIN
        unnest(v_question_ids) WITH ORDINALITY t(id, ord) ON q.id = t.id
    ORDER BY
        t.ord; -- Kaydedilen sıraya göre getir
END;
$$;
