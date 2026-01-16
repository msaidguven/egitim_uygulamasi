-- Migration: 0046_create_finish_and_start_wrong_answers_rpc.sql
-- Bu fonksiyon, mevcut bir aktif oturum varsa onu sonlandırır ve ardından yanlış cevaplar için yeni bir oturum başlatır.
-- Bu, "duplicate key" hatasını önler ve kullanıcıya istisnai bir durum sunar.

CREATE OR REPLACE FUNCTION public.finish_and_start_wrong_answers_session(
    p_client_id uuid,
    p_unit_id bigint,
    p_user_id uuid
)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_active_session_id bigint;
    v_new_session_id int;
BEGIN
    -- 1. Kullanıcının bu ünite için aktif bir oturumu olup olmadığını kontrol et
    SELECT id INTO v_active_session_id
    FROM public.test_sessions
    WHERE
        unit_id = p_unit_id
        AND user_id = p_user_id
        AND completed_at IS NULL
    LIMIT 1;

    -- 2. Eğer aktif bir oturum varsa, onu sonlandır
    IF v_active_session_id IS NOT NULL THEN
        UPDATE public.test_sessions
        SET completed_at = now()
        WHERE id = v_active_session_id;
    END IF;

    -- 3. Şimdi, start_wrong_answers_session fonksiyonunu çağırarak yeni bir oturum başlat
    -- Bu fonksiyon artık çakışma olmadan çalışacaktır.
    SELECT public.start_wrong_answers_session(
        p_client_id := p_client_id,
        p_unit_id := p_unit_id,
        p_user_id := p_user_id
    ) INTO v_new_session_id;

    -- 4. Yeni oturumun ID'sini döndür
    RETURN v_new_session_id;
END;
$$;
