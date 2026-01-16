-- Fonksiyon, aralıklı tekrar (spaced repetition) mantığını içerecek şekilde güncellendi.
-- Artık soruları seçerken `user_question_stats` tablosunu kontrol eder.
CREATE OR REPLACE FUNCTION start_weekly_test(p_user_id uuid, p_topic_id bigint, p_week integer)
RETURNS TABLE(session_id bigint, unit_id bigint)
LANGUAGE plpgsql
AS $$
DECLARE
    v_session_id bigint;
    v_settings jsonb;
    v_unit_id bigint;
BEGIN
    -- 1. Adım: Verilen topic_id'den unit_id'yi al.
    SELECT t.unit_id INTO v_unit_id FROM topics t WHERE t.id = p_topic_id;

    -- Eğer unit_id bulunamazsa, hata ver.
    IF v_unit_id IS NULL THEN
        RAISE EXCEPTION 'Topic with id % not found or does not have a unit.', p_topic_id;
    END IF;

    -- 2. Adım: Kullanıcının bu ÜNİTE için zaten aktif (tamamlanmamış) bir testi var mı diye kontrol et.
    SELECT id INTO v_session_id
    FROM test_sessions ts
    WHERE
        ts.user_id = p_user_id
        AND ts.unit_id = v_unit_id
        AND ts.completed_at IS NULL;

    -- 3. Adım: Eğer aktif bir oturum bulunduysa, onun ID'sini ve unit_id'yi döndür.
    IF v_session_id IS NOT NULL THEN
        RETURN QUERY SELECT v_session_id, v_unit_id;
        RETURN;
    END IF;

    -- 4. Adım: Aktif oturum yoksa, yeni bir tane oluştur.
    v_settings := jsonb_build_object(
        'mode', 'weekly',
        'status', 'started',
        'topic_id', p_topic_id,
        'week', p_week
    );

    INSERT INTO test_sessions (user_id, unit_id, settings, client_id)
    VALUES (p_user_id, v_unit_id, v_settings, gen_random_uuid())
    RETURNING id INTO v_session_id;

    -- 5. Adım: Yeni oturum için soruları seç ve ekle (SPACED REPETITION MANTIĞI EKLENDİ).
    INSERT INTO test_session_questions (test_session_id, question_id, order_no)
    SELECT
        v_session_id,
        q.id,
        ROW_NUMBER() OVER (ORDER BY q.difficulty, q.id) AS new_order_no
    FROM
        public.questions q
    JOIN
        public.question_usages qu ON q.id = qu.question_id
    LEFT JOIN
        public.user_question_stats uqs ON q.id = uqs.question_id AND uqs.user_id = p_user_id
    WHERE
        qu.usage_type = 'weekly'
        AND qu.topic_id = p_topic_id
        AND qu.display_week = p_week
        AND (uqs.user_id IS NULL OR uqs.next_review_at <= now()) -- Spaced Repetition Mantığı
    ORDER BY
        q.difficulty ASC,
        q.id ASC
    LIMIT 10;

    -- 6. Adım: Oluşturulan yeni session_id ve unit_id'yi döndür.
    RETURN QUERY SELECT v_session_id, v_unit_id;
END;
$$;
