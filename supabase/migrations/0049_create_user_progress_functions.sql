-- Migration: 0049_create_user_progress_functions.sql
-- Bu migration, kullanıcının haftalık ilerlemesini yönetmek için gerekli olan RPC'leri oluşturur.
-- Bu fonksiyonlar, `user_progress` tablosunun kısıtlamalarıyla (constraints) uyumlu çalışacak şekilde tasarlanmıştır.

-- 1. Bir haftayı "başlandı" olarak işaretleyen fonksiyon
-- Kullanıcı bir haftanın içeriğini ilk kez görüntülediğinde çağrılır.
CREATE OR REPLACE FUNCTION public.mark_week_as_started(
    p_user_id uuid,
    p_topic_id bigint
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- `uq_user_topic` unique kısıtlamasını kullanarak, eğer kayıt zaten varsa hiçbir şey yapma.
    -- Eğer kayıt yoksa, yeni bir kayıt ekle.
    -- `completed = false` ve `progress_percentage = 0` değerleri, tablodaki kısıtlamalarla uyumludur.
    INSERT INTO public.user_progress (user_id, topic_id, completed, progress_percentage, completed_at)
    VALUES (p_user_id, p_topic_id, false, 0, NULL)
    ON CONFLICT (user_id, topic_id) DO NOTHING;
END;
$$;


-- 2. Bir haftayı "tamamlandı" olarak işaretleyen fonksiyon
-- Kullanıcı "Bu Haftayı Tamamladım" butonuna bastığında çağrılır.
CREATE OR REPLACE FUNCTION public.mark_week_as_completed(
    p_user_id uuid,
    p_topic_id bigint
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Mevcut kaydı güncelle.
    -- `completed = true`, `completed_at = now()`, `progress_percentage = 100` değerleri,
    -- tablodaki `user_progress_completed_check` ve `chk_progress_completed` kısıtlamalarını karşılar.
    UPDATE public.user_progress
    SET
        completed = true,
        completed_at = now(),
        progress_percentage = 100
    WHERE
        user_id = p_user_id AND topic_id = p_topic_id;
END;
$$;
