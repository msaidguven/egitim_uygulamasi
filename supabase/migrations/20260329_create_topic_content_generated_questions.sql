CREATE TABLE IF NOT EXISTS public.topic_content_generated_questions (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  topic_content_v11_id BIGINT NOT NULL REFERENCES public.topic_contents_v11(id) ON DELETE CASCADE,
  question_id BIGINT NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  quiz_ref TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (topic_content_v11_id, question_id),
  UNIQUE (topic_content_v11_id, quiz_ref)
);

CREATE INDEX IF NOT EXISTS idx_tcgq_content_id
  ON public.topic_content_generated_questions (topic_content_v11_id);

CREATE INDEX IF NOT EXISTS idx_tcgq_question_id
  ON public.topic_content_generated_questions (question_id);
