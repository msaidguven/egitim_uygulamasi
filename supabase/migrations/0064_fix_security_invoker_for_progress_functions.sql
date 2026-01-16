-- Migration: 0064_fix_security_invoker_for_progress_functions.sql
-- Bu migration, `user_progress` tablosuna yazma işlemi yapan fonksiyonların
-- RLS politikalarıyla doğru bir şekilde çalışabilmesi için onları `SECURITY INVOKER` olarak günceller.
-- Bu, "kullanıcı kimliği belirsizliği" sorununu ve kayıt eklenememesi hatasını çözer.

-- 1. Adım: `mark_week_as_started` fonksiyonunu `SECURITY INVOKER` olarak güncelle.
-- Artık bu fonksiyon, onu çağıran kullanıcının yetkileriyle çalışacak.
CREATE OR REPLACE FUNCTION public.mark_week_as_started(
    p_user_id uuid,
    p_lesson_id bigint,
    p_grade_id bigint,
    p_week_no integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER -- ÖNEMLİ DEĞİŞİKLİK: DEFINER'dan INVOKER'a
AS $$
BEGIN
    INSERT INTO public.user_progress (user_id, lesson_id, grade_id, week_no, progress_percentage, success_rate)
    VALUES (p_user_id, p_lesson_id, p_grade_id, p_week_no, 0, 0.00)
    ON CONFLICT (user_id, lesson_id, grade_id, week_no) DO NOTHING;
END;
$$;


-- 2. Adım: `declare_week_completed` fonksiyonunu `SECURITY INVOKER` olarak güncelle.
CREATE OR REPLACE FUNCTION public.declare_week_completed(
    p_user_id uuid,
    p_lesson_id bigint,
    p_grade_id bigint,
    p_week_no integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER -- ÖNEMLİ DEĞİŞİKLİK: DEFINER'dan INVOKER'a
AS $$
BEGIN
    INSERT INTO public.user_progress (user_id, lesson_id, grade_id, week_no, declared_completed_at)
    VALUES (p_user_id, p_lesson_id, p_grade_id, p_week_no, now())
    ON CONFLICT (user_id, lesson_id, grade_id, week_no)
    DO UPDATE SET declared_completed_at = now();
END;
$$;


-- 3. Adım: `sync_user_progress_on_answer` trigger fonksiyonunu `SECURITY INVOKER` olarak güncelle.
CREATE OR REPLACE FUNCTION public.sync_user_progress_on_answer()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER -- ÖNEMLİ DEĞİŞİKLİK: DEFINER'dan INVOKER'a
AS $$
DECLARE
    v_lesson_id bigint;
    v_grade_id bigint;
    v_week_no integer;
    v_total_questions_in_week integer;
    v_solved_in_week integer;
    v_correct_in_week integer;
    v_progress_percentage integer;
    v_success_rate numeric(5, 2);
BEGIN
    SELECT u.lesson_id, ug.grade_id, qu.display_week
    INTO v_lesson_id, v_grade_id, v_week_no
    FROM public.question_usages qu
    JOIN public.topics t ON qu.topic_id = t.id
    JOIN public.units u ON t.unit_id = u.id
    JOIN public.unit_grades ug ON u.id = ug.unit_id
    WHERE qu.question_id = NEW.question_id
    LIMIT 1;

    IF v_week_no IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT count(*)
    INTO v_total_questions_in_week
    FROM public.question_usages qu
    WHERE qu.display_week = v_week_no AND qu.topic_id IN (
        SELECT t.id FROM topics t JOIN units u ON t.unit_id = u.id WHERE u.lesson_id = v_lesson_id
    );

    IF v_total_questions_in_week = 0 THEN
        v_total_questions_in_week := 1;
    END IF;

    SELECT
        count(DISTINCT uqs.question_id),
        count(DISTINCT uqs.question_id) FILTER (WHERE uqs.last_answer_correct = true)
    INTO v_solved_in_week, v_correct_in_week
    FROM public.user_question_stats uqs
    WHERE uqs.user_id = NEW.user_id AND uqs.question_id IN (
        SELECT qu.question_id FROM public.question_usages qu WHERE qu.display_week = v_week_no
    );

    v_progress_percentage := (v_solved_in_week * 100) / v_total_questions_in_week;
    IF v_solved_in_week > 0 THEN
        v_success_rate := (v_correct_in_week::numeric * 100) / v_solved_in_week;
    ELSE
        v_success_rate := 0.00;
    END IF;

    INSERT INTO public.user_progress (
        user_id, lesson_id, grade_id, week_no,
        progress_percentage, success_rate
    )
    VALUES (
        NEW.user_id, v_lesson_id, v_grade_id, v_week_no,
        v_progress_percentage, v_success_rate
    )
    ON CONFLICT (user_id, lesson_id, grade_id, week_no)
    DO UPDATE SET
        progress_percentage = v_progress_percentage,
        success_rate = v_success_rate,
        updated_at = now();

    IF v_progress_percentage >= 70 AND v_success_rate >= 85.00 THEN
        UPDATE public.user_progress
        SET
            system_completed = true,
            system_completed_at = now()
        WHERE
            user_id = NEW.user_id
            AND lesson_id = v_lesson_id
            AND grade_id = v_grade_id
            AND week_no = v_week_no;
    END IF;

    RETURN NEW;
END;
$$;
