-- Migration: Add solution_text to questions table
ALTER TABLE public.questions ADD COLUMN solution_text text;

COMMENT ON COLUMN public.questions.solution_text IS 'Soru için çözüm açıklaması veya ipuçlarını içerir.';
