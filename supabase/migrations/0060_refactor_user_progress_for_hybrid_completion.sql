-- Migration: 0060_refactor_user_progress_for_hybrid_completion.sql
-- Bu migration, `user_progress` tablosunu, hem kullanıcının "bitirme niyetini" (beyanını)
-- hem de sistemin "otomatik değerlendirmesini" ayrı ayrı tutacak hibrit bir yapıya kavuşturur.

-- ÖNEMLİ: Bu işlem, mevcut `user_progress` tablosunu silip yeniden oluşturur.
-- Bu, tablodaki tüm mevcut ilerleme verilerinin silinmesine neden olur.

-- 1. Adım: Eski tabloyu ve bağımlılıklarını güvenli bir şekilde sil.
DROP TABLE IF EXISTS public.user_progress;

-- 2. Adım: Yeni ve hibrit yapıya sahip tabloyu oluştur.
CREATE TABLE public.user_progress (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id uuid NOT NULL,
  lesson_id bigint NOT NULL,
  grade_id bigint NOT NULL,
  week_no integer NOT NULL,

  -- Kullanıcının Beyanı
  declared_completed_at timestamp with time zone, -- Kullanıcının "Tamamladım" butonuna bastığı zaman.

  -- Sistemin Otomatik Değerlendirmesi
  progress_percentage integer NOT NULL DEFAULT 0,   -- O haftaki soruların yüzde kaçının çözüldüğü.
  success_rate numeric(5, 2) NOT NULL DEFAULT 0.00, -- Çözülen sorulardaki başarı oranı.
  system_completed boolean NOT NULL DEFAULT false,    -- Sistemin, koşullara göre haftayı tamamlanmış kabul edip etmediği.
  system_completed_at timestamp with time zone,     -- Sistemin haftayı tamamlanmış kabul ettiği zaman.

  -- Standart Sütunlar
  last_accessed_at timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),

  -- Kısıtlamalar
  CONSTRAINT user_progress_pkey PRIMARY KEY (id),
  CONSTRAINT uq_user_weekly_progress UNIQUE (user_id, lesson_id, grade_id, week_no),

  -- Foreign Key'ler
  CONSTRAINT user_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
  CONSTRAINT user_progress_lesson_id_fkey FOREIGN KEY (lesson_id) REFERENCES public.lessons(id) ON DELETE CASCADE,
  CONSTRAINT user_progress_grade_id_fkey FOREIGN KEY (grade_id) REFERENCES public.grades(id) ON DELETE CASCADE,

  -- Mantıksal Bütünlük Kuralları
  CONSTRAINT user_progress_week_no_check CHECK (week_no >= 1),
  CONSTRAINT user_progress_progress_percentage_check CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
  CONSTRAINT user_progress_success_rate_check CHECK (success_rate >= 0.00 AND success_rate <= 100.00),
  CONSTRAINT user_progress_system_completed_check CHECK (
    (system_completed = false AND system_completed_at IS NULL) OR
    (system_completed = true AND system_completed_at IS NOT NULL)
  )
);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON public.user_progress USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_keys ON public.user_progress USING btree (lesson_id, grade_id, week_no);
