-- GÖREV 1: Tablolar ve Constraintler (db_schema.md ile tam uyumlu)

-- 1. test_sessions tablosu zaten var, eksik constraintleri ve indexleri ekle
DO $$
BEGIN
    -- Mevcut mükerrer aktif oturumları temizle (en yenisi hariç hepsini kapat)
    WITH duplicates AS (
        SELECT id,
               ROW_NUMBER() OVER (PARTITION BY user_id, unit_id ORDER BY created_at DESC) as rn
        FROM public.test_sessions
        WHERE completed_at IS NULL
    )
    UPDATE public.test_sessions
    SET completed_at = now()
    WHERE id IN (SELECT id FROM duplicates WHERE rn > 1);
END $$;

DROP INDEX IF EXISTS public.idx_unique_active_session;
CREATE UNIQUE INDEX idx_unique_active_session
ON public.test_sessions (user_id, unit_id)
WHERE (completed_at IS NULL);

-- 2. test_session_questions tablosu (Sütun adı: test_session_id)
-- Eğer tablo yoksa oluştur, varsa sütun adlarını kontrol et
CREATE TABLE IF NOT EXISTS public.test_session_questions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    test_session_id bigint NOT NULL REFERENCES public.test_sessions(id) ON DELETE CASCADE,
    question_id bigint NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    order_no integer NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL
);

-- UNIQUE constraint ekle (Eğer yoksa)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'test_session_questions_unique_q') THEN
        ALTER TABLE public.test_session_questions
        ADD CONSTRAINT test_session_questions_unique_q UNIQUE (test_session_id, question_id);
    END IF;
END $$;

-- order_no check constraint
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'test_session_questions_order_check') THEN
        ALTER TABLE public.test_session_questions
        ADD CONSTRAINT test_session_questions_order_check CHECK (order_no BETWEEN 1 AND 10);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_tsq_session_order ON public.test_session_questions (test_session_id, order_no);

-- GÖREV 2: Test Başlatma Fonksiyonu

CREATE OR REPLACE FUNCTION public.start_test(p_user_id uuid, p_unit_id bigint)
RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
    v_session_id bigint;
    v_question_count int;
BEGIN
    -- Aktif oturum kontrolü
    SELECT id INTO v_session_id
    FROM public.test_sessions
    WHERE user_id = p_user_id
      AND unit_id = p_unit_id
      AND completed_at IS NULL
    LIMIT 1;

    IF v_session_id IS NOT NULL THEN
        RETURN v_session_id;
    END IF;

    -- Soru havuzu kontrolü (unit -> topics -> questions)
    SELECT count(DISTINCT qu.question_id) INTO v_question_count
    FROM public.question_usages qu
    JOIN public.topics t ON qu.topic_id = t.id
    WHERE t.unit_id = p_unit_id;

    IF v_question_count < 10 THEN
        RAISE EXCEPTION 'Yetersiz soru sayısı: %', v_question_count;
    END IF;

    -- Yeni oturum oluştur
    INSERT INTO public.test_sessions (user_id, unit_id)
    VALUES (p_user_id, p_unit_id)
    RETURNING id INTO v_session_id;

    -- Soruları sabitle (test_session_id sütununa dikkat)
    INSERT INTO public.test_session_questions (test_session_id, question_id, order_no)
    SELECT v_session_id, q_id, row_number() OVER ()
    FROM (
        SELECT DISTINCT qu.question_id as q_id
        FROM public.question_usages qu
        JOIN public.topics t ON qu.topic_id = t.id
        WHERE t.unit_id = p_unit_id
        ORDER BY random()
        LIMIT 10
    ) sub;

    RETURN v_session_id;
END;
$$;

-- GÖREV 3: Devam Eden Testi Bulma

CREATE OR REPLACE FUNCTION public.get_active_question(p_session_id bigint)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_question_id bigint;
    v_result jsonb;
BEGIN
    -- test_session_questions (test_session_id) ile user_answers (session_id) karşılaştırması
    SELECT tsq.question_id INTO v_question_id
    FROM public.test_session_questions tsq
    LEFT JOIN public.user_answers ua ON tsq.test_session_id = ua.session_id AND tsq.question_id = ua.question_id
    WHERE tsq.test_session_id = p_session_id AND ua.id IS NULL
    ORDER BY tsq.order_no ASC
    LIMIT 1;

    IF v_question_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Soru detaylarını getir
    SELECT public.get_question_details(v_question_id) INTO v_result;
    RETURN v_result;
END;
$$;

-- GÖREV 4: Test Bitirme

CREATE OR REPLACE FUNCTION public.finish_test(p_session_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE public.test_sessions
    SET completed_at = now()
    WHERE id = p_session_id AND completed_at IS NULL;
END;
$$;
