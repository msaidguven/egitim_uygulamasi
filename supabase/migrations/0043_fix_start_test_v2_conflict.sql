-- Migration: 0043_fix_start_test_v2_conflict.sql
-- Soru seçme mantığı, çözülmemiş soruları önceliklendirecek şekilde güncellendi.

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
    WHERE unit_id = p_unit_id
      AND completed_at IS NULL
      AND (
          (p_user_id IS NOT NULL AND user_id = p_user_id)
          OR
          (p_user_id IS NULL AND client_id = p_client_id)
      )
    ORDER BY created_at DESC
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
        RAISE EXCEPTION 'Ünitede test oluşturmak için yeterli soru (10) bulunmuyor. Toplam soru: %', v_question_count;
    END IF;

    -- 3. Yeni oturum oluştur
    INSERT INTO public.test_sessions (user_id, client_id, unit_id, settings)
    VALUES (p_user_id, p_client_id, p_unit_id, '{"type": "unit_test", "version": "2.0"}'::jsonb)
    RETURNING id INTO v_session_id;

    -- 4. 10 soruyu ÖNCELİKLİ, AKILLI VE RASTGELE seç ve sabitle
    INSERT INTO public.test_session_questions (test_session_id, question_id, order_no)
    SELECT v_session_id, q_id, row_number() OVER (ORDER BY random())
    FROM (
        SELECT
            q.id as q_id,
            -- Önceliklendirme için sıralama sütunu oluştur:
            -- 0 = Hiç çözülmemiş (en yüksek öncelik)
            -- 1 = Tekrar zamanı gelmiş (ikinci öncelik)
            (CASE WHEN uqs.user_id IS NULL THEN 0 ELSE 1 END) as priority
        FROM public.questions q
        JOIN public.question_usages qu ON q.id = qu.question_id
        JOIN public.topics t ON qu.topic_id = t.id
        LEFT JOIN public.user_question_stats uqs ON q.id = uqs.question_id AND uqs.user_id = p_user_id
        WHERE
            t.unit_id = p_unit_id
            AND (
                p_user_id IS NULL -- Misafir kullanıcı ise filtreleme yapma
                OR uqs.user_id IS NULL -- Veya hiç cevaplanmamışsa
                OR uqs.next_review_at <= now() -- Veya tekrar zamanı gelmişse
            )
        GROUP BY q.id, uqs.user_id
        ORDER BY
            priority ASC, -- Önce hiç çözülmemişleri al
            random()      -- Kendi öncelik grupları içinde rastgele sırala
        LIMIT 10
    ) sub;

    RETURN v_session_id;
END;
$$;
