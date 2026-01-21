-- Migration: Add unique constraints for ON CONFLICT statements

-- 1. Add UNIQUE constraint to user_weekly_question_progress table
-- This fixes the first ON CONFLICT in the finish_weekly_test function.
ALTER TABLE public.user_weekly_question_progress
ADD CONSTRAINT user_weekly_question_progress_unique_key
UNIQUE (user_id, unit_id, curriculum_week, question_id);

-- 2. Create the user_weekly_summary table
-- This table was missing from the schema and is required by the finish_weekly_test function.
-- The PRIMARY KEY constraint will satisfy the second ON CONFLICT.
CREATE TABLE public.user_weekly_summary (
    user_id uuid NOT NULL,
    unit_id bigint NOT NULL,
    curriculum_week integer NOT NULL,
    correct_count integer NOT NULL DEFAULT 0,
    wrong_count integer NOT NULL DEFAULT 0,
    last_updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT user_weekly_summary_pkey PRIMARY KEY (user_id, unit_id, curriculum_week),
    CONSTRAINT user_weekly_summary_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT user_weekly_summary_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id) ON DELETE CASCADE
);