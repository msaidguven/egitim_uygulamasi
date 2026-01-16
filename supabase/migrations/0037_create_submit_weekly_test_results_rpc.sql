CREATE OR REPLACE FUNCTION submit_weekly_test_results(p_session_id bigint, p_user_answers jsonb)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id uuid;
    v_question_id bigint;
    v_is_correct boolean;
    answer_record record;
BEGIN
    -- Oturumun kullanıcısını al
    SELECT user_id INTO v_user_id FROM test_sessions WHERE id = p_session_id;

    -- Eğer oturum bulunamazsa veya kullanıcı yoksa çık
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Test session not found or user_id is null';
    END IF;

    -- p_user_answers (jsonb) içindeki her bir cevabı döngüye al
    FOR answer_record IN SELECT * FROM jsonb_to_recordset(p_user_answers) AS x(question_id bigint, is_correct boolean)
    LOOP
        v_question_id := answer_record.question_id;
        v_is_correct := answer_record.is_correct;

        -- user_question_stats tablosunu güncelle veya yeni kayıt ekle
        INSERT INTO user_question_stats (user_id, question_id, correct_answers, incorrect_answers, last_answered_correct)
        VALUES (v_user_id, v_question_id, CASE WHEN v_is_correct THEN 1 ELSE 0 END, CASE WHEN v_is_correct THEN 0 ELSE 1 END, v_is_correct)
        ON CONFLICT (user_id, question_id)
        DO UPDATE SET
            correct_answers = user_question_stats.correct_answers + EXCLUDED.correct_answers,
            incorrect_answers = user_question_stats.incorrect_answers + EXCLUDED.incorrect_answers,
            last_answered_correct = EXCLUDED.last_answered_correct,
            updated_at = now();

        -- user_answers tablosuna da kaydı ekleyelim
        -- Not: Bu kısım, cevapların ayrıca saklanması isteniyorsa gereklidir.
        -- `start_weekly_test` içinde `test_session_questions` zaten doldurulduğu için
        -- burada sadece cevabın kendisini güncellemek yeterli olabilir.
        -- Şimdilik, bu fonksiyonun sadece istatistikleri güncellediğini varsayıyoruz.

    END LOOP;

    -- user_progress tablosunu güncelleme mantığı buraya eklenebilir.
    -- Örneğin, tamamlanan hafta sayısını artırma veya o haftanın puanını kaydetme.
    -- UPDATE user_progress SET ... WHERE user_id = v_user_id;

END;
$$;