-- Migration: 0069_create_user_weekly_question_progress.sql
-- Bu migration, haftalık testlerdeki bireysel soru ilerlemesini kaydetmek için
-- yeni bir tablo oluşturur ve bu tablo için gerekli RLS politikalarını tanımlar.

-- 1. YENİ TABLOYU OLUŞTURMA
CREATE TABLE public.user_weekly_question_progress (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    unit_id bigint NOT NULL REFERENCES public.units(id) ON DELETE CASCADE,
    week_no integer NOT NULL,
    question_id bigint NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    is_correct boolean NOT NULL,
    answered_at timestamptz NOT NULL DEFAULT now(),

    -- Bir kullanıcının, bir haftanın bir sorusunu sadece bir kez kaydetmesini sağlar.
    CONSTRAINT uq_user_weekly_question_progress UNIQUE (user_id, unit_id, week_no, question_id)
);

-- Tablo ve kolonlar hakkında yorumlar ekleyerek daha anlaşılır hale getirelim.
COMMENT ON TABLE public.user_weekly_question_progress IS 'Kullanıcıların haftalık testlerdeki her bir soruya verdiği cevabı ve sonucunu kaydeder.';
COMMENT ON COLUMN public.user_weekly_question_progress.user_id IS 'Cevabı veren kullanıcının ID''si.';
COMMENT ON COLUMN public.user_weekly_question_progress.unit_id IS 'Sorunun ait olduğu ünitenin ID''si.';
COMMENT ON COLUMN public.user_weekly_question_progress.week_no IS 'Sorunun ait olduğu haftanın numarası.';
COMMENT ON COLUMN public.user_weekly_question_progress.question_id IS 'Cevaplanan sorunun ID''si.';
COMMENT ON COLUMN public.user_weekly_question_progress.is_correct IS 'Verilen cevabın doğru olup olmadığı.';
COMMENT ON COLUMN public.user_weekly_question_progress.answered_at IS 'Cevabın verildiği zaman damgası.';


-- 2. RLS (ROW-LEVEL SECURITY) AYARLARINI YAPMA

-- Tablo için RLS'yi etkinleştir.
ALTER TABLE public.user_weekly_question_progress ENABLE ROW LEVEL SECURITY;

-- Kullanıcıların sadece kendi ilerleme kayıtlarını görmesini sağlayan SELECT politikası.
CREATE POLICY "Allow individual select access"
ON public.user_weekly_question_progress
FOR SELECT
USING (auth.uid() = user_id);

-- Kullanıcıların sadece kendi adlarına yeni ilerleme kaydı eklemesini sağlayan INSERT politikası.
CREATE POLICY "Allow individual insert access"
ON public.user_weekly_question_progress
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Kullanıcıların sadece kendi ilerleme kayıtlarını silmesini sağlayan DELETE politikası (reklamla sıfırlama için).
CREATE POLICY "Allow individual delete access"
ON public.user_weekly_question_progress
FOR DELETE
USING (auth.uid() = user_id);

-- Kullanıcıların sadece kendi ilerleme kayıtlarını güncelleyebilmesini sağlayan UPDATE politikası.
CREATE POLICY "Allow individual update access"
ON public.user_weekly_question_progress
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
