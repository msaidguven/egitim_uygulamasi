-- Migration: 0040_create_get_unit_summary_rpc.sql

CREATE OR REPLACE FUNCTION public.get_unit_summary(p_user_id uuid, p_unit_id bigint, p_client_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_stats record;
    v_session record;
    v_unit_name text;
BEGIN
    -- 1. Ünite Adını Al
    SELECT title INTO v_unit_name FROM public.units WHERE id = p_unit_id;

    -- 2. İstatistikleri user_question_stats üzerinden hesapla
    SELECT
        count(q.id)::int as total_q,
        count(uqs.question_id)::int as solved_q,
        sum(uqs.total_attempts)::int as total_attempts,
        sum(uqs.correct_attempts)::int as correct_attempts,
        sum(uqs.wrong_attempts)::int as wrong_attempts,
        count(*) FILTER (WHERE uqs.last_answer_correct = true)::int as correct_q,
        count(*) FILTER (WHERE uqs.last_answer_correct = false)::int as incorrect_q
    INTO v_stats
    FROM public.questions q
    JOIN public.question_usages qu ON q.id = qu.question_id
    JOIN public.topics t ON qu.topic_id = t.id
    LEFT JOIN public.user_question_stats uqs ON uqs.question_id = q.id AND uqs.user_id = p_user_id
    WHERE t.unit_id = p_unit_id;

    -- 3. Devam eden (yarım kalmış) test oturumunu bul (client_id bazlı)
    SELECT
        ts.id as session_id,
        (SELECT count(*) FROM public.test_session_questions tsq WHERE tsq.test_session_id = ts.id)::int as session_total,
        (SELECT count(*) FROM public.test_session_answers tsa WHERE tsa.test_session_id = ts.id)::int as session_answered
    INTO v_session
    FROM public.test_sessions ts
    WHERE ts.client_id = p_client_id
      AND ts.unit_id = p_unit_id
      AND ts.completed_at IS NULL
    ORDER BY ts.created_at DESC
    LIMIT 1;

    -- 4. Sonucu JSON olarak birleştir
    RETURN jsonb_build_object(
        'unit_name', v_unit_name,
        'total_questions', v_stats.total_q,
        'solved_questions', v_stats.solved_q,
        'total_attempts', COALESCE(v_stats.total_attempts, 0),
        'correct_attempts', COALESCE(v_stats.correct_attempts, 0),
        'wrong_attempts', COALESCE(v_stats.wrong_attempts, 0),
        'correct_count', v_stats.correct_q,
        'incorrect_count', v_stats.incorrect_q,
        'unsolved_count', (v_stats.total_q - COALESCE(v_stats.solved_q, 0)),
        'success_rate', CASE WHEN v_stats.solved_q > 0 THEN ROUND((v_stats.correct_q::numeric / v_stats.solved_q * 100), 1) ELSE 0 END,
        'active_session', CASE WHEN v_session.session_id IS NOT NULL THEN
            jsonb_build_object(
                'id', v_session.session_id,
                'total', v_session.session_total,
                'answered', v_session.session_answered
            ) ELSE NULL END
    );
END;
$$;
