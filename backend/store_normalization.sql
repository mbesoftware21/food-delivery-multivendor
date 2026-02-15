-- Normalized schema for Restaurants (Stores)
BEGIN;

-- 1. Table for Restaurant Settings (One-to-One)
CREATE TABLE IF NOT EXISTS public.restaurant_settings (
    restaurant_id UUID PRIMARY KEY REFERENCES public.restaurants(id) ON DELETE CASCADE,
    minimum_order NUMERIC(10,2) DEFAULT 0,
    tax NUMERIC(10,2) DEFAULT 0,
    commission_rate NUMERIC(10,2) DEFAULT 0,
    is_delivery_enabled BOOLEAN DEFAULT TRUE,
    is_pickup_enabled BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Table for Opening Times (One-to-Many)
CREATE TABLE IF NOT EXISTS public.opening_times (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE,
    day TEXT NOT NULL, -- 'MONDAY', 'TUESDAY', etc.
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_closed BOOLEAN DEFAULT FALSE,
    UNIQUE(restaurant_id, day)
);

-- 3. Initial migration: Move data from restaurants to restaurant_settings
-- Only move minimum_order as tax is not in the source table currently
INSERT INTO public.restaurant_settings (restaurant_id, minimum_order)
SELECT id, minimum_order FROM public.restaurants
ON CONFLICT (restaurant_id) DO NOTHING;

COMMIT;
