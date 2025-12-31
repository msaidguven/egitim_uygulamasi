-- supabase/migrations/0006_setup_grades_rls.sql
--
-- Bu SQL kodunu Supabase projenizdeki SQL Editor'de çalıştırmanız gerekmektedir.
-- Bu işlem, 'grades' tablosu için Satır Seviyesi Güvenlik (RLS) politikalarını oluşturur.
-- Bu politikalar, sadece 'admin' rolüne sahip kullanıcıların 'grades' tablosunda
-- değişiklik yapmasına izin verirken, tüm kullanıcıların verileri okumasına olanak tanır.

-- 1. 'grades' tablosunda RLS'i etkinleştir.
-- Eğer zaten etkinse bu komut bir uyarı verecektir, görmezden gelebilirsiniz.
ALTER TABLE public.grades ENABLE ROW LEVEL SECURITY;

-- 2. Mevcut politikaları temizle (isteğe bağlı, temiz bir başlangıç için)
-- DİKKAT: Bu komut, 'grades' tablosundaki mevcut tüm RLS politikalarını silecektir.
-- Eğer özel politikalarınız varsa bu adımı atlayın.
DROP POLICY IF EXISTS "Allow public read access on grades" ON public.grades;
DROP POLICY IF EXISTS "Allow admins to update grades" ON public.grades;
DROP POLICY IF EXISTS "Allow admins to insert grades" ON public.grades;
DROP POLICY IF EXISTS "Allow admins to delete grades" ON public.grades;

-- 3. Herkesin sınıfları okumasına izin ver (SELECT)
-- Bu politika, uygulamanızdaki herkesin (giriş yapmış veya yapmamış)
-- sınıf listesini görmesine olanak tanır.
CREATE POLICY "Allow public read access on grades"
ON public.grades
FOR SELECT
TO public
USING (true);

-- 4. Yöneticilerin sınıfları güncellemesine izin ver (UPDATE)
-- Bu politika, 'profiles' tablosunda 'admin' rolüne sahip olan
-- kullanıcıların 'grades' tablosundaki kayıtları güncellemesini sağlar.
-- UI'da gördüğünüz hatanın ana çözümü budur.
CREATE POLICY "Allow admins to update grades"
ON public.grades
FOR UPDATE
TO authenticated
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin')
WITH CHECK ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- 5. Yöneticilerin yeni sınıf eklemesine izin ver (INSERT)
CREATE POLICY "Allow admins to insert grades"
ON public.grades
FOR INSERT
TO authenticated
WITH CHECK ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- 6. Yöneticilerin sınıf silmesine izin ver (DELETE)
CREATE POLICY "Allow admins to delete grades"
ON public.grades
FOR DELETE
TO authenticated
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- Sonrasında Supabase Studio'daki "RLS policies" bölümünden 'grades' tablosu
-- için bu politikaların doğru bir şekilde eklendiğini kontrol edebilirsiniz.
