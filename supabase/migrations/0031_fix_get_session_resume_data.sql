-- 1. get_session_resume_data fonksiyonunu düzelt
-- Sorun: question_ids dizisi ile questions tablosunu join ederken sıra kayboluyor veya null değerler sorun yaratıyor olabilir.
-- Ayrıca user_answers tablosundan veri çekerken tekil kayıt gelmesini garanti altına almalıyız.

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

    -- Eğer question_ids null ise boş dön
    IF v_question_ids IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        -- Sorunun detayları (get_question_details fonksiyonunu kullanıyoruz)
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
            ORDER BY ua.answered_at DESC -- En son cevabı al
            LIMIT 1
        ) AS user_answer_data
    FROM
        unnest(v_question_ids) WITH ORDINALITY t(id, ord)
    JOIN
        public.questions q ON q.id = t.id
    ORDER BY
        t.ord; -- Kaydedilen sıraya göre getir
END;
$$;
