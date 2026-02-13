-- Type for rider input
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'rider_input_type') THEN
        CREATE TYPE rider_input_type AS (
            _id text,
            name text,
            username text,
            password text,
            phone text,
            available boolean,
            vehicle_type text,
            zone_id text
        );
    END IF;
END $$;

-- Function to create rider
CREATE OR REPLACE FUNCTION create_rider("riderInput" rider_input_type)
RETURNS users AS $$
DECLARE
    new_user users;
    new_rider_data RECORD;
BEGIN
    INSERT INTO users (
        email, -- username is used as email for riders
        password, 
        name, 
        phone, 
        user_type, 
        is_active,
        image
    ) VALUES (
        "riderInput".username,
        "riderInput".password,
        "riderInput".name,
        "riderInput".phone,
        'RIDER',
        true,
        NULL
    ) RETURNING * INTO new_user;
    
    INSERT INTO riders_data (
        user_id,
        zone_id,
        is_available,
        vehicle_type
    ) VALUES (
        new_user.id,
        "riderInput".zone_id::uuid,
        COALESCE("riderInput".available, true),
        "riderInput".vehicle_type
    );
    
    RETURN new_user;
END;
$$ LANGUAGE plpgsql;

-- Function to edit rider
CREATE OR REPLACE FUNCTION edit_rider("riderInput" rider_input_type)
RETURNS users AS $$
DECLARE
    updated_user users;
    target_id uuid;
BEGIN
    target_id := "riderInput"._id::uuid;
    
    UPDATE users SET
        email = COALESCE("riderInput".username, email),
        password = COALESCE("riderInput".password, password),
        name = COALESCE("riderInput".name, name),
        phone = COALESCE("riderInput".phone, phone),
        updated_at = now()
    WHERE id = target_id
    RETURNING * INTO updated_user;
    
    UPDATE riders_data SET
        zone_id = COALESCE("riderInput".zone_id::uuid, zone_id),
        is_available = COALESCE("riderInput".available, is_available),
        vehicle_type = COALESCE("riderInput".vehicle_type, vehicle_type)
    WHERE user_id = target_id;
    
    RETURN updated_user;
END;
$$ LANGUAGE plpgsql;
