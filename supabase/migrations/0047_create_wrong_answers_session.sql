-- Migration: 0047_create_wrong_answers_session.sql
-- Fonksiyon, yanlışlar testini 10 soru ile sınırlandıracak şekilde güncellendi.

CREATE OR REPLACE FUNCTION public.start_wrong_answers_session(
    p_client_id uuid,
    p_unit_id bigint,
    p_user_id uuid
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_session_id bigint;
    v_question_count int;
BEGIN
    -- SECURITY GUARD
    IF p_user_id <> auth.uid() THEN
        RAISE EXCEPTION 'Yetkisiz user_id kullanımı.';
    END IF;

    -- 1. Bu ünite için yanlış cevaplanmış soru sayısını kontrol et
    SELECT count(*) INTO v_question_count
    FROM public.user_question_stats uqs
    JOIN public.question_usages qu ON uqs.question_id = qu.question_id
    JOIN public.topics t ON qu.topic_id = t.id
    WHERE t.unit_id = p_unit_id
      AND uqs.user_id = p_user_id
      AND uqs.last_answer_correct = false;

    IF v_question_count = 0 THEN
        RAISE EXCEPTION 'Bu ünitede yanlış cevaplanmış sorunuz bulunmuyor.';
    END IF;

    -- 2. Yeni bir "yanlışlar testi" oturumu oluştur
    INSERT INTO public.test_sessions (user_id, client_id, unit_id, settings)
    VALUES (p_user_id, p_client_id, p_unit_id, '{"type": "wrong_answers_test", "version": "1.0"}'::jsonb)
    RETURNING id INTO v_session_id;

    -- 3. Yanlış cevaplanmış sorulardan rastgele 10 tanesini oturuma ekle
    INSERT INTO public.test_session_questions (test_session_id, question_id, order_no)
    SELECT v_session_id, uqs.question_id, row_number() OVER (ORDER BY random())
    FROM public.user_question_stats uqs
    JOIN public.question_usages qu ON uqs.question_id = qu.question_id
    JOIN public.topics t ON qu.topic_id = t.id
    WHERE t.unit_id = p_unit_id
      AND uqs.user_id = p_user_id
      AND uqs.last_answer_correct = false
    ORDER BY random()
    LIMIT 10; -- Hata düzeltmesi: Testi 10 soru ile sınırla

    RETURN v_session_id;
END;
$$;
