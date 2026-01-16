-- Önceki tüm hatalı fonksiyonları sil
DROP FUNCTION IF EXISTS get_question_count_for_topic(p_topic_id INT, p_difficulty INT);
DROP FUNCTION IF EXISTS get_question_count_for_topic(p_topic_id INT, p_difficulty INT, p_week_no INT);

-- HATA AYIKLAMA SÜRÜMÜ
-- Bu fonksiyon, Supabase loglarına (Database -> Logs) hata ayıklama mesajları yazar.
CREATE OR REPLACE FUNCTION get_question_count_for_topic(p_topic_id INT, p_difficulty INT, p_week_no INT)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  question_count INT;
  current_user_id UUID := auth.uid();
BEGIN
  -- 1. Fonksiyonun hangi parametrelerle çağrıldığını logla
  RAISE NOTICE '[get_question_count_for_topic] Çağrıldı. Parametreler: topic_id=%, difficulty=%, week_no=%', p_topic_id, p_difficulty, p_week_no;
  RAISE NOTICE '[get_question_count_for_topic] Kullanıcı ID: %', current_user_id;

  -- 2. Sorguyu çalıştır
  SELECT COUNT(*)
  INTO question_count
  FROM public.questions q
  JOIN public.question_usages qu ON q.id = qu.question_id
  WHERE
    qu.topic_id = p_topic_id
    AND q.difficulty = p_difficulty
    AND qu.display_week = p_week_no
    AND q.question_type_id IN (1, 2)
    AND (
      NOT EXISTS (
        SELECT 1
        FROM public.user_question_stats uqs
        WHERE uqs.question_id = q.id AND uqs.user_id = current_user_id
      )
      OR
      EXISTS (
        SELECT 1
        FROM public.user_question_stats uqs
        WHERE uqs.question_id = q.id AND uqs.user_id = current_user_id AND uqs.next_review_at <= now()
      )
    );

  -- 3. Sorgu sonucunu ve dönüş değerini logla
  RAISE NOTICE '[get_question_count_for_topic] Sorgu tamamlandı. Bulunan soru sayısı: %', question_count;

  RETURN question_count;
END;
$$;
