-- supabase/migrations/0009_fix_question_blanks_relation.sql

-- Bu migrasyon, 'questions' ve 'question_blank_options' tabloları arasındaki
-- ilişkiyi yeniden kurarak PostgREST şema önbelleği sorununu çözmeyi amaçlamaktadır.

-- Adım 1: Mevcut olabilecek hatalı veya eski ilişkiyi kaldır.
-- Bu komut, eğer ilişki yoksa hata verebilir, bu normaldir ve göz ardı edilebilir.
-- Supabase UI üzerinden çalıştırırken "Continue on error" seçeneğini kullanabilirsiniz.
ALTER TABLE public.question_blank_options
DROP CONSTRAINT IF EXISTS question_blank_options_question_id_fkey;

-- Adım 2: Doğru yabancı anahtar (foreign key) ilişkisini yeniden oluştur.
-- Bu, 'question_blank_options' tablosundaki 'question_id' sütununun,
-- 'questions' tablosundaki 'id' sütununa başvurduğunu ve bir soru silindiğinde
-- ilgili tüm boşluk doldurma seçeneklerinin de silinmesi gerektiğini (ON DELETE CASCADE) belirtir.
ALTER TABLE public.question_blank_options
ADD CONSTRAINT question_blank_options_question_id_fkey
FOREIGN KEY (question_id)
REFERENCES public.questions (id)
ON DELETE CASCADE;

-- Adım 3: Supabase'in bu ilişkiyi tanıdığından emin olmak için bir yorum ekleyelim.
-- PostgREST, bu tür meta verileri şemayı yeniden oluştururken kullanabilir.
COMMENT ON CONSTRAINT question_blank_options_question_id_fkey ON public.question_blank_options IS 'Relates blank options to a specific question.';
