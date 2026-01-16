-- Migration: 0076_remove_all_session_constraints.sql
-- Bu migration, test oturumları üzerindeki tüm katı ve hataya neden olan
-- benzersiz kısıtlama kurallarını (unique indexes) kalıcı olarak kaldırır.
-- Bu, test başlatma kontrolünü tamamen fonksiyonların içine taşımak için son adımdır.

BEGIN;

-- 1. Ünite bazlı kısıtlamayı kaldır.
DROP INDEX IF EXISTS public.idx_unique_active_session;

-- 2. Ders bazlı katı kısıtlamayı kaldır.
DROP INDEX IF EXISTS public.idx_unique_active_lesson_session;

-- 3. Misafir kullanıcılar için olan ünite bazlı katı kısıtlamayı kaldır.
DROP INDEX IF EXISTS public.idx_unique_active_session_client;

COMMIT;

COMMENT ON TABLE public.test_sessions IS 'Artık test oturumu benzersizliği, veritabanı kuralları yerine doğrudan start_test_v2 ve start_weekly_test_session fonksiyonları içindeki mantık tarafından yönetilmektedir.';
