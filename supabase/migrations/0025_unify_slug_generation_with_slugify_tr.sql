-- Unify slug generation to a single source of truth: public.slugify_tr(text)
-- and remove legacy slug triggers that append numeric suffixes.

-- Backward-compatible wrapper for legacy calls.
CREATE OR REPLACE FUNCTION public.generate_slug_tr(p_title text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT public.slugify_tr(p_title);
$$;

-- Drop legacy BEFORE INSERT/UPDATE row-level triggers on units/topics that
-- explicitly write NEW.slug (likely old suffix-appending behavior).
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT
      n.nspname AS schema_name,
      c.relname AS table_name,
      t.tgname AS trigger_name
    FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_proc p ON p.oid = t.tgfoid
    WHERE NOT t.tgisinternal
      AND n.nspname = 'public'
      AND c.relname IN ('units', 'topics')
      AND (t.tgtype & 2) = 2 -- BEFORE
      AND (t.tgtype & 1) = 1 -- FOR EACH ROW
      AND ((t.tgtype & 4) = 4 OR (t.tgtype & 16) = 16) -- INSERT or UPDATE
      AND pg_get_functiondef(p.oid) ILIKE '%new.slug%'
  LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS %I ON %I.%I',
      r.trigger_name,
      r.schema_name,
      r.table_name
    );
  END LOOP;
END
$$;

CREATE OR REPLACE FUNCTION public.trg_set_slug_from_title()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.slug := public.slugify_tr(NEW.title);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_units_set_slug_from_title ON public.units;
CREATE TRIGGER trg_units_set_slug_from_title
BEFORE INSERT OR UPDATE OF title
ON public.units
FOR EACH ROW
EXECUTE FUNCTION public.trg_set_slug_from_title();

DROP TRIGGER IF EXISTS trg_topics_set_slug_from_title ON public.topics;
CREATE TRIGGER trg_topics_set_slug_from_title
BEFORE INSERT OR UPDATE OF title
ON public.topics
FOR EACH ROW
EXECUTE FUNCTION public.trg_set_slug_from_title();

-- Re-normalize existing data with the canonical function.
UPDATE public.units
SET slug = public.slugify_tr(title)
WHERE title IS NOT NULL
  AND slug IS DISTINCT FROM public.slugify_tr(title);

UPDATE public.topics
SET slug = public.slugify_tr(title)
WHERE title IS NOT NULL
  AND slug IS DISTINCT FROM public.slugify_tr(title);
