-- ============================================
-- OWNER LOGIN FUNCTION FOR HASURA
-- ============================================

-- Function to handle login credentials
CREATE OR REPLACE FUNCTION owner_login(email text, password text)
RETURNS SETOF json AS $$
DECLARE
    v_user users%ROWTYPE;
    v_restaurants json;
BEGIN
    -- Check user credentials
    SELECT * INTO v_user 
    FROM users 
    WHERE users.email = owner_login.email 
    AND users.password = owner_login.password;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid email or password';
    END IF;

    -- Get associated restaurants for this user
    SELECT json_agg(json_build_object(
        '_id', r.id,
        'orderId', r.slug, -- Using slug as orderId proxy for now
        'name', r.name,
        'image', r.image,
        'address', r.address
    )) INTO v_restaurants
    FROM restaurants r
    WHERE r.owner_id = v_user.id;

    -- Return the JSON structure expected by the frontend
    RETURN QUERY SELECT json_build_object(
        'userId', v_user.id,
        'token', 'mock-jwt-token-12345', -- Mock token for MVP
        'email', v_user.email,
        'userType', v_user.user_type,
        'restaurants', COALESCE(v_restaurants, '[]'::json),
        'permissions', '["SUPER_ADMIN"]', -- Granting super admin permissions
        'userTypeId', v_user.id,
        'image', v_user.image,
        'name', v_user.name
    );
END;
$$ LANGUAGE plpgsql STABLE;
