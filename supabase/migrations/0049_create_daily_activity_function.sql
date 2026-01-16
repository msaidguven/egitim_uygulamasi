-- Migration: 0049_create_daily_activity_function.sql
-- Kullanıcının son bir yıldaki günlük soru çözme aktivitesini döndürür.

CREATE OR REPLACE FUNCTION public.get_daily_activity(p_user_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
    SELECT jsonb_agg(daily_counts)
    FROM (
        SELECT
            date_trunc('day', tsa.created_at)::date AS date,
            count(*)::int AS count
        FROM
            public.test_session_answers tsa
        WHERE
            tsa.user_id = p_user_id
            AND tsa.created_at >= (now() - interval '1 year')
        GROUP BY
            1 -- group by "date"
        ORDER BY
            1 -- order by "date"
    ) AS daily_counts;
$$;
