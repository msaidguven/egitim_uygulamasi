-- Bu script, test ve cevap tabloları için RLS (Satır Seviyesi Güvenlik) politikalarını uygular.
-- Daha önceki bir migration'da bu adımlar atlanmış veya eksik kalmış olabilir.
-- Bu script, politikaların mevcut olup olmadığını kontrol ederek idempotent (tekrar çalıştırılabilir) olacak şekilde yazılmıştır.

-- Adım 1: Tablolarda RLS'yi etkinleştir (zaten etkinse bir şey yapmaz)
ALTER TABLE public.test_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_answers ENABLE ROW LEVEL SECURITY;

----------------------------------------
-- test_sessions İÇİN POLİTİKALAR
----------------------------------------

-- Mevcut politikaları temizle (varsa)
DROP POLICY IF EXISTS "Allow users to read their own test sessions" ON public.test_sessions;
DROP POLICY IF EXISTS "Allow users to create their own test sessions" ON public.test_sessions;
DROP POLICY IF EXISTS "Allow users to update their own test sessions" ON public.test_sessions;
DROP POLICY IF EXISTS "Allow users to delete their own test sessions" ON public.test_sessions;

-- Politika 1 (SELECT): Kullanıcılar sadece kendi test oturumlarını görebilir.
CREATE POLICY "Allow users to read their own test sessions"
ON public.test_sessions
FOR SELECT
USING (auth.uid() = user_id);

-- Politika 2 (INSERT): Kullanıcılar sadece kendileri için yeni bir test oturumu oluşturabilir.
CREATE POLICY "Allow users to create their own test sessions"
ON public.test_sessions
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Politika 3 (UPDATE): Kullanıcılar sadece kendi test oturumlarını güncelleyebilir.
CREATE POLICY "Allow users to update their own test sessions"
ON public.test_sessions
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Politika 4 (DELETE): Kullanıcılar sadece kendi test oturumlarını silebilir.
CREATE POLICY "Allow users to delete their own test sessions"
ON public.test_sessions
FOR DELETE
USING (auth.uid() = user_id);


----------------------------------------
-- user_answers İÇİN POLİTİKALAR
----------------------------------------

-- Mevcut politikaları temizle (varsa)
DROP POLICY IF EXISTS "Allow users to read their own answers" ON public.user_answers;
DROP POLICY IF EXISTS "Allow users to insert their own answers" ON public.user_answers;

-- Politika 1 (SELECT): Kullanıcılar sadece kendi verdikleri cevapları görebilir.
CREATE POLICY "Allow users to read their own answers"
ON public.user_answers
FOR SELECT
USING (auth.uid() = user_id);

-- Politika 2 (INSERT): Kullanıcılar sadece kendileri için yeni cevaplar ekleyebilir.
CREATE POLICY "Allow users to insert their own answers"
ON public.user_answers
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- NOT: user_answers için UPDATE ve DELETE politikaları, veri bütünlüğünü korumak amacıyla
-- bilinçli olarak eklenmemiştir. Bir cevap verildikten sonra değiştirilmemelidir.

-- Mesaj: Politikalar başarıyla uygulandı.
SELECT 'RLS policies for test_sessions and user_answers have been successfully applied.';
