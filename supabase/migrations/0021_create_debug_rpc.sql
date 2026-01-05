-- Bu fonksiyon, sorunun veride mi yoksa sorguda mı olduğunu anlamak için bir teşhis aracıdır.
-- Belirli bir konu ve hafta için 'question_usages' tablosunda kaç adet soru olduğunu sayar.
CREATE OR REPLACE FUNCTION debug_find_weekly_questions(
    p_topic_id BIGINT,
    p_week_no INT
)
RETURNS TABLE (
    searched_topic_id BIGINT,
    searched_week_no INT,
    found_questions_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p_topic_id,
        p_week_no,
        COUNT(qu.question_id)
    FROM
        public.question_usages qu
    WHERE
        qu.topic_id = p_topic_id AND qu.display_week = p_week_no;
END;
$$ LANGUAGE plpgsql;
