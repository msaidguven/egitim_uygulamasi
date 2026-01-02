-- supabase/migrations/0011_remove_duplicate_qbo_fk.sql

-- Bu migrasyon, 'questions' ve 'question_blank_options' tabloları arasındaki
-- yinelenen yabancı anahtar (foreign key) ilişkisini kaldırır.
-- 'fk_qbo_question' isimli kısıtlama, 'question_blank_options_question_id_fkey'
-- ile aynı amaca hizmet ettiği için gereksizdir ve PostgREST'in ilişki
-- seçiminde kafa karışıklığına neden olmaktadır.

ALTER TABLE public.question_blank_options
DROP CONSTRAINT IF EXISTS fk_qbo_question;
