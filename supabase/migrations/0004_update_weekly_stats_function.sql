CREATE OR REPLACE FUNCTION public.get_weekly_summary_stats(
    p_user_id uuid,
    p_unit_id bigint,
    p_curriculum_week integer
)
RETURNS json
LANGUAGE plpgsql
AS $function$
DECLARE
v_summary json;
    v_active_session_details jsonb;
    v_total_questions int;
    v_available_questions_count int;
    v_correct_count int := 0;
    v_wrong_count int := 0;
    v_solved_unique int := 0;
BEGIN
    /* 1️⃣ Aktif haftalık test oturumu */
SELECT
    jsonb_build_object(
            'id', ts.id,
            'total_questions',
            (SELECT count(*)
             FROM public.test_session_questions
             WHERE test_session_id = ts.id),
            'answered_questions',
            (SELECT count(*)
             FROM public.test_session_answers
             WHERE test_session_id = ts.id)
    )
INTO v_active_session_details
FROM public.test_sessions ts
WHERE ts.unit_id = p_unit_id
  AND ts.user_id = p_user_id
  AND ts.completed_at IS NULL
  AND ts.settings->>'type' = 'weekly'
  AND (ts.settings->>'curriculum_week')::integer = p_curriculum_week
ORDER BY ts.created_at DESC
    LIMIT 1;

/* 2️⃣ Haftalık toplam soru */
SELECT COALESCE(cwqc.total_questions, 0)
INTO v_total_questions
FROM public.curriculum_week_question_counts cwqc
WHERE cwqc.unit_id = p_unit_id
  AND cwqc.curriculum_week = p_curriculum_week;

/* 3️⃣ Kullanıcının henüz görmediği sorular */
WITH all_weekly_questions AS (
    SELECT q.id
    FROM public.questions q
             JOIN public.question_usages qu ON q.id = qu.question_id
             JOIN public.topics t ON qu.topic_id = t.id
    WHERE t.unit_id = p_unit_id
      AND qu.curriculum_week = p_curriculum_week
)
SELECT
    count(q.id) FILTER (WHERE ucwsq.id IS NULL)
INTO v_available_questions_count
FROM all_weekly_questions q
         LEFT JOIN public.user_curriculum_week_seen_questions ucwsq
                   ON q.id = ucwsq.question_id
                       AND ucwsq.user_id = p_user_id
                       AND ucwsq.unit_id = p_unit_id
                       AND ucwsq.curriculum_week = p_curriculum_week;

/* 4️⃣ En son denemenin doğru/yanlış özetini al (run_no en büyük olan) */
SELECT
    COALESCE(correct_count, 0),
    COALESCE(wrong_count, 0)
INTO
    v_correct_count,
    v_wrong_count
FROM public.user_curriculum_week_run_summary
WHERE user_id = p_user_id
  AND unit_id = p_unit_id
  AND curriculum_week = p_curriculum_week
ORDER BY run_no DESC
    LIMIT 1;

v_solved_unique := v_correct_count + v_wrong_count;

    /* 5️⃣ Final JSON */
SELECT json_build_object(
               'total_questions', v_total_questions,
               'solved_unique', v_solved_unique,
               'correct_count', v_correct_count,
               'wrong_count', v_wrong_count,
               'active_session', v_active_session_details,
               'available_questions_count', v_available_questions_count
       )
INTO v_summary;

RETURN v_summary;
END;
$function$;
