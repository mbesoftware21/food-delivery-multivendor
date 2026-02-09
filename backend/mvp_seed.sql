-- ============================================
-- SEED DATA FOR MVP
-- ============================================

-- 1. Create a Zone
INSERT INTO zones (id, title, description, location)
VALUES (
    uuid_generate_v4(),
    'Downtown Zone',
    'Main delivery area for downtown',
    ST_GeogFromText('POLYGON((-74.01 40.70, -74.00 40.70, -74.00 40.71, -74.01 40.71, -74.01 40.70))')
);

-- Get Zone ID
DO $$
DECLARE
    v_zone_id UUID;
    v_vendor_id UUID;
    v_rest_id UUID;
    v_cat_id UUID;
    v_rider_id UUID;
BEGIN
    SELECT id INTO v_zone_id FROM zones WHERE title = 'Downtown Zone' LIMIT 1;
    SELECT id INTO v_vendor_id FROM users WHERE user_type = 'VENDOR' LIMIT 1;

    -- 2. Create Restaurant
    INSERT INTO restaurants (id, owner_id, name, slug, address, location, delivery_time, minimum_order, delivery_charges)
    VALUES (
        uuid_generate_v4(),
        v_vendor_id,
        'Tasty Burger',
        'tasty-burger',
        '123 Main St, New York, NY',
        ST_GeogFromText('POINT(-74.005 40.705)'),
        30,
        10.00,
        2.50
    ) RETURNING id INTO v_rest_id;

    -- Link Restaurant to Zone
    INSERT INTO restaurant_zones (restaurant_id, zone_id) VALUES (v_rest_id, v_zone_id);

    -- 3. Create Categories
    INSERT INTO categories (id, restaurant_id, title, display_order)
    VALUES (uuid_generate_v4(), v_rest_id, 'Burgers', 1) RETURNING id INTO v_cat_id;

    INSERT INTO categories (restaurant_id, title, display_order)
    VALUES (v_rest_id, 'Drinks', 2);

    -- 4. Create Food Items
    INSERT INTO food_items (restaurant_id, category_id, title, description, price, image)
    VALUES 
    (v_rest_id, v_cat_id, 'Classic Cheeseburger', 'Juicy beef patty with cheddar cheese', 8.99, 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd'),
    (v_rest_id, v_cat_id, 'Bacon BBQ Burger', 'Crispy bacon with bbq sauce', 10.99, 'https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5');

    -- 5. Update Rider Details
    SELECT id INTO v_rider_id FROM users WHERE user_type = 'RIDER' LIMIT 1;
    
    INSERT INTO riders (user_id, zone_id, vehicle_type, is_available, current_location)
    VALUES (
        v_rider_id,
        v_zone_id,
        'BIKE',
        true,
        ST_GeogFromText('POINT(-74.006 40.706)')
    );

END $$;
