-- Ensure curriculum_week_question_counts rows are deleted automatically
-- when the parent unit is deleted.

ALTER TABLE public.curriculum_week_question_counts
DROP CONSTRAINT IF EXISTS weekly_question_counts_unit_id_fkey;

ALTER TABLE public.curriculum_week_question_counts
ADD CONSTRAINT weekly_question_counts_unit_id_fkey
FOREIGN KEY (unit_id)
REFERENCES public.units(id)
ON DELETE CASCADE;
