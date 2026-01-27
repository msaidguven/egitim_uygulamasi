-- 1. Eksik Sütunların Kontrolü ve Eklenmesi
-- Units tablosunda question_count olduğundan emin ol
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'units' AND column_name = 'question_count') THEN
        ALTER TABLE public.units ADD COLUMN question_count integer NOT NULL DEFAULT 0;
    END IF;
END $$;

-- 2. Curriculum Week Tablosu için Unique Constraint (Upsert işlemi için gerekli)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'curriculum_week_question_counts_unique_key') THEN
        ALTER TABLE public.curriculum_week_question_counts
        ADD CONSTRAINT curriculum_week_question_counts_unique_key UNIQUE (unit_id, curriculum_week);
    END IF;
END $$;

-- 3. Trigger Fonksiyonunun Oluşturulması
CREATE OR REPLACE FUNCTION public.handle_new_question_usage()
RETURNS TRIGGER AS $$
DECLARE
  v_unit_id bigint;
  v_lesson_id bigint;
BEGIN
  -- Eklenen sorunun (topic üzerinden) hangi unit ve lesson'a ait olduğunu bul
  SELECT t.unit_id, u.lesson_id
  INTO v_unit_id, v_lesson_id
  FROM public.topics t
  JOIN public.units u ON u.id = t.unit_id
  WHERE t.id = NEW.topic_id;

  -- Eğer ilişkili kayıt bulunamazsa işlem yapma
  IF v_unit_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- A. Unit question_count artır
  UPDATE public.units
  SET question_count = question_count + 1
  WHERE id = v_unit_id;

  -- B. Lesson Grades question_count artır
  -- Bu ünitenin bağlı olduğu tüm sınıfları (unit_grades) bul ve ilgili lesson_grades kayıtlarını güncelle
  UPDATE public.lesson_grades lg
  SET question_count = question_count + 1
  FROM public.unit_grades ug
  WHERE ug.unit_id = v_unit_id      -- Sorunun eklendiği üniteye bağlı kayıtları bul
    AND ug.grade_id = lg.grade_id   -- Bu grade için lesson_grades eşleşmesini yakala
    AND lg.lesson_id = v_lesson_id; -- Ve sadece bu dersin kaydını güncelle

  -- C. Grades question_count artır (YENİ EKLENDİ)
  -- Bu ünitenin bağlı olduğu tüm sınıfların (grades) genel toplamını artır
  UPDATE public.grades g
  SET question_count = question_count + 1
  FROM public.unit_grades ug
  WHERE ug.unit_id = v_unit_id      -- Sorunun eklendiği ünite...
    AND ug.grade_id = g.id;         -- ...hangi sınıflara bağlıysa onları güncelle

  -- D. Week question_count artır (curriculum_week doluysa)
  IF NEW.curriculum_week IS NOT NULL THEN
    INSERT INTO public.curriculum_week_question_counts (unit_id, curriculum_week, total_questions)
    VALUES (v_unit_id, NEW.curriculum_week, 1)
    ON CONFLICT ON CONSTRAINT curriculum_week_question_counts_unique_key
    DO UPDATE SET total_questions = curriculum_week_question_counts.total_questions + 1;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Trigger'ın Tanımlanması
DROP TRIGGER IF EXISTS on_question_usage_created ON public.question_usages;

CREATE TRIGGER on_question_usage_created
AFTER INSERT ON public.question_usages
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_question_usage();
