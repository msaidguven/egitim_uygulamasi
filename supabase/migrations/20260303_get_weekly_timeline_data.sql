-- supabase/migrations/20260303_get_weekly_timeline_data.sql

DROP FUNCTION IF EXISTS get_weekly_timeline_data(uuid, bigint, bigint, int);

CREATE OR REPLACE FUNCTION get_weekly_timeline_data(p_user_id uuid, p_lesson_id bigint, p_grade_id bigint, p_current_week int)
RETURNS TABLE (
    unit_id bigint,
    unit_title text,
    unit_total_questions bigint,
    unit_solved_questions bigint,
    week_no integer,
    topic_names text,
    week_total_questions bigint,
    week_solved_questions bigint,
    is_current boolean,
    is_completed boolean,
    is_locked boolean
) AS $$
BEGIN
    RETURN QUERY
    WITH weekly_questions AS (
        -- Her haftanın toplam soru sayısı
        SELECT 
            u.id as uid,
            cw.curriculum_week as w_no,
            SUM(cw.total_questions)::bigint as total_q
        FROM units u
        JOIN curriculum_week_question_counts cw ON u.id = cw.unit_id
        WHERE u.lesson_id = p_lesson_id AND u.grade_id = p_grade_id
        GROUP BY u.id, cw.curriculum_week
    ),
    weekly_user_progress AS (
        -- Kullanıcının o haftadaki çözdüğü sorular
        SELECT 
            s.unit_id as uid,
            s.curriculum_week as w_no,
            SUM(s.correct_count + s.wrong_count)::bigint as solved_q
        FROM (
            SELECT DISTINCT ON (ucrwrs.user_id, ucrwrs.unit_id, ucrwrs.curriculum_week)
                ucrwrs.unit_id,
                ucrwrs.curriculum_week,
                ucrwrs.correct_count,
                ucrwrs.wrong_count
            FROM user_curriculum_week_run_summary ucrwrs
            WHERE ucrwrs.user_id = p_user_id
            ORDER BY ucrwrs.user_id, ucrwrs.unit_id, ucrwrs.curriculum_week, ucrwrs.run_no DESC
        ) s
        GROUP BY s.unit_id, s.curriculum_week
    ),
    weekly_topics AS (
        -- Haftaya ait konu isimleri
        SELECT 
            u.id as uid,
            tcw.curriculum_week as w_no,
            string_agg(DISTINCT t.title, ', ') as topics
        FROM units u
        JOIN topics t ON u.id = t.unit_id
        JOIN topic_contents tc ON t.id = tc.topic_id
        JOIN topic_content_weeks tcw ON tc.id = tcw.topic_content_id
        WHERE u.lesson_id = p_lesson_id AND u.grade_id = p_grade_id
        GROUP BY u.id, tcw.curriculum_week
    ),
    all_weeks AS (
        -- Ünitelerin haftalık dökümü
        SELECT 
            u.id as uid,
            u.title as utitle,
            u.order_no as u_order,
            u.question_count::bigint as u_total_q,
            COALESCE(uus.solved_question_count, 0)::bigint as u_solved_q,
            w.w_no,
            COALESCE(w.total_q, 0) as w_total_q,
            COALESCE(up.solved_q, 0) as w_solved_q,
            COALESCE(wt.topics, '') as w_topics
        FROM units u
        JOIN weekly_questions w ON u.id = w.uid
        LEFT JOIN weekly_user_progress up ON u.id = up.uid AND w.w_no = up.w_no
        LEFT JOIN weekly_topics wt ON u.id = wt.uid AND w.w_no = wt.w_no
        LEFT JOIN user_unit_summary uus ON u.id = uus.unit_id AND uus.user_id = p_user_id
        WHERE u.lesson_id = p_lesson_id AND u.grade_id = p_grade_id AND u.is_active = true
    )
    SELECT 
        aw.uid as unit_id,
        aw.utitle as unit_title,
        aw.u_total_q as unit_total_questions,
        aw.u_solved_q as unit_solved_questions,
        aw.w_no as week_no,
        aw.w_topics as topic_names,
        aw.w_total_q as week_total_questions,
        aw.w_solved_q as week_solved_questions,
        (aw.w_no = p_current_week) as is_current,
        (aw.w_no < p_current_week) as is_completed,
        (aw.w_no > p_current_week) as is_locked
    FROM all_weeks aw
    ORDER BY aw.u_order, aw.w_no;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION get_weekly_timeline_data(uuid, bigint, bigint, int) TO authenticated;
