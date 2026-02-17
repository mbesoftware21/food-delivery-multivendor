-- ============================================
-- PHASE 2: SHOP TYPES AND CUISINES SCHEMA
-- ============================================

-- 1. SHOP TYPES TABLE
CREATE TABLE IF NOT EXISTS shop_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    image TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. CUISINES TABLE
CREATE TABLE IF NOT EXISTS cuisines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    image TEXT,
    is_active BOOLEAN DEFAULT true,
    shop_type_id UUID REFERENCES shop_types(id) ON DELETE SET NULL, -- Optional link to shop type
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. UPDATE RESTAURANTS TABLE
-- Add shop_type and cuisines columns if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'restaurants' AND column_name = 'shop_type') THEN
        ALTER TABLE restaurants ADD COLUMN shop_type TEXT; -- Store ID or Title? Usually store ID or a slug. Let's use TEXT for flexibility for now, or UUID if we link strict. Frontend sends a string ID usually.
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'restaurants' AND column_name = 'cuisines') THEN
        ALTER TABLE restaurants ADD COLUMN cuisines TEXT[]; -- Array of cuisine IDs or names
    END IF;
END $$;

-- 4. SEED DATA
-- Insert some default Shop Types
INSERT INTO shop_types (title, description, is_active)
VALUES 
('Grocery', 'Supermarkets and grocery stores', true),
('Food', 'Restaurants and food outlets', true),
('Pharmacy', 'Drug stores and pharmacies', true)
ON CONFLICT DO NOTHING; -- No unique constraint on title usually, but good practice to check duplicates if constraints existed.

-- Insert some default Cuisines
INSERT INTO cuisines (title, description, is_active)
VALUES 
('Italian', 'Pizza, Pasta, and more', true),
('American', 'Burgers, Fries, and Steaks', true),
('Chinese', 'Noodles, Rice, and Dim Sum', true),
('Indian', 'Curry, Naan, and Spices', true),
('Japanese', 'Sushi, Ramen, and Sashimi', true)
ON CONFLICT DO NOTHING;
