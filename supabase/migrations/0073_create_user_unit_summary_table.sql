-- Migration: 0073_create_user_unit_summary_table.sql
-- GÜNCELLEME 2: Tabloyu yeniden oluşturmak yerine, mevcut tabloya yeni kolon ekleyecek
-- ve RLS politikalarını güvenli bir şekilde oluşturacak şekilde düzeltildi.

-- 1. MEVCUT TABLOYU GÜNCELLEME
-- "Kitap Ayracı" sistemini desteklemek için yeni kolonu ekle.
-- `IF NOT EXISTS` ifadesi, bu script'in tekrar çalıştırıldığında hata vermesini engeller.
ALTER TABLE public.user_unit_summary
ADD COLUMN IF NOT EXISTS solved_question_count integer NOT NULL DEFAULT 0;

-- Kolon hakkında yorum ekleyelim.
COMMENT ON COLUMN public.user_unit_summary.solved_question_count IS 'Kullanıcının bu ünitede o ana kadar çözdüğü toplam soru sayısı (kaldığı yeri belirtir).';


-- 2. RLS (ROW-LEVEL SECURITY) AYARLARINI GÜVENLİ BİR ŞEKİLDE OLUŞTURMA

-- Tablo için RLS'yi etkinleştir (zaten etkinse bir şey yapmaz).
ALTER TABLE public.user_unit_summary ENABLE ROW LEVEL SECURITY;

-- Mevcut politikaları güvenli bir şekilde silip yeniden oluştur.
DROP POLICY IF EXISTS "Allow individual select access on user_unit_summary" ON public.user_unit_summary;
CREATE POLICY "Allow individual select access on user_unit_summary"
ON public.user_unit_summary
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow individual insert access on user_unit_summary" ON public.user_unit_summary;
CREATE POLICY "Allow individual insert access on user_unit_summary"
ON public.user_unit_summary
FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow individual update access on user_unit_summary" ON public.user_unit_summary;
CREATE POLICY "Allow individual update access on user_unit_summary"
ON public.user_unit_summary
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow individual delete access on user_unit_summary" ON public.user_unit_summary;
CREATE POLICY "Allow individual delete access on user_unit_summary"
ON public.user_unit_summary
FOR DELETE
USING (auth.uid() = user_id);
