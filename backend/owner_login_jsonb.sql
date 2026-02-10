-- ULTIMATE FIX: Use JSONB return instead of SETOF for direct mutation args
DROP FUNCTION IF EXISTS owner_login(text, text) CASCADE;

CREATE OR REPLACE FUNCTION owner_login(
    email TEXT,
    password TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_user_record RECORD;
BEGIN
    -- Find user by email
    SELECT * INTO v_user_record
    FROM users u
    WHERE u.email = owner_login.email
    AND u.user_type IN ('ADMIN', 'VENDOR')
    LIMIT 1;
    
    -- Check if user exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid credentials';
    END IF;
    
    -- Check password (NOT SECURE - FOR MVP DEV ONLY)
    IF v_user_record.password != owner_login.password THEN
        RAISE EXCEPTION 'Invalid credentials';
    END IF;
    
    -- Build and return JSON response
    RETURN json_build_object(
        'userId', v_user_record._id,
        'token', 'mock_jwt_token_' || v_user_record.id::text,
        'email', v_user_record.email,
        'userType', v_user_record.user_type,
        'name', v_user_record.name,
        'isActive', v_user_record.is_active
    )::jsonb;
END;
$$ LANGUAGE plpgsql VOLATILE;
