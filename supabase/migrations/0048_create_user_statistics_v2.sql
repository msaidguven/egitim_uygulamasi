-- Migration: 0048_create_user_statistics_v2.sql
-- HATA DÜZELTME: Fonksiyon artık doğru tablo olan `test_session_answers`'a bakıyor.

CREATE OR REPLACE FUNCTION public.get_user_statistics_v2(p_user_id uuid, p_period text)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_date timestamptz;
    v_result jsonb;
BEGIN
    -- 1. Periyoda göre başlangıç tarihini belirle
    v_start_date :=
        CASE
            WHEN p_period = 'daily' THEN date_trunc('day', now())
            WHEN p_period = 'weekly' THEN date_trunc('week', now())
            WHEN p_period = 'monthly' THEN date_trunc('month', now())
            ELSE null
        END;

    -- 2. Tüm istatistikleri tek bir sorgu içinde, doğru tabloyu kullanarak hesapla
    WITH period_answers AS (
        -- DOĞRU TABLO: `test_session_answers`
        SELECT *
        FROM public.test_session_answers tsa
        WHERE tsa.user_id = p_user_id
          -- DOĞRU SÜTUN: `created_at`
          AND (v_start_date IS NULL OR tsa.created_at >= v_start_date)
    )
    SELECT jsonb_build_object(
        'general_stats', (
            SELECT jsonb_build_object(
                'total_questions', count(*)::int,
                'correct_answers', count(*) FILTER (WHERE pa.is_correct = true)::int,
                'incorrect_answers', count(*) FILTER (WHERE pa.is_correct = false)::int,
                'success_rate', CASE WHEN count(*) > 0 THEN ROUND((count(*) FILTER (WHERE pa.is_correct = true)::numeric / count(*) * 100), 1) ELSE 0 END
            )
            FROM period_answers pa
        ),
        'lesson_stats', COALESCE((
            SELECT jsonb_agg(l_stats)
            FROM (
                SELECT
                    l.id as lesson_id,
                    l.name as lesson_name,
                    count(*)::int AS total_questions,
                    count(*) FILTER (WHERE pa.is_correct = true)::int AS correct_answers,
                    count(*) FILTER (WHERE pa.is_correct = false)::int AS incorrect_answers,
                    ROUND(AVG(CASE WHEN pa.is_correct THEN 100 ELSE 0 END), 1) as success_rate
                FROM period_answers pa
                JOIN public.questions q ON pa.question_id = q.id
                JOIN public.question_usages qu ON q.id = qu.question_id
                JOIN public.topics t ON qu.topic_id = t.id
                JOIN public.units u ON t.unit_id = u.id
                JOIN public.lessons l ON u.lesson_id = l.id
                GROUP BY l.id, l.name
                ORDER BY l.name
            ) l_stats
        ), '[]'::jsonb),
        'weakest_topics', COALESCE((
            SELECT jsonb_agg(t_stats)
            FROM (
                SELECT
                    t.id as topic_id,
                    t.title as topic_name,
                    u.id as unit_id,
                    ROUND(AVG(CASE WHEN pa.is_correct THEN 100 ELSE 0 END), 1) as success_rate
                FROM period_answers pa
                JOIN public.questions q ON pa.question_id = q.id
                JOIN public.question_usages qu ON q.id = qu.question_id
                JOIN public.topics t ON qu.topic_id = t.id
                JOIN public.units u ON t.unit_id = u.id
                GROUP BY t.id, t.title, u.id
                HAVING count(*) >= 3
                ORDER BY success_rate ASC, count(*) DESC
                LIMIT 3
            ) t_stats
        ), '[]'::jsonb)
    )
    INTO v_result
    FROM (SELECT 1) AS placeholder;

    RETURN v_result;
END;
$$;
