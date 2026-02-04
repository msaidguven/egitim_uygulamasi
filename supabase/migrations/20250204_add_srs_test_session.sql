-- SRS (Spaced Repetition) Test Session oluşturma fonksiyonu
-- Kullanıcının belirlediği üniteden, tekrar etmesi gereken soruları getirir.
-- Şema kısıtları:
-- 1. test_sessions: status sütunu yok, completed_at NULL ise aktif.
-- 2. test_session_questions: order_no sütunu max 10 olabilir.
-- 3. user_question_stats: srs verileri burada tutulur.

CREATE OR REPLACE FUNCTION start_srs_test_session(
    p_user_id UUID,
    p_unit_id BIGINT,
    p_client_id UUID,
    p_question_limit INTEGER
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_session_id BIGINT;
    v_question_ids BIGINT[];
    v_lesson_id BIGINT;
    v_grade_id BIGINT;
BEGIN
    -- 1. Bu mod için zaten aktif bir test var mı diye kontrol et.
    SELECT id
    INTO v_session_id
    FROM public.test_sessions
    WHERE user_id = p_user_id
        AND (p_unit_id IS NULL OR unit_id = p_unit_id)
        AND client_id = p_client_id
        AND completed_at IS NULL
        AND settings->>'mode' = 'srs'
    LIMIT 1;

    -- Eğer aktif bir oturum bulunduysa, onun ID'sini döndür.
    IF v_session_id IS NOT NULL THEN
        RETURN v_session_id;
    END IF;

    -- 2. SRS mantığına göre soruları seç (SRS: Tekrar zamanı gelmiş sorular).
    SELECT
        ARRAY_AGG(sub.id)
    INTO
        v_question_ids
    FROM (
        SELECT
            q.id
        FROM
            public.questions AS q
        JOIN
            public.question_usages AS qu ON q.id = qu.question_id
        JOIN
            public.topics AS t ON qu.topic_id = t.id
        WHERE
            t.is_active = true
            AND (p_unit_id IS NULL OR t.unit_id = p_unit_id)
            AND NOT EXISTS (
                SELECT 1 FROM user_question_stats uqs
                WHERE uqs.question_id = q.id
                    AND uqs.user_id = p_user_id
                    AND uqs.last_answer_correct = true
                    AND uqs.next_review_at > NOW()
            )
        GROUP BY q.id
        ORDER BY
            RANDOM()
        LIMIT LEAST(p_question_limit, 10)
    ) AS sub;

    -- Eğer çözülecek soru bulunamazsa, NULL döndür.
    IF v_question_ids IS NULL OR array_length(v_question_ids, 1) = 0 THEN
        RETURN NULL;
    END IF;

    -- 3. Eğer unit_id varsa, lesson_id ve grade_id'yi bul.
    IF p_unit_id IS NOT NULL THEN
        SELECT u.lesson_id, ug.grade_id
        INTO v_lesson_id, v_grade_id
        FROM public.units u
        LEFT JOIN public.unit_grades ug ON u.id = ug.unit_id
        WHERE u.id = p_unit_id
        LIMIT 1;
    END IF;

    -- 4. Yeni bir test oturumu oluştur.
    INSERT INTO public.test_sessions (
        user_id, 
        unit_id, 
        lesson_id, 
        grade_id, 
        client_id, 
        created_at,
        question_ids, 
        settings
    )
    VALUES (
        p_user_id,
        p_unit_id,
        v_lesson_id,
        v_grade_id,
        p_client_id,
        NOW(),
        v_question_ids,
        jsonb_build_object(
            'mode', 'srs',
            'limit_requested', p_question_limit,
            'status', 'active'
        )
    )
    RETURNING id INTO v_session_id;

    -- 5. Seçilen soruları test_session_questions tablosuna ekle.
    INSERT INTO public.test_session_questions (test_session_id, question_id, order_no)
    SELECT
        v_session_id,
        question_id,
        row_number() OVER ()
    FROM
        unnest(v_question_ids) AS question_id;

    -- 6. Yeni oturumun ID'sini döndür.
    RETURN v_session_id;
END;
$$;

-- İzinleri tanımla
GRANT EXECUTE ON FUNCTION start_srs_test_session(UUID, BIGINT, UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION start_srs_test_session(UUID, BIGINT, UUID, INTEGER) TO anon;
