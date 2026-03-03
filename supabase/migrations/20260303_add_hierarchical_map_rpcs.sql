-- supabase/migrations/20260303_add_hierarchical_map_rpcs.sql

DROP FUNCTION IF EXISTS get_subject_unit_map_data(uuid, bigint, bigint, int, bigint);

CREATE OR REPLACE FUNCTION get_subject_unit_map_data(
  p_user_id uuid,
  p_lesson_id bigint,
  p_grade_id bigint,
  p_current_week int DEFAULT NULL,
  p_unit_id bigint DEFAULT NULL
)
RETURNS TABLE (
  unit_id bigint,
  unit_title text,
  order_no integer,
  start_week integer,
  end_week integer,
  total_questions bigint,
  solved_questions bigint,
  topics_total integer,
  topics_completed integer,
  is_current_week boolean,
  is_completed boolean
) AS $$
BEGIN
  RETURN QUERY
  WITH unit_base AS (
    SELECT
      u.id AS uid,
      u.title AS utitle,
      u.order_no AS uorder,
      u.start_week AS s_week,
      u.end_week AS e_week,
      COALESCE(u.question_count, 0)::bigint AS total_q
    FROM public.units u
    WHERE u.lesson_id = p_lesson_id
      AND u.grade_id = p_grade_id
      AND u.is_active = true
      AND (p_unit_id IS NULL OR u.id = p_unit_id)
  ),
  topic_base AS (
    SELECT
      t.id AS tid,
      t.unit_id AS uid
    FROM public.topics t
    JOIN unit_base ub ON ub.uid = t.unit_id
    WHERE t.is_active = true
  ),
  topic_question_totals AS (
    SELECT
      tb.tid,
      COUNT(DISTINCT qu.question_id)::int AS total_q
    FROM topic_base tb
    LEFT JOIN public.question_usages qu ON qu.topic_id = tb.tid
    GROUP BY tb.tid
  ),
  topic_question_solved AS (
    SELECT
      tb.tid,
      COUNT(DISTINCT qu.question_id)::int AS solved_q
    FROM topic_base tb
    LEFT JOIN public.question_usages qu ON qu.topic_id = tb.tid
    LEFT JOIN public.user_question_stats uqs
      ON uqs.question_id = qu.question_id
     AND uqs.user_id = p_user_id
    WHERE uqs.total_attempts > 0
    GROUP BY tb.tid
  ),
  topic_progress AS (
    SELECT
      tb.uid,
      tb.tid,
      COALESCE(tqt.total_q, 0) AS total_q,
      COALESCE(tqs.solved_q, 0) AS solved_q,
      (COALESCE(tqt.total_q, 0) > 0 AND COALESCE(tqs.solved_q, 0) >= COALESCE(tqt.total_q, 0)) AS is_completed
    FROM topic_base tb
    LEFT JOIN topic_question_totals tqt ON tqt.tid = tb.tid
    LEFT JOIN topic_question_solved tqs ON tqs.tid = tb.tid
  ),
  unit_topic_stats AS (
    SELECT
      tp.uid,
      COUNT(tp.tid)::int AS total_topics,
      COUNT(tp.tid) FILTER (WHERE tp.is_completed)::int AS completed_topics
    FROM topic_progress tp
    GROUP BY tp.uid
  ),
  user_unit_stats AS (
    SELECT
      uus.unit_id AS uid,
      COALESCE(uus.solved_question_count, 0)::bigint AS solved_q
    FROM public.user_unit_summary uus
    WHERE uus.user_id = p_user_id
  )
  SELECT
    ub.uid AS unit_id,
    ub.utitle AS unit_title,
    ub.uorder AS order_no,
    ub.s_week AS start_week,
    ub.e_week AS end_week,
    ub.total_q AS total_questions,
    COALESCE(uus.solved_q, 0) AS solved_questions,
    COALESCE(uts.total_topics, 0) AS topics_total,
    COALESCE(uts.completed_topics, 0) AS topics_completed,
    (
      p_current_week IS NOT NULL
      AND ub.s_week IS NOT NULL
      AND ub.e_week IS NOT NULL
      AND p_current_week BETWEEN ub.s_week AND ub.e_week
    ) AS is_current_week,
    (
      COALESCE(uts.total_topics, 0) > 0
      AND COALESCE(uts.completed_topics, 0) = COALESCE(uts.total_topics, 0)
    ) AS is_completed
  FROM unit_base ub
  LEFT JOIN user_unit_stats uus ON uus.uid = ub.uid
  LEFT JOIN unit_topic_stats uts ON uts.uid = ub.uid
  ORDER BY ub.uorder;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION get_subject_unit_map_data(uuid, bigint, bigint, int, bigint) TO authenticated;


