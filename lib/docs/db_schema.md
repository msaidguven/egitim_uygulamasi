-- supabase db schema --
-- docs/db_schema.md --



-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.grades (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name text NOT NULL,
  order_no integer NOT NULL DEFAULT 0 UNIQUE CHECK (order_no >= 0),
  CONSTRAINT grades_pkey PRIMARY KEY (id)
);
CREATE TABLE public.lesson_grades (
  lesson_id bigint NOT NULL,
  grade_id bigint NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT lesson_grades_pkey PRIMARY KEY (lesson_id, grade_id),
  CONSTRAINT fk_lg_grade FOREIGN KEY (grade_id) REFERENCES public.grades(id),
  CONSTRAINT fk_lg_lesson FOREIGN KEY (lesson_id) REFERENCES public.lessons(id)
);
CREATE TABLE public.lessons (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name text NOT NULL UNIQUE,
  icon text,
  description text,
  order_no integer DEFAULT 0 UNIQUE CHECK (order_no >= 0),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT lessons_pkey PRIMARY KEY (id)
);
CREATE TABLE public.outcomes (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  topic_id bigint NOT NULL,
  description text NOT NULL,
  week_number integer NOT NULL CHECK (week_number >= 1),
  order_index integer DEFAULT 0 CHECK (order_index >= 0),
  CONSTRAINT outcomes_pkey PRIMARY KEY (id),
  CONSTRAINT fk_outcomes_topic FOREIGN KEY (topic_id) REFERENCES public.topics(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  full_name text,
  username text UNIQUE,
  gender text CHECK (gender = ANY (ARRAY['male'::text, 'female'::text, 'other'::text])),
  birth_date date,
  about text,
  role text DEFAULT 'student'::text CHECK (role = ANY (ARRAY['student'::text, 'teacher'::text, 'admin'::text])),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.topic_contents (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  topic_id bigint NOT NULL,
  title text NOT NULL,
  content text NOT NULL,
  section_type text,
  display_week smallint,
  order_no integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT topic_contents_pkey PRIMARY KEY (id),
  CONSTRAINT fk_tc_topic FOREIGN KEY (topic_id) REFERENCES public.topics(id)
);
CREATE TABLE public.topic_videos (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  topic_id bigint NOT NULL,
  title text,
  video_url text NOT NULL,
  order_no integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT topic_videos_pkey PRIMARY KEY (id),
  CONSTRAINT fk_tv_topic FOREIGN KEY (topic_id) REFERENCES public.topics(id)
);
CREATE TABLE public.topics (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  unit_id bigint NOT NULL,
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  order_no integer NOT NULL DEFAULT 0 CHECK (order_no >= 0),
  is_active boolean NOT NULL DEFAULT true,
  order_status text NOT NULL DEFAULT 'approved'::text CHECK (order_status = ANY (ARRAY['approved'::text, 'pending'::text, 'rejected'::text])),
  pending_order_no integer,
  created_at timestamp with time zone DEFAULT now(),
  grade_id bigint,
  CONSTRAINT topics_pkey PRIMARY KEY (id),
  CONSTRAINT topics_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id),
  CONSTRAINT topics_grade_id_fkey FOREIGN KEY (grade_id) REFERENCES public.grades(id)
);
CREATE TABLE public.unit_grades (
  unit_id bigint NOT NULL,
  grade_id bigint NOT NULL,
  CONSTRAINT unit_grades_pkey PRIMARY KEY (unit_id, grade_id),
  CONSTRAINT unit_grades_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id),
  CONSTRAINT unit_grades_grade_id_fkey FOREIGN KEY (grade_id) REFERENCES public.grades(id)
);
CREATE TABLE public.units (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  lesson_id bigint NOT NULL,
  title text NOT NULL,
  description text,
  order_no integer NOT NULL DEFAULT 0 CHECK (order_no >= 0),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT units_pkey PRIMARY KEY (id),
  CONSTRAINT fk_units_lesson FOREIGN KEY (lesson_id) REFERENCES public.lessons(id)
);
CREATE TABLE public.user_progress (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id uuid NOT NULL,
  topic_id bigint NOT NULL,
  completed boolean NOT NULL DEFAULT false,
  completed_at timestamp with time zone,
  progress_percentage integer NOT NULL DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
  last_accessed_at timestamp with time zone DEFAULT now(),
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_progress_pkey PRIMARY KEY (id),
  CONSTRAINT user_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT user_progress_topic_id_fkey FOREIGN KEY (topic_id) REFERENCES public.topics(id)
);