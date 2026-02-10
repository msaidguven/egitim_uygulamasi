-- Add is_published to topic contents payload
DROP FUNCTION IF EXISTS get_weekly_curriculum(uuid, int, int, int);

CREATE OR REPLACE FUNCTION get_weekly_curriculum(
    p_user_id uuid,
    p_grade_id int,
    p_lesson_id int,
    p_curriculum_week int
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
) AS $$
DECLARE
    v_client_id uuid;
BEGIN
    -- Kullanıcının client_id'sini bul
    SELECT id INTO v_client_id FROM public.profiles WHERE id = p_user_id;

    RETURN QUERY
    SELECT
      o.id AS outcome_id,
      o.description AS outcome_description,
      u.id AS unit_id,
      u.title AS unit_title,
      t.id AS topic_id,
      t.title AS topic_title,
      -- Topic içerikleri sadece belirtilen curriculum_week için
      (SELECT COALESCE(
           jsonb_agg(
             jsonb_build_object(
               'id', tc.id,
               'topic_id', tc.topic_id,
               'title', tc.title,
               'content', tc.content,
               'order_no', tc.order_no,
               'is_published', tc.is_published
             )
             ORDER BY tc.order_no
           ),
           '[]'::jsonb
       )
       FROM topic_contents tc
       JOIN topic_content_weeks tcw
         ON tc.id = tcw.topic_content_id
       WHERE tc.topic_id = t.id
         AND tcw.curriculum_week = p_curriculum_week
      ) AS contents,
      -- Mini quiz soruları (1 ve 2 tipleri, rastgele 5 adet)
      (SELECT jsonb_agg(public.get_question_details(q.id, p_user_id))
       FROM (
           SELECT q_inner.id
           FROM questions q_inner
           JOIN question_usages qu
             ON q_inner.id = qu.question_id
           WHERE qu.curriculum_week = p_curriculum_week
             AND qu.topic_id = t.id
             AND q_inner.question_type_id IN (1,2)
           ORDER BY random()
           LIMIT 5
       ) q
      ) AS mini_quiz_questions,
      -- Unit'in son haftası kontrolü
      (ug.end_week = p_curriculum_week) AS is_last_week_of_unit,
      CASE
        WHEN (ug.end_week = p_curriculum_week) THEN public.get_unit_summary(p_user_id, u.id, v_client_id)
        ELSE NULL
      END AS unit_summary
    FROM outcomes o
    JOIN outcome_weeks ow ON o.id = ow.outcome_id
    JOIN topics t ON t.id = o.topic_id
    JOIN units u ON u.id = t.unit_id
    JOIN unit_grades ug ON ug.unit_id = u.id
       AND ug.grade_id = p_grade_id
    WHERE u.lesson_id = p_lesson_id
      AND p_curriculum_week BETWEEN ow.start_week AND ow.end_week
      AND u.is_active = true
      AND t.is_active = true
    ORDER BY o.order_index;
END;
$$ LANGUAGE plpgsql;
