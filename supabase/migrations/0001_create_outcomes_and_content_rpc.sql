-- =================================================================
-- FUNCTION: create_outcomes_and_content
--
-- !! DİKKAT !!
-- BU FONKSİYON, VERİTABANI ŞEMASINDAKİ DEĞİŞİKLİKLERE UYGUN OLARAK
-- GÜNCELLENMİŞTİR. 'outcomes' VE 'topic_contents' TABLOLARINDAKİ
-- 'display_week' SÜTUNU ARTIK KULLANILMAMAKTADIR.
--
-- Bu güncel sürüm, hafta bilgisini doğru olan 'outcome_weeks' ve
-- 'topic_content_weeks' tablolarına kaydeder.
--
-- Lütfen bu değişikliğin veritabanınıza uygulandığından emin olun.
-- =================================================================

create or replace function create_outcomes_and_content(
  p_topic_id bigint,
  p_week integer,
  p_outcomes text[],
  p_contents jsonb
)
returns void
language plpgsql
security definer
as $$
declare
  content_item jsonb;
  outcome_text text;
  new_content_id bigint;
  new_outcome_id bigint;
begin
  -- Topic contents (içerikler) tablosuna ekleme yap
  if p_contents is not null and jsonb_array_length(p_contents) > 0 then
    for content_item in select * from jsonb_array_elements(p_contents) loop
      if content_item->>'title' is null or trim(content_item->>'title') = '' then
        raise exception 'Konu içeriği başlığı boş olamaz: %', content_item;
      end if;

      -- HATA DÜZELTMESİ: 'display_week' sütunu kaldırıldı.
      insert into public.topic_contents (topic_id, title, content, section_type, order_no)
      values (
        p_topic_id,
        content_item->>'title',
        content_item->>'content',
        content_item->>'section_type',
        (content_item->>'order_no')::integer
      ) returning id into new_content_id;

      -- YENİ YÖNTEM: Hafta bilgisi 'topic_content_weeks' tablosuna ekleniyor.
      insert into public.topic_content_weeks (topic_content_id, start_week, end_week)
      values (new_content_id, p_week, p_week);
    end loop;
  end if;

  -- Outcomes (kazanımlar) tablosuna ekleme yap
  if p_outcomes is not null and array_length(p_outcomes, 1) > 0 then
    foreach outcome_text in array p_outcomes
    loop
      -- HATA DÜZELTMESİ: 'display_week' sütunu kaldırıldı.
      insert into public.outcomes (topic_id, description)
      values (p_topic_id, outcome_text)
      returning id into new_outcome_id;

      -- YENİ YÖNTEM: Hafta bilgisi 'outcome_weeks' tablosuna ekleniyor.
      insert into public.outcome_weeks (outcome_id, start_week, end_week)
      values (new_outcome_id, p_week, p_week);
    end loop;
  end if;
end;
$$;
