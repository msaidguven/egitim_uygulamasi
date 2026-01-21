-- supabase/migrations/0004_get_weekly_dashboard_agenda.sql

-- Önceki hatalı versiyonu (eğer varsa) sil
DROP FUNCTION IF EXISTS get_weekly_dashboard_agenda(uuid, integer, integer);

-- Fonksiyonu doğru tiplerle ve doğru mantıkla yeniden oluştur
CREATE OR REPLACE FUNCTION get_weekly_dashboard_agenda(p_user_id uuid, p_grade_id int, p_curriculum_week int)
RETURNS TABLE (
    lesson_id bigint,
    lesson_name text,
    total_questions bigint,
    solved_questions bigint,
    correct_answers bigint,
    grade_id bigint,
    grade_name text,
    current_topic_title text,
    current_unit_id bigint,
    current_curriculum_week int
) AS $$
BEGIN
    RETURN QUERY
    WITH weekly_total_questions AS (
        -- Her ders için belirtilen HAFTAYA AİT toplam soru sayısını hesapla
        SELECT
            l.id AS lesson_id,
            sum(cwqc.total_questions)::bigint AS total_questions
        FROM lessons l
        JOIN units u ON l.id = u.lesson_id
        JOIN unit_grades ug ON u.id = ug.unit_id
        JOIN curriculum_week_question_counts cwqc ON u.id = cwqc.unit_id
        WHERE ug.grade_id = p_grade_id AND cwqc.curriculum_week = p_curriculum_week
        GROUP BY l.id
    ),
    weekly_user_stats AS (
        -- Kullanıcının belirtilen HAFTAYA AİT en son denemelerinin istatistiklerini topla
        SELECT
            u.lesson_id,
            sum(s.correct_count) AS correct_answers,
            sum(s.correct_count + s.wrong_count) AS solved_questions
        FROM (
            SELECT DISTINCT ON (user_id, unit_id, curriculum_week)
                unit_id,
                correct_count,
                wrong_count
            FROM user_curriculum_week_run_summary
            WHERE user_id = p_user_id AND curriculum_week = p_curriculum_week
            ORDER BY user_id, unit_id, curriculum_week, run_no DESC
        ) s
        JOIN units u ON s.unit_id = u.id
        GROUP BY u.lesson_id
    ),
    weekly_focus AS (
        -- Belirtilen hafta için her dersteki konuyu, doğru tablo ilişkilerini kullanarak bul
        SELECT DISTINCT ON (u.lesson_id)
            u.lesson_id,
            t.title AS topic_title,
            t.unit_id,
            tcw.curriculum_week
        FROM topic_content_weeks tcw
        JOIN topic_contents tc ON tcw.topic_content_id = tc.id
        JOIN topics t ON tc.topic_id = t.id
        JOIN units u ON t.unit_id = u.id
        JOIN unit_grades ug ON u.id = ug.unit_id
        WHERE tcw.curriculum_week = p_curriculum_week AND ug.grade_id = p_grade_id
    )
    -- Ana sorgu: Tüm verileri birleştir
    SELECT
        l.id AS lesson_id,
        l.name AS lesson_name,
        COALESCE(wtq.total_questions, 0) AS total_questions,
        COALESCE(wus.solved_questions, 0) AS solved_questions,
        COALESCE(wus.correct_answers, 0) AS correct_answers,
        g.id AS grade_id,
        g.name AS grade_name,
        wf.topic_title AS current_topic_title,
        wf.unit_id AS current_unit_id,
        wf.curriculum_week AS current_curriculum_week
    FROM lessons l
    -- Sadece belirtilen sınıfa ait dersleri almak için join yapısı
    INNER JOIN (
        SELECT DISTINCT u.lesson_id
        FROM units u
        JOIN unit_grades ug ON u.id = ug.unit_id
        WHERE ug.grade_id = p_grade_id
    ) AS lessons_for_grade ON l.id = lessons_for_grade.lesson_id
    JOIN grades g ON p_grade_id = g.id
    LEFT JOIN weekly_total_questions wtq ON l.id = wtq.lesson_id
    LEFT JOIN weekly_user_stats wus ON l.id = wus.lesson_id
    LEFT JOIN weekly_focus wf ON l.id = wf.lesson_id
    WHERE l.is_active = true -- Sadece aktif dersleri listele
    ORDER BY l.order_no;
END;
$$ LANGUAGE plpgsql;
