-- Migration: 0065_fix_get_all_next_steps.sql
-- DIAGNOSTIC TEST: Bu fonksiyonun gerçekten çağrılıp çağrılmadığını anlamak için
-- ders adının başına `[TEST] - ` metni eklenmiştir.

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
    progress_percentage integer,
    success_rate numeric(5, 2)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        'test_status'::text AS status,
        weeks.week_no,
        weeks.lesson_id,
        '[TEST] - ' || weeks.lesson_name AS lesson_name, -- <<<<<<<<<<<<<<<<<<<< DIAGNOSTIC TEST
        p_grade_id AS grade_id,
        g.name AS grade_name,
        weeks.topic_title,
        50 AS progress_percentage, -- Sabit değerler
        50.00 AS success_rate      -- Sabit değerler

    FROM (
        SELECT DISTINCT
            qu.display_week AS week_no,
            u.lesson_id,
            l.name AS lesson_name,
            t.title AS topic_title,
            u.id AS unit_id
        FROM public.question_usages qu
        JOIN public.topics t ON qu.topic_id = t.id
        JOIN public.units u ON t.unit_id = u.id
        JOIN public.lessons l ON u.lesson_id = l.id
        JOIN public.unit_grades ug ON u.id = ug.unit_id
        WHERE ug.grade_id = p_grade_id AND qu.display_week IS NOT NULL
    ) AS weeks
    JOIN public.grades g ON p_grade_id = g.id
    WHERE
        weeks.week_no != p_exclude_week_no
        AND weeks.week_no < p_current_academic_week
    ORDER BY
        weeks.week_no ASC,
        weeks.lesson_id ASC;
END;
$$;
