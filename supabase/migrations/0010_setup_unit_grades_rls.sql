-- supabase/migrations/0010_setup_unit_grades_rls.sql
--
-- This migration sets up Row Level Security (RLS) policies for the
-- 'unit_grades' table.
--
-- These policies allow users with the 'admin' role to manage all aspects
-- of the table (insert, update, delete), while allowing any authenticated
-- user to read the data. This is crucial for the application's forms to
-- work correctly after the logic was moved from a SECURITY DEFINER RPC
-- into the Dart client code.

-- 1. Enable RLS on 'unit_grades' table if not already enabled.
-- This was likely done in a previous migration, but we ensure it here.
ALTER TABLE public.unit_grades ENABLE ROW LEVEL SECURITY;

-- 2. Clean up any existing policies to ensure a fresh start.
DROP POLICY IF EXISTS "Allow authenticated read access to unit_grades" ON public.unit_grades;
DROP POLICY IF EXISTS "Allow admins to manage unit_grades" ON public.unit_grades;

-- 3. Allow any authenticated user to read from 'unit_grades'.
-- This is necessary for the app to display unit/grade relationships.
CREATE POLICY "Allow authenticated read access to unit_grades"
ON public.unit_grades
FOR SELECT
TO authenticated
USING (true);

-- 4. Allow admin users to perform all operations (INSERT, UPDATE, DELETE).
-- This is the main fix for the error "new row violates row-level security
-- policy for table 'unit_grades'". It grants admin users the necessary
-- permissions to create and manage the links between units and grades.
CREATE POLICY "Allow admins to manage unit_grades"
ON public.unit_grades
FOR ALL
TO authenticated
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin')
WITH CHECK ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- After applying this migration, you can verify in the Supabase Studio
-- under "RLS policies" that these policies have been correctly added
-- to the 'unit_grades' table.
