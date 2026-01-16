-- Migration: 0052_create_weekly_progress_functions.sql
-- Bu migration, YENİ `user_progress` tablo yapısına uygun olarak,
-- kullanıcının haftalık ilerlemesini yöneten RPC'leri oluşturur.

-- 1. Bir haftayı "başlandı" olarak işaretleyen fonksiyon
CREATE OR REPLACE FUNCTION public.mark_week_as_started(
    p_user_id uuid,
    p_lesson_id bigint,
    p_grade_id bigint,
    p_week_no integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Yeni `uq_user_weekly_progress` kısıtlamasını kullanarak, kayıt zaten varsa hiçbir şey yapma.
    INSERT INTO public.user_progress (user_id, lesson_id, grade_id, week_no, completed, progress_percentage, completed_at)
    VALUES (p_user_id, p_lesson_id, p_grade_id, p_week_no, false, 0, NULL)
    ON CONFLICT (user_id, lesson_id, grade_id, week_no) DO NOTHING;
END;
$$;


-- 2. Bir haftayı "tamamlandı" olarak işaretleyen fonksiyon
CREATE OR REPLACE FUNCTION public.mark_week_as_completed(
    p_user_id uuid,
    p_lesson_id bigint,
    p_grade_id bigint,
    p_week_no integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Mevcut kaydı `week_no`'ya göre güncelle.
    UPDATE public.user_progress
    SET
        completed = true,
        completed_at = now(),
        progress_percentage = 100
    WHERE
        user_id = p_user_id
        AND lesson_id = p_lesson_id
        AND grade_id = p_grade_id
        AND week_no = p_week_no;
END;
$$;
