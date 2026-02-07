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
SECURITY DEFINER -- RLS bypass için gerekli ancak içeride yetki kontrolü şart
SET search_path = public -- Search path injection saldırılarını önlemek için güvenli yol
AS $$
DECLARE
    v_session_id BIGINT;
    v_question_ids BIGINT[];
    v_lesson_id BIGINT;
    v_grade_id BIGINT;
    v_user_grade_id BIGINT;
    v_limit INTEGER := LEAST(COALESCE(p_question_limit, 10), 10);
BEGIN
    -- 0. Güvenlik Kontrolü: Kullanıcının sadece kendi adına işlem yapabildiğinden emin ol
    -- auth.uid() kontrolü ID Spoofing saldırılarını engeller.
    IF p_user_id IS NULL OR p_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Access Denied: Identity mismatch recorded.';
    END IF;

    -- 0.1 Kullanıcının profilindeki grade_id'yi al
    SELECT grade_id INTO v_user_grade_id
    FROM public.profiles
    WHERE id = p_user_id;

    -- 1. Bu mod için zaten aktif bir test var mı diye kontrol et.
    -- Yarış durumu (race condition) için ilk bariyer.
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

    -- 2. Grade ve Lesson bilgilerini belirle
    IF p_unit_id IS NOT NULL AND p_unit_id > 0 THEN
        SELECT u.lesson_id, ug.grade_id
        INTO v_lesson_id, v_grade_id
        FROM public.units u
        JOIN public.unit_grades ug ON u.id = ug.unit_id
        WHERE u.id = p_unit_id
        LIMIT 1;

        -- Geçersiz unit_id koruması
        IF v_grade_id IS NULL THEN
            RAISE EXCEPTION 'Invalid unit specification.';
        END IF;
    ELSE
        -- Ünite yoksa Global SRS'dir
        v_lesson_id := NULL;
        v_grade_id := v_user_grade_id;
    END IF;

    -- 2.1 Grade_id kontrolü (Eğer hala null ise profil hatası vardır)
    IF v_grade_id IS NULL THEN
        RAISE EXCEPTION 'Configuration Error: User profile has no assigned grade.';
    END IF;

    -- 3. SRS mantığına göre soruları seç
    -- Sadece bu tabloda olan (daha önce çözülmüş) ve zamanı gelmiş olanları rastgele seçer.
    SELECT
        ARRAY_AGG(sub.question_id)
    INTO
        v_question_ids
    FROM (
        SELECT
            uqs.question_id
        FROM
            public.user_question_stats AS uqs
        WHERE
            uqs.user_id = p_user_id
            AND uqs.grade_id = v_grade_id
            AND uqs.total_attempts > 0
            AND uqs.next_review_at <= NOW()
            AND (p_unit_id IS NULL OR p_unit_id = 0 OR EXISTS (
                SELECT 1 FROM public.question_usages qu
                JOIN public.topics t ON qu.topic_id = t.id
                WHERE qu.question_id = uqs.question_id
                AND t.unit_id = p_unit_id
            ))
        ORDER BY
            RANDOM()
        LIMIT v_limit
    ) AS sub;

    -- Eğer çözülecek soru bulunamazsa, sessizce NULL döndür (Brute-force inference kısıtlaması)
    IF v_question_ids IS NULL OR array_length(v_question_ids, 1) = 0 THEN
        RETURN NULL;
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
            'limit_requested', v_limit,
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
-- Anonim erişim siber güvenlik açısından riskli olduğu için kapatıldı
REVOKE EXECUTE ON FUNCTION start_srs_test_session(UUID, BIGINT, UUID, INTEGER) FROM anon;
