-- ============================================
-- ERP MANAGEMENT MUTATIONS
-- ============================================

-- TYPES
DROP TYPE IF EXISTS variation_input_type CASCADE;
CREATE TYPE variation_input_type AS (
    _id text,
    title text,
    price numeric,
    discounted numeric,
    isOutOfStock boolean
);

DROP TYPE IF EXISTS food_input_type CASCADE;
CREATE TYPE food_input_type AS (
    _id text,
    restaurant text,
    category text,
    subCategory text,
    title text,
    description text,
    image text,
    variations variation_input_type[]
);

DROP TYPE IF EXISTS restaurant_input_type CASCADE;
CREATE TYPE restaurant_input_type AS (
    name text,
    address text,
    image text,
    logo text,
    phoneNumber text,
    deliveryTime integer,
    minOrder numeric,
    salesTax numeric,
    shopType text,
    cuisines text[]
);

DROP TYPE IF EXISTS category_input_type CASCADE;
CREATE TYPE category_input_type AS (
    _id text,
    restaurant text,
    title text
);

-- FUNCTIONS

-- CREATE RESTAURANT
CREATE OR REPLACE FUNCTION create_restaurant(restaurant restaurant_input_type, owner uuid)
RETURNS restaurants AS $$
DECLARE
    new_res restaurants;
BEGIN
    INSERT INTO restaurants (
        name, address, image, logo, phone, delivery_time, minimum_order, tax, owner_id
    ) VALUES (
        restaurant.name, restaurant.address, restaurant.image, restaurant.logo, 
        restaurant.phoneNumber, restaurant.deliveryTime, restaurant.minOrder, 
        restaurant.salesTax, owner
    ) RETURNING * INTO new_res;
    RETURN new_res;
END;
$$ LANGUAGE plpgsql;

-- EDIT RESTAURANT
CREATE OR REPLACE FUNCTION edit_restaurant(restaurant restaurant_input_type, id uuid)
RETURNS restaurants AS $$
DECLARE
    updated_res restaurants;
BEGIN
    UPDATE restaurants SET
        name = COALESCE(restaurant.name, name),
        address = COALESCE(restaurant.address, address),
        image = COALESCE(restaurant.image, image),
        logo = COALESCE(restaurant.logo, logo),
        phone = COALESCE(restaurant.phoneNumber, phone),
        delivery_time = COALESCE(restaurant.deliveryTime, delivery_time),
        minimum_order = COALESCE(restaurant.minOrder, minimum_order),
        tax = COALESCE(restaurant.salesTax, tax),
        updated_at = now()
    WHERE restaurants.id = edit_restaurant.id
    RETURNING * INTO updated_res;
    RETURN updated_res;
END;
$$ LANGUAGE plpgsql;

-- CREATE FOOD
CREATE OR REPLACE FUNCTION create_food("foodInput" food_input_type)
RETURNS food_items AS $$
DECLARE
    v_variation variation_input_type;
    v_first_id uuid;
    v_item food_items;
BEGIN
    FOREACH v_variation IN ARRAY "foodInput".variations
    LOOP
        INSERT INTO food_items (
            restaurant_id, category_id, title, description, image, price, is_active
        ) VALUES (
            "foodInput".restaurant::uuid, 
            "foodInput".category::uuid, 
            CASE WHEN array_length("foodInput".variations, 1) > 1 THEN "foodInput".title || ' (' || v_variation.title || ')' ELSE "foodInput".title END,
            "foodInput".description,
            "foodInput".image,
            v_variation.price,
            NOT v_variation.isOutOfStock
        ) RETURNING * INTO v_item;
        
        IF v_first_id IS NULL THEN
            v_first_id := v_item.id;
        END IF;
    END LOOP;
    
    SELECT * INTO v_item FROM food_items WHERE id = v_first_id;
    RETURN v_item;
END;
$$ LANGUAGE plpgsql;

-- CREATE CATEGORY
CREATE OR REPLACE FUNCTION create_category(category category_input_type)
RETURNS categories AS $$
DECLARE
    new_cat categories;
BEGIN
    INSERT INTO categories (
        restaurant_id, title
    ) VALUES (
        category.restaurant::uuid,
        category.title
    ) RETURNING * INTO new_cat;
    RETURN new_cat;
END;
$$ LANGUAGE plpgsql;

-- EDIT FOOD
-- Logic: The current table structure is flat (one row per variation). 
-- This function replaces variations for a given food title.
CREATE OR REPLACE FUNCTION edit_food("foodInput" food_input_type)
RETURNS food_items AS $$
DECLARE
    v_variation variation_input_type;
    v_first_id uuid;
    v_item food_items;
BEGIN
    -- Delete old variations (matching restaurant, category and original title)
    -- We use title prefix or ID if provided. For better safety, we should use ID.
    -- Assuming _id in foodInput refers to one of the variations or a common identifier.
    -- If _id is provided, we use it to find the name of the food to delete.
    DELETE FROM food_items WHERE restaurant_id = "foodInput".restaurant::uuid 
    AND category_id = "foodInput".category::uuid
    AND (id::text = "foodInput"._id OR title = "foodInput".title OR title LIKE "foodInput".title || ' (%)');

    -- Re-create variations
    FOREACH v_variation IN ARRAY "foodInput".variations
    LOOP
        INSERT INTO food_items (
            restaurant_id, category_id, title, description, image, price, is_active
        ) VALUES (
            "foodInput".restaurant::uuid, 
            "foodInput".category::uuid, 
            CASE WHEN array_length("foodInput".variations, 1) > 1 THEN "foodInput".title || ' (' || v_variation.title || ')' ELSE "foodInput".title END,
            "foodInput".description,
            "foodInput".image,
            v_variation.price,
            NOT v_variation.isOutOfStock
        ) RETURNING * INTO v_item;
        
        IF v_first_id IS NULL THEN
            v_first_id := v_item.id;
        END IF;
    END LOOP;
    
    SELECT * INTO v_item FROM food_items WHERE id = v_first_id;
    RETURN v_item;
END;
$$ LANGUAGE plpgsql;

-- EDIT CATEGORY
CREATE OR REPLACE FUNCTION edit_category(category category_input_type)
RETURNS categories AS $$
DECLARE
    updated_cat categories;
BEGIN
    UPDATE categories SET
        title = category.title,
        updated_at = now()
    WHERE id::text = category._id
    RETURNING * INTO updated_cat;
    RETURN updated_cat;
END;
$$ LANGUAGE plpgsql;

-- DELETE RESTAURANT
CREATE OR REPLACE FUNCTION delete_restaurant(id uuid)
RETURNS restaurants AS $$
DECLARE
    deleted_res restaurants;
BEGIN
    UPDATE restaurants SET is_active = false WHERE restaurants.id = delete_restaurant.id RETURNING * INTO deleted_res;
    RETURN deleted_res;
END;
$$ LANGUAGE plpgsql;

-- DELETE FOOD
CREATE OR REPLACE FUNCTION delete_food(id uuid)
RETURNS food_items AS $$
DECLARE
    deleted_food food_items;
BEGIN
    DELETE FROM food_items WHERE id = delete_food.id RETURNING * INTO deleted_food;
    RETURN deleted_food;
END;
$$ LANGUAGE plpgsql;

-- DELETE CATEGORY
CREATE OR REPLACE FUNCTION delete_category(id uuid)
RETURNS categories AS $$
DECLARE
    deleted_cat categories;
BEGIN
    DELETE FROM categories WHERE id = delete_category.id RETURNING * INTO deleted_cat;
    RETURN deleted_cat;
END;
$$ LANGUAGE plpgsql;
