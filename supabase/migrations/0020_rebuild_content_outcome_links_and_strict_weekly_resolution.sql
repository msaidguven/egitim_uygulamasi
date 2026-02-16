-- Rebuild content<->outcome links from current week ranges and
-- make weekly curriculum resolution prefer canonical links.

-- 1) One-shot full rebuild utility (safe to keep for future maintenance)
CREATE OR REPLACE FUNCTION public.refresh_all_topic_content_outcomes()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM public.topic_content_outcomes;

  INSERT INTO public.topic_content_outcomes (topic_content_id, outcome_id)
  SELECT DISTINCT
    tc.id,
    o.id
  FROM public.topic_contents tc
  JOIN public.topic_content_weeks tcw
    ON tcw.topic_content_id = tc.id
  JOIN public.outcomes o
    ON o.topic_id = tc.topic_id
  JOIN public.outcome_weeks ow
    ON ow.outcome_id = o.id
   AND tcw.curriculum_week BETWEEN ow.start_week AND ow.end_week
  ON CONFLICT DO NOTHING;
END;
$$;

-- 2) Rebuild now to clean legacy inconsistencies
SELECT public.refresh_all_topic_content_outcomes();

-- 3) Tighten weekly content resolution
-- Rule:
--   - If canonical mapping exists for a content, use only mapped outcomes.
--   - Fallback to week-based tcw only for unmapped legacy content.
CREATE OR REPLACE FUNCTION public.get_weekly_curriculum(
    p_user_id uuid,
    p_grade_id int,
    p_lesson_id int,
    p_curriculum_week int,
    p_is_admin boolean
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
    IF p_user_id IS NOT NULL THEN
      SELECT id INTO v_client_id
      FROM public.profiles
      WHERE id = p_user_id;
    END IF;

    RETURN QUERY
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
              'order_no', tc.order_no,
              'is_published', tc.is_published
            )
            ORDER BY tc.order_no
          ),
          '[]'::jsonb
        )
        FROM public.topic_contents tc
        LEFT JOIN public.topic_content_outcomes tco
          ON tco.topic_content_id = tc.id
         AND tco.outcome_id = o.id
        LEFT JOIN public.topic_content_weeks tcw
          ON tcw.topic_content_id = tc.id
         AND tcw.curriculum_week = p_curriculum_week
        WHERE tc.topic_id = t.id
          AND (p_is_admin OR tc.is_published = true)
          AND (
            tco.outcome_id IS NOT NULL
            OR (
              tcw.topic_content_id IS NOT NULL
              AND NOT EXISTS (
                SELECT 1
                FROM public.topic_content_outcomes tco_any
                WHERE tco_any.topic_content_id = tc.id
              )
            )
          )
      ) AS contents,
      (
        SELECT jsonb_agg(public.get_question_details(q.id, p_user_id))
        FROM (
          SELECT q_inner.id
          FROM public.questions q_inner
          JOIN public.question_usages qu
            ON q_inner.id = qu.question_id
          WHERE qu.curriculum_week = p_curriculum_week
            AND qu.topic_id = t.id
            AND q_inner.question_type_id IN (1, 2)
          ORDER BY random()
          LIMIT 5
        ) q
      ) AS mini_quiz_questions,
      (ug.end_week = p_curriculum_week) AS is_last_week_of_unit,
      CASE
        WHEN (ug.end_week = p_curriculum_week)
          THEN public.get_unit_summary(p_user_id, u.id, v_client_id)
        ELSE NULL
      END AS unit_summary
    FROM public.outcomes o
    JOIN public.topics t ON t.id = o.topic_id
    JOIN public.units u ON u.id = t.unit_id
    JOIN public.unit_grades ug ON ug.unit_id = u.id
      AND ug.grade_id = p_grade_id
    WHERE u.lesson_id = p_lesson_id
      AND u.is_active = true
      AND t.is_active = true
      AND EXISTS (
        SELECT 1
        FROM public.outcome_weeks ow
        WHERE ow.outcome_id = o.id
          AND p_curriculum_week BETWEEN ow.start_week AND ow.end_week
      )
    ORDER BY o.order_index;
END;
$$ LANGUAGE plpgsql;
