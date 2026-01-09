-- start_test fonksiyonunu DISTINCT + ORDER BY hatasını giderecek şekilde güncelle

CREATE OR REPLACE FUNCTION public.start_test(p_user_id uuid, p_unit_id bigint)
RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
    v_session_id bigint;
    v_question_count int;
BEGIN
    -- 1. Aktif oturum kontrolü
    SELECT id INTO v_session_id
    FROM public.test_sessions
    WHERE user_id = p_user_id
      AND unit_id = p_unit_id
      AND completed_at IS NULL
    LIMIT 1;

    IF v_session_id IS NOT NULL THEN
        RETURN v_session_id;
    END IF;

    -- 2. Soru havuzu sayısını kontrol et (GROUP BY ile güvenli sayım)
    SELECT count(*) INTO v_question_count
    FROM (
        SELECT qu.question_id
        FROM public.question_usages qu
        JOIN public.topics t ON qu.topic_id = t.id
        WHERE t.unit_id = p_unit_id
        GROUP BY qu.question_id
    ) sub;

    IF v_question_count < 10 THEN
        RAISE EXCEPTION 'Yetersiz soru sayısı: %', v_question_count;
    END IF;

    -- 3. Yeni oturum oluştur
    INSERT INTO public.test_sessions (user_id, unit_id)
    VALUES (p_user_id, p_unit_id)
    RETURNING id INTO v_session_id;

    -- 4. Soruları rastgele seç ve sabitle (Hata giderildi: GROUP BY kullanıldı)
    INSERT INTO public.test_session_questions (test_session_id, question_id, order_no)
    SELECT v_session_id, q_id, row_number() OVER ()
    FROM (
        SELECT qu.question_id as q_id
        FROM public.question_usages qu
        JOIN public.topics t ON qu.topic_id = t.id
        WHERE t.unit_id = p_unit_id
        GROUP BY qu.question_id
        ORDER BY random()
        LIMIT 10
    ) sub;

    RETURN v_session_id;
END;
$$;
