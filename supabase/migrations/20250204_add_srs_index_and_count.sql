-- SRS (Spaced Repetition) için gerekli index ve fonksiyonlar

-- next_review_at üzerinde index oluştur (performans için)
CREATE INDEX IF NOT EXISTS idx_user_question_stats_next_review 
ON user_question_stats(user_id, next_review_at) 
WHERE next_review_at IS NOT NULL;

-- Zamanı gelen tekrar sorularının sayısını getiren fonksiyon
CREATE OR REPLACE FUNCTION get_srs_due_count(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM user_question_stats
    WHERE user_id = p_user_id
      AND next_review_at <= NOW()
      AND total_attempts > 0;

    RETURN v_count;
END;
$$;

-- Fonksiyon yetkilerini ayarla
GRANT EXECUTE ON FUNCTION get_srs_due_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_srs_due_count(UUID) TO anon;
