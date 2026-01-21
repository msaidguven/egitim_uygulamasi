-- Drop the old function if it exists
DROP FUNCTION IF EXISTS public.get_user_activity_and_streak_v2(p_user_id uuid);

-- Create the new, optimized and corrected function
CREATE OR REPLACE FUNCTION public.get_user_activity_and_streak_v2(p_user_id uuid)
RETURNS json
LANGUAGE plpgsql
AS $$
DECLARE
    current_streak INT := 0;
    activity_dates_from_summary DATE[];
    today_has_activity BOOLEAN := FALSE;
    all_activity_dates_raw DATE[];
    final_activity_dates DATE[];
    current_date DATE := (NOW() AT TIME ZONE 'Europe/Istanbul')::DATE;
BEGIN
    -- 1. Get historical activity dates from the summary table
    SELECT array_agg(period_date ORDER BY period_date)
    INTO activity_dates_from_summary
    FROM public.user_time_based_stats
    WHERE user_id = p_user_id
      AND period_type = 'daily'
      AND total_questions > 0;

    -- 2. Check for today's activity from user_question_stats (for real-time accuracy)
    SELECT EXISTS (
        SELECT 1
        FROM public.user_question_stats
        WHERE user_id = p_user_id
          AND (last_answer_at AT TIME ZONE 'Europe/Istanbul')::DATE = current_date
        LIMIT 1
    ) INTO today_has_activity;

    -- 3. Combine all activity dates, ensuring uniqueness
    all_activity_dates_raw := COALESCE(activity_dates_from_summary, ARRAY[]::DATE[]);

    IF today_has_activity AND NOT (current_date = ANY(all_activity_dates_raw)) THEN
        all_activity_dates_raw := array_append(all_activity_dates_raw, current_date);
    END IF;

    -- Ensure unique and sorted dates for the final output array
    SELECT array_agg(DISTINCT date_val ORDER BY date_val DESC)
    INTO final_activity_dates
    FROM unnest(all_activity_dates_raw) AS date_val;

    -- 4. Calculate the current streak (only if active today)
    IF today_has_activity THEN
        WITH consecutive_days AS (
            SELECT
                d.activity_date,
                d.activity_date - (ROW_NUMBER() OVER (ORDER BY d.activity_date ASC)) * INTERVAL '1 day' as grp
            FROM (
                SELECT unnest(final_activity_dates) as activity_date
            ) d
        )
        SELECT COUNT(*)
        INTO current_streak
        FROM consecutive_days
        WHERE grp = (SELECT grp FROM consecutive_days WHERE activity_date = current_date);
    ELSE
        -- If not active today, the current streak is 0.
        current_streak := 0;
    END IF;

    RETURN json_build_object(
        'current_streak', COALESCE(current_streak, 0),
        'activity_dates', COALESCE(final_activity_dates, ARRAY[]::DATE[])
    );
END;
$$;
