-- 1. RLS'yi Etkinleştir (Eğer değilse)
ALTER TABLE public.test_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_session_questions ENABLE ROW LEVEL SECURITY;

-- 2. test_sessions Politikaları
DROP POLICY IF EXISTS "Users can view their own sessions" ON public.test_sessions;
CREATE POLICY "Users can view their own sessions"
ON public.test_sessions FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own sessions" ON public.test_sessions;
CREATE POLICY "Users can insert their own sessions"
ON public.test_sessions FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own sessions" ON public.test_sessions;
CREATE POLICY "Users can update their own sessions"
ON public.test_sessions FOR UPDATE
USING (auth.uid() = user_id);

-- 3. test_session_questions Politikaları
DROP POLICY IF EXISTS "Users can view their own session questions" ON public.test_session_questions;
CREATE POLICY "Users can view their own session questions"
ON public.test_session_questions FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.test_sessions
        WHERE id = test_session_questions.test_session_id
        AND user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can insert their own session questions" ON public.test_session_questions;
CREATE POLICY "Users can insert their own session questions"
ON public.test_session_questions FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.test_sessions
        WHERE id = test_session_id
        AND user_id = auth.uid()
    )
);

-- 4. Fonksiyonları SECURITY DEFINER olarak güncelle (RLS engeline takılmaması için)
-- Not: SET search_path güvenliği için önemlidir.

CREATE OR REPLACE FUNCTION public.start_test(p_user_id uuid, p_unit_id bigint)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER -- Yetki yükseltme
SET search_path = public, auth -- Güvenlik için path sabitleme
AS $$
DECLARE
    v_session_id bigint;
    v_question_count int;
BEGIN
    -- Güvenlik Kontrolü: Sadece kendi adına test başlatabilir
    IF auth.uid() <> p_user_id THEN
        RAISE EXCEPTION 'Yetkisiz işlem.';
    END IF;

    SELECT id INTO v_session_id
    FROM public.test_sessions
    WHERE user_id = p_user_id
      AND unit_id = p_unit_id
      AND completed_at IS NULL
    LIMIT 1;

    IF v_session_id IS NOT NULL THEN
        RETURN v_session_id;
    END IF;

    SELECT count(*) INTO v_question_count
    FROM (
        SELECT qu.question_id
        FROM public.question_usages qu
        JOIN public.topics t ON qu.topic_id = t.id
        WHERE t.unit_id = p_unit_id
        GROUP BY qu.question_id
    ) sub;

    IF v_question_count < 10 THEN
        RAISE EXCEPTION 'Yetersiz soru sayısı: %', v_question_count;
    END IF;

    INSERT INTO public.test_sessions (user_id, unit_id)
    VALUES (p_user_id, p_unit_id)
    RETURNING id INTO v_session_id;

    INSERT INTO public.test_session_questions (test_session_id, question_id, order_no)
    SELECT v_session_id, q_id, row_number() OVER ()
    FROM (
        SELECT qu.question_id as q_id
        FROM public.question_usages qu
        JOIN public.topics t ON qu.topic_id = t.id
        WHERE t.unit_id = p_unit_id
        GROUP BY qu.question_id
        ORDER BY random()
        LIMIT 10
    ) sub;

    RETURN v_session_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.finish_test(p_session_id bigint)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    UPDATE public.test_sessions
    SET completed_at = now()
    WHERE id = p_session_id
      AND user_id = auth.uid() -- Güvenlik kontrolü
      AND completed_at IS NULL;
END;
$$;
