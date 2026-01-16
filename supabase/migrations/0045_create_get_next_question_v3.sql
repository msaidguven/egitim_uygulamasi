-- Migration: 0045_create_get_next_question_v3.sql
-- Bu fonksiyon, hem sıradaki soruyu hem de cevaplanmış soru sayısını tek seferde döndürerek performansı artırır.

CREATE OR REPLACE FUNCTION public.get_next_question_v3(p_session_id bigint)
RETURNS json -- Tek bir JSON nesnesi döndürür
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_question_id bigint;
    v_answered_count int;
    v_question_details jsonb;
    v_result json;
BEGIN
    -- 1. Cevaplanmış soru sayısını hesapla
    SELECT count(*) INTO v_answered_count
    FROM public.test_session_answers tsa
    WHERE tsa.test_session_id = p_session_id;

    -- 2. Sıradaki çözülmemiş soruyu bul
    SELECT tsq.question_id INTO v_question_id
    FROM public.test_session_questions tsq
    LEFT JOIN public.test_session_answers tsa ON tsq.test_session_id = tsa.test_session_id AND tsq.question_id = tsa.question_id
    WHERE tsq.test_session_id = p_session_id AND tsa.id IS NULL
    ORDER BY tsq.order_no ASC
    LIMIT 1;

    -- 3. Eğer soru kalmadıysa, sadece cevap sayısını döndür, soru null olsun
    IF v_question_id IS NULL THEN
        SELECT json_build_object(
            'answered_count', v_answered_count,
            'question', null
        ) INTO v_result;
        RETURN v_result;
    END IF;

    -- 4. Soru detaylarını al (get_question_details fonksiyonunu doğrudan buraya entegre ederek daha da hızlandırabiliriz, şimdilik ayrı bırakalım)
    SELECT public.get_question_details(v_question_id) INTO v_question_details;

    -- 5. Tüm bilgileri tek bir JSON nesnesinde birleştir
    SELECT json_build_object(
        'answered_count', v_answered_count,
        'question', v_question_details
    ) INTO v_result;

    RETURN v_result;
END;
$$;
