-- ==================================================================================
--  ACTIVE DATABASE LOGIC REGISTRY (VERİTABANI MANTIĞI KAYIT DEFTERİ)
-- ==================================================================================
--  Bu dosya, projenin veritabanında kullanılan GÜNCEL ve GEÇERLİ fonksiyon/trigger'ları içerir.
--  Burada yer almayan herhangi bir trigger veya fonksiyon (Supabase defaultları hariç)
--  "ÇÖP" (obsolete) olarak kabul edilmeli ve silinmelidir.
-- ==================================================================================


-- ----------------------------------------------------------------------------------
-- 1. SORU SAYACI GÜNCELLEME (Unit, Lesson, Grade, Week)
-- ----------------------------------------------------------------------------------
-- Amaç: 'question_usages' tablosuna soru eklendiğinde (+1) veya silindiğinde (-1)
-- ilgili Unit, Lesson, LessonGrade ve Haftalık sayaçları otomatik günceller.
-- Tablo: question_usages
-- Tetiklenme: AFTER INSERT OR DELETE

CREATE OR REPLACE FUNCTION public.handle_question_usage_change()
RETURNS TRIGGER AS $$
DECLARE
  v_unit_id bigint;
  v_lesson_id bigint;
  rec RECORD;
  modifier integer;
BEGIN
  -- İşlem türünü belirle (Ekleme mi Silme mi?)
  IF (TG_OP = 'DELETE') THEN
    rec := OLD;
    modifier := -1;
  ELSE
    rec := NEW;
    modifier := 1;
  END IF;

  -- Etkilenen unit ve lesson'ı bul
  SELECT t.unit_id, u.lesson_id
  INTO v_unit_id, v_lesson_id
  FROM public.topics t
  JOIN public.units u ON u.id = t.unit_id
  WHERE t.id = rec.topic_id;

  -- Kayıt bulunamazsa çık
  IF v_unit_id IS NULL THEN
    RETURN NULL;
  END IF;

  -- A. Unit question_count güncelle
  UPDATE public.units
  SET question_count = question_count + modifier
  WHERE id = v_unit_id;

  -- B. Lesson Grades question_count güncelle
  UPDATE public.lesson_grades lg
  SET question_count = question_count + modifier
  FROM public.unit_grades ug
  WHERE ug.unit_id = v_unit_id
    AND ug.grade_id = lg.grade_id
    AND lg.lesson_id = v_lesson_id;

  -- C. Grades (Sınıf Toplamı) question_count güncelle
  UPDATE public.grades g
  SET question_count = question_count + modifier
  FROM public.unit_grades ug
  WHERE ug.unit_id = v_unit_id
    AND ug.grade_id = g.id;

  -- D. Week question_count güncelle (Haftalık Program)
  IF rec.curriculum_week IS NOT NULL THEN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO public.curriculum_week_question_counts (unit_id, curriculum_week, total_questions)
        VALUES (v_unit_id, rec.curriculum_week, 1)
        ON CONFLICT ON CONSTRAINT curriculum_week_question_counts_unique_key
        DO UPDATE SET total_questions = curriculum_week_question_counts.total_questions + 1;
    ELSE
        UPDATE public.curriculum_week_question_counts
        SET total_questions = total_questions - 1
        WHERE unit_id = v_unit_id AND curriculum_week = rec.curriculum_week;
    END IF;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger Tanımı
DROP TRIGGER IF EXISTS on_question_usage_change ON public.question_usages;

CREATE TRIGGER on_question_usage_change
AFTER INSERT OR DELETE ON public.question_usages
FOR EACH ROW
EXECUTE FUNCTION public.handle_question_usage_change();


-- ----------------------------------------------------------------------------------
-- 2. İSTATİSTİK ONARIM VE BAŞLATMA (Manuel Çağrılır)
-- ----------------------------------------------------------------------------------
-- Amaç: Profil sayfasında 0 görünen istatistikleri düzeltmek için geçmiş verileri tarar.
-- Kullanım: SQL Editor'de bir kez manuel çalıştırılır.

/*
DO $$
DECLARE
    r RECORD;
    v_total_questions integer;
    -- ... (Tam kod daha önce paylaşıldı, yer kaplamasın diye özet geçildi)
BEGIN
    -- ...
END $$;
*/
