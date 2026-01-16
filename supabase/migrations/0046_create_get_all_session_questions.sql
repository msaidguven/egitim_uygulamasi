-- Migration: 0046_create_get_all_session_questions.sql
-- Bir test oturumundaki tüm soruları ve detaylarını tek seferde getiren fonksiyon.
-- Bu, istemcinin soruları önceden yüklemesine (pre-fetching) olanak tanır.

CREATE OR REPLACE FUNCTION public.get_all_session_questions(p_session_id bigint)
RETURNS jsonb -- Bir JSON dizisi (liste) döndürür
LANGUAGE sql
STABLE
AS $$
    SELECT
        jsonb_agg(q_details.details)
    FROM (
        SELECT
            public.get_question_details(tsq.question_id) as details
        FROM
            public.test_session_questions tsq
        WHERE
            tsq.test_session_id = p_session_id
        ORDER BY
            tsq.order_no ASC
    ) as q_details;
$$;
