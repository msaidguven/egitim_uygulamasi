-- Migration: 0066_get_all_next_steps (FINAL, SIMPLIFIED)
-- Bu migration, `get_all_next_steps_for_user` fonksiyonunu,
-- sadece ve sadece "tamamlanmamış VE geçmişte kalmış" haftaları gösterecek şekilde basitleştirir.

DROP FUNCTION IF EXISTS public.get_all_next_steps_for_user(uuid, bigint, integer, integer);
CREATE OR REPLACE FUNCTION public.get_all_next_steps_for_user(
    p_user_id uuid,
    p_grade_id bigint,
    p_exclude_week_no integer, -- Bu parametre artık ana filtre için kullanılmayacak ama arayüzle uyumluluk için kalabilir.
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
AS $$
BEGIN
    RETURN QUERY
    SELECT
        'in_progress'::text AS status, -- Artık hepsi yarım kalmış sayılır.
        up.week_no,
        up.lesson_id,
        l.name AS lesson_name,
        up.grade_id,
        g.name AS grade_name,
        (
            SELECT t.title
            FROM topics t
            JOIN topic_contents tc ON t.id = tc.topic_id
            JOIN topic_content_weeks tcw ON tc.id = tcw.topic_content_id
            WHERE tcw.display_week = up.week_no AND (SELECT u.lesson_id FROM units u WHERE u.id = t.unit_id) = up.lesson_id
            LIMIT 1
        ) AS topic_title,
        up.progress_percentage,
        up.success_rate
    FROM public.user_progress up
    JOIN public.lessons l ON up.lesson_id = l.id
    JOIN public.grades g ON up.grade_id = g.id
    WHERE
        up.user_id = p_user_id
        AND up.grade_id = p_grade_id
        AND up.system_completed = false      -- Koşul 1: Tamamlanmamış olmalı
        AND up.week_no < p_current_academic_week; -- Koşul 2: Mevcut haftadan küçük olmalı
END;
$$;
