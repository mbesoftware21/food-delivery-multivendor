-- ============================================
-- RESTAURANTS & VENDORS PAGINATED QUERIES
-- ============================================

-- 1. Create type for owner (nested in restaurant)
DROP TYPE IF EXISTS restaurant_owner_type CASCADE;
CREATE TYPE restaurant_owner_type AS (
    "_id" TEXT,
    "email" TEXT,
    "isActive" BOOLEAN
);

-- 2. Create type for restaurant data
DROP TYPE IF EXISTS restaurant_data_type CASCADE;
CREATE TYPE restaurant_data_type AS (
    "unique_restaurant_id" INT,
    "_id" TEXT,
    "name" TEXT,
    "image" TEXT,
    "orderPrefix" TEXT,
    "slug" TEXT,
    "address" TEXT,
    "deliveryTime" INT,
    "minimumOrder" FLOAT,
    "isActive" BOOLEAN,
    "commissionRate" FLOAT,
    "username" TEXT,
    "tax" FLOAT,
    "owner" JSON,
    "shopType" TEXT
);

-- 3. Create table for restaurantsPaginated response
DROP TABLE IF EXISTS restaurants_paginated_response CASCADE;
CREATE TABLE restaurants_paginated_response (
    "data" JSON,
    "totalCount" INT,
    "currentPage" INT,
    "totalPages" INT
);

-- 4. Create restaurantsPaginated function
CREATE OR REPLACE FUNCTION restaurants_paginated(
    page INT DEFAULT 1,
    "limit" INT DEFAULT 10,
    search TEXT DEFAULT ''
)
RETURNS SETOF restaurants_paginated_response AS $$
DECLARE
    v_offset INT;
    v_total_count INT;
    v_total_pages INT;
    v_result restaurants_paginated_response%ROWTYPE;
BEGIN
    -- Calculate offset
    v_offset := (page - 1) * "limit";
    
    -- Get total count (with search filter if provided)
    IF search IS NOT NULL AND search != '' THEN
        SELECT COUNT(*) INTO v_total_count 
        FROM restaurants r
        WHERE r.name ILIKE '%' || search || '%' OR r.address ILIKE '%' || search || '%';
    ELSE
        SELECT COUNT(*) INTO v_total_count FROM restaurants;
    END IF;
    
    -- Calculate total pages
    v_total_pages := CEIL(v_total_count::FLOAT / "limit");
    
    -- Build JSON array of restaurants
    SELECT 
        json_agg(
            json_build_object(
                'unique_restaurant_id', r.id::text,
                '_id', r._id,
                'name', r.name,
                'image', r.image,
                'orderPrefix', r.order_prefix,
                'slug', r.slug,
                'address', r.address,
                'deliveryTime', r.delivery_time,
                'minimumOrder', r.minimum_order,
                'isActive', r.is_active,
                'commissionRate', r.commission_rate,
                'username', r.username,
                'tax', r.sales_tax,
                'owner', json_build_object(
                    '_id', u._id,
                    'email', u.email,
                    'isActive', u.is_active
                ),
                'shopType', 'restaurant'
            )
        ),
        v_total_count,
        page,
        v_total_pages
    INTO v_result."data", v_result."totalCount", v_result."currentPage", v_result."totalPages"
    FROM restaurants r
    LEFT JOIN users u ON r.owner_id = u.id
    WHERE (search IS NULL OR search = '' OR r.name ILIKE '%' || search || '%' OR r.address ILIKE '%' || search || '%')
    ORDER BY r.created_at DESC
    LIMIT "limit" OFFSET v_offset;
    
    RETURN NEXT v_result;
END;
$$ LANGUAGE plpgsql STABLE;


-- 5. Create vendors view (users with userType = VENDOR)
DROP VIEW IF EXISTS vendors CASCADE;
CREATE VIEW vendors AS
SELECT 
    u.id::text as unique_id,
    u._id,
    u.email,
    u.user_type as "userType",
    u.is_active as "isActive",
    u.name,
    u.image
FROM users u
WHERE u.user_type = 'VENDOR';
