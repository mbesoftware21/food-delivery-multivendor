-- Type for staff input
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'staff_input_type') THEN
        CREATE TYPE staff_input_type AS (
            _id text,
            name text,
            email text,
            password text,
            phone text,
            is_active boolean,
            permissions text[]
        );
    END IF;
END $$;

-- Function to create staff
CREATE OR REPLACE FUNCTION create_staff("staffInput" staff_input_type)
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
        is_active,
        image,
        permissions
    ) VALUES (
        "staffInput".email,
        "staffInput".password,
        COALESCE("staffInput".name, "staffInput".email),
        "staffInput".phone,
        'STAFF',
        COALESCE("staffInput".is_active, true),
        NULL,
        "staffInput".permissions
    ) RETURNING * INTO new_user;
    
    RETURN new_user;
END;
$$ LANGUAGE plpgsql;

-- Function to edit staff
CREATE OR REPLACE FUNCTION edit_staff("staffInput" staff_input_type)
RETURNS users AS $$
DECLARE
    updated_user users;
    target_id uuid;
BEGIN
    target_id := "staffInput"._id::uuid;
    
    UPDATE users SET
        email = COALESCE("staffInput".email, email),
        password = COALESCE("staffInput".password, password),
        name = COALESCE("staffInput".name, name),
        phone = COALESCE("staffInput".phone, phone),
        is_active = COALESCE("staffInput".is_active, is_active),
        permissions = COALESCE("staffInput".permissions, permissions),
        updated_at = now()
    WHERE id = target_id
    RETURNING * INTO updated_user;
    
    RETURN updated_user;
END;
$$ LANGUAGE plpgsql;
