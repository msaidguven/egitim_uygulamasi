CREATE OR REPLACE FUNCTION get_available_weeks(p_grade_id bigint, p_lesson_id bigint)
RETURNS TABLE(curriculum_week integer) AS $$
BEGIN
  RETURN QUERY
    SELECT DISTINCT
      q.curriculum_week
    FROM (
      SELECT
        generate_series(ow.start_week, ow.end_week)::integer AS curriculum_week
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
        AND ow.start_week IS NOT NULL
        AND ow.end_week IS NOT NULL

      UNION

      SELECT
        tcw.curriculum_week
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
        AND tcw.curriculum_week IS NOT NULL
    ) AS q
    ORDER BY q.curriculum_week;
END;
$$ LANGUAGE plpgsql;