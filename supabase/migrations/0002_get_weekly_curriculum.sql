-- Migration: 0002_get_weekly_curriculum.sql
-- GÜNCELLEME: Fonksiyon, haftalık başarı oranını ve mini quiz sorularını,
-- sadece ve sadece `question_usages` tablosunda o haftaya (`display_week`) atanmış sorular üzerinden hesaplayacak şekilde yeniden düzenlendi.
-- Bu, hem başarı oranının doğru olmasını hem de mini quiz'in konuyla %100 alakalı olmasını sağlar.

DROP FUNCTION IF EXISTS get_weekly_curriculum(uuid, bigint, bigint, integer);

CREATE OR REPLACE FUNCTION get_weekly_curriculum(
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
  weekly_success_rate numeric,
  is_started boolean,
  mini_quiz_questions jsonb
)
LANGUAGE sql
AS $$
WITH weekly_topic AS (
  -- Önce bu haftanın hangi konuya ait olduğunu bulalım.
  SELECT t.id
  FROM outcomes o
  JOIN outcome_weeks ow ON o.id = ow.outcome_id
  JOIN topics t ON t.id = o.topic_id
  JOIN units u ON u.id = t.unit_id
  JOIN unit_grades ug ON ug.unit_id = u.id AND ug.grade_id = p_grade_id
  WHERE u.lesson_id = p_lesson_id AND p_week_no BETWEEN ow.start_week AND ow.end_week
  LIMIT 1
),
weekly_questions AS (
  -- TEMEL GERÇEK: Bu haftaya özel olarak atanmış tüm soruların ID'lerini al.
  SELECT qu.question_id
  FROM public.question_usages qu
  WHERE qu.topic_id = (SELECT id FROM weekly_topic) AND qu.display_week = p_week_no
),
user_weekly_stats AS (
  -- Haftalık başarıyı, sadece bu haftanın soruları üzerinden hesapla.
  SELECT
    count(DISTINCT uqs.question_id) as total_solved,
    count(DISTINCT uqs.question_id) FILTER (WHERE uqs.last_answer_correct = true) as total_correct
  FROM public.user_question_stats uqs
  WHERE uqs.user_id = p_user_id AND uqs.question_id IN (SELECT question_id FROM weekly_questions)
)
SELECT
  o.id AS outcome_id,
  o.description AS outcome_description,
  u.id AS unit_id,
  u.title AS unit_title,
  t.id AS topic_id,
  t.title AS topic_title,
  (
    SELECT COALESCE(jsonb_agg(tc.* ORDER BY tc.order_no), '[]'::jsonb)
    FROM topic_contents tc
    JOIN topic_content_weeks tcw ON tc.id = tcw.topic_content_id
    WHERE tc.topic_id = t.id AND tcw.display_week = p_week_no
  ) AS contents,
  -- Haftalık başarı oranı (doğru hesaplama)
  CASE
    WHEN (SELECT total_solved FROM user_weekly_stats) > 0
    THEN ROUND(((SELECT total_correct FROM user_weekly_stats)::numeric / (SELECT total_solved FROM user_weekly_stats) * 100), 1)
    ELSE 0
  END AS weekly_success_rate,
  -- Haftaya başlanıp başlanmadığı (doğru hesaplama)
  (SELECT total_solved FROM user_weekly_stats) > 0 AS is_started,
  -- Mini quiz soruları (doğru filtreleme)
  (
    SELECT jsonb_agg(public.get_question_details(q.id, p_user_id))
    FROM (
      SELECT id FROM public.questions q
      WHERE
        -- Sadece bu haftanın soruları arasından seç
        q.id IN (SELECT question_id FROM weekly_questions)
        AND q.question_type_id IN (1, 2) -- Sadece Çoktan Seçmeli ve Doğru/Yanlış
      ORDER BY random()
      LIMIT 5
    ) q
  ) AS mini_quiz_questions
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
$$;


CREATE OR REPLACE FUNCTION get_available_weeks(
  p_grade_id bigint,
  p_lesson_id bigint
)
RETURNS TABLE (
  week_no integer
)
LANGUAGE sql
AS $$
SELECT DISTINCT
  generate_series(ow.start_week, ow.end_week)::integer AS week_no
FROM outcome_weeks ow
JOIN outcomes o ON o.id = ow.outcome_id
JOIN topics t ON t.id = o.topic_id
JOIN units u ON u.id = t.unit_id
JOIN unit_grades ug ON ug.unit_id = u.id
WHERE
  ug.grade_id = p_grade_id
  AND u.lesson_id = p_lesson_id
  AND u.is_active = true
  AND t.is_active = true
UNION
SELECT DISTINCT
  tcw.display_week AS week_no
FROM topic_content_weeks tcw
JOIN topic_contents tc ON tc.id = tcw.topic_content_id
JOIN topics t ON t.id = tc.topic_id
JOIN units u ON u.id = t.unit_id
JOIN unit_grades ug ON ug.unit_id = u.id
WHERE
  ug.grade_id = p_grade_id
  AND u.lesson_id = p_lesson_id
  AND u.is_active = true
  AND t.is_active = true
ORDER BY week_no;
$$;
