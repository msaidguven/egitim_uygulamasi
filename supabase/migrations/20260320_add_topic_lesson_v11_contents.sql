CREATE TABLE IF NOT EXISTS public.topic_lesson_v11_contents (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  topic_id bigint NOT NULL REFERENCES public.topics(id) ON DELETE CASCADE,
  lesson_id bigint NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
  version_no integer NOT NULL DEFAULT 1 CHECK (version_no >= 1),
  title text,
  payload jsonb NOT NULL,
  source text NOT NULL DEFAULT 'lesson_v11_ai',
  is_published boolean NOT NULL DEFAULT false,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  UNIQUE (topic_id, version_no)
);

CREATE INDEX IF NOT EXISTS idx_topic_lesson_v11_contents_topic_id
  ON public.topic_lesson_v11_contents (topic_id);

CREATE INDEX IF NOT EXISTS idx_topic_lesson_v11_contents_lesson_id
  ON public.topic_lesson_v11_contents (lesson_id);

CREATE INDEX IF NOT EXISTS idx_topic_lesson_v11_contents_published
  ON public.topic_lesson_v11_contents (is_published);

CREATE INDEX IF NOT EXISTS idx_topic_lesson_v11_contents_payload_gin
  ON public.topic_lesson_v11_contents USING gin (payload);

CREATE OR REPLACE FUNCTION public.set_topic_lesson_v11_contents_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_topic_lesson_v11_contents_updated_at
  ON public.topic_lesson_v11_contents;

CREATE TRIGGER trg_topic_lesson_v11_contents_updated_at
BEFORE UPDATE ON public.topic_lesson_v11_contents
FOR EACH ROW
EXECUTE FUNCTION public.set_topic_lesson_v11_contents_updated_at();

ALTER TABLE public.topic_lesson_v11_contents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "topic_lesson_v11_contents_public_read"
  ON public.topic_lesson_v11_contents;
DROP POLICY IF EXISTS "topic_lesson_v11_contents_admin_teacher_read"
  ON public.topic_lesson_v11_contents;
DROP POLICY IF EXISTS "topic_lesson_v11_contents_admin_teacher_insert"
  ON public.topic_lesson_v11_contents;
DROP POLICY IF EXISTS "topic_lesson_v11_contents_admin_teacher_update"
  ON public.topic_lesson_v11_contents;
DROP POLICY IF EXISTS "topic_lesson_v11_contents_admin_delete"
  ON public.topic_lesson_v11_contents;

CREATE POLICY "topic_lesson_v11_contents_public_read"
ON public.topic_lesson_v11_contents
FOR SELECT
USING (
  is_published = true
  AND EXISTS (
    SELECT 1
    FROM public.lessons l
    WHERE l.id = topic_lesson_v11_contents.lesson_id
      AND l.is_active = true
  )
);

CREATE POLICY "topic_lesson_v11_contents_admin_teacher_read"
ON public.topic_lesson_v11_contents
FOR SELECT
USING (public.is_admin_or_teacher());

CREATE POLICY "topic_lesson_v11_contents_admin_teacher_insert"
ON public.topic_lesson_v11_contents
FOR INSERT
WITH CHECK (
  public.is_admin_or_teacher()
  AND auth.uid() IS NOT NULL
  AND (created_by IS NULL OR created_by = auth.uid())
);

CREATE POLICY "topic_lesson_v11_contents_admin_teacher_update"
ON public.topic_lesson_v11_contents
FOR UPDATE
USING (public.is_admin_or_teacher())
WITH CHECK (
  public.is_admin_or_teacher()
  AND (created_by IS NULL OR created_by = auth.uid() OR public.is_admin())
);

CREATE POLICY "topic_lesson_v11_contents_admin_delete"
ON public.topic_lesson_v11_contents
FOR DELETE
USING (public.is_admin());
