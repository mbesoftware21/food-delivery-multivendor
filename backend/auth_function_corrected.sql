-- ============================================
-- CORRECTED OWNER LOGIN FUNCTION
-- ============================================

-- 1. Create a Type for the Response
DROP TYPE IF EXISTS login_response_type CASCADE;
CREATE TYPE login_response_type AS (
    "userId" UUID,
    "token" TEXT,
    "email" TEXT,
    "userType" TEXT,
    "restaurants" JSON,
    "permissions" JSON,
    "userTypeId" UUID,
    "image" TEXT,
    "name" TEXT
);

-- 2. Create the Function Returning the Type
CREATE OR REPLACE FUNCTION owner_login(email text, password text)
RETURNS SETOF login_response_type AS $$
DECLARE
    v_user users%ROWTYPE;
    v_restaurants json;
    v_result login_response_type;
BEGIN
    -- Check user credentials
    SELECT * INTO v_user 
    FROM users 
    WHERE users.email = owner_login.email 
    AND users.password = owner_login.password;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid email or password';
    END IF;

    -- Get associated restaurants
    SELECT json_agg(json_build_object(
        '_id', r.id,
        'orderId', r.slug,
        'name', r.name,
        'image', r.image,
        'address', r.address
    )) INTO v_restaurants
    FROM restaurants r
    WHERE r.owner_id = v_user.id;

    -- Construct the result
    v_result."userId" := v_user.id;
    v_result."token" := 'mock-jwt-token-12345';
    v_result."email" := v_user.email;
    v_result."userType" := v_user.user_type;
    v_result."restaurants" := COALESCE(v_restaurants, '[]'::json);
    v_result."permissions" := '["SUPER_ADMIN"]';
    v_result."userTypeId" := v_user.id;
    v_result."image" := v_user.image;
    v_result."name" := v_user.name;

    RETURN NEXT v_result;
END;
$$ LANGUAGE plpgsql STABLE;
