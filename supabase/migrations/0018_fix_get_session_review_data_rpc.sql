-- Mevcut fonksiyonu sil ve yeniden oluştur (idempotent)
DROP FUNCTION IF EXISTS public.get_session_review_data(p_session_id bigint);

CREATE OR REPLACE FUNCTION public.get_session_review_data(p_session_id bigint)
RETURNS TABLE(
    -- questions tablosundan tüm sütunlar
    id bigint,
    question_type_id smallint,
    question_text text,
    difficulty smallint,
    score smallint,
    created_at timestamp without time zone,
    -- user_answers tablosundan eklenen sütunlar
    user_selected_option_id bigint,
    user_answer_text text,
    is_correct boolean
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Bu fonksiyon, belirli bir test oturumundaki tüm soruları
    -- ve kullanıcının bu sorulara verdiği cevapları birleştirerek döndürür.
    RETURN QUERY
    SELECT
        q.id,
        q.question_type_id,
        q.question_text,
        q.difficulty,
        q.score,
        q.created_at,
        ua.selected_option_id as user_selected_option_id,
        ua.answer_text as user_answer_text,
        ua.is_correct
    FROM
        public.questions q
    JOIN
        public.user_answers ua ON q.id = ua.question_id
    WHERE
        ua.session_id = p_session_id
    ORDER BY
        ua.answered_at; -- Soruları cevaplanma sırasına göre diz
END;
$$;
