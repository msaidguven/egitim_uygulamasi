-- Migration: 0062_update_all_readers_for_hybrid_progress.sql
-- GÜNCELLEME 4 (NİHAİ VE KESİN DÜZELTME): `get_current_week_agenda` fonksiyonu,
-- hem ilerleme hem de başarı oranını, tek ve doğru kaynak olan `user_weekly_question_progress`
-- ve `weekly_question_counts` tablolarını kullanarak hesaplayacak şekilde yeniden yazıldı.

-- 1. FONKSİYON: `get_weekly_curriculum` (OutcomesScreen için) - DEĞİŞTİRİLMEDİ
DROP FUNCTION IF EXISTS public.get_weekly_curriculum(uuid, bigint, bigint, integer);
CREATE OR REPLACE FUNCTION public.get_weekly_curriculum(
  p_user_id uuid,
  p_grade_id bigint,
  p_lesson_id bigint,
  p_week_no integer
)
RETURNS TABLE (
  outcome_id bigint,
  outcome_description text,
  unit_id bigint,
  unit_title text,
  topic_id bigint,
  topic_title text,
  contents jsonb,
  mini_quiz_questions jsonb,
  is_last_week_of_unit boolean,
  unit_summary jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_client_id uuid;
BEGIN
    SELECT id INTO v_client_id FROM public.profiles WHERE id = p_user_id;

    RETURN QUERY
    SELECT
      o.id AS outcome_id,
      o.description AS outcome_description,
      u.id AS unit_id,
      u.title AS unit_title,
      t.id AS topic_id,
      t.title AS topic_title,
      (SELECT COALESCE(jsonb_agg(tc.* ORDER BY tc.order_no), '[]'::jsonb) FROM topic_contents tc JOIN topic_content_weeks tcw ON tc.id = tcw.topic_content_id WHERE tc.topic_id = t.id AND tcw.display_week = p_week_no) AS contents,
      (SELECT jsonb_agg(public.get_question_details(q.id, p_user_id)) FROM (SELECT q_inner.id FROM questions q_inner JOIN question_usages qu ON q_inner.id = qu.question_id WHERE qu.display_week = p_week_no AND qu.topic_id = t.id AND q_inner.question_type_id IN (1, 2) ORDER BY random() LIMIT 5) q) AS mini_quiz_questions,
      (ug.end_week = p_week_no) AS is_last_week_of_unit,
      CASE
        WHEN (ug.end_week = p_week_no) THEN public.get_unit_summary(p_user_id, u.id, v_client_id)
        ELSE NULL
      END AS unit_summary
    FROM outcomes o
    JOIN outcome_weeks ow ON o.id = ow.outcome_id
    JOIN topics t ON t.id = o.topic_id
    JOIN units u ON u.id = t.unit_id
    JOIN unit_grades ug ON ug.unit_id = u.id AND ug.grade_id = p_grade_id
    WHERE
      u.lesson_id = p_lesson_id
      AND p_week_no BETWEEN ow.start_week AND ow.end_week
      AND u.is_active = true
      AND t.is_active = true
    ORDER BY o.order_index;
END;
$$;


-- 2. FONKSİYON: `get_current_week_agenda` (HomeScreen için) - YENİDEN YAZILDI
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
    progress_percentage integer,
    success_rate numeric(5, 2)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH
    -- 1. O hafta için kullanıcının gerçek, benzersiz ilerlemesini hesapla ("KARNE")
    user_progress_summary AS (
        SELECT
            uwqp.unit_id,
            count(*) AS solved_unique_count,
            count(*) FILTER (WHERE is_correct) AS correct_unique_count
        FROM public.user_weekly_question_progress uwqp
        WHERE uwqp.user_id = p_user_id AND uwqp.week_no = p_week_no
        GROUP BY uwqp.unit_id
    ),
    -- 2. O hafta için hangi dersin hangi konuyu/üniteyi işlediğini bul
    weekly_info AS (
        SELECT DISTINCT ON (u.lesson_id)
            u.lesson_id,
            t.title AS topic_title,
            u.id AS unit_id
        FROM public.question_usages qu
        JOIN public.topics t ON qu.topic_id = t.id
        JOIN public.units u ON t.unit_id = u.id
        JOIN public.unit_grades ug ON u.id = ug.unit_id
        WHERE ug.grade_id = p_grade_id AND qu.display_week = p_week_no
    )
    -- 3. Tüm verileri birleştir
    SELECT
        l.id AS lesson_id,
        l.name AS lesson_name,
        p_grade_id AS grade_id,
        g.name AS grade_name,
        p_week_no AS week_no,
        wi.topic_title,
        -- İlerleme Yüzdesi (Doğru Pay / Doğru Payda)
        CASE
            WHEN COALESCE(wqc.total_questions, 0) > 0 THEN
                (100 * COALESCE(ups.solved_unique_count, 0) / wqc.total_questions)::integer
            ELSE 0
        END AS progress_percentage,
        -- Başarı Oranı (Doğru Pay / Doğru Payda)
        CASE
            WHEN COALESCE(ups.solved_unique_count, 0) > 0 THEN
                (100.0 * ups.correct_unique_count / ups.solved_unique_count)::numeric(5, 2)
            ELSE 0.00
        END AS success_rate
    FROM public.lessons l
    JOIN public.lesson_grades lg ON l.id = lg.lesson_id
    JOIN public.grades g ON lg.grade_id = g.id
    LEFT JOIN weekly_info wi ON l.id = wi.lesson_id
    -- PAYDA: Toplam soru sayısını almak için
    LEFT JOIN public.weekly_question_counts wqc
        ON wi.unit_id = wqc.unit_id AND wqc.week_no = p_week_no
    -- PAY: Çözülen benzersiz soru ve doğru sayısını almak için
    LEFT JOIN user_progress_summary ups ON wi.unit_id = ups.unit_id
    WHERE
        lg.grade_id = p_grade_id AND l.is_active = true
    ORDER BY
        l.order_no;
END;
$$;


-- 3. FONKSİYON: `get_all_next_steps_for_user` (HomeScreen için) - DEĞİŞTİRİLMEDİ
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
    topic_title text
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
        (SELECT t.title FROM topics t JOIN topic_contents tc ON t.id = tc.topic_id JOIN topic_content_weeks tcw ON tc.id = tcw.topic_content_id WHERE tcw.display_week = all_weeks.week_no AND tc.topic_id = all_weeks.topic_id LIMIT 1) AS topic_title
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
