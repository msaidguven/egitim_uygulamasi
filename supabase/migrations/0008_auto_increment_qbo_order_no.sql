-- This file creates a function and a trigger to automatically set the
-- 'order_no' when a new option is inserted into 'question_blank_options'.

-- Step 1: Create the function that calculates the next order_no.
CREATE OR REPLACE FUNCTION public.set_qbo_order_no()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Find the maximum order_no for the specific question_blank_id being inserted,
  -- add 1 to it, and assign it to the new row's order_no.
  -- COALESCE is used to handle the case where it's the very first option,
  -- in which case MAX(order_no) would be NULL. We start from 0.
  SELECT COALESCE(MAX(order_no), -1) + 1
  INTO NEW.order_no
  FROM public.question_blank_options
  WHERE question_blank_id = NEW.question_blank_id;

  RETURN NEW;
END;
$$;

-- Step 2: Create the trigger that calls the function before every insert.
-- We use "DROP TRIGGER IF EXISTS" to make this script idempotent (runnable multiple times).
DROP TRIGGER IF EXISTS trg_set_qbo_order_no ON public.question_blank_options;

CREATE TRIGGER trg_set_qbo_order_no
BEFORE INSERT ON public.question_blank_options
FOR EACH ROW
EXECUTE FUNCTION public.set_qbo_order_no();
