-- Migration: 0075_update_test_sessions_for_lesson_lock.sql
-- GÜNCELLEME: Bu dosya, artık sadece `test_sessions` tablosuna `lesson_id` ve `grade_id`
-- kolonlarını eklemek ve eski ünite bazlı kuralı kaldırmak için kullanılıyor.
-- DÜZELTME 2: Hem kullanıcı hem de client bazlı katı kurallar kaldırıldı.

BEGIN;

-- 1. YENİ KOLONLARI EKLE
ALTER TABLE public.test_sessions
ADD COLUMN IF NOT EXISTS lesson_id bigint,
ADD COLUMN IF NOT EXISTS grade_id bigint;

-- 2. MEVCUT FOREIGN KEY KISITLAMALARINI GÜVENLİ BİR ŞEKİLDE YENİDEN OLUŞTUR
ALTER TABLE public.test_sessions
DROP CONSTRAINT IF EXISTS fk_test_sessions_lesson,
DROP CONSTRAINT IF EXISTS fk_test_sessions_grade;

ALTER TABLE public.test_sessions
ADD CONSTRAINT fk_test_sessions_lesson FOREIGN KEY (lesson_id) REFERENCES public.lessons(id) ON DELETE CASCADE,
ADD CONSTRAINT fk_test_sessions_grade FOREIGN KEY (grade_id) REFERENCES public.grades(id) ON DELETE CASCADE;

-- 3. MEVCUT VERİLERİ DOLDUR (Backfill)
WITH session_details AS (
    SELECT
        ts.id as session_id,
        u.lesson_id,
        ug.grade_id
    FROM public.test_sessions ts
    JOIN public.units u ON ts.unit_id = u.id
    LEFT JOIN (SELECT DISTINCT ON (unit_id) unit_id, grade_id FROM public.unit_grades) ug ON u.id = ug.unit_id
    WHERE ts.lesson_id IS NULL OR ts.grade_id IS NULL
)
UPDATE public.test_sessions ts
SET
    lesson_id = sd.lesson_id,
    grade_id = sd.grade_id
FROM session_details sd
WHERE ts.id = sd.session_id;

-- 4. TÜM KATİ KURALLARI KALDIR
-- Bu kurallar, kontrolü fonksiyonların içinden yapacağımız için artık gereksizdir ve hataya neden olmaktadır.
DROP INDEX IF EXISTS public.idx_unique_active_session;
DROP INDEX IF EXISTS public.idx_unique_active_lesson_session;
DROP INDEX IF EXISTS public.idx_unique_active_session_client; -- HATANIN KAYNAĞI OLAN İKİNCİ KURAL DA KALDIRILDI.

-- Yorumlar ve basit indeksler kalabilir.
CREATE INDEX IF NOT EXISTS idx_test_sessions_lesson_id ON public.test_sessions(lesson_id);
COMMENT ON COLUMN public.test_sessions.lesson_id IS 'Bu test oturumunun ait olduğu dersin ID''si.';
COMMENT ON COLUMN public.test_sessions.grade_id IS 'Bu test oturumunun ait olduğu sınıfın ID''si.';

COMMIT;
