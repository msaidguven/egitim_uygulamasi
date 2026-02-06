-- ==================================================================================
--  ACTIVE DATABASE LOGIC REGISTRY (VERİTABANI MANTIĞI KAYIT DEFTERİ)
-- ==================================================================================
--  Bu dosya, projenin veritabanında kullanılan GÜNCEL ve GEÇERLİ fonksiyon/trigger'ları içerir.
--  Burada yer almayan herhangi bir trigger veya fonksiyon (Supabase defaultları hariç)
--  "ÇÖP" (obsolete) olarak kabul edilmeli ve silinmelidir.
-- ==================================================================================


-- ----------------------------------------------------------------------------------
-- 0. SRS SAYACI (Kullanıcının tekrar zamanı gelen soruları)
-- ----------------------------------------------------------------------------------
-- Amaç: start_srs_test_session ile aynı mantıkta, kullanıcının tekrar sorusu sayısını döndürür.
-- Kullanım: RPC (get_srs_due_count)

CREATE OR REPLACE FUNCTION public.get_srs_due_count(
    p_user_id UUID,
    p_unit_id BIGINT DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT COUNT(*)::INTEGER
    FROM (
        SELECT q.id
        FROM public.questions AS q
        JOIN public.question_usages AS qu ON q.id = qu.question_id
        JOIN public.topics AS t ON qu.topic_id = t.id
        WHERE t.is_active = true
          AND (p_unit_id IS NULL OR t.unit_id = p_unit_id)
          AND NOT EXISTS (
              SELECT 1 FROM public.user_question_stats uqs
              WHERE uqs.question_id = q.id
                AND uqs.user_id = p_user_id
                AND uqs.last_answer_correct = true
                AND uqs.next_review_at > NOW()
          )
        GROUP BY q.id
    ) AS sub;
$$;

GRANT EXECUTE ON FUNCTION public.get_srs_due_count(UUID, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_srs_due_count(UUID, BIGINT) TO anon;


-- ----------------------------------------------------------------------------------
-- 0.1 SRS TEST OTURUMU OLUŞTURMA
-- ----------------------------------------------------------------------------------
-- Amaç: Kullanıcının tekrar zamanı gelen sorularıyla SRS test oturumu oluşturur.
-- Not: Limit DB tarafında en fazla 10 olacak şekilde sabittir.

CREATE OR REPLACE FUNCTION start_srs_test_session(
    p_user_id UUID,
    p_unit_id BIGINT,
    p_client_id UUID,
    p_question_limit INTEGER
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_session_id BIGINT;
    v_question_ids BIGINT[];
    v_lesson_id BIGINT;
    v_grade_id BIGINT;
    v_limit INTEGER := LEAST(COALESCE(p_question_limit, 10), 10);
BEGIN
    -- 1. Bu mod için zaten aktif bir test var mı diye kontrol et.
    SELECT id
    INTO v_session_id
    FROM public.test_sessions
    WHERE user_id = p_user_id
        AND (p_unit_id IS NULL OR unit_id = p_unit_id)
        AND client_id = p_client_id
        AND completed_at IS NULL
        AND settings->>'mode' = 'srs'
    LIMIT 1;

    -- Eğer aktif bir oturum bulunduysa, onun ID'sini döndür.
    IF v_session_id IS NOT NULL THEN
        RETURN v_session_id;
    END IF;

    -- 2. SRS mantığına göre soruları seç (SRS: Tekrar zamanı gelmiş sorular).
    SELECT
        ARRAY_AGG(sub.id)
    INTO
        v_question_ids
    FROM (
        SELECT
            q.id
        FROM
            public.questions AS q
        JOIN
            public.question_usages AS qu ON q.id = qu.question_id
        JOIN
            public.topics AS t ON qu.topic_id = t.id
        WHERE
            t.is_active = true
            AND (p_unit_id IS NULL OR t.unit_id = p_unit_id)
            AND NOT EXISTS (
                SELECT 1 FROM public.user_question_stats uqs
                WHERE uqs.question_id = q.id
                    AND uqs.user_id = p_user_id
                    AND uqs.last_answer_correct = true
                    AND uqs.next_review_at > NOW()
            )
        GROUP BY q.id
        ORDER BY
            RANDOM()
        LIMIT v_limit
    ) AS sub;

    -- Eğer çözülecek soru bulunamazsa, NULL döndür.
    IF v_question_ids IS NULL OR array_length(v_question_ids, 1) = 0 THEN
        RETURN NULL;
    END IF;

    -- 3. Eğer unit_id varsa, lesson_id ve grade_id'yi bul.
    IF p_unit_id IS NOT NULL THEN
        SELECT u.lesson_id, ug.grade_id
        INTO v_lesson_id, v_grade_id
        FROM public.units u
        LEFT JOIN public.unit_grades ug ON u.id = ug.unit_id
        WHERE u.id = p_unit_id
        LIMIT 1;
    END IF;

    -- 4. Yeni bir test oturumu oluştur.
    INSERT INTO public.test_sessions (
        user_id, 
        unit_id, 
        lesson_id, 
        grade_id, 
        client_id, 
        created_at,
        question_ids, 
        settings
    )
    VALUES (
        p_user_id,
        p_unit_id,
        v_lesson_id,
        v_grade_id,
        p_client_id,
        NOW(),
        v_question_ids,
        jsonb_build_object(
            'mode', 'srs',
            'limit_requested', v_limit,
            'status', 'active'
        )
    )
    RETURNING id INTO v_session_id;

    -- 5. Seçilen soruları test_session_questions tablosuna ekle.
    INSERT INTO public.test_session_questions (test_session_id, question_id, order_no)
    SELECT
        v_session_id,
        question_id,
        row_number() OVER ()
    FROM
        unnest(v_question_ids) AS question_id;

    -- 6. Yeni oturumun ID'sini döndür.
    RETURN v_session_id;
END;
$$;

GRANT EXECUTE ON FUNCTION start_srs_test_session(UUID, BIGINT, UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION start_srs_test_session(UUID, BIGINT, UUID, INTEGER) TO anon;


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