DROP FUNCTION IF EXISTS get_unit_timeline_topic_data(uuid, bigint, int, bigint);

CREATE OR REPLACE FUNCTION get_unit_timeline_topic_data(
  p_user_id uuid,
  p_unit_id bigint,
  p_current_week int DEFAULT NULL,
  p_topic_id bigint DEFAULT NULL
)
RETURNS TABLE (
  topic_id bigint,
  topic_title text,
  unit_id bigint,
  week_index integer,
  gain_order integer,
  total_questions bigint,
  solved_questions bigint,
  is_completed boolean,
  is_in_progress boolean,
  is_locked boolean
) AS $$
BEGIN
  RETURN QUERY
  WITH topic_base AS (
    SELECT
      t.id AS tid,
      t.title AS ttitle,
      t.unit_id AS uid,
      t.order_no AS torder
    FROM public.topics t
    WHERE t.unit_id = p_unit_id
      AND t.is_active = true
      AND (p_topic_id IS NULL OR t.id = p_topic_id)
  ),
  topic_week_content AS (
    SELECT
      tb.tid,
      MIN(tcw.curriculum_week)::int AS min_week
    FROM topic_base tb
    LEFT JOIN public.topic_contents tc ON tc.topic_id = tb.tid
    LEFT JOIN public.topic_content_weeks tcw ON tcw.topic_content_id = tc.id
    GROUP BY tb.tid
  ),
  topic_week_usage AS (
    SELECT
      tb.tid,
      MIN(qu.curriculum_week)::int AS min_week
    FROM topic_base tb
    LEFT JOIN public.question_usages qu ON qu.topic_id = tb.tid
    GROUP BY tb.tid
  ),
  topic_weeks AS (
    SELECT
      tb.tid,
      COALESCE(twc.min_week, twu.min_week, u.start_week, 0)::int AS w_index
    FROM topic_base tb
    JOIN public.units u ON u.id = tb.uid
    LEFT JOIN topic_week_content twc ON twc.tid = tb.tid
    LEFT JOIN topic_week_usage twu ON twu.tid = tb.tid
  ),
  topic_question_totals AS (
    SELECT
      tb.tid,
      COUNT(DISTINCT qu.question_id)::bigint AS total_q
    FROM topic_base tb
    LEFT JOIN public.question_usages qu ON qu.topic_id = tb.tid
    GROUP BY tb.tid
  ),
  topic_question_solved AS (
    SELECT
      tb.tid,
      COUNT(DISTINCT qu.question_id)::bigint AS solved_q
    FROM topic_base tb
    LEFT JOIN public.question_usages qu ON qu.topic_id = tb.tid
    LEFT JOIN public.user_question_stats uqs
      ON uqs.question_id = qu.question_id
     AND uqs.user_id = p_user_id
    WHERE uqs.total_attempts > 0
    GROUP BY tb.tid
  )
  SELECT
    tb.tid AS topic_id,
    tb.ttitle AS topic_title,
    tb.uid AS unit_id,
    COALESCE(tw.w_index, 0)::int AS week_index,
    tb.torder AS gain_order,
    COALESCE(tqt.total_q, 0) AS total_questions,
    COALESCE(tqs.solved_q, 0) AS solved_questions,
    (COALESCE(tqt.total_q, 0) > 0 AND COALESCE(tqs.solved_q, 0) >= COALESCE(tqt.total_q, 0)) AS is_completed,
    (COALESCE(tqs.solved_q, 0) > 0 AND COALESCE(tqs.solved_q, 0) < COALESCE(tqt.total_q, 0)) AS is_in_progress,
    (p_current_week IS NOT NULL AND COALESCE(tw.w_index, 0) > p_current_week) AS is_locked
  FROM topic_base tb
  LEFT JOIN topic_weeks tw ON tw.tid = tb.tid
  LEFT JOIN topic_question_totals tqt ON tqt.tid = tb.tid
  LEFT JOIN topic_question_solved tqs ON tqs.tid = tb.tid
  ORDER BY COALESCE(tw.w_index, 0), tb.torder;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION get_unit_timeline_topic_data(uuid, bigint, int, bigint) TO authenticated;
