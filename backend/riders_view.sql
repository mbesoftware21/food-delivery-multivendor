-- ============================================
-- FLATTENED RIDERS VIEW (MVP)
-- ============================================

-- 1. Rename original table to avoid conflict
ALTER TABLE riders RENAME TO riders_data;

-- 2. Create View matching Frontend Schema
CREATE OR REPLACE VIEW riders AS
SELECT 
    rd.id,
    rd.id::text as _id, -- Frontend expects _id
    u.name,
    u.email as username, -- Mapping email to username
    u.password,
    u.phone,
    rd.is_available as available, -- Mapping
    rd.vehicle_type as "vehicleType", -- CamelCase
    rd.vehicle_type as "assigned", -- Mocking assigned from vehicle_type for now (or false)
    rd.zone_id,
    rd.user_id,
    rd.created_at,
    rd.updated_at
FROM riders_data rd
JOIN users u ON rd.user_id = u.id;

-- 3. Restore Dependencies/Triggers if needed
-- (Triggers are on the table, so they stay on riders_data)
