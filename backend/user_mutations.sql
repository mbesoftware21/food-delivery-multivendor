-- Type for user input
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_input_type') THEN
        CREATE TYPE user_input_type AS (
            _id text,
            name text,
            email text,
            password text,
            phone text
        );
    END IF;
END $$;

-- Function to create user (Customer)
CREATE OR REPLACE FUNCTION create_user("userInput" user_input_type)
RETURNS users AS $$
DECLARE
    new_user users;
BEGIN
    INSERT INTO users (
        email, 
        password, 
        name, 
        phone, 
        user_type, 
        is_active
    ) VALUES (
        "userInput".email,
        "userInput".password,
        COALESCE("userInput".name, "userInput".email),
        "userInput".phone,
        'CUSTOMER',
        true
    ) RETURNING * INTO new_user;
    
    RETURN new_user;
END;
$$ LANGUAGE plpgsql;

-- Function to edit user
CREATE OR REPLACE FUNCTION edit_user("userInput" user_input_type)
RETURNS users AS $$
DECLARE
    updated_user users;
    target_id uuid;
BEGIN
    target_id := "userInput"._id::uuid;
    
    UPDATE users SET
        email = COALESCE("userInput".email, email),
        password = COALESCE("userInput".password, password),
        name = COALESCE("userInput".name, name),
        phone = COALESCE("userInput".phone, phone),
        updated_at = now()
    WHERE id = target_id
    RETURNING * INTO updated_user;
    
    RETURN updated_user;
END;
$$ LANGUAGE plpgsql;
