-- Migration: 0036_guest_auth_session_system.sql
-- GÜNCELLEME 8 (KİTAP AYRACI SİSTEMİ - SON ADIM):
-- `finish_test_v2` fonksiyonu, artık test bittiğinde `solved_question_count`
-- "kitap ayracını" ilerletecek şekilde güncellendi.

-- 1. test_sessions Tablosunu Güncelle (DEĞİŞİKLİK YOK)
ALTER TABLE public.test_sessions ADD COLUMN IF NOT EXISTS client_id uuid;
UPDATE public.test_sessions SET client_id = gen_random_uuid() WHERE client_id IS NULL;
ALTER TABLE public.test_sessions ALTER COLUMN client_id SET NOT NULL;

-- 2. test_session_answers Tablosu (DEĞİŞİKLİK YOK)
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

-- 3. start_test_v2 RPC (DEĞİŞİKLİK YOK)
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
    v_question_ids bigint[];
    v_lesson_id bigint;
    v_grade_id bigint;
    v_solved_count integer;
BEGIN
    IF p_user_id IS NOT NULL AND p_user_id <> auth.uid() THEN
        RAISE EXCEPTION 'Yetkisiz user_id kullanımı.';
    END IF;

    SELECT u.lesson_id, ug.grade_id
    INTO v_lesson_id, v_grade_id
    FROM public.units u
    JOIN public.unit_grades ug ON u.id = ug.unit_id
    WHERE u.id = p_unit_id
    LIMIT 1;

    SELECT solved_question_count
    INTO v_solved_count
    FROM public.user_unit_summary
    WHERE user_id = p_user_id AND unit_id = p_unit_id;

    IF NOT FOUND THEN
        v_solved_count := 0;
    END IF;

    SELECT ARRAY_AGG(q.id)
    INTO v_question_ids
    FROM (
        SELECT q.id
        FROM public.questions q
        JOIN public.question_usages qu ON q.id = qu.question_id
        JOIN public.topics t ON qu.topic_id = t.id
        WHERE t.unit_id = p_unit_id
        ORDER BY q.id
        OFFSET v_solved_count
        LIMIT 10
    ) q;

    IF v_question_ids IS NULL OR array_length(v_question_ids, 1) = 0 THEN
        RETURN NULL;
    END IF;

    INSERT INTO public.test_sessions (user_id, client_id, unit_id, lesson_id, grade_id, settings, question_ids)
    VALUES (p_user_id, p_client_id, p_unit_id, v_lesson_id, v_grade_id, '{"type": "unit_test"}'::jsonb, v_question_ids)
    RETURNING id INTO v_session_id;

    INSERT INTO public.test_session_questions (test_session_id, question_id, order_no)
    SELECT v_session_id, question_id, row_number() OVER ()
    FROM unnest(v_question_ids) as question_id;

    RETURN v_session_id;
END;
$$;

-- 4. link_guest_data_to_user RPC (DEĞİŞİKLİK YOK)
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

-- 5. get_active_question_v2 RPC (DEĞİŞİKLİK YOK)
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

-- 6. finish_test_v2 RPC (YENİDEN YAZILDI)
CREATE OR REPLACE FUNCTION public.finish_test_v2(p_session_id bigint)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_session_info record;
    v_test_summary record;
    v_answered_count integer;
BEGIN
    -- 1. Oturum bilgilerini (unit_id, user_id) al.
    SELECT
        ts.user_id,
        ts.unit_id
    INTO v_session_info
    FROM public.test_sessions ts
    WHERE ts.id = p_session_id AND ts.completed_at IS NULL;

    -- Eğer oturum bulunamazsa, zaten tamamlanmışsa veya kullanıcı girişi yapılmamışsa, bir şey yapma.
    IF NOT FOUND OR v_session_info.user_id IS NULL THEN
        UPDATE public.test_sessions SET completed_at = now() WHERE id = p_session_id;
        RETURN;
    END IF;

    -- 2. Bu test oturumundaki doğru, yanlış ve toplam cevaplanan soru sayılarını hesapla.
    SELECT
        count(*) FILTER (WHERE tsa.is_correct = true) AS correct_answers,
        count(*) FILTER (WHERE tsa.is_correct = false) AS wrong_answers,
        count(*) AS total_answered
    INTO v_test_summary
    FROM public.test_session_answers tsa
    WHERE tsa.test_session_id = p_session_id;

    -- 3. Hesaplanan sonuçları ve "kitap ayracını" `user_unit_summary` özet tablosuna işle.
    INSERT INTO public.user_unit_summary (user_id, unit_id, correct_count, wrong_count, solved_question_count, last_updated_at)
    VALUES (
        v_session_info.user_id,
        v_session_info.unit_id,
        v_test_summary.correct_answers,
        v_test_summary.wrong_answers,
        v_test_summary.total_answered,
        now()
    )
    ON CONFLICT (user_id, unit_id) DO UPDATE
    SET
        correct_count = user_unit_summary.correct_count + EXCLUDED.correct_count,
        wrong_count = user_unit_summary.wrong_count + EXCLUDED.wrong_count,
        solved_question_count = user_unit_summary.solved_question_count + EXCLUDED.solved_question_count, -- "Kitap Ayracını" ilerlet
        last_updated_at = now();

    -- 4. Oturumu "tamamlandı" olarak işaretle.
    UPDATE public.test_sessions
    SET completed_at = now()
    WHERE id = p_session_id;
END;
$$;
