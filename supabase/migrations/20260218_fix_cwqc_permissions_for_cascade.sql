-- Fix permission issues while deleting units with ON DELETE CASCADE.
-- Cascading delete may still fail if the acting role cannot delete from
-- curriculum_week_question_counts.

GRANT SELECT, DELETE ON TABLE public.curriculum_week_question_counts TO authenticated;

ALTER TABLE public.curriculum_week_question_counts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cwqc_admin_delete ON public.curriculum_week_question_counts;
CREATE POLICY cwqc_admin_delete
ON public.curriculum_week_question_counts
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
  )
);
