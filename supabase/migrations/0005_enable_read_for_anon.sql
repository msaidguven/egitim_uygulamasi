-- oturum açmamış (unauthenticated) kullanıcıların uygulama içeriğini görebilmesi için bu migrasyonun çalıştırılması gerekmektedir.
-- Oturum açmamış bir kullanıcının `Supabase.instance.client.auth.currentSession` değeri `null` olur.
-- Bu durumda Supabase, veritabanı isteklerini `anon` (anonymous) rolü ile yapar.
-- Bu SQL dosyası, ilgili tablolarda `anon` rolüne okuma (SELECT) izni veren RLS (Row Level Security) kurallarını oluşturur.

-- This migration enables Row Level Security (RLS) for public content tables
-- and creates policies to allow anonymous, unauthenticated users to read them.
-- When a user is not logged in, their session is null, and Supabase uses the 'anon' role.
-- These policies grant the necessary read permissions to that 'anon' role.

-- Enable RLS and create read-only policy for 'grades'
ALTER TABLE public.grades ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read access to grades" ON public.grades;
CREATE POLICY "Allow public read access to grades" ON public.grades FOR SELECT TO anon USING (true);

-- Enable RLS and create read-only policy for 'lessons'
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read access to lessons" ON public.lessons;
CREATE POLICY "Allow public read access to lessons" ON public.lessons FOR SELECT TO anon USING (true);

-- Enable RLS and create read-only policy for 'units'
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read access to units" ON public.units;
CREATE POLICY "Allow public read access to units" ON public.units FOR SELECT TO anon USING (true);

-- Enable RLS and create read-only policy for 'topics'
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read access to topics" ON public.topics;
CREATE POLICY "Allow public read access to topics" ON public.topics FOR SELECT TO anon USING (true);

-- Enable RLS and create read-only policy for 'outcomes'
ALTER TABLE public.outcomes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read access to outcomes" ON public.outcomes;
CREATE POLICY "Allow public read access to outcomes" ON public.outcomes FOR SELECT TO anon USING (true);

-- Enable RLS and create read-only policy for 'topic_contents'
ALTER TABLE public.topic_contents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read access to topic_contents" ON public.topic_contents;
CREATE POLICY "Allow public read access to topic_contents" ON public.topic_contents FOR SELECT TO anon USING (true);

-- Enable RLS and create read-only policy for 'unit_videos'
-- Note: Assuming 'unit_videos' replaced 'topic_videos'
ALTER TABLE public.unit_videos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read access to unit_videos" ON public.unit_videos;
CREATE POLICY "Allow public read access to unit_videos" ON public.unit_videos FOR SELECT TO anon USING (true);

-- Enable RLS and create read-only policy for 'unit_grades' (join table)
ALTER TABLE public.unit_grades ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read access to unit_grades" ON public.unit_grades;
CREATE POLICY "Allow public read access to unit_grades" ON public.unit_grades FOR SELECT TO anon USING (true);

-- Enable RLS and create read-only policy for 'lesson_grades' (join table)
ALTER TABLE public.lesson_grades ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read access to lesson_grades" ON public.lesson_grades;
CREATE POLICY "Allow public read access to lesson_grades" ON public.lesson_grades FOR SELECT TO anon USING (true);
