-- Fonksiyonu sil
DROP FUNCTION IF EXISTS public.bulk_create_questions(bigint, text, int, jsonb);

-- Fonksiyonu yeniden oluştur (SADECE SİZİN İSTEDİĞİNİZ DEĞİŞİKLİKLE)
CREATE OR REPLACE FUNCTION bulk_create_questions(
    p_topic_id BIGINT,
    p_usage_type TEXT,
    p_display_week INT,
    p_questions_json JSONB
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    question_data JSONB;
    pair_data JSONB;
    choice_data JSONB;
    blank_option_data JSONB;
    question_type_text TEXT;
    v_question_type_id SMALLINT;
    new_question_id BIGINT;
    v_is_true_correct BOOLEAN;
BEGIN
    FOR question_data IN SELECT * FROM jsonb_array_elements(p_questions_json->'questions')
    LOOP
        v_question_type_id := (question_data->>'question_type_id')::SMALLINT;
        SELECT code INTO question_type_text FROM public.question_types WHERE id = v_question_type_id;
        IF NOT FOUND THEN RAISE EXCEPTION 'Geçersiz "question_type_id": %', v_question_type_id; END IF;

        INSERT INTO public.questions (question_type_id, question_text, difficulty, score)
        VALUES (
            v_question_type_id,
            question_data->>'question_text',
            (question_data->>'difficulty')::SMALLINT,
            (question_data->>'score')::SMALLINT
        )
        RETURNING id INTO new_question_id;

        IF p_usage_type = 'weekly' THEN
            INSERT INTO public.question_usages (question_id, topic_id, usage_type, display_week)
            VALUES (new_question_id, p_topic_id, p_usage_type, p_display_week);
        ELSE
            INSERT INTO public.question_usages (question_id, topic_id, usage_type)
            VALUES (new_question_id, p_topic_id, p_usage_type);
        END IF;

        -- *** DEĞİŞİKLİK SADECE BURADA ***
        IF question_type_text = 'multiple_choice' OR question_type_text = 'true_false' THEN
            FOR choice_data IN SELECT * FROM jsonb_array_elements(question_data->'choices')
            LOOP
                -- Flutter'dan 'text' geldiği için 'text' okunuyor, DB'ye 'choice_text' olarak yazılıyor.
                INSERT INTO public.question_choices (question_id, choice_text, is_correct)
                VALUES (new_question_id, choice_data->>'text', (choice_data->>'is_correct')::BOOLEAN);
            END LOOP;

        -- Diğer bloklar aynı kalıyor
        ELSIF question_type_text = 'fill_blank' THEN
            IF question_data->'blank' ? 'options' THEN
                FOR blank_option_data IN SELECT * FROM jsonb_array_elements(question_data->'blank'->'options')
                LOOP
                    INSERT INTO public.question_blank_options (question_id, option_text, is_correct)
                    VALUES (new_question_id, blank_option_data->>'text', (blank_option_data->>'is_correct')::BOOLEAN);
                END LOOP;
            END IF;

        ELSIF question_type_text = 'classical' THEN
             IF question_data ? 'model_answer' THEN
                INSERT INTO public.question_classical (question_id, model_answer)
                VALUES (new_question_id, question_data->>'model_answer');
             END IF;
        ELSIF question_type_text = 'matching' THEN
            FOR pair_data IN SELECT * FROM jsonb_array_elements(question_data->'pairs')
            LOOP
                INSERT INTO public.question_matching_pairs (question_id, left_text, right_text)
                VALUES (new_question_id, pair_data->>'left_text', pair_data->>'right_text');
            END LOOP;
        END IF;
    END LOOP;
END;
$$;