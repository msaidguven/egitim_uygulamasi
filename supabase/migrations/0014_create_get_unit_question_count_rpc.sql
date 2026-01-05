-- Fonksiyon, bir unit_id alarak o üniteye bağlı tüm konulardaki
-- toplam soru sayısını döndürür.
CREATE OR REPLACE FUNCTION get_unit_question_count(p_unit_id BIGINT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    total_questions INT;
BEGIN
    SELECT
        COUNT(q.id)
    INTO
        total_questions
    FROM
        public.questions q
    WHERE
        q.topic_id IN (SELECT t.id FROM public.topics t WHERE t.unit_id = p_unit_id);

    RETURN total_questions;
END;
$$;
