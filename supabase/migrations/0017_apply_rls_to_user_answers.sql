-- 1. Enable RLS on the user_answers table if it's not already enabled.
ALTER TABLE public.user_answers ENABLE ROW LEVEL SECURITY;

-- 2. Drop the policy if it exists, to ensure a clean state.
DROP POLICY IF EXISTS "Allow users to insert their own answers" ON public.user_answers;

-- 3. Create the policy that allows users to insert their own answers.
-- The WITH CHECK clause ensures that a user can only insert answers for themselves (auth.uid() = user_id).
CREATE POLICY "Allow users to insert their own answers"
ON public.user_answers
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- 4. Also, ensure users can read their own answers, which is needed for fetching results.
DROP POLICY IF EXISTS "Allow users to read their own answers" ON public.user_answers;

CREATE POLICY "Allow users to read their own answers"
ON public.user_answers
FOR SELECT
USING (auth.uid() = user_id);
