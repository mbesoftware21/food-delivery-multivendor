-- ============================================
-- ENATEGA MVP DATABASE SCHEMA
-- Order Management System
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================
-- 1. USERS TABLE (Multi-role: Admin, Customer, Rider, Vendor)
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    name TEXT NOT NULL,
    phone TEXT,
    user_type TEXT NOT NULL DEFAULT 'CUSTOMER', -- 'ADMIN', 'VENDOR', 'RIDER', 'CUSTOMER'
    image TEXT,
    is_active BOOLEAN DEFAULT true,
    is_email_verified BOOLEAN DEFAULT false,
    is_phone_verified BOOLEAN DEFAULT false,
    notification_token TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_type ON users(user_type);
CREATE INDEX idx_users_active ON users(is_active);

-- ============================================
-- 2. ZONES (Delivery Areas)
-- ============================================
CREATE TABLE zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    location GEOGRAPHY(POLYGON, 4326), -- PostGIS polygon for geographic boundaries
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_zones_active ON zones(is_active);
CREATE INDEX idx_zones_location ON zones USING GIST(location);

-- ============================================
-- 3. RESTAURANTS
-- ============================================
CREATE TABLE restaurants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    slug TEXT UNIQUE,
    image TEXT,
    logo TEXT,
    address TEXT NOT NULL,
    location GEOGRAPHY(POINT, 4326), -- PostGIS point for restaurant location
    phone TEXT,
    delivery_time INTEGER DEFAULT 30, -- minutes
    minimum_order DECIMAL(10, 2) DEFAULT 0,
    delivery_charges DECIMAL(10, 2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    is_available BOOLEAN DEFAULT true, -- Currently accepting orders
    rating DECIMAL(3, 2) DEFAULT 0,
    reviews_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_restaurants_active ON restaurants(is_active);
CREATE INDEX idx_restaurants_available ON restaurants(is_available);
CREATE INDEX idx_restaurants_owner ON restaurants(owner_id);
CREATE INDEX idx_restaurants_location ON restaurants USING GIST(location);

-- ============================================
-- 4. RESTAURANT_ZONES (Many-to-Many)
-- ============================================
CREATE TABLE restaurant_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    zone_id UUID REFERENCES zones(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(restaurant_id, zone_id)
);

CREATE INDEX idx_restaurant_zones_restaurant ON restaurant_zones(restaurant_id);
CREATE INDEX idx_restaurant_zones_zone ON restaurant_zones(zone_id);

-- ============================================
-- 5. CATEGORIES
-- ============================================
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    image TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_categories_restaurant ON categories(restaurant_id);
CREATE INDEX idx_categories_active ON categories(is_active);

-- ============================================
-- 6. FOOD_ITEMS
-- ============================================
CREATE TABLE food_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    image TEXT,
    price DECIMAL(10, 2) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_food_items_restaurant ON food_items(restaurant_id);
CREATE INDEX idx_food_items_category ON food_items(category_id);
CREATE INDEX idx_food_items_active ON food_items(is_active);

-- ============================================
-- 7. ADDONS (Extras like "Extra Cheese", "Spicy Sauce")
-- ============================================
CREATE TABLE addons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_addons_restaurant ON addons(restaurant_id);
CREATE INDEX idx_addons_active ON addons(is_active);

-- ============================================
-- 8. FOOD_ADDONS (Many-to-Many: Which addons are available for which food)
-- ============================================
CREATE TABLE food_addons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    food_id UUID REFERENCES food_items(id) ON DELETE CASCADE,
    addon_id UUID REFERENCES addons(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(food_id, addon_id)
);

CREATE INDEX idx_food_addons_food ON food_addons(food_id);
CREATE INDEX idx_food_addons_addon ON food_addons(addon_id);

-- ============================================
-- 9. RIDERS
-- ============================================
CREATE TABLE riders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    zone_id UUID REFERENCES zones(id) ON DELETE SET NULL,
    vehicle_type TEXT, -- 'BIKE', 'MOTORCYCLE', 'CAR'
    vehicle_number TEXT,
    is_available BOOLEAN DEFAULT false,
    current_location GEOGRAPHY(POINT, 4326),
    rating DECIMAL(3, 2) DEFAULT 0,
    reviews_count INTEGER DEFAULT 0,
    total_deliveries INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_riders_user ON riders(user_id);
CREATE INDEX idx_riders_zone ON riders(zone_id);
CREATE INDEX idx_riders_available ON riders(is_available);
CREATE INDEX idx_riders_location ON riders USING GIST(current_location);

-- ============================================
-- 10. ORDERS
-- ============================================
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id TEXT UNIQUE NOT NULL, -- Human-readable order ID like "ORD-20240209-001"
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE SET NULL,
    rider_id UUID REFERENCES riders(id) ON DELETE SET NULL,
    
    -- Order Status
    status TEXT NOT NULL DEFAULT 'PENDING', 
    -- PENDING → ACCEPTED → PREPARING → READY → PICKED → ON_THE_WAY → DELIVERED → COMPLETED
    -- Can also be: CANCELLED, REJECTED
    
    -- Delivery Details
    delivery_address JSONB NOT NULL, -- {street, city, coordinates, instructions}
    delivery_location GEOGRAPHY(POINT, 4326),
    
    -- Pricing
    order_amount DECIMAL(10, 2) NOT NULL, -- Subtotal of items
    delivery_charges DECIMAL(10, 2) DEFAULT 0,
    tax_amount DECIMAL(10, 2) DEFAULT 0,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL, -- Final amount
    
    -- Payment
    payment_method TEXT DEFAULT 'CASH', -- 'CASH', 'CARD', 'WALLET'
    payment_status TEXT DEFAULT 'PENDING', -- 'PENDING', 'PAID', 'FAILED'
    
    -- Timestamps
    order_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    ready_at TIMESTAMP WITH TIME ZONE,
    picked_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    
    -- Additional
    special_instructions TEXT,
    cancellation_reason TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_restaurant ON orders(restaurant_id);
CREATE INDEX idx_orders_rider ON orders(rider_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_location ON orders USING GIST(delivery_location);

-- ============================================
-- 11. ORDER_ITEMS
-- ============================================
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    food_id UUID REFERENCES food_items(id) ON DELETE SET NULL,
    title TEXT NOT NULL, -- Store food name in case food is deleted
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    special_instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_food ON order_items(food_id);

-- ============================================
-- 12. ORDER_ADDONS (Addons selected for each order item)
-- ============================================
CREATE TABLE order_addons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_item_id UUID REFERENCES order_items(id) ON DELETE CASCADE,
    addon_id UUID REFERENCES addons(id) ON DELETE SET NULL,
    title TEXT NOT NULL, -- Store addon name
    price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_order_addons_item ON order_addons(order_item_id);

-- ============================================
-- 13. ORDER_STATUS_HISTORY (Track all status changes)
-- ============================================
CREATE TABLE order_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    changed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_order_history_order ON order_status_history(order_id);
CREATE INDEX idx_order_history_date ON order_status_history(created_at);

-- ============================================
-- 14. CONFIGURATION (Global Settings)
-- ============================================
CREATE TABLE configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    currency TEXT DEFAULT 'USD',
    currency_symbol TEXT DEFAULT '$',
    delivery_rate DECIMAL(10, 2) DEFAULT 5.00,
    tax_rate DECIMAL(5, 2) DEFAULT 0, -- Percentage
    commission_rate DECIMAL(5, 2) DEFAULT 10, -- Platform commission %
    
    -- API Keys (encrypted in production)
    stripe_publishable_key TEXT,
    stripe_secret_key TEXT,
    google_maps_key TEXT,
    cloudinary_upload_url TEXT,
    cloudinary_api_key TEXT,
    
    -- Notifications
    twilio_enabled BOOLEAN DEFAULT false,
    twilio_account_sid TEXT,
    twilio_auth_token TEXT,
    twilio_phone_number TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default configuration
INSERT INTO configuration (id) VALUES (uuid_generate_v4());

-- ============================================
-- 15. PAYMENTS (Track payment transactions)
-- ============================================
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method TEXT NOT NULL,
    payment_status TEXT DEFAULT 'PENDING', -- 'PENDING', 'SUCCESS', 'FAILED'
    transaction_id TEXT, -- External payment gateway transaction ID
    payment_data JSONB, -- Store payment gateway response
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_payments_status ON payments(payment_status);

-- ============================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_zones_updated_at BEFORE UPDATE ON zones FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_restaurants_updated_at BEFORE UPDATE ON restaurants FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_food_items_updated_at BEFORE UPDATE ON food_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_addons_updated_at BEFORE UPDATE ON addons FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_riders_updated_at BEFORE UPDATE ON riders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_configuration_updated_at BEFORE UPDATE ON configuration FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SEED DATA
-- ============================================

-- Admin user (already exists from init.sql, but adding here for completeness)
INSERT INTO users (email, password, name, user_type)
VALUES ('admin@enatega.com', '123456', 'Super Admin', 'ADMIN')
ON CONFLICT (email) DO NOTHING;

-- Sample Customer
INSERT INTO users (email, password, name, user_type, phone)
VALUES ('customer@test.com', '123456', 'Test Customer', 'CUSTOMER', '+1234567890')
ON CONFLICT (email) DO NOTHING;

-- Sample Vendor
INSERT INTO users (email, password, name, user_type)
VALUES ('vendor@test.com', '123456', 'Test Vendor', 'VENDOR')
ON CONFLICT (email) DO NOTHING;

-- Sample Rider
INSERT INTO users (email, password, name, user_type)
VALUES ('rider@test.com', '123456', 'Test Rider', 'RIDER')
ON CONFLICT (email) DO NOTHING;
