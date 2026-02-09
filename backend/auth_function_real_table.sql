-- ============================================
-- TABLE-BACKED OWNER LOGIN FUNCTION
-- ============================================

-- 1. Create a Table to define the Type
DROP TABLE IF EXISTS login_responses CASCADE;
CREATE TABLE login_responses (
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

-- 2. Drop Function
DROP FUNCTION IF EXISTS owner_login(text, text);

-- 3. Create Function returning SETOF table
CREATE OR REPLACE FUNCTION owner_login(p_email text, p_password text)
RETURNS SETOF login_responses AS $$
DECLARE
    v_user users%ROWTYPE;
    v_restaurants json;
    v_response login_responses%ROWTYPE;
BEGIN
    -- Check user credentials
    SELECT * INTO v_user 
    FROM users 
    WHERE users.email = owner_login.p_email 
    AND users.password = owner_login.p_password;

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

    -- Construct Response
    v_response."userId" := v_user.id;
    v_response."token" := 'mock-jwt-token-12345';
    v_response."email" := v_user.email;
    v_response."userType" := v_user.user_type;
    v_response."restaurants" := COALESCE(v_restaurants, '[]'::json);
    v_response."permissions" := '["SUPER_ADMIN"]';
    v_response."userTypeId" := v_user.id;
    v_response."image" := v_user.image;
    v_response."name" := v_user.name;

    RETURN NEXT v_response;
END;
$$ LANGUAGE plpgsql VOLATILE;
