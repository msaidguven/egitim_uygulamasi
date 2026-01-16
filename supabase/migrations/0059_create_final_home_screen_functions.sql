-- Migration: 0059_create_final_home_screen_functions.sql
-- SON GÜNCELLEME: Fonksiyonlar artık ana sayfada ilerleme çubuklarını göstermek için
-- `progress_percentage` ve `success_rate` değerlerini de döndürüyor.

-- 1. FONKSİYON: `get_current_week_agenda` (HomeScreen için)
DROP FUNCTION IF EXISTS public.get_current_week_agenda(uuid, bigint, integer);
CREATE OR REPLACE FUNCTION public.get_current_week_agenda(
    p_user_id uuid,
    p_grade_id bigint,
    p_week_no integer
)
RETURNS TABLE (
    lesson_id bigint,
    lesson_name text,
    grade_id bigint,
    grade_name text,
    week_no integer,
    topic_title text,
    status text,
    progress_percentage integer, -- YENİ
    success_rate numeric(5, 2)    -- YENİ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        l.id AS lesson_id,
        l.name AS lesson_name,
        g.id AS grade_id,
        g.name AS grade_name,
        p_week_no AS week_no,
        (SELECT t.title FROM topics t JOIN units u_inner ON t.unit_id = u_inner.id JOIN topic_content_weeks tcw ON t.id = (SELECT tc.topic_id FROM topic_contents tc WHERE tc.id = tcw.topic_content_id) WHERE tcw.display_week = p_week_no AND u_inner.lesson_id = l.id LIMIT 1) AS topic_title,
        COALESCE(
            (SELECT
                CASE
                    WHEN up.system_completed THEN 'completed'::text
                    ELSE 'in_progress'::text
                END
             FROM public.user_progress up
             WHERE up.user_id = p_user_id AND up.lesson_id = l.id AND up.grade_id = g.id AND up.week_no = p_week_no
            ),
            'not_started'::text
        ) AS status,
        (SELECT up.progress_percentage FROM public.user_progress up WHERE up.user_id = p_user_id AND up.lesson_id = l.id AND up.grade_id = g.id AND up.week_no = p_week_no) AS progress_percentage,
        (SELECT up.success_rate FROM public.user_progress up WHERE up.user_id = p_user_id AND up.lesson_id = l.id AND up.grade_id = g.id AND up.week_no = p_week_no) AS success_rate
    FROM public.lessons l
    JOIN public.lesson_grades lg ON l.id = lg.lesson_id
    JOIN public.grades g ON lg.grade_id = g.id
    WHERE
        lg.grade_id = p_grade_id
        AND l.is_active = true;
END;
$$;


-- 2. FONKSİYON: `get_all_next_steps_for_user` (HomeScreen için)
DROP FUNCTION IF EXISTS public.get_all_next_steps_for_user(uuid, bigint, integer, integer);
CREATE OR REPLACE FUNCTION public.get_all_next_steps_for_user(
    p_user_id uuid,
    p_grade_id bigint,
    p_exclude_week_no integer,
    p_current_academic_week integer
)
RETURNS TABLE (
    status text,
    week_no integer,
    lesson_id bigint,
    lesson_name text,
    grade_id bigint,
    grade_name text,
    topic_title text,
    progress_percentage integer, -- YENİ
    success_rate numeric(5, 2)    -- YENİ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        CASE
            WHEN up.id IS NOT NULL THEN 'in_progress'::text
            ELSE 'next'::text
        END AS status,
        all_weeks.week_no,
        all_weeks.lesson_id,
        all_weeks.lesson_name,
        p_grade_id AS grade_id,
        g.name AS grade_name,
        (SELECT t.title FROM topics t JOIN topic_contents tc ON t.id = tc.topic_id JOIN topic_content_weeks tcw ON tc.id = tcw.topic_content_id WHERE tcw.display_week = all_weeks.week_no AND tc.topic_id = all_weeks.topic_id LIMIT 1) AS topic_title,
        up.progress_percentage,
        up.success_rate
    FROM (
        SELECT DISTINCT tcw.display_week AS week_no, u.lesson_id, l.name AS lesson_name, t.id as topic_id
        FROM topic_content_weeks tcw
        JOIN topic_contents tc ON tcw.topic_content_id = tc.id
        JOIN topics t ON tc.topic_id = t.id
        JOIN units u ON t.unit_id = u.id
        JOIN lessons l ON u.lesson_id = l.id
        JOIN unit_grades ug ON u.id = ug.unit_id
        WHERE ug.grade_id = p_grade_id
    ) AS all_weeks
    LEFT JOIN public.user_progress up ON up.user_id = p_user_id AND up.lesson_id = all_weeks.lesson_id AND up.grade_id = p_grade_id AND up.week_no = all_weeks.week_no
    JOIN public.grades g ON p_grade_id = g.id
    WHERE
        up.system_completed IS DISTINCT FROM true
        AND all_weeks.week_no != p_exclude_week_no
        AND all_weeks.week_no < p_current_academic_week
    ORDER BY
        status ASC,
        all_weeks.week_no ASC,
        all_weeks.lesson_id ASC;
END;
$$;
