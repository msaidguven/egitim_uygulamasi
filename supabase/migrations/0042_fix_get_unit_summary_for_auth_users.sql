-- Migration: 0042_fix_get_unit_summary_for_auth_users.sql
-- GÜNCELLEME 3 (NİHAİ DÜZELTME): Fonksiyon, artık yarım kalmış bir oturum ararken,
-- sadece 'unit_test' veya 'wrongAnswers' türündeki testleri arayacak şekilde düzeltildi.

CREATE OR REPLACE FUNCTION public.get_unit_summary(p_user_id uuid, p_unit_id bigint, p_client_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_summary jsonb;
    v_session record;
BEGIN
    -- 1. Devam eden (yarım kalmış) 'normal' veya 'yanlışlar' test oturumunu bul.
    --    Bu sorgu artık sadece kendi ilgilendiği test türlerini arar.
    SELECT
        ts.id as session_id,
        (SELECT count(*) FROM public.test_session_questions tsq WHERE tsq.test_session_id = ts.id)::int as session_total,
        (SELECT count(*) FROM public.test_session_answers tsa WHERE tsa.test_session_id = ts.id)::int as session_answered
    INTO v_session
    FROM public.test_sessions ts
    WHERE
      ts.unit_id = p_unit_id
      AND ts.completed_at IS NULL
      AND (
          (p_user_id IS NOT NULL AND ts.user_id = p_user_id)
          OR
          (p_user_id IS NULL AND ts.client_id = p_client_id)
      )
      -- KRİTİK DÜZELTME: Sadece 'unit_test' veya 'wrongAnswers' türündeki testleri ara.
      AND (ts.settings->>'type' = 'unit_test' OR ts.settings->>'type' = 'wrongAnswers')
    ORDER BY ts.created_at DESC
    LIMIT 1;

    -- 2. İstatistikleri yeni özet tablolarından JOIN ile al
    SELECT
        jsonb_build_object(
            'unit_name', u.title,
            'total_questions', u.question_count,
            'unique_solved_count', COALESCE(uus.correct_count, 0) + COALESCE(uus.wrong_count, 0),
            'correct_count', COALESCE(uus.correct_count, 0),
            'incorrect_count', COALESCE(uus.wrong_count, 0),
            'unsolved_count', GREATEST(0, u.question_count - (COALESCE(uus.correct_count, 0) + COALESCE(uus.wrong_count, 0))),
            'success_rate', CASE WHEN (COALESCE(uus.correct_count, 0) + COALESCE(uus.wrong_count, 0)) > 0 THEN ROUND((COALESCE(uus.correct_count, 0)::numeric / (COALESCE(uus.correct_count, 0) + COALESCE(uus.wrong_count, 0)) * 100), 1) ELSE 0 END,
            'available_question_count', GREATEST(0, u.question_count - (COALESCE(uus.correct_count, 0) + COALESCE(uus.wrong_count, 0))),
            'active_session', CASE WHEN v_session.session_id IS NOT NULL THEN
                jsonb_build_object(
                    'id', v_session.session_id,
                    'total', v_session.session_total,
                    'answered', v_session.session_answered
                ) ELSE NULL END
        )
    INTO v_summary
    FROM public.units u
    LEFT JOIN public.user_unit_summary uus
        ON u.id = uus.unit_id
        AND uus.user_id = p_user_id
    WHERE u.id = p_unit_id;

    -- Eğer ünite bulunamazsa, boş bir özet döndür.
    IF NOT FOUND THEN
        RETURN '{}'::jsonb;
    END IF;

    RETURN v_summary;
END;
$$;
