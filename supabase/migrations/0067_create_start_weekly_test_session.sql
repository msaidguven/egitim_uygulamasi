-- Migration: 0067_create_start_weekly_test_session.sql
-- GÜNCELLEME 2: `settings` alanı, artık 'mode' yerine standart olan 'type' anahtarını kullanacak şekilde güncellendi.

CREATE OR REPLACE FUNCTION public.start_weekly_test_session(
    p_user_id uuid,
    p_unit_id bigint,
    p_week_no integer,
    p_client_id uuid
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_session_id bigint;
    v_question_ids bigint[];
    v_lesson_id bigint;
    v_grade_id bigint;
BEGIN
    -- 1. Bu HAFTA için zaten aktif bir test var mı diye kontrol et.
    SELECT id
    INTO v_session_id
    FROM public.test_sessions
    WHERE user_id = p_user_id
      AND unit_id = p_unit_id
      AND completed_at IS NULL
      AND settings->>'type' = 'weekly' -- 'mode' -> 'type' olarak düzeltildi
      AND (settings->>'week_no')::integer = p_week_no
    LIMIT 1;

    -- Eğer bu hafta için aktif bir oturum bulunduysa, onun ID'sini döndür.
    IF v_session_id IS NOT NULL THEN
        RETURN v_session_id;
    END IF;

    -- 2. O haftaya ait, KULLANICININ HENÜZ ÇÖZMEDİĞİ soruları seç.
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
        LEFT JOIN
            public.user_weekly_question_progress AS uwqp
            ON q.id = uwqp.question_id
            AND uwqp.user_id = p_user_id
            AND uwqp.unit_id = p_unit_id
            AND uwqp.week_no = p_week_no
        WHERE
            t.unit_id = p_unit_id
            AND qu.display_week = p_week_no
            AND uwqp.id IS NULL
        ORDER BY
            RANDOM()
        LIMIT 10
    ) AS sub;

    -- Eğer çözülecek uygun yeni soru bulunamazsa, NULL döndür.
    IF v_question_ids IS NULL OR array_length(v_question_ids, 1) = 0 THEN
        RETURN NULL;
    END IF;

    -- 3. Yeni oturumu oluşturmadan önce lesson_id ve grade_id'yi bul.
    SELECT u.lesson_id, ug.grade_id
    INTO v_lesson_id, v_grade_id
    FROM public.units u
    JOIN public.unit_grades ug ON u.id = ug.unit_id
    WHERE u.id = p_unit_id
    LIMIT 1;

    -- 4. Yeni bir test oturumu oluştur.
    INSERT INTO public.test_sessions (user_id, unit_id, lesson_id, grade_id, client_id, question_ids, settings)
    VALUES (
        p_user_id,
        p_unit_id,
        v_lesson_id,
        v_grade_id,
        p_client_id,
        v_question_ids,
        jsonb_build_object('type', 'weekly', 'week_no', p_week_no) -- 'mode' -> 'type' olarak düzeltildi
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
