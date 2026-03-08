-- =============================================================
-- LESSON ENGINE + RLS (SCHEMA + POLICIES)
-- =============================================================
-- Bu dosya sadece mevcut tabloların RLS'ini değil, aynı zamanda
-- JSON tabanlı yeni ders içerik tablosunu da oluşturur.
-- =============================================================

-- =============================================================
-- HELPER FUNCTIONS
-- =============================================================
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.is_admin_or_teacher()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  );
$$;

-- =============================================================
-- LESSON ENGINE TABLE (JSON PAYLOAD)
-- =============================================================
CREATE TABLE IF NOT EXISTS public.lesson_contents (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  lesson_id bigint NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
  version_no integer NOT NULL DEFAULT 1 CHECK (version_no >= 1),
  title text,
  payload jsonb NOT NULL,
  source text NOT NULL DEFAULT 'json_import',
  is_published boolean NOT NULL DEFAULT false,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  UNIQUE (lesson_id, version_no)
);

CREATE INDEX IF NOT EXISTS idx_lesson_contents_lesson_id
  ON public.lesson_contents (lesson_id);

CREATE INDEX IF NOT EXISTS idx_lesson_contents_published
  ON public.lesson_contents (is_published);

CREATE INDEX IF NOT EXISTS idx_lesson_contents_payload_gin
  ON public.lesson_contents USING gin (payload);

ALTER TABLE public.lesson_contents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "lesson_contents_public_read"          ON public.lesson_contents;
DROP POLICY IF EXISTS "lesson_contents_admin_teacher_read"   ON public.lesson_contents;
DROP POLICY IF EXISTS "lesson_contents_admin_teacher_insert" ON public.lesson_contents;
DROP POLICY IF EXISTS "lesson_contents_admin_teacher_update" ON public.lesson_contents;
DROP POLICY IF EXISTS "lesson_contents_admin_teacher_delete" ON public.lesson_contents;

-- Öğrenci/anon: sadece yayınlanmış içerik + aktif ders
CREATE POLICY "lesson_contents_public_read" ON public.lesson_contents
  FOR SELECT USING (
    is_published = true
    AND EXISTS (
      SELECT 1
      FROM public.lessons l
      WHERE l.id = lesson_contents.lesson_id
        AND l.is_active = true
    )
  );

-- Admin/teacher: tüm içerikleri görebilir
CREATE POLICY "lesson_contents_admin_teacher_read" ON public.lesson_contents
  FOR SELECT USING (public.is_admin_or_teacher());

-- Admin/teacher: içerik ekleyebilir
CREATE POLICY "lesson_contents_admin_teacher_insert" ON public.lesson_contents
  FOR INSERT WITH CHECK (
    public.is_admin_or_teacher()
    AND auth.uid() IS NOT NULL
    AND (created_by IS NULL OR created_by = auth.uid())
  );

-- Admin/teacher: içerik güncelleyebilir
CREATE POLICY "lesson_contents_admin_teacher_update" ON public.lesson_contents
  FOR UPDATE USING (public.is_admin_or_teacher())
  WITH CHECK (
    public.is_admin_or_teacher()
    AND (created_by IS NULL OR created_by = auth.uid() OR public.is_admin())
  );

-- Silme sadece admin
CREATE POLICY "lesson_contents_admin_teacher_delete" ON public.lesson_contents
  FOR DELETE USING (public.is_admin());

-- =============================================================
-- 1) LESSONS
-- columns in 0001: id, name, icon, description, order_no, created_at,
--                  is_active, slug
-- =============================================================
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "lessons_public_read"          ON public.lessons;
DROP POLICY IF EXISTS "lessons_admin_write"          ON public.lessons;
DROP POLICY IF EXISTS "lessons_admin_teacher_insert" ON public.lessons;
DROP POLICY IF EXISTS "lessons_admin_teacher_update" ON public.lessons;
DROP POLICY IF EXISTS "lessons_admin_teacher_delete" ON public.lessons;

-- Everyone (including anon) can read active lessons
CREATE POLICY "lessons_public_read" ON public.lessons
  FOR SELECT USING (is_active = true);

-- Teacher/Admin can insert/update
CREATE POLICY "lessons_admin_teacher_insert" ON public.lessons
  FOR INSERT WITH CHECK (public.is_admin_or_teacher());

CREATE POLICY "lessons_admin_teacher_update" ON public.lessons
  FOR UPDATE USING (public.is_admin_or_teacher())
  WITH CHECK (public.is_admin_or_teacher());

-- Delete only admin
CREATE POLICY "lessons_admin_teacher_delete" ON public.lessons
  FOR DELETE USING (public.is_admin());

-- =============================================================
-- 2) GRADES
-- =============================================================
ALTER TABLE public.grades ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "grades_public_read"   ON public.grades;
DROP POLICY IF EXISTS "grades_admin_insert"  ON public.grades;
DROP POLICY IF EXISTS "grades_admin_update"  ON public.grades;
DROP POLICY IF EXISTS "grades_admin_delete"  ON public.grades;

CREATE POLICY "grades_public_read" ON public.grades
  FOR SELECT USING (is_active = true);

CREATE POLICY "grades_admin_insert" ON public.grades
  FOR INSERT WITH CHECK (public.is_admin());

