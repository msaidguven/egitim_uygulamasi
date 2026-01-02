-- This function takes an array of unit IDs in their desired order
-- and updates the 'order_no' for each unit sequentially.
-- This version first sets temporary, large positive values to avoid both
-- unique and check constraint violations.
CREATE OR REPLACE FUNCTION update_unit_order(
    p_unit_ids INT[]
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    array_len INT;
    i INT;
BEGIN
    array_len := array_length(p_unit_ids, 1);

    -- Step 1: Set a temporary, non-conflicting POSITIVE order_no
    -- by adding the total length of the array to the current order.
    -- This avoids the CHECK constraint (>= 0) and the UNIQUE constraint.
    FOR i IN 1..array_len
    LOOP
        UPDATE public.units
        SET order_no = order_no + array_len
        WHERE id = p_unit_ids[i];
    END LOOP;

    -- Step 2: Set the final, correct order_no.
    FOR i IN 1..array_len
    LOOP
        UPDATE public.units
        SET order_no = i - 1 -- 0-indexed
        WHERE id = p_unit_ids[i];
    END LOOP;
END;
$$;
