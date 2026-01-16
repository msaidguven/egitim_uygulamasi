-- Migration: 0063_add_rls_to_user_progress.sql
-- Bu migration, yeniden yapılandırılmış `user_progress` tablosu için Satır Seviyesi Güvenliği (RLS) politikalarını tanımlar.

-- 1. Adım: `user_progress` tablosu için RLS'i etkinleştir.
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;

-- 2. Adım: Mevcut politikaları temizle (güvenli bir başlangıç için).
DROP POLICY IF EXISTS "Kullanıcılar sadece kendi ilerlemelerini görebilir" ON public.user_progress;
DROP POLICY IF EXISTS "Kullanıcılar sadece kendi adlarına ilerleme ekleyebilir" ON public.user_progress;
DROP POLICY IF EXISTS "Kullanıcılar sadece kendi ilerlemelerini güncelleyebilir" ON public.user_progress;

-- 3. Adım: SELECT (Okuma) Politikası
CREATE POLICY "Kullanıcılar sadece kendi ilerlemelerini görebilir"
ON public.user_progress
FOR SELECT
USING (auth.uid() = user_id);

-- 4. Adım: INSERT (Ekleme) Politikası
CREATE POLICY "Kullanıcılar sadece kendi adlarına ilerleme ekleyebilir"
ON public.user_progress
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- 5. Adım: UPDATE (Güncelleme) Politikası
CREATE POLICY "Kullanıcılar sadece kendi ilerlemelerini güncelleyebilir"
ON public.user_progress
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- NOT: DELETE (Silme) politikası bilinçli olarak oluşturulmamıştır.
-- Kullanıcıların ilerleme verilerini doğrudan silmesi istenmeyen bir durumdur.
