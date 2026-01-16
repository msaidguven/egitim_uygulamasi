-- Migration: 0054_enhance_profiles_table.sql
-- Bu migration, `profiles` tablosunu, hem öğrenciler hem de öğretmenler için
-- daha detaylı ve kullanışlı alanlar içerecek şekilde genişletir.

-- `profiles` tablosuna yeni sütunlar ekle.
-- `IF NOT EXISTS` kullanarak, bu migration'ın tekrar çalıştırılması durumunda hata vermesini önle.
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS grade_id bigint,
  ADD COLUMN IF NOT EXISTS school_name text,
  ADD COLUMN IF NOT EXISTS branch text, -- Öğretmenler için branş
  ADD COLUMN IF NOT EXISTS title text,   -- Öğretmenler için unvan (Prof., Dr., vb.)
  ADD COLUMN IF NOT EXISTS city_id integer,
  ADD COLUMN IF NOT EXISTS district_id bigint;

-- Foreign Key kısıtlamalarını ekle (eğer daha önce eklenmemişse).
-- `grade_id` için `grades` tablosuna referans.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'fk_profiles_grade' AND conrelid = 'public.profiles'::regclass
  ) THEN
    ALTER TABLE public.profiles
    ADD CONSTRAINT fk_profiles_grade FOREIGN KEY (grade_id) REFERENCES public.grades(id) ON DELETE SET NULL;
  END IF;
END;
$$;

-- `city_id` için `cities` tablosuna referans.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'fk_profiles_city' AND conrelid = 'public.profiles'::regclass
  ) THEN
    ALTER TABLE public.profiles
    ADD CONSTRAINT fk_profiles_city FOREIGN KEY (city_id) REFERENCES public.cities(id) ON DELETE SET NULL;
  END IF;
END;
$$;

-- `district_id` için `districts` tablosuna referans.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'fk_profiles_district' AND conrelid = 'public.profiles'::regclass
  ) THEN
    ALTER TABLE public.profiles
    ADD CONSTRAINT fk_profiles_district FOREIGN KEY (district_id) REFERENCES public.districts(id) ON DELETE SET NULL;
  END IF;
END;
$$;
