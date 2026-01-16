-- Belirli bir konunun hangi haftalarda işlendiğini ve ilgili kazanımlarını getiren fonksiyon.
CREATE OR REPLACE FUNCTION get_weeks_for_topic(p_topic_id bigint)
RETURNS TABLE (
    id bigint,
    start_week integer,
    outcome_id bigint
)
LANGUAGE sql
STABLE
AS $$
    -- Bu sorgu, hem içeriklerin hem de soruların kullanıldığı haftaları birleştirir
    -- ve her hafta için bir kayıt döndürür.
    -- DISTINCT ON (week) kullanarak her hafta için sadece bir satır alırız.
    SELECT DISTINCT ON (week)
        -- Haftalık içeriğin ID'sini veya birincil anahtar olarak haftanın kendisini kullanabiliriz.
        -- Şimdilik, basitlik adına, haftanın kendisini bir ID gibi döndürelim.
        -- Gerçek bir 'weekly_outcomes' tablonuz varsa, onun ID'si (id) daha doğru olur.
        week AS id,
        week AS start_week,
        -- Bu kısım, haftalık kazanımları tutan ayrı bir tablonuz varsa doldurulabilir.
        -- Şimdilik null bırakıyoruz.
        NULL::bigint AS outcome_id
    FROM (
        -- Konu içeriklerinin haftaları
        SELECT tc.week
        FROM topic_content_weeks tc
        JOIN topic_contents tcs ON tc.topic_content_id = tcs.id
        WHERE tcs.topic_id = p_topic_id

        UNION

        -- Soruların kullanıldığı haftalar
        SELECT qu.display_week AS week
        FROM question_usages qu
        WHERE qu.topic_id = p_topic_id AND qu.usage_type = 'weekly'
    ) AS all_weeks
    WHERE week IS NOT NULL
    ORDER BY week;
$$;