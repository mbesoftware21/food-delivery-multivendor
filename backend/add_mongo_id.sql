-- ============================================
-- ADD MONGODB COMPATIBILITY (_id)
-- ============================================

-- Function to add _id column if not exists
CREATE OR REPLACE FUNCTION add_mongo_id_column(tbl text) RETURNS void AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS _id TEXT GENERATED ALWAYS AS (id::text) STORED', tbl);
EXCEPTION
    WHEN OTHERS THEN RAISE NOTICE 'Table % might not have id column or _id already exists', tbl;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables
SELECT add_mongo_id_column('users');
SELECT add_mongo_id_column('zones');
SELECT add_mongo_id_column('restaurants');
SELECT add_mongo_id_column('categories');
SELECT add_mongo_id_column('food_items');
SELECT add_mongo_id_column('addons');
SELECT add_mongo_id_column('riders');
SELECT add_mongo_id_column('orders');
SELECT add_mongo_id_column('order_items');
SELECT add_mongo_id_column('order_addons');
SELECT add_mongo_id_column('configuration');
SELECT add_mongo_id_column('payments');

-- Drop function after use
DROP FUNCTION add_mongo_id_column(text);
