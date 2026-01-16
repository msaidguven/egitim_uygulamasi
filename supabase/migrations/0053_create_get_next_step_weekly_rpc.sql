-- Migration: 0053_create_get_next_step_weekly_rpc.sql
-- Bu migration, YENİ `user_progress` tablo yapısına uygun olarak,
-- kullanıcının ana sayfasında gösterilecek "sıradaki adımı" bulan RPC'yi oluşturur.
-- DÜZELTME: `topic_title` alınırken yapılan hatalı JOIN düzeltildi. `tcw.topic_id` yerine `tc.topic_id` kullanıldı.

CREATE OR REPLACE FUNCTION public.get_next_step_for_user(
    p_user_id uuid,
    p_grade_id bigint
)
RETURNS TABLE (
    status text, -- 'in_progress' veya 'next'
    week_no integer,
    lesson_id bigint,
    lesson_name text,
    grade_id bigint,
    grade_name text,
    topic_title text
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- ÖNCELİK 1: Yarım kalmış bir hafta var mı?
    RETURN QUERY
    SELECT
        'in_progress'::text AS status,
        up.week_no,
        up.lesson_id,
        l.name AS lesson_name,
        up.grade_id,
        g.name AS grade_name,
        -- DÜZELTME: Doğru JOIN ile haftanın konusunu bul
        (SELECT t.title FROM topics t JOIN topic_contents tc ON t.id = tc.topic_id JOIN topic_content_weeks tcw ON tc.id = tcw.topic_content_id WHERE tcw.display_week = up.week_no LIMIT 1) AS topic_title
    FROM public.user_progress up
    JOIN public.lessons l ON up.lesson_id = l.id
    JOIN public.grades g ON up.grade_id = g.id
    WHERE
        up.user_id = p_user_id
        AND up.grade_id = p_grade_id
        AND up.completed = false
    ORDER BY up.week_no ASC
    LIMIT 1;

    IF FOUND THEN
        RETURN;
    END IF;

    -- ÖNCELİK 2: Sıradaki yeni hafta hangisi?
    RETURN QUERY
    SELECT
        'next'::text AS status,
        all_weeks.week_no,
        all_weeks.lesson_id,
        all_weeks.lesson_name,
        p_grade_id AS grade_id,
        g.name AS grade_name,
        -- DÜZELTME: Doğru JOIN ile haftanın konusunu bul
        (SELECT t.title FROM topics t JOIN topic_contents tc ON t.id = tc.topic_id JOIN topic_content_weeks tcw ON tc.id = tcw.topic_content_id WHERE tcw.display_week = all_weeks.week_no LIMIT 1) AS topic_title
    FROM (
        SELECT DISTINCT tcw.display_week as week_no, u.lesson_id, l.name as lesson_name
        FROM topic_content_weeks tcw
        JOIN topic_contents tc ON tcw.topic_content_id = tc.id
        JOIN topics t ON tc.topic_id = t.id
        JOIN units u ON t.unit_id = u.id
        JOIN lessons l ON u.lesson_id = l.id
        JOIN unit_grades ug ON u.id = ug.unit_id
        WHERE ug.grade_id = p_grade_id
    ) AS all_weeks
    LEFT JOIN public.user_progress up ON
        up.user_id = p_user_id
        AND up.lesson_id = all_weeks.lesson_id
        AND up.grade_id = p_grade_id
        AND up.week_no = all_weeks.week_no
    JOIN public.grades g ON p_grade_id = g.id
    WHERE up.id IS NULL
    ORDER BY all_weeks.week_no ASC, all_weeks.lesson_id ASC
    LIMIT 1;

END;
$$;
