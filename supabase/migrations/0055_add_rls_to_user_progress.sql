-- Migration: 0055_add_rls_to_user_progress.sql
-- Bu migration, `user_progress` tablosu için Satır Seviyesi Güvenliği (RLS) politikalarını tanımlar.
-- Amaç: Kullanıcıların sadece kendi ilerleme verilerine erişebilmesini ve onları değiştirebilmesini sağlamak.

-- 1. Adım: `user_progress` tablosu için RLS'i etkinleştir.
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;

-- 2. Adım: Mevcut politikaları temizle (güvenli bir başlangıç için).
DROP POLICY IF EXISTS "Kullanıcılar sadece kendi ilerlemelerini görebilir" ON public.user_progress;
DROP POLICY IF EXISTS "Kullanıcılar sadece kendi adlarına ilerleme ekleyebilir" ON public.user_progress;
DROP POLICY IF EXISTS "Kullanıcılar sadece kendi ilerlemelerini güncelleyebilir" ON public.user_progress;

-- 3. Adım: SELECT (Okuma) Politikası
-- Kullanıcıların sadece kendi `user_id`'lerine sahip kayıtları okumasına izin ver.
CREATE POLICY "Kullanıcılar sadece kendi ilerlemelerini görebilir"
ON public.user_progress
FOR SELECT
USING (auth.uid() = user_id);

-- 4. Adım: INSERT (Ekleme) Politikası
-- Kullanıcıların sadece kendi `user_id`'lerini kullanarak yeni kayıt eklemesine izin ver.
CREATE POLICY "Kullanıcılar sadece kendi adlarına ilerleme ekleyebilir"
ON public.user_progress
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- 5. Adım: UPDATE (Güncelleme) Politikası
-- Kullanıcıların sadece kendi `user_id`'lerine sahip kayıtları güncellemesine izin ver.
CREATE POLICY "Kullanıcılar sadece kendi ilerlemelerini güncelleyebilir"
ON public.user_progress
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- NOT: DELETE (Silme) politikası bilinçli olarak oluşturulmamıştır.
-- Kullanıcıların ilerleme verilerini doğrudan silmesi istenmeyen bir durumdur.
-- Bu işlem, gerekirse sadece admin yetkileriyle veya özel bir RPC ile yapılmalıdır.
