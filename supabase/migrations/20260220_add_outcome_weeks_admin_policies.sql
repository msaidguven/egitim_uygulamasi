-- Admin policies for outcome_weeks so week ranges can be updated from admin UI.

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.outcome_weeks TO authenticated;

ALTER TABLE public.outcome_weeks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS outcome_weeks_admin_select ON public.outcome_weeks;
CREATE POLICY outcome_weeks_admin_select
ON public.outcome_weeks
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

DROP POLICY IF EXISTS outcome_weeks_admin_insert ON public.outcome_weeks;
CREATE POLICY outcome_weeks_admin_insert
ON public.outcome_weeks
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

DROP POLICY IF EXISTS outcome_weeks_admin_update ON public.outcome_weeks;
CREATE POLICY outcome_weeks_admin_update
ON public.outcome_weeks
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

DROP POLICY IF EXISTS outcome_weeks_admin_delete ON public.outcome_weeks;
CREATE POLICY outcome_weeks_admin_delete
ON public.outcome_weeks
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
