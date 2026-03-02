-- supabase/migrations/20260302_add_get_unit_map_data.sql

DROP FUNCTION IF EXISTS get_unit_map_data(uuid, bigint, bigint);

CREATE OR REPLACE FUNCTION get_unit_map_data(p_user_id uuid, p_lesson_id bigint, p_grade_id bigint, p_current_week int)
RETURNS TABLE (
    unit_id bigint,
    title text,
    total_questions bigint,
    solved_questions bigint,
    correct_answers bigint,
    order_no integer,
    is_current_week boolean,
    start_week integer,
    end_week integer
) AS $$
BEGIN
    RETURN QUERY
    WITH unit_stats AS (
        SELECT 
            u.id as uid,
            u.title as utitle,
            COALESCE(u.question_count, 0)::bigint as total_q,
            u.order_no as uno,
            COALESCE(uus.solved_question_count, 0)::bigint as solved_q,
            COALESCE(uus.correct_count, 0)::bigint as correct_a
        FROM public.units u
        LEFT JOIN public.user_unit_summary uus ON u.id = uus.unit_id AND uus.user_id = p_user_id
        WHERE u.lesson_id = p_lesson_id AND u.grade_id = p_grade_id AND u.is_active = true
    ),
    unit_weeks AS (
        SELECT 
            u.id as uid,
            MIN(cwqc.curriculum_week) as s_week,
            MAX(cwqc.curriculum_week) as e_week
        FROM public.units u
        LEFT JOIN public.curriculum_week_question_counts cwqc ON u.id = cwqc.unit_id
        WHERE u.lesson_id = p_lesson_id AND u.grade_id = p_grade_id
        GROUP BY u.id
    )
    SELECT 
        us.uid as unit_id,
        us.utitle as title,
        us.total_q as total_questions,
        us.solved_q as solved_questions,
        us.correct_a as correct_answers,
        us.uno as order_no,
        (p_current_week BETWEEN uw.s_week AND uw.e_week) as is_current_week,
        uw.s_week as start_week,
        uw.e_week as end_week
    FROM unit_stats us
    LEFT JOIN unit_weeks uw ON us.uid = uw.uid
    ORDER BY us.uno;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION get_unit_map_data(uuid, bigint, bigint, int) TO authenticated;
