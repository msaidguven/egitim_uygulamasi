-- Migration: 0050_create_get_next_step_rpc.sql
-- Bu migration, kullanıcının ana sayfasında gösterilecek olan "sıradaki adımı" bulan akıllı RPC'yi oluşturur.

CREATE OR REPLACE FUNCTION public.get_next_step_for_user(
    p_user_id uuid,
    p_grade_id bigint,
    p_lesson_id bigint
)
RETURNS TABLE (
    status text, -- 'in_progress' (yarım kalmış) veya 'next' (sıradaki yeni)
    week_no integer,
    topic_id bigint,
    topic_title text,
    lesson_id bigint,
    lesson_name text,
    grade_id bigint,
    grade_name text
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_last_completed_week integer;
BEGIN
    -- ÖNCELİK 1: Yarım kalmış bir hafta var mı?
    -- user_progress'te 'completed = false' olan en düşük haftayı bul.
    RETURN QUERY
    SELECT
        'in_progress'::text AS status,
        ow.display_week AS week_no,
        t.id AS topic_id,
        t.title AS topic_title,
        l.id AS lesson_id,
        l.name AS lesson_name,
        g.id AS grade_id,
        g.name AS grade_name
    FROM public.user_progress up
    JOIN public.topics t ON up.topic_id = t.id
    JOIN public.units u ON t.unit_id = u.id
    JOIN public.lessons l ON u.lesson_id = l.id
    JOIN public.grades g ON u.grade_id = g.id
    -- Haftanın numarasını bulmak için topic_content_weeks'e join yapıyoruz.
    -- Bu, bir konunun birden fazla haftaya yayılma ihtimaline karşı en düşük haftayı alır.
    JOIN (
        SELECT topic_id, MIN(display_week) as display_week
        FROM public.topic_content_weeks
        GROUP BY topic_id
    ) ow ON t.id = ow.topic_id
    WHERE
        up.user_id = p_user_id
        AND up.completed = false
        AND u.lesson_id = p_lesson_id
        AND g.id = p_grade_id
    ORDER BY ow.display_week ASC
    LIMIT 1;

    -- Eğer yukarıdaki sorgu bir sonuç döndürdüyse, fonksiyon burada biter.
    IF FOUND THEN
        RETURN;
    END IF;

    -- ÖNCELİK 2: Sıradaki yeni hafta hangisi?
    -- Tamamlanmış en son haftayı bul.
    SELECT MAX(ow.display_week)
    INTO v_last_completed_week
    FROM public.user_progress up
    JOIN public.topics t ON up.topic_id = t.id
    JOIN public.units u ON t.unit_id = u.id
    JOIN (
        SELECT topic_id, MIN(display_week) as display_week
        FROM public.topic_content_weeks
        GROUP BY topic_id
    ) ow ON t.id = ow.topic_id
    WHERE
        up.user_id = p_user_id
        AND up.completed = true
        AND u.lesson_id = p_lesson_id
        AND u.grade_id = p_grade_id;

    -- Tamamlanmış en son haftadan sonraki ilk haftayı bul.
    RETURN QUERY
    SELECT
        'next'::text AS status,
        ow.display_week AS week_no,
        t.id AS topic_id,
        t.title AS topic_title,
        l.id AS lesson_id,
        l.name AS lesson_name,
        g.id AS grade_id,
        g.name AS grade_name
    FROM public.topic_content_weeks ow
    JOIN public.topics t ON ow.topic_id = t.id
    JOIN public.units u ON t.unit_id = u.id
    JOIN public.lessons l ON u.lesson_id = l.id
    JOIN public.grades g ON u.grade_id = g.id
    WHERE
        u.lesson_id = p_lesson_id
        AND g.id = p_grade_id
        AND ow.display_week > COALESCE(v_last_completed_week, 0)
    ORDER BY ow.display_week ASC
    LIMIT 1;

END;
$$;
