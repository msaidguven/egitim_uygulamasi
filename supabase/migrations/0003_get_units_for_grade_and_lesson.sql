CREATE OR REPLACE FUNCTION get_units_for_grade_and_lesson(
    p_grade_id BIGINT,
    p_lesson_id BIGINT
)
RETURNS SETOF units
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT u.*
    FROM units u
    JOIN unit_grades ug ON u.id = ug.unit_id
    WHERE ug.grade_id = p_grade_id
      AND u.lesson_id = p_lesson_id
      AND u.is_active = true
    ORDER BY u.order_no;
END;
$$;
