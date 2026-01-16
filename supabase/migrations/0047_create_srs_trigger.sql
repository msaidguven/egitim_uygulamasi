-- Migration: 0047_create_srs_trigger.sql
-- Bu migration, Aralıklı Tekrar Sistemi (SRS) için gerekli olan trigger fonksiyonunu ve trigger'ı oluşturur.
-- Amaç: Bir soruya verilen cevaba göre, o sorunun bir sonraki tekrar zamanını (next_review_at) akıllıca belirlemek.

-- 1. Trigger Fonksiyonunu Oluşturma
CREATE OR REPLACE FUNCTION public.sync_user_question_stats()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_exists boolean;
  v_correct_attempts integer;
  v_next_interval interval;
BEGIN

  -- Kullanıcının bu soruyla ilgili daha önce bir istatistiği var mı diye kontrol et
  SELECT true, COALESCE(correct_attempts, 0)
  INTO v_exists, v_correct_attempts
  FROM public.user_question_stats
  WHERE user_id = NEW.user_id
    AND question_id = NEW.question_id;

  IF NOT FOUND THEN
    -- İLK ÇÖZÜM: Soru ilk defa çözülüyor
    IF NEW.is_correct THEN
      v_next_interval := interval '8 hours'; -- İlk doğru cevap, gün içinde tekrar
    ELSE
      v_next_interval := interval '10 minutes'; -- Yanlış cevap, hemen tekrar
    END IF;

    INSERT INTO public.user_question_stats (
      user_id,
      question_id,
      last_answer_correct,
      last_answer_at,
      total_attempts,
      correct_attempts,
      wrong_attempts,
      next_review_at
    )
    VALUES (
      NEW.user_id,
      NEW.question_id,
      NEW.is_correct,
      NEW.created_at,
      1,
      CASE WHEN NEW.is_correct THEN 1 ELSE 0 END,
      CASE WHEN NEW.is_correct THEN 0 ELSE 1 END,
      now() + v_next_interval
    );

  ELSE
    -- TEKRAR ÇÖZÜM: Soru daha önce çözülmüş
    IF NEW.is_correct THEN
      -- Doğru cevap senaryoları
      IF v_correct_attempts = 0 THEN
        v_next_interval := interval '8 hours';   -- Yanlıştan sonraki ilk doğru
      ELSIF v_correct_attempts = 1 THEN
        v_next_interval := interval '1 day';
      ELSIF v_correct_attempts = 2 THEN
        v_next_interval := interval '3 days';
      ELSIF v_correct_attempts = 3 THEN
        v_next_interval := interval '7 days';
      ELSE
        v_next_interval := interval '15 days';  -- Üst limit
      END IF;
    ELSE
      -- Yanlış cevap senaryosu: Tekrar periyodunu sıfırla
      v_next_interval := interval '10 minutes';
    END IF;

    UPDATE public.user_question_stats
    SET
      last_answer_correct = NEW.is_correct,
      last_answer_at = NEW.created_at,
      total_attempts = total_attempts + 1,
      correct_attempts = CASE WHEN NEW.is_correct THEN correct_attempts + 1 ELSE correct_attempts END,
      wrong_attempts   = CASE WHEN NEW.is_correct THEN wrong_attempts ELSE wrong_attempts + 1 END,
      next_review_at   = now() + v_next_interval,
      updated_at       = now()
    WHERE user_id = NEW.user_id
      AND question_id = NEW.question_id;
  END IF;

  RETURN NEW;
END;
$$;

-- 2. Trigger'ı Oluşturma
-- Bu trigger, 'test_session_answers' tablosuna her yeni kayıt eklendiğinde (INSERT) çalışır.
-- NOT: Sadece 'user_id'si olan (yani giriş yapmış) kullanıcılar için çalışır.
CREATE TRIGGER on_new_answer_srs
  AFTER INSERT ON public.test_session_answers
  FOR EACH ROW
  WHEN (NEW.user_id IS NOT NULL)
  EXECUTE FUNCTION public.sync_user_question_stats();
