-- Migration: 0056_create_get_all_next_steps_rpc.sql
-- Bu migration, kullanıcının ana sayfasında gösterilecek olan "tüm sıradaki adımları" bir liste halinde bulan RPC'yi oluşturur.
-- DÜZELTME: `topic_title` alınırken yapılan hatalı JOIN düzeltildi. `tcw.topic_id` yerine doğru tablo birleştirmesi kullanıldı.

-- Önceki tekil fonksiyonu sil (artık kullanılmayacak)
DROP FUNCTION IF EXISTS public.get_next_step_for_user(uuid, bigint);
DROP FUNCTION IF EXISTS public.get_all_next_steps_for_user(uuid, bigint);

-- Yeni liste döndüren fonksiyonu oluştur
CREATE OR REPLACE FUNCTION public.get_all_next_steps_for_user(
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
    -- Bir kullanıcının belirli bir sınıftaki tüm mevcut ders-hafta kombinasyonlarını ve ilerleme durumlarını birleştir.
    RETURN QUERY
    SELECT
        -- Durumu belirle: Eğer user_progress'te bir kayıt varsa ve tamamlanmamışsa 'in_progress', yoksa 'next'.
        CASE
            WHEN up.id IS NOT NULL THEN 'in_progress'::text
            ELSE 'next'::text
        END AS status,
        all_weeks.week_no,
        all_weeks.lesson_id,
        all_weeks.lesson_name,
        p_grade_id AS grade_id,
        g.name AS grade_name,
        -- DÜZELTME: Haftanın konusunu doğru JOIN'ler ile bul
        (
            SELECT t.title
            FROM topics t
            JOIN topic_contents tc ON t.id = tc.topic_id
            JOIN topic_content_weeks tcw ON tc.id = tcw.topic_content_id
            WHERE tcw.display_week = all_weeks.week_no
            LIMIT 1
        ) AS topic_title
    FROM (
        -- Bir sınıf için mevcut tüm ders-hafta kombinasyonlarını getir
        SELECT DISTINCT
            tcw.display_week AS week_no,
            u.lesson_id,
            l.name AS lesson_name
        FROM topic_content_weeks tcw
        JOIN topic_contents tc ON tcw.topic_content_id = tc.id
        JOIN topics t ON tc.topic_id = t.id
        JOIN units u ON t.unit_id = u.id
        JOIN lessons l ON u.lesson_id = l.id
        JOIN unit_grades ug ON u.id = ug.unit_id
        WHERE ug.grade_id = p_grade_id
    ) AS all_weeks
    -- Kullanıcının ilerleme durumuyla birleştir
    LEFT JOIN public.user_progress up ON
        up.user_id = p_user_id
        AND up.lesson_id = all_weeks.lesson_id
        AND up.grade_id = p_grade_id
        AND up.week_no = all_weeks.week_no
    JOIN public.grades g ON p_grade_id = g.id
    WHERE
        -- Sadece tamamlanmamış veya hiç başlanmamış haftaları göster
        up.completed IS DISTINCT FROM true
    ORDER BY
        -- Önce yarım kalanları (in_progress), sonra yenileri (next) sırala
        status ASC,
        -- Ardından hafta numarasına göre sırala
        all_weeks.week_no ASC,
        all_weeks.lesson_id ASC;

END;
$$;
