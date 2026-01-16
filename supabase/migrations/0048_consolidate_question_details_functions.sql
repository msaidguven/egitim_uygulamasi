-- Migration: 0048_consolidate_question_details_functions.sql
-- Bu migration, soru detayları ve istatistikleri getiren fonksiyonlardaki imza değişikliklerini tek bir yerde toplayarak
-- "function does not exist" hatasını çözer ve bağımlılıkları doğru yönetir.
-- DÜZELTME: uqs.id yerine uqs.user_id kontrolü yapıldı.

-- 1. get_question_details fonksiyonunun son hali
-- Kullanıcı istatistiklerini getirmek için p_user_id parametresi alır.
DROP FUNCTION IF EXISTS public.get_question_details(bigint);
CREATE OR REPLACE FUNCTION public.get_question_details(p_question_id bigint, p_user_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
  SELECT
    jsonb_build_object(
      'id', q.id,
      'question_text', q.question_text,
      'difficulty', q.difficulty,
      'score', q.score,
      'question_type_id', q.question_type_id,
      'question_type', jsonb_build_object('code', qt.code),
      -- DÜZELTME: uqs.id yerine uqs.user_id kontrolü yapıldı.
      'user_stats', CASE WHEN uqs.user_id IS NOT NULL THEN jsonb_build_object(
        'total_attempts', uqs.total_attempts,
        'correct_attempts', uqs.correct_attempts,
        'wrong_attempts', uqs.wrong_attempts,
        'last_answer_at', uqs.last_answer_at
      ) ELSE NULL END,
      'question_choices', COALESCE((SELECT jsonb_agg(jsonb_build_object('id', qc.id, 'choice_text', qc.choice_text, 'is_correct', qc.is_correct)) FROM public.question_choices qc WHERE qc.question_id = q.id), '[]'::jsonb),
      'question_blank_options', COALESCE((SELECT jsonb_agg(jsonb_build_object('id', qbo.id, 'question_id', qbo.question_id, 'option_text', qbo.option_text, 'is_correct', qbo.is_correct, 'order_no', qbo.order_no)) FROM public.question_blank_options qbo WHERE qbo.question_id = q.id), '[]'::jsonb),
      'question_matching_pairs', COALESCE((SELECT jsonb_agg(jsonb_build_object('id', qmp.id, 'left_text', qmp.left_text, 'right_text', qmp.right_text)) FROM public.question_matching_pairs qmp WHERE qmp.question_id = q.id), '[]'::jsonb),
      'question_classical', COALESCE((SELECT jsonb_agg(jsonb_build_object('model_answer', qcl.model_answer)) FROM public.question_classical qcl WHERE qcl.question_id = q.id), '[]'::jsonb)
    )
  FROM
    public.questions q
  JOIN
    public.question_types qt ON q.question_type_id = qt.id
  LEFT JOIN
    public.user_question_stats uqs ON q.id = uqs.question_id AND uqs.user_id = p_user_id
  WHERE
    q.id = p_question_id;
$$;


-- 2. get_next_question_v3 fonksiyonunun son hali
-- get_question_details'e p_user_id geçirebilmek için p_user_id parametresi alır.
DROP FUNCTION IF EXISTS public.get_next_question_v3(bigint);
CREATE OR REPLACE FUNCTION public.get_next_question_v3(p_session_id bigint, p_user_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_question_id bigint;
    v_answered_count int;
    v_correct_count int;
    v_question_details jsonb;
    v_result json;
BEGIN
    SELECT count(*), count(*) FILTER (WHERE tsa.is_correct = true) INTO v_answered_count, v_correct_count
    FROM public.test_session_answers tsa WHERE tsa.test_session_id = p_session_id;

    SELECT tsq.question_id INTO v_question_id
    FROM public.test_session_questions tsq
    LEFT JOIN public.test_session_answers tsa ON tsq.test_session_id = tsa.test_session_id AND tsq.question_id = tsa.question_id
    WHERE tsq.test_session_id = p_session_id AND tsa.id IS NULL
    ORDER BY tsq.order_no ASC
    LIMIT 1;

    IF v_question_id IS NULL THEN
        SELECT json_build_object('answered_count', v_answered_count, 'correct_count', v_correct_count, 'question', null) INTO v_result;
        RETURN v_result;
    END IF;

    SELECT public.get_question_details(v_question_id, p_user_id) INTO v_question_details;

    SELECT json_build_object('answered_count', v_answered_count, 'correct_count', v_correct_count, 'question', v_question_details) INTO v_result;
    RETURN v_result;
END;
$$;


-- 3. get_all_session_questions fonksiyonunun son hali
-- get_question_details'e p_user_id geçirebilmek için p_user_id parametresi alır.
DROP FUNCTION IF EXISTS public.get_all_session_questions(bigint);
CREATE OR REPLACE FUNCTION public.get_all_session_questions(p_session_id bigint, p_user_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
    SELECT
        jsonb_agg(q_details.details)
    FROM (
        SELECT
            public.get_question_details(tsq.question_id, p_user_id) as details
        FROM
            public.test_session_questions tsq
        WHERE
            tsq.test_session_id = p_session_id
        ORDER BY
            tsq.order_no ASC
    ) as q_details;
$$;
