-- Dynamic special week events for breaks, social activity and custom content.

CREATE TABLE IF NOT EXISTS public.special_week_events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  grade_id bigint REFERENCES public.grades(id) ON DELETE CASCADE,
  lesson_id bigint REFERENCES public.lessons(id) ON DELETE CASCADE,
  curriculum_week integer NOT NULL CHECK (curriculum_week >= 1 AND curriculum_week <= 52),
  event_type text NOT NULL CHECK (event_type IN ('special_content', 'break', 'social_activity')),
  title text NOT NULL,
  subtitle text,
  content_html text,
  is_active boolean NOT NULL DEFAULT true,
  priority integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  -- lesson scope cannot exist without grade scope
  CONSTRAINT special_week_events_scope_ck
    CHECK (lesson_id IS NULL OR grade_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_special_week_events_scope
  ON public.special_week_events (grade_id, lesson_id, curriculum_week, event_type);

CREATE INDEX IF NOT EXISTS idx_special_week_events_active_week
  ON public.special_week_events (is_active, curriculum_week);

-- Prevent accidental active duplicates in the same scope/week/type/title.
CREATE UNIQUE INDEX IF NOT EXISTS ux_special_week_events_active_scope
  ON public.special_week_events (
    coalesce(grade_id, 0),
    coalesce(lesson_id, 0),
    curriculum_week,
    event_type,
    lower(title),
    lower(coalesce(subtitle, ''))
  )
  WHERE is_active = true;

-- Keep updated_at current on updates.
CREATE OR REPLACE FUNCTION public.touch_special_week_events_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_special_week_events_updated_at ON public.special_week_events;
CREATE TRIGGER trg_touch_special_week_events_updated_at
BEFORE UPDATE ON public.special_week_events
FOR EACH ROW
EXECUTE FUNCTION public.touch_special_week_events_updated_at();

ALTER TABLE public.special_week_events ENABLE ROW LEVEL SECURITY;

-- Everyone can read active events (needed by student app screens).
DROP POLICY IF EXISTS special_week_events_read_active ON public.special_week_events;
CREATE POLICY special_week_events_read_active
ON public.special_week_events
FOR SELECT
USING (is_active = true);

-- Only admins can manage events.
DROP POLICY IF EXISTS special_week_events_admin_insert ON public.special_week_events;
CREATE POLICY special_week_events_admin_insert
ON public.special_week_events
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
  )
);

DROP POLICY IF EXISTS special_week_events_admin_update ON public.special_week_events;
CREATE POLICY special_week_events_admin_update
ON public.special_week_events
FOR UPDATE
USING (
  EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
  )
);

DROP POLICY IF EXISTS special_week_events_admin_delete ON public.special_week_events;
CREATE POLICY special_week_events_admin_delete
ON public.special_week_events
FOR DELETE
USING (
  EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
  )
);
