-- ============================================
-- FINAL OWNER LOGIN FUNCTION
-- ============================================

-- Drop all possible variations
DROP FUNCTION IF EXISTS owner_login(text, text);

-- Create Function
CREATE OR REPLACE FUNCTION owner_login(p_email text, p_password text)
RETURNS TABLE (
    "userId" UUID,
    "token" TEXT,
    "email" TEXT,
    "userType" TEXT,
    "restaurants" JSON,
    "permissions" JSON,
    "userTypeId" UUID,
    "image" TEXT,
    "name" TEXT
) AS $$
DECLARE
    v_user users%ROWTYPE;
    v_restaurants json;
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

    -- Return the values
    "userId" := v_user.id;
    "token" := 'mock-jwt-token-12345';
    "email" := v_user.email;
    "userType" := v_user.user_type;
    "restaurants" := COALESCE(v_restaurants, '[]'::json);
    "permissions" := '["SUPER_ADMIN"]';
    "userTypeId" := v_user.id;
    "image" := v_user.image;
    "name" := v_user.name;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql VOLATILE;
