-- SRS: Kullanıcı için tekrar zamanı gelen / uygun soruların sayısını getirir
-- Mantık start_srs_test_session ile aynı olacak şekilde tasarlandı.

CREATE OR REPLACE FUNCTION public.get_srs_due_count(
    p_user_id UUID,
    p_unit_id BIGINT DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_grade_id BIGINT;
    v_count INTEGER;
BEGIN
    -- 0. Güvenlik Kontrolü: Kullanıcının sadece kendi verisini sorgulayabildiğinden emin ol
    IF p_user_id IS NULL OR p_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Access Denied: Authentication required.';
    END IF;

    -- 1. Grade bilgisini belirle
    IF p_unit_id IS NOT NULL AND p_unit_id > 0 THEN
        -- Ünite bazlı ise o ünitenin grade_id'sini al
        SELECT ug.grade_id INTO v_grade_id
        FROM public.unit_grades ug
        WHERE ug.unit_id = p_unit_id
        LIMIT 1;
    ELSE
        -- Global ise kullanıcının profilindeki grade_id'yi al
        SELECT grade_id INTO v_grade_id
        FROM public.profiles
        WHERE id = p_user_id;
    END IF;

    -- Eğer grade_id bulunamazsa 0 dön
    IF v_grade_id IS NULL THEN
        RETURN 0;
    END IF;

    -- 2. Sayımı yap
    SELECT COUNT(*)::INTEGER INTO v_count
    FROM public.user_question_stats AS uqs
    WHERE
        uqs.user_id = p_user_id
        AND uqs.grade_id = v_grade_id
        AND uqs.total_attempts > 0 -- Sadece daha önce çözülmüş sorular
        AND uqs.next_review_at <= NOW() -- Tekrar zamanı gelmiş olanlar
        AND (p_unit_id IS NULL OR p_unit_id = 0 OR EXISTS (
            -- Ünite bazlı filtreleme gerekiyorsa
            SELECT 1 FROM public.question_usages qu
            JOIN public.topics t ON qu.topic_id = t.id
            WHERE qu.question_id = uqs.question_id
            AND t.unit_id = p_unit_id
        ));

    RETURN COALESCE(v_count, 0);
END;
$$;

-- İzinleri tanımla
GRANT EXECUTE ON FUNCTION public.get_srs_due_count(UUID, BIGINT) TO authenticated;
-- Anonim erişim güvenliği için kapatıldı
REVOKE EXECUTE ON FUNCTION public.get_srs_due_count(UUID, BIGINT) FROM anon;
