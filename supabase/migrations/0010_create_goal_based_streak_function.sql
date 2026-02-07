-- supabase/migrations/0010_create_goal_based_streak_function.sql

-- Hedef odaklı (40 soru) günlük seri hesaplama fonksiyonu
CREATE OR REPLACE FUNCTION public.get_user_daily_goal_stats(p_user_id uuid, p_goal int DEFAULT 40)
RETURNS json
LANGUAGE plpgsql
AS $$
DECLARE
    v_streak_count INT := 0;
    v_today_solved INT := 0;
    v_target_met_dates DATE[];
    v_current_date DATE := (NOW() AT TIME ZONE 'Europe/Istanbul')::DATE;
    v_last_active_date DATE;
    v_temp_date DATE;
    v_is_streak_broken BOOLEAN := FALSE;
BEGIN
    -- 1. Bugün çözülen toplam soru sayısını al
    SELECT COALESCE(total_questions, 0)
    INTO v_today_solved
    FROM public.user_time_based_stats
    WHERE user_id = p_user_id
      AND period_type = 'daily'
      AND period_date = v_current_date;

    -- 2. Hedefin tamamlandığı GÜNLERİ geçmişten bugüne getir (en yeniden en eskiye)
    SELECT array_agg(period_date ORDER BY period_date DESC)
    INTO v_target_met_dates
    FROM public.user_time_based_stats
    WHERE user_id = p_user_id
      AND period_type = 'daily'
      AND total_questions >= p_goal;

    -- 3. Seri hesaplama mantığı
    -- Eğer hiç hedef tamamlanmamışsa seri 0'dır
    IF v_target_met_dates IS NULL OR array_length(v_target_met_dates, 1) = 0 THEN
        v_streak_count := 0;
    ELSE
        -- Seri kontrolü: Ya bugün tamamlanmış olmalı ya da dün tamamlanmış olmalı
        -- (Bugün tamamlanmamışsa bile dünkü seri hala geçerlidir)
        
        v_last_active_date := v_target_met_dates[1];
        
        -- Eğer son tamamlanan tarih bugün veya dün değilse seri bozulmuştur
        IF v_last_active_date < v_current_date - INTERVAL '1 day' THEN
            v_streak_count := 0;
        ELSE
            -- Geriye doğru ardışık günleri say
            v_temp_date := v_last_active_date;
            v_streak_count := 1;
            
            FOR i IN 2..array_length(v_target_met_dates, 1) LOOP
                IF v_target_met_dates[i] = v_temp_date - INTERVAL '1 day' THEN
                    v_streak_count := v_streak_count + 1;
                    v_temp_date := v_target_met_dates[i];
                ELSE
                    EXIT; -- Ardışıklık bozuldu
                END IF;
            END LOOP;
        END IF;
    END IF;

    RETURN json_build_object(
        'current_streak', v_streak_count,
        'today_solved', v_today_solved,
        'daily_goal', p_goal
    );
END;
$$;
