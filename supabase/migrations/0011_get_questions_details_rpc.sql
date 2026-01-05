-- Bu RPC, bir soruya ait tüm ilişkili verileri tek bir JSON nesnesinde birleştirir.
-- DÜZELTME: Artık var olmayan 'correct_answer' sütunu kaldırıldı.

-- Önce mevcut fonksiyonu sil (yapısı değiştiği için)
DROP FUNCTION IF EXISTS public.get_question_details(bigint);

-- Fonksiyonu güncel haliyle yeniden oluştur
CREATE OR REPLACE FUNCTION public.get_question_details(p_question_id bigint)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
  SELECT
    jsonb_build_object(
      'id', q.id,
      'question_text', q.question_text,
      'difficulty', q.difficulty,
      'score', q.score,
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
          )
          FROM public.question_choices qc WHERE qc.question_id = q.id
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
          )
          FROM public.question_blank_options qbo WHERE qbo.question_id = q.id
        ),
        '[]'::jsonb
      ),
      'question_matching_pairs', COALESCE(
        (
          SELECT jsonb_agg(
            jsonb_build_object(
              'id', qmp.id,
              'left_text', qmp.left_text,
              'right_text', qmp.right_text
            )
          )
          FROM public.question_matching_pairs qmp WHERE qmp.question_id = q.id
        ),
        '[]'::jsonb
      ),
      'question_classical', COALESCE(
        (
          SELECT jsonb_agg(
            jsonb_build_object('model_answer', qcl.model_answer)
          )
          FROM public.question_classical qcl WHERE qcl.question_id = q.id
        ),
        '[]'::jsonb
      )
    )
  FROM
    public.questions q
  JOIN
    public.question_types qt ON q.question_type_id = qt.id
  WHERE
    q.id = p_question_id;
$$;
