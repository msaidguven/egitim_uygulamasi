CREATE OR REPLACE FUNCTION get_weekly_curriculum(
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
  contents jsonb
)
LANGUAGE sql
AS $$
SELECT
  o.id AS outcome_id,
  o.description AS outcome_description,
  u.id AS unit_id,
  u.title AS unit_title,
  t.id AS topic_id,
  t.title AS topic_title,
  (
    SELECT COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'id', tc.id,
          'topic_id', tc.topic_id,
          'title', tc.title,
          'content', tc.content,
          'order_no', tc.order_no
        )
        ORDER BY tc.order_no
      ),
      '[]'::jsonb
    )
    FROM topic_contents tc
    JOIN topic_content_weeks tcw
      ON tc.id = tcw.topic_content_id
    WHERE
      tc.topic_id = t.id
      AND tcw.display_week = p_week_no
  ) AS contents
FROM outcomes o
JOIN outcome_weeks ow
  ON o.id = ow.outcome_id
JOIN topics t
  ON t.id = o.topic_id
JOIN units u
  ON u.id = t.unit_id
JOIN unit_grades ug
  ON ug.unit_id = u.id
 AND ug.grade_id = p_grade_id
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
