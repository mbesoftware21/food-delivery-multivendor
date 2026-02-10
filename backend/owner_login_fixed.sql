-- Fix owner_login function with correct argument names
DROP FUNCTION IF EXISTS owner_login(text, text);

CREATE OR REPLACE FUNCTION owner_login(
    email TEXT,
    password TEXT
)
RETURNS SETOF login_responses AS $$
DECLARE
    v_user_record RECORD;
    v_response login_responses%ROWTYPE;
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
    
    -- In production, you would verify the password hash here
    -- For MVP, we'll just check if password matches (NOT SECURE - FOR DEV ONLY)
    IF v_user_record.password != owner_login.password THEN
        RAISE EXCEPTION 'Invalid credentials';
    END IF;
    
    -- Build response
    v_response."userId" := v_user_record._id;
    v_response."token" := 'mock_jwt_token_' || v_user_record.id::text;
    v_response."email" := v_user_record.email;
    v_response."userType" := v_user_record.user_type;
    v_response."name" := v_user_record.name;
    v_response."isActive" := v_user_record.is_active;
    
    RETURN NEXT v_response;
END;
$$ LANGUAGE plpgsql;
