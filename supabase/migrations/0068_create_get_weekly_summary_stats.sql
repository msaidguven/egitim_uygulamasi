-- Migration: 0068_create_get_weekly_summary_stats.sql
-- GÜNCELLEME 3 (NİHAİ DÜZELTME): Fonksiyon, yarım kalmış oturumun detaylarını
-- (toplam ve cevaplanmış soru sayısı) tekrar doğru bir şekilde döndürecek şekilde düzeltildi.

CREATE OR REPLACE FUNCTION public.get_weekly_summary_stats(
    p_user_id uuid,
    p_unit_id bigint,
    p_week_no integer
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_summary json;
    v_active_session_details jsonb; -- Oturum detaylarını tutacak jsonb değişkeni
    v_total_questions int;
    v_available_questions_count int;
    v_stats record;
BEGIN
    -- 1. Aktif oturumu ve detaylarını bul
    SELECT
        jsonb_build_object(
            'id', ts.id,
            'total_questions', (SELECT count(*) FROM public.test_session_questions WHERE test_session_id = ts.id),
            'answered_questions', (SELECT count(*) FROM public.test_session_answers WHERE test_session_id = ts.id)
        )
    INTO v_active_session_details
    FROM public.test_sessions ts
    WHERE ts.unit_id = p_unit_id
      AND ts.user_id = p_user_id
      AND ts.completed_at IS NULL
      AND ts.settings->>'type' = 'weekly'
      AND (ts.settings->>'week_no')::integer = p_week_no
    ORDER BY ts.created_at DESC
    LIMIT 1;

    -- 2. Bu haftanın toplam soru sayısını ve çözülmeye hazır (kalan) soru sayısını hesapla
    WITH all_weekly_questions AS (
        SELECT q.id
        FROM public.questions AS q
        JOIN public.question_usages AS qu ON q.id = qu.question_id
        JOIN public.topics AS t ON qu.topic_id = t.id
        WHERE t.unit_id = p_unit_id
          AND qu.display_week = p_week_no
    )
    SELECT
        count(*), -- Toplam soru sayısı
        count(q.id) FILTER (WHERE uwqp.id IS NULL) -- Çözülmemiş (hazır) soru sayısı
    INTO
        v_total_questions,
        v_available_questions_count
    FROM all_weekly_questions q
    LEFT JOIN public.user_weekly_question_progress uwqp
        ON q.id = uwqp.question_id
        AND uwqp.user_id = p_user_id
        AND uwqp.unit_id = p_unit_id
        AND uwqp.week_no = p_week_no;

    -- 3. Çözülmüş sorular üzerinden istatistikleri YENİ TABLODAN HESAPLA
    SELECT
        count(*)::int AS solved_unique,
        count(*) FILTER (WHERE is_correct = true)::int AS correct_count,
        count(*) FILTER (WHERE is_correct = false)::int AS wrong_count
    INTO v_stats
    FROM public.user_weekly_question_progress
    WHERE user_id = p_user_id
      AND unit_id = p_unit_id
      AND week_no = p_week_no;

    -- 4. Sonucu JSON olarak birleştir
    SELECT
        json_build_object(
            'total_questions', v_total_questions,
            'solved_unique', COALESCE(v_stats.solved_unique, 0),
            'correct_count', COALESCE(v_stats.correct_count, 0),
            'wrong_count', COALESCE(v_stats.wrong_count, 0),
            'active_session', v_active_session_details, -- Düzeltilmiş detaylı nesneyi kullan
            'available_questions_count', v_available_questions_count
        )
    INTO v_summary;

    RETURN v_summary;
END;
$$;
