-- SRS (Spaced Repetition) Test Session oluşturma fonksiyonu
-- Bu fonksiyon, kullanıcının tekrar etmesi gereken sorular için bir test session oluşturur

CREATE OR REPLACE FUNCTION start_srs_test_session(
    p_user_id UUID,
    p_client_id UUID
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_session_id BIGINT;
    v_question_ids BIGINT[];
BEGIN
    -- Zamanı gelen tekrar sorularını getir (next_review_at <= şimdi)
    SELECT ARRAY_AGG(question_id)
    INTO v_question_ids
    FROM user_question_stats
    WHERE user_id = p_user_id
      AND next_review_at <= NOW()
      AND total_attempts > 0;  -- En az bir kez çözülmüş sorular

    -- Eğer tekrar edilecek soru yoksa hata fırlat
    IF v_question_ids IS NULL OR array_length(v_question_ids, 1) IS NULL THEN
        RAISE EXCEPTION 'Tekrar edilecek soru bulunamadı';
    END IF;

    -- Yeni test session oluştur
    INSERT INTO test_sessions (
        user_id,
        client_id,
        created_at,
        settings,
        question_ids
    ) VALUES (
        p_user_id,
        p_client_id,
        NOW(),
        jsonb_build_object(
            'mode', 'srs',
            'question_count', array_length(v_question_ids, 1)
        ),
        v_question_ids
    )
    RETURNING id INTO v_session_id;

    RETURN v_session_id;
END;
$$;

-- Fonksiyon yetkilerini ayarla
GRANT EXECUTE ON FUNCTION start_srs_test_session(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION start_srs_test_session(UUID, UUID) TO anon;
