-- Migration: 0070_create_finish_weekly_test_function.sql
-- GÜNCELLEME 2: Fonksiyon, artık test sonuçlarını hem bireysel olarak `user_weekly_question_progress`
-- tablosuna hem de özet olarak `user_weekly_summary` tablosuna işleyecek şekilde düzeltildi.

CREATE OR REPLACE FUNCTION public.finish_weekly_test(p_session_id bigint)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_session_info record;
    v_test_summary record;
BEGIN
    -- 1. Oturum bilgilerini (unit_id, week_no, user_id) al.
    SELECT
        ts.user_id,
        ts.unit_id,
        (ts.settings->>'week_no')::integer as week_no
    INTO v_session_info
    FROM public.test_sessions ts
    WHERE ts.id = p_session_id AND ts.completed_at IS NULL;

    -- Eğer oturum bulunamazsa veya zaten tamamlanmışsa, bir şey yapma.
    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- 2. KRİTİK DÜZELTME: Bireysel cevapları `user_weekly_question_progress` tablosuna işle.
    -- Bu, hangi soruların çözüldüğünü kalıcı olarak kaydeder.
    INSERT INTO public.user_weekly_question_progress (user_id, unit_id, week_no, question_id, is_correct, answered_at)
    SELECT
        tsa.user_id,
        v_session_info.unit_id,
        v_session_info.week_no,
        tsa.question_id,
        tsa.is_correct,
        tsa.created_at
    FROM public.test_session_answers tsa
    WHERE tsa.test_session_id = p_session_id
    -- Herhangi bir çakışma durumunda (nadir, ama güvenli olması için) son cevabı geçerli say.
    ON CONFLICT (user_id, unit_id, week_no, question_id) DO UPDATE
    SET
        is_correct = EXCLUDED.is_correct,
        answered_at = EXCLUDED.answered_at;

    -- 3. Bu test oturumundaki doğru ve yanlış sayılarını hesapla.
    SELECT
        count(*) FILTER (WHERE tsa.is_correct = true) AS correct_answers,
        count(*) FILTER (WHERE tsa.is_correct = false) AS wrong_answers
    INTO v_test_summary
    FROM public.test_session_answers tsa
    WHERE tsa.test_session_id = p_session_id;

    -- 4. Hesaplanan sonuçları `user_weekly_summary` özet tablosuna işle.
    INSERT INTO public.user_weekly_summary (user_id, unit_id, week_no, correct_count, wrong_count, last_updated_at)
    VALUES (
        v_session_info.user_id,
        v_session_info.unit_id,
        v_session_info.week_no,
        v_test_summary.correct_answers,
        v_test_summary.wrong_answers,
        now()
    )
    ON CONFLICT (user_id, unit_id, week_no) DO UPDATE
    SET
        correct_count = user_weekly_summary.correct_count + EXCLUDED.correct_count,
        wrong_count = user_weekly_summary.wrong_count + EXCLUDED.wrong_count,
        last_updated_at = now();

    -- 5. Oturumu "tamamlandı" olarak işaretle.
    UPDATE public.test_sessions
    SET completed_at = now()
    WHERE id = p_session_id;

END;
$$;

COMMENT ON FUNCTION public.finish_weekly_test(bigint) IS 'Bir haftalık test oturumunu sonlandırır, cevapları `user_weekly_question_progress` ve `user_weekly_summary` tablolarına işler.';
