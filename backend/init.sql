CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    name TEXT NOT NULL,
    phone TEXT,
    user_type TEXT NOT NULL DEFAULT 'CUSTOMER', -- 'ADMIN', 'VENDOR', 'RIDER', 'CUSTOMER'
    image TEXT,
    permissions JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS restaurants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id SERIAL,
    name TEXT NOT NULL,
    image TEXT,
    address TEXT,
    owner_id UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert Default Admin User
-- Password is '123456' (hashed ideally, but plain for now if we handle it in code, lets assume plain for start debugging)
INSERT INTO users (email, password, name, user_type, permissions)
VALUES ('admin@enatega.com', '123456', 'Super Admin', 'ADMIN', '["ALL"]')
ON CONFLICT (email) DO NOTHING;
