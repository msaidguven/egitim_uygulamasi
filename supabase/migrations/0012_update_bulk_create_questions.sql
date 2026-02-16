-- Migration: Update bulk_create_questions to support solution_text
CREATE OR REPLACE FUNCTION public.bulk_create_questions(
    p_topic_id BIGINT,
    p_usage_type TEXT,
    p_questions_json JSONB,
    p_curriculum_week INTEGER DEFAULT NULL,
    p_start_week INTEGER DEFAULT NULL,
    p_end_week INTEGER DEFAULT NULL
)
RETURNS JSONB
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
    v_correct_answer BOOLEAN;
    v_errors JSONB := '[]'::JSONB;
    v_inserted_count INTEGER := 0;
BEGIN
    FOR question_data IN
        SELECT * FROM jsonb_array_elements(p_questions_json->'questions')
    LOOP
        BEGIN
            v_question_type_id := (question_data->>'question_type_id')::SMALLINT;

            SELECT code
            INTO question_type_text
            FROM public.question_types
            WHERE id = v_question_type_id;

            IF NOT FOUND THEN
                v_errors := v_errors || jsonb_build_object('error', 'Geçersiz question_type_id: ' || v_question_type_id, 'question', question_data);
                CONTINUE;
            END IF;

            -- 1. Soruyu Ekle (solution_text eklendi)
            INSERT INTO public.questions (
                question_type_id,
                question_text,
                difficulty,
                score,
                solution_text
            )
            VALUES (
                v_question_type_id,
                question_data->>'question_text',
                COALESCE((question_data->>'difficulty')::SMALLINT, 1),
                COALESCE((question_data->>'score')::SMALLINT, 1),
                question_data->>'solution_text'
            )
            RETURNING id INTO new_question_id;

            -- 2. Kullanım Alanını Belirle (question_usages)
            IF p_usage_type = 'weekly' THEN
                -- Eğer aralık verildiyse (BulkQuestionForm'dan geliyorsa)
                IF p_start_week IS NOT NULL AND p_end_week IS NOT NULL THEN
                    FOR i IN p_start_week..p_end_week LOOP
                        INSERT INTO public.question_usages (question_id, topic_id, usage_type, curriculum_week)
                        VALUES (new_question_id, p_topic_id, p_usage_type, i);
                    END LOOP;
                ELSE
                    -- Tek bir hafta verildiyse (SmartQuestionAdditionPage'den geliyorsa)
                    INSERT INTO public.question_usages (question_id, topic_id, usage_type, curriculum_week)
                    VALUES (new_question_id, p_topic_id, p_usage_type, p_curriculum_week);
                END IF;
            ELSE
                INSERT INTO public.question_usages (question_id, topic_id, usage_type)
                VALUES (new_question_id, p_topic_id, p_usage_type);
            END IF;

            -- 3. Soru Tiplerine Göre Detayları Ekle
            
            -- Çoktan seçmeli & doğru-yanlış
            IF question_type_text IN ('multiple_choice', 'true_false') THEN
                IF question_type_text = 'true_false' AND NOT (question_data ? 'choices') THEN
                    v_correct_answer := (question_data->>'correct_answer')::BOOLEAN;
                    INSERT INTO public.question_choices (question_id, choice_text, is_correct)
                    VALUES 
                        (new_question_id, 'Doğru', v_correct_answer = TRUE),
                        (new_question_id, 'Yanlış', v_correct_answer = FALSE);
                ELSE
                    FOR choice_data IN SELECT * FROM jsonb_array_elements(question_data->'choices')
                    LOOP
                        INSERT INTO public.question_choices (question_id, choice_text, is_correct)
                        VALUES (new_question_id, choice_data->>'text', (choice_data->>'is_correct')::BOOLEAN);
                    END LOOP;
                END IF;

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

            v_inserted_count := v_inserted_count + 1;

        EXCEPTION WHEN OTHERS THEN
            v_errors := v_errors || jsonb_build_object('error', SQLERRM, 'question', question_data);
        END;
    END LOOP;

    RETURN jsonb_build_object(
        'success', v_errors = '[]'::JSONB,
        'inserted_count', v_inserted_count,
        'errors', v_errors
    );
END;
$$;