CREATE POLICY "grades_admin_update" ON public.grades
  FOR UPDATE USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "grades_admin_delete" ON public.grades
  FOR DELETE USING (public.is_admin());

-- =============================================================
-- 3) LESSON_GRADES
-- =============================================================
ALTER TABLE public.lesson_grades ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "lesson_grades_public_read"   ON public.lesson_grades;
DROP POLICY IF EXISTS "lesson_grades_admin_insert"  ON public.lesson_grades;
DROP POLICY IF EXISTS "lesson_grades_admin_update"  ON public.lesson_grades;
DROP POLICY IF EXISTS "lesson_grades_admin_delete"  ON public.lesson_grades;

CREATE POLICY "lesson_grades_public_read" ON public.lesson_grades
  FOR SELECT USING (is_active = true);

CREATE POLICY "lesson_grades_admin_insert" ON public.lesson_grades
  FOR INSERT WITH CHECK (public.is_admin_or_teacher());

CREATE POLICY "lesson_grades_admin_update" ON public.lesson_grades
  FOR UPDATE USING (public.is_admin_or_teacher())
  WITH CHECK (public.is_admin_or_teacher());

CREATE POLICY "lesson_grades_admin_delete" ON public.lesson_grades
  FOR DELETE USING (public.is_admin());

-- =============================================================
-- 4) PROFILES
-- NOTE: parent_id does not exist in 0001 schema, so parent policy removed.
-- =============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_own_read"    ON public.profiles;
DROP POLICY IF EXISTS "profiles_own_insert"  ON public.profiles;
DROP POLICY IF EXISTS "profiles_own_update"  ON public.profiles;
DROP POLICY IF EXISTS "profiles_parent_read" ON public.profiles;
DROP POLICY IF EXISTS "profiles_admin_all"   ON public.profiles;

CREATE POLICY "profiles_own_read" ON public.profiles
  FOR SELECT USING (id = auth.uid());

CREATE POLICY "profiles_own_insert" ON public.profiles
  FOR INSERT WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_own_update" ON public.profiles
  FOR UPDATE USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_admin_all" ON public.profiles
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- =============================================================
-- 5) TEST_SESSIONS
-- =============================================================
ALTER TABLE public.test_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "test_sessions_own_select" ON public.test_sessions;
DROP POLICY IF EXISTS "test_sessions_own_insert" ON public.test_sessions;
DROP POLICY IF EXISTS "test_sessions_own_update" ON public.test_sessions;
DROP POLICY IF EXISTS "test_sessions_admin_read" ON public.test_sessions;

CREATE POLICY "test_sessions_own_select" ON public.test_sessions
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "test_sessions_own_insert" ON public.test_sessions
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "test_sessions_own_update" ON public.test_sessions
  FOR UPDATE USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "test_sessions_admin_read" ON public.test_sessions
  FOR SELECT USING (public.is_admin_or_teacher());

-- =============================================================
-- 6) TEST_SESSION_QUESTIONS
-- =============================================================
ALTER TABLE public.test_session_questions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "tsq_own_select" ON public.test_session_questions;
DROP POLICY IF EXISTS "tsq_admin_all"  ON public.test_session_questions;

-- Student can read questions only for own sessions
CREATE POLICY "tsq_own_select" ON public.test_session_questions
  FOR SELECT USING (
    EXISTS (
      SELECT 1
      FROM public.test_sessions ts
      WHERE ts.id = test_session_questions.test_session_id
        AND ts.user_id = auth.uid()
    )
  );

-- Admin/Teacher can read/write
CREATE POLICY "tsq_admin_all" ON public.test_session_questions
  FOR ALL USING (public.is_admin_or_teacher())
  WITH CHECK (public.is_admin_or_teacher());

-- =============================================================
-- 7) TEST_SESSION_ANSWERS
-- =============================================================
ALTER TABLE public.test_session_answers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "tsa_own_select" ON public.test_session_answers;
DROP POLICY IF EXISTS "tsa_own_insert" ON public.test_session_answers;
DROP POLICY IF EXISTS "tsa_own_update" ON public.test_session_answers;
DROP POLICY IF EXISTS "tsa_admin_read" ON public.test_session_answers;

-- Student can read only own answers
CREATE POLICY "tsa_own_select" ON public.test_session_answers
  FOR SELECT USING (user_id = auth.uid());

-- Student can insert only own answers
CREATE POLICY "tsa_own_insert" ON public.test_session_answers
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Student can update only own answers
CREATE POLICY "tsa_own_update" ON public.test_session_answers
  FOR UPDATE USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Admin/Teacher can read all answers
CREATE POLICY "tsa_admin_read" ON public.test_session_answers
  FOR SELECT USING (public.is_admin_or_teacher());

-- =============================================================
-- ACCESS SUMMARY (current schema)
-- lessons                : anon read(active), teacher/admin write
-- grades                 : anon read(active), admin write
-- lesson_grades          : anon read(active), teacher/admin write (delete admin)
-- profiles               : own read/write, admin all
-- test_sessions          : own read/write, teacher/admin read
-- test_session_questions : own session read, teacher/admin all
-- test_session_answers   : own read/write, teacher/admin read
-- =============================================================
