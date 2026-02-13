-- Custom type for the input argument to match frontend mutation
-- Using lowercase for all fields to avoid case-sensitivity issues in Postgres
DROP TYPE IF EXISTS vendor_input_type CASCADE;
CREATE TYPE vendor_input_type AS (
    _id text,
    name text,
    email text,
    password text,
    image text,
    firstname text,
    lastname text,
    phonenumber text
);

-- Function to create a vendor
CREATE OR REPLACE FUNCTION create_vendor("vendorInput" vendor_input_type)
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
        image
    ) VALUES (
        "vendorInput".email,
        "vendorInput".password,
        COALESCE("vendorInput".name, "vendorInput".firstname || ' ' || "vendorInput".lastname),
        "vendorInput".phonenumber,
        'VENDOR',
        "vendorInput".image
    ) RETURNING * INTO new_user;
    
    RETURN new_user;
END;
$$ LANGUAGE plpgsql;

-- Function to edit a vendor
CREATE OR REPLACE FUNCTION edit_vendor("vendorInput" vendor_input_type)
RETURNS users AS $$
DECLARE
    updated_user users;
BEGIN
    UPDATE users SET
        email = COALESCE("vendorInput".email, email),
        password = COALESCE("vendorInput".password, password),
        name = COALESCE("vendorInput".name, "vendorInput".firstname || ' ' || "vendorInput".lastname, name),
        phone = COALESCE("vendorInput".phonenumber, phone),
        image = COALESCE("vendorInput".image, image),
        updated_at = now()
    WHERE id::text = "vendorInput"._id OR id::text = "vendorInput"._id -- Ensure matching by UUID string if needed
    RETURNING * INTO updated_user;
    
    RETURN updated_user;
END;
$$ LANGUAGE plpgsql;
