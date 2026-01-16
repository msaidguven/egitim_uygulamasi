-- Migration: 0074_create_weekly_count_trigger.sql
-- Bu migration, `weekly_question_counts` tablosunu otomatik olarak güncel tutmak için
-- gerekli olan trigger fonksiyonunu ve trigger'ı oluşturur.

-- 1. TRIGGER FONKSİYONUNU OLUŞTURMA
CREATE OR REPLACE FUNCTION public.update_weekly_question_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_unit_id bigint;
    v_week_no integer;
    v_topic_id bigint;
    v_total_questions integer;
BEGIN
    -- Değişiklikten etkilenen `topic_id` ve `week_no`'yu belirle
    IF (TG_OP = 'DELETE') THEN
        -- On DELETE, use the old data
        v_topic_id := OLD.topic_id;
        v_week_no := OLD.display_week;
    ELSE
        -- On INSERT or UPDATE, use the new data
        v_topic_id := NEW.topic_id;
        v_week_no := NEW.display_week;
    END IF;

    -- Eğer topic veya week bilgisi yoksa, işlem yapma
    IF v_topic_id IS NULL OR v_week_no IS NULL THEN
        RETURN NULL;
    END IF;

    -- `topic_id` üzerinden `unit_id`'yi bul
    SELECT t.unit_id INTO v_unit_id FROM public.topics t WHERE t.id = v_topic_id;

    -- Eğer unit bulunamazsa, işlem yapma
    IF v_unit_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Etkilenen hafta/ünite için toplam benzersiz soru sayısını yeniden hesapla
    SELECT count(DISTINCT qu.question_id)
    INTO v_total_questions
    FROM public.question_usages qu
    JOIN public.topics t ON qu.topic_id = t.id
    WHERE t.unit_id = v_unit_id AND qu.display_week = v_week_no;

    -- Yeni sayıyı özet tablosuna işle (yoksa ekle, varsa güncelle)
    INSERT INTO public.weekly_question_counts (unit_id, week_no, total_questions)
    VALUES (v_unit_id, v_week_no, v_total_questions)
    ON CONFLICT (unit_id, week_no) DO UPDATE
    SET total_questions = EXCLUDED.total_questions;

    RETURN NULL; -- AFTER trigger'lar için dönüş değeri önemli değildir
END;
$$;

-- 2. TRIGGER'I OLUŞTURMA
-- Önce, yeniden çalıştırılabilir olması için trigger'ı varsa sil
DROP TRIGGER IF EXISTS on_question_usage_change_update_weekly_counts ON public.question_usages;

-- `question_usages` tablosundaki her satır değişikliğinden sonra fonksiyonu çalıştıracak trigger'ı oluştur
CREATE TRIGGER on_question_usage_change_update_weekly_counts
  AFTER INSERT OR UPDATE OR DELETE ON public.question_usages
  FOR EACH ROW
  EXECUTE FUNCTION public.update_weekly_question_count();

COMMENT ON TRIGGER on_question_usage_change_update_weekly_counts ON public.question_usages
IS 'Keeps the weekly_question_counts summary table up-to-date when a question is added to, removed from, or changed in a week.';
