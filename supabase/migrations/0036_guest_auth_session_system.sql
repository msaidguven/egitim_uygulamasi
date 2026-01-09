-- 1. test_sessions Tablosunu Güncelle
ALTER TABLE public.test_sessions ADD COLUMN IF NOT EXISTS client_id uuid;

-- Mevcut veriler için geçici bir client_id ata (NOT NULL kısıtı ekleyebilmek için)
UPDATE public.test_sessions
SET client_id = gen_random_uuid()
WHERE client_id IS NULL;

-- client_id artık NOT NULL olabilir
ALTER TABLE public.test_sessions ALTER COLUMN client_id SET NOT NULL;

-- Tekil Aktif Oturum İndeksi (Cihaz Bazlı)
DROP INDEX IF EXISTS public.idx_unique_active_session_client;
CREATE UNIQUE INDEX idx_unique_active_session_client
ON public.test_sessions (client_id, unit_id)
WHERE (completed_at IS NULL);

-- 2. test_session_answers Tablosu
CREATE TABLE IF NOT EXISTS public.test_session_answers (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    test_session_id bigint NOT NULL REFERENCES public.test_sessions(id) ON DELETE CASCADE,
    question_id bigint NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    client_id uuid NOT NULL,
    selected_option_id bigint,
    answer_text text,
    is_correct boolean NOT NULL,
    duration_seconds integer,
    created_at timestamptz DEFAULT now() NOT NULL,
    UNIQUE (test_session_id, question_id)
);

-- 3. start_test_v2 RPC
CREATE OR REPLACE FUNCTION public.start_test_v2(
    p_client_id uuid,
    p_unit_id bigint,
    p_user_id uuid DEFAULT NULL
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_session_id bigint;
    v_question_count int;
BEGIN
    -- SECURITY GUARD
    IF p_user_id IS NOT NULL AND p_user_id <> auth.uid() THEN
        RAISE EXCEPTION 'Yetkisiz user_id kullanımı.';
    END IF;

    -- 1. Aktif oturum kontrolü
    SELECT id INTO v_session_id
    FROM public.test_sessions
    WHERE client_id = p_client_id
      AND unit_id = p_unit_id
      AND completed_at IS NULL
    LIMIT 1;

    IF v_session_id IS NOT NULL THEN
        RETURN v_session_id;
    END IF;

    -- 2. Soru havuzu kontrolü
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

    -- 3. Yeni oturum oluştur
    INSERT INTO public.test_sessions (user_id, client_id, unit_id, settings)
    VALUES (p_user_id, p_client_id, p_unit_id, '{"type": "unit_test", "version": "2.0"}'::jsonb)
    RETURNING id INTO v_session_id;

    -- 4. 10 soruyu rastgele seç ve sabitle
    INSERT INTO public.test_session_questions (test_session_id, question_id, order_no)
    SELECT v_session_id, q_id, row_number() OVER (ORDER BY random())
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

-- 4. link_guest_data_to_user RPC
CREATE OR REPLACE FUNCTION public.link_guest_data_to_user(
    p_client_id uuid,
    p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    IF p_user_id <> auth.uid() THEN
        RAISE EXCEPTION 'Sadece kendi verilerinizi bağlayabilirsiniz.';
    END IF;

    UPDATE public.test_sessions
    SET user_id = p_user_id
    WHERE client_id = p_client_id
      AND user_id IS NULL;

    UPDATE public.test_session_answers
    SET user_id = p_user_id
    WHERE client_id = p_client_id
      AND user_id IS NULL;
END;
$$;

-- 5. get_active_question_v2 RPC
CREATE OR REPLACE FUNCTION public.get_active_question_v2(p_session_id bigint)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_question_id bigint;
    v_result jsonb;
BEGIN
    SELECT tsq.question_id INTO v_question_id
    FROM public.test_session_questions tsq
    LEFT JOIN public.test_session_answers tsa ON tsq.test_session_id = tsa.test_session_id AND tsq.question_id = tsa.question_id
    WHERE tsq.test_session_id = p_session_id AND tsa.id IS NULL
    ORDER BY tsq.order_no ASC
    LIMIT 1;

    IF v_question_id IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT public.get_question_details(v_question_id) INTO v_result;
    RETURN v_result;
END;
$$;

-- 6. finish_test_v2 RPC
CREATE OR REPLACE FUNCTION public.finish_test_v2(p_session_id bigint)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    UPDATE public.test_sessions
    SET completed_at = now()
    WHERE id = p_session_id
      AND completed_at IS NULL;
END;
$$;
