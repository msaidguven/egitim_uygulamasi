-- Migration: 0071_create_weekly_question_counts_table.sql
-- Bu migration, her bir hafta/ünite kombinasyonundaki toplam soru sayısını
-- önceden hesaplayıp saklamak için `weekly_question_counts` tablosunu oluşturur.

CREATE TABLE public.weekly_question_counts (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    unit_id bigint NOT NULL REFERENCES public.units(id) ON DELETE CASCADE,
    week_no integer NOT NULL,
    total_questions integer NOT NULL DEFAULT 0,

    -- Her ünite ve hafta için sadece bir toplam soru sayısı kaydı olmasını sağlar.
    CONSTRAINT uq_weekly_question_counts UNIQUE (unit_id, week_no)
);

-- Tablo ve kolonlar hakkında yorumlar ekleyelim.
COMMENT ON TABLE public.weekly_question_counts IS 'Her bir ünite ve hafta kombinasyonu için toplam soru sayısını tutar.';
COMMENT ON COLUMN public.weekly_question_counts.unit_id IS 'Soruların ait olduğu ünitenin ID''si.';
COMMENT ON COLUMN public.weekly_question_counts.week_no IS 'Soruların ait olduğu haftanın numarası.';
COMMENT ON COLUMN public.weekly_question_counts.total_questions IS 'Bu ünite ve hafta kombinasyonundaki toplam soru sayısı.';

-- Bu tablo kişisel veri içermediği için RLS etkinleştirilmeyecektir.
