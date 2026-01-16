CREATE OR REPLACE FUNCTION get_test_session_questions(p_session_id bigint)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    result jsonb;
BEGIN
    SELECT
        -- DOĞRU YÖNTEM: Sıralamayı, alt sorgudan gelen "order_no" sütununa göre yap.
        jsonb_agg(qwd.question_data ORDER BY qwd.order_no)
    INTO
        result
    FROM (
        SELECT
            tsq.order_no, -- Dış sorgunun görebilmesi için order_no'yu burada bir sütun olarak seç.
            (
                jsonb_build_object(
                    'id', q.id,
                    'topic_id', qu.topic_id,
                    'question_text', q.question_text,
                    'question_type_id', q.question_type_id,
                    'difficulty', q.difficulty,
                    'score', q.score
                ) ||
                CASE (SELECT code FROM public.question_types WHERE id = q.question_type_id)
                    WHEN 'choices' THEN
                        jsonb_build_object('choices', (
                            SELECT jsonb_agg(c ORDER BY c.id)
                            FROM (
                                SELECT qc.id, qc.choice_text, qc.is_correct
                                FROM public.question_choices qc
                                WHERE qc.question_id = q.id
                            ) c
                        ))
                    WHEN 'matching' THEN
                        jsonb_build_object('matching_options', (
                            SELECT jsonb_agg(p ORDER BY p.order_no)
                            FROM (
                                SELECT qmp.id, qmp.left_text, qmp.right_text, qmp.order_no
                                FROM public.question_matching_pairs qmp
                                WHERE qmp.question_id = q.id
                            ) p
                        ))
                    WHEN 'blank' THEN
                        jsonb_build_object('blanks', (
                            SELECT jsonb_agg(b ORDER BY b.order_no)
                            FROM (
                                SELECT qbo.id, qbo.option_text, qbo.is_correct, qbo.order_no
                                FROM public.question_blank_options qbo
                                WHERE qbo.question_id = q.id
                            ) b
                        ))
                    ELSE
                        '{}'::jsonb
                END
            ) AS question_data
        FROM
            public.test_session_questions tsq
        JOIN
            public.questions q ON tsq.question_id = q.id
        JOIN
            public.question_usages qu ON q.id = qu.question_id
        WHERE
            tsq.test_session_id = p_session_id
            AND qu.usage_type = 'weekly'
    ) AS qwd; -- Alt sorguya bir takma ad ver.

    RETURN COALESCE(result, '[]'::jsonb);
END;
$$;