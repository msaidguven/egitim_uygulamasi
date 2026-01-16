-- Migration: 0051_refactor_user_progress_table.sql
-- Bu migration, `user_progress` tablosunu, ilerlemeyi konu bazında değil,
-- HAFTA bazında takip edecek şekilde yeniden yapılandırır.
-- Bu, bir konunun birden fazla haftaya yayıldığı durumları doğru bir şekilde yönetmek için kritik bir değişikliktir.

-- ÖNEMLİ: Bu işlem, mevcut `user_progress` tablosunu silip yeniden oluşturur.
-- Bu, tablodaki tüm mevcut ilerleme verilerinin silinmesine neden olur.

-- 1. Adım: Eski tabloyu ve bağımlılıklarını güvenli bir şekilde sil.
DROP TABLE IF EXISTS public.user_progress;

-- 2. Adım: Yeni ve doğru yapıya sahip tabloyu oluştur.
CREATE TABLE public.user_progress (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id uuid NOT NULL,
  lesson_id bigint NOT NULL, -- 'topic_id' yerine geldi
  grade_id bigint NOT NULL,  -- 'topic_id' yerine geldi
  week_no integer NOT NULL,    -- YENİ SÜTUN
  completed boolean NOT NULL DEFAULT false,
  completed_at timestamp with time zone,
  progress_percentage integer NOT NULL DEFAULT 0,
  last_accessed_at timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),

  -- Kısıtlamalar
  CONSTRAINT user_progress_pkey PRIMARY KEY (id),

  -- Yeni benzersizlik kuralı: Bir kullanıcı, bir derste, bir sınıfta, bir haftayı sadece bir kez takip edebilir.
  CONSTRAINT uq_user_weekly_progress UNIQUE (user_id, lesson_id, grade_id, week_no),

  -- Foreign Key'ler
  CONSTRAINT user_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
  CONSTRAINT user_progress_lesson_id_fkey FOREIGN KEY (lesson_id) REFERENCES public.lessons(id) ON DELETE CASCADE,
  CONSTRAINT user_progress_grade_id_fkey FOREIGN KEY (grade_id) REFERENCES public.grades(id) ON DELETE CASCADE,

  -- Mantıksal Bütünlük Kuralları (Mevcut şemadan korundu)
  CONSTRAINT user_progress_week_no_check CHECK (week_no >= 1),
  CONSTRAINT user_progress_progress_percentage_check CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
  CONSTRAINT user_progress_completed_check CHECK (
    (completed = false AND completed_at IS NULL) OR
    (completed = true AND completed_at IS NOT NULL)
  ),
  CONSTRAINT chk_progress_completed CHECK (
    (completed = true AND progress_percentage = 100) OR
    (completed = false AND progress_percentage < 100)
  )
);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON public.user_progress USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_lesson_grade_week ON public.user_progress USING btree (lesson_id, grade_id, week_no);
