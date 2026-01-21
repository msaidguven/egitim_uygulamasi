-- Drop the old function if it exists
DROP FUNCTION IF EXISTS public.get_time_series_stats_v2(p_user_id uuid, p_days integer);

-- Create the new, optimized function using the summary table
CREATE OR REPLACE FUNCTION public.get_time_series_stats_v2(p_user_id uuid, p_days integer)
RETURNS TABLE(date date, total_questions bigint, correct_answers bigint, success_rate double precision)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH date_series AS (
        -- Create a series of dates for the specified period to ensure all days are represented
        SELECT generate_series(
            (NOW() AT TIME ZONE 'Europe/Istanbul')::DATE - (p_days - 1) * INTERVAL '1 day',
            (NOW() AT TIME ZONE 'Europe/Istanbul')::DATE,
            '1 day'::interval
        )::DATE as series_date
    ),
    daily_summary AS (
        -- Fetch pre-calculated daily stats from the summary table
        SELECT
            uts.period_date,
            uts.total_questions,
            uts.correct_answers
        FROM public.user_time_based_stats uts
        WHERE uts.user_id = p_user_id
          AND uts.period_type = 'daily'
          AND uts.period_date >= (NOW() AT TIME ZONE 'Europe/Istanbul')::DATE - (p_days - 1) * INTERVAL '1 day'
    )
    SELECT
        ds.series_date AS date,
        COALESCE(summary.total_questions, 0)::BIGINT AS total_questions,
        COALESCE(summary.correct_answers, 0)::BIGINT AS correct_answers,
        CASE
            WHEN COALESCE(summary.total_questions, 0) = 0 THEN 0.0
            ELSE (COALESCE(summary.correct_answers, 0) * 100.0 / summary.total_questions)
        END AS success_rate
    FROM date_series ds
    LEFT JOIN daily_summary summary ON ds.series_date = summary.period_date
    ORDER BY ds.series_date;
END;
$$;
