-- Fix get_questions_details: questions table has no q.correct_answer column.
-- True/False correctness is represented in question_choices.

CREATE OR REPLACE FUNCTION public.get_questions_details(
  p_question_ids bigint[]
)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', q.id,
        'question_text', q.question_text,
        'difficulty', q.difficulty,
        'score', q.score,
        'solution_text', q.solution_text,
        'question_type_id', q.question_type_id,
        'question_type', jsonb_build_object('code', qt.code),
        'question_choices', COALESCE(
          (
            SELECT jsonb_agg(
              jsonb_build_object(
                'id', qc.id,
                'choice_text', qc.choice_text,
                'is_correct', qc.is_correct
              )
              ORDER BY qc.id
            )
            FROM public.question_choices qc
            WHERE qc.question_id = q.id
          ),
          '[]'::jsonb
        ),
        'question_blank_options', COALESCE(
          (
            SELECT jsonb_agg(
              jsonb_build_object(
                'id', qbo.id,
                'question_id', qbo.question_id,
                'option_text', qbo.option_text,
                'is_correct', qbo.is_correct,
                'order_no', qbo.order_no
              )
              ORDER BY qbo.order_no, qbo.id
            )
            FROM public.question_blank_options qbo
            WHERE qbo.question_id = q.id
          ),
          '[]'::jsonb
        ),
        'question_matching_pairs', COALESCE(
          (
            SELECT jsonb_agg(
              jsonb_build_object(
                'id', qmp.id,
                'left_text', qmp.left_text,
                'right_text', qmp.right_text,
                'order_no', qmp.order_no
              )
              ORDER BY qmp.order_no, qmp.id
            )
            FROM public.question_matching_pairs qmp
            WHERE qmp.question_id = q.id
          ),
          '[]'::jsonb
        ),
        'question_classical', COALESCE(
          (
            SELECT jsonb_agg(
              jsonb_build_object('model_answer', qcl.model_answer)
            )
            FROM public.question_classical qcl
            WHERE qcl.question_id = q.id
          ),
          '[]'::jsonb
        )
      )
      ORDER BY array_position(p_question_ids, q.id)
    ),
    '[]'::jsonb
  )
  FROM public.questions q
  JOIN public.question_types qt ON qt.id = q.question_type_id
  WHERE q.id = ANY(p_question_ids);
$$;

-- Compatibility overload for clients sending integer[]
CREATE OR REPLACE FUNCTION public.get_questions_details(
  p_question_ids integer[]
)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
  SELECT public.get_questions_details(
    ARRAY(SELECT x::bigint FROM unnest(p_question_ids) AS x)
  );
$$;
