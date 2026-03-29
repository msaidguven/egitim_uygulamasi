-- Fix permission denied on curriculum_week_question_counts during
-- question_usages delete/insert trigger updates.

GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE public.curriculum_week_question_counts
TO authenticated;

ALTER TABLE public.curriculum_week_question_counts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cwqc_admin_insert ON public.curriculum_week_question_counts;
CREATE POLICY cwqc_admin_insert
ON public.curriculum_week_question_counts
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
  )
);

DROP POLICY IF EXISTS cwqc_admin_update ON public.curriculum_week_question_counts;
CREATE POLICY cwqc_admin_update
ON public.curriculum_week_question_counts
FOR UPDATE
TO authenticated
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

DROP POLICY IF EXISTS cwqc_admin_select ON public.curriculum_week_question_counts;
CREATE POLICY cwqc_admin_select
ON public.curriculum_week_question_counts
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
  )
);
