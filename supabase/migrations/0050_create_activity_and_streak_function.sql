-- Migration: 0050_create_activity_and_streak_function.sql
-- Kullanıcının hem günlük aktivite takvimini hem de mevcut serisini (streak) hesaplar.

CREATE OR REPLACE FUNCTION public.get_user_activity_and_streak(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_activity_data jsonb;
    v_current_streak int;
BEGIN
    -- 1. Takvim için son 1 yıldaki aktif günleri al
    SELECT jsonb_agg(daily.activity_date)
    INTO v_activity_data
    FROM (
        SELECT DISTINCT date_trunc('day', tsa.created_at)::date AS activity_date
        FROM public.test_session_answers tsa
        WHERE tsa.user_id = p_user_id
          AND tsa.created_at >= (now() - interval '1 year')
        ORDER BY activity_date
    ) daily;

    -- 2. Mevcut seriyi (streak) hesapla
    WITH dates AS (
        -- Kullanıcının tüm aktif olduğu günleri (tekilleştirilmiş) al
        SELECT DISTINCT created_at::date AS d
        FROM test_session_answers
        WHERE user_id = p_user_id
    ),
    groups AS (
        -- Her günü, bir önceki günden 1 günden fazla fark varsa yeni bir gruba ata
        SELECT
            d,
            (d - (row_number() OVER (ORDER BY d))::int * '1 day'::interval) AS group_date
        FROM dates
    )
    SELECT
        count(*)
    INTO v_current_streak
    FROM groups
    -- Sadece en son gruba odaklan
    WHERE group_date = (SELECT group_date FROM groups ORDER BY d DESC LIMIT 1)
      -- Ve bu grubun son gününün bugün veya dün olduğundan emin ol (seri güncel mi?)
      AND (SELECT d FROM groups ORDER BY d DESC LIMIT 1) >= (now()::date - '1 day'::interval);

    -- 3. Tüm sonuçları tek bir JSON'da birleştir
    RETURN jsonb_build_object(
        'activity_dates', COALESCE(v_activity_data, '[]'::jsonb),
        'current_streak', COALESCE(v_current_streak, 0)
    );
END;
$$;
