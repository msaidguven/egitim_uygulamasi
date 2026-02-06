-- SRS: Kullanıcı için tekrar zamanı gelen / uygun soruların sayısını getirir
-- Mantık start_srs_test_session ile aynı olacak şekilde tasarlandı.

CREATE OR REPLACE FUNCTION public.get_srs_due_count(
    p_user_id UUID,
    p_unit_id BIGINT DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT COUNT(*)::INTEGER
    FROM (
        SELECT q.id
        FROM public.questions AS q
        JOIN public.question_usages AS qu ON q.id = qu.question_id
        JOIN public.topics AS t ON qu.topic_id = t.id
        WHERE t.is_active = true
          AND (p_unit_id IS NULL OR t.unit_id = p_unit_id)
          AND NOT EXISTS (
              SELECT 1 FROM public.user_question_stats uqs
              WHERE uqs.question_id = q.id
                AND uqs.user_id = p_user_id
                AND uqs.last_answer_correct = true
                AND uqs.next_review_at > NOW()
          )
        GROUP BY q.id
    ) AS sub;
$$;

GRANT EXECUTE ON FUNCTION public.get_srs_due_count(UUID, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_srs_due_count(UUID, BIGINT) TO anon;
