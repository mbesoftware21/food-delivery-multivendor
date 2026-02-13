-- ============================================
-- MANUAL ORDER ENTRY FUNCTION
-- ============================================

-- Sequence for human-readable order IDs (e.g., ORD-20240209-0001)
CREATE SEQUENCE IF NOT EXISTS order_id_seq;

CREATE OR REPLACE FUNCTION place_manual_order(
    arg_user_id UUID,
    arg_restaurant_id UUID,
    arg_items JSONB, -- Array of {food_id, quantity, unit_price, title, total_price, addons: [{addon_id, title, price}]}
    arg_delivery_address JSONB,
    arg_payment_method TEXT,
    arg_delivery_charges DECIMAL,
    arg_tax_amount DECIMAL,
    arg_total_amount DECIMAL,
    arg_order_amount DECIMAL,
    arg_special_instructions TEXT DEFAULT NULL
) RETURNS SETOF orders AS $$
DECLARE
    new_order_id UUID;
    human_order_id TEXT;
    item_record JSONB;
    addon_record JSONB;
    new_order_item_id UUID;
BEGIN
    -- Generate human readable ID: ORD-YYYYMMDD-XXXX
    human_order_id := 'ORD-' || to_char(NOW(), 'YYYYMMDD') || '-' || LPAD(nextval('order_id_seq')::text, 4, '0');

    -- Insert into orders
    INSERT INTO orders (
        order_id,
        user_id,
        restaurant_id,
        status,
        delivery_address,
        order_amount,
        delivery_charges,
        tax_amount,
        total_amount,
        payment_method,
        payment_status,
        special_instructions,
        order_date
    ) VALUES (
        human_order_id,
        arg_user_id,
        arg_restaurant_id,
        'PENDING',
        arg_delivery_address,
        arg_order_amount,
        arg_delivery_charges,
        arg_tax_amount,
        arg_total_amount,
        arg_payment_method,
        'PENDING',
        arg_special_instructions,
        NOW()
    ) RETURNING id INTO new_order_id;

    -- Insert into order_items
    FOR item_record IN SELECT * FROM jsonb_array_elements(arg_items)
    LOOP
        INSERT INTO order_items (
            order_id,
            food_id,
            title,
            quantity,
            unit_price,
            total_price,
            special_instructions
        ) VALUES (
            new_order_id,
            (item_record->>'food_id')::UUID,
            item_record->>'title',
            (item_record->>'quantity')::INTEGER,
            (item_record->>'unit_price')::DECIMAL,
            (item_record->>'total_price')::DECIMAL,
            item_record->>'special_instructions'
        ) RETURNING id INTO new_order_item_id;

        -- Insert addons if any
        IF item_record ? 'addons' AND item_record->'addons' IS NOT NULL AND jsonb_array_length(item_record->'addons') > 0 THEN
            FOR addon_record IN SELECT * FROM jsonb_array_elements(item_record->'addons')
            LOOP
                INSERT INTO order_addons (
                    order_item_id,
                    addon_id,
                    title,
                    price
                ) VALUES (
                    new_order_item_id,
                    (addon_record->>'addon_id')::UUID,
                    addon_record->>'title',
                    (addon_record->>'price')::DECIMAL
                );
            END LOOP;
        END IF;
    END LOOP;

    -- Record initial status in history
    INSERT INTO order_status_history (
        order_id,
        status,
        notes
    ) VALUES (
        new_order_id,
        'PENDING',
        'Order created manually via Admin Dashboard'
    );

    RETURN QUERY SELECT * FROM orders WHERE id = new_order_id;
END;
$$ LANGUAGE plpgsql;
