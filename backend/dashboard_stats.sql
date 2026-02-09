-- ============================================
-- DASHBOARD STATISTICS FUNCTIONS (MOCK/MVP)
-- ============================================

-- 1. getDashboardUsers
-- Returns counts of users, vendors, restaurants, riders
DROP TYPE IF EXISTS dashboard_users_stats CASCADE;
CREATE TYPE dashboard_users_stats AS (
    "usersCount" INT,
    "vendorsCount" INT,
    "restaurantsCount" INT,
    "ridersCount" INT
);

CREATE OR REPLACE FUNCTION get_dashboard_users()
RETURNS SETOF dashboard_users_stats AS $$
DECLARE
    v_stats dashboard_users_stats%ROWTYPE;
BEGIN
    SELECT COUNT(*) INTO v_stats."usersCount" FROM users WHERE user_type = 'CUSTOMER';
    SELECT COUNT(*) INTO v_stats."vendorsCount" FROM users WHERE user_type = 'VENDOR';
    SELECT COUNT(*) INTO v_stats."restaurantsCount" FROM restaurants;
    SELECT COUNT(*) INTO v_stats."ridersCount" FROM riders;
    RETURN NEXT v_stats;
END;
$$ LANGUAGE plpgsql STABLE;


-- 2. getDashboardUsersByYear
-- Returns stats with percentage change (mocked as 0 for MVP)
DROP TYPE IF EXISTS percentage_change_stats CASCADE;
CREATE TYPE percentage_change_stats AS (
    "usersPercent" FLOAT,
    "vendorsPercent" FLOAT,
    "restaurantsPercent" FLOAT,
    "ridersPercent" FLOAT
);

DROP TYPE IF EXISTS dashboard_users_year_stats CASCADE;
CREATE TYPE dashboard_users_year_stats AS (
    "usersCount" INT,
    "vendorsCount" INT,
    "restaurantsCount" INT,
    "ridersCount" INT,
    "percentageChange" JSON -- Simulating nested object
);

CREATE OR REPLACE FUNCTION get_dashboard_users_by_year(year int)
RETURNS SETOF dashboard_users_year_stats AS $$
DECLARE
    v_stats dashboard_users_year_stats%ROWTYPE;
BEGIN
    SELECT COUNT(*) INTO v_stats."usersCount" FROM users WHERE user_type = 'CUSTOMER';
    SELECT COUNT(*) INTO v_stats."vendorsCount" FROM users WHERE user_type = 'VENDOR';
    SELECT COUNT(*) INTO v_stats."restaurantsCount" FROM restaurants;
    SELECT COUNT(*) INTO v_stats."ridersCount" FROM riders;
    
    -- Mock percentage change
    v_stats."percentageChange" := json_build_object(
        'usersPercent', 0,
        'vendorsPercent', 0,
        'restaurantsPercent', 0,
        'ridersPercent', 0
    );

    RETURN NEXT v_stats;
END;
$$ LANGUAGE plpgsql STABLE;


-- 3. getDashboardOrdersByType
-- Returns orders grouped by type (e.g., PENDING, DELIVERED)
DROP TYPE IF EXISTS chart_data_point CASCADE;
CREATE TYPE chart_data_point AS (
    "value" FLOAT,
    "label" TEXT
);

CREATE OR REPLACE FUNCTION get_dashboard_orders_by_type()
RETURNS SETOF chart_data_point AS $$
BEGIN
    -- Return dummy data for MVP to prevent crash
    RETURN QUERY SELECT 0.0::FLOAT, 'PENDING'::TEXT;
    RETURN QUERY SELECT 0.0::FLOAT, 'DELIVERED'::TEXT;
    RETURN QUERY SELECT 0.0::FLOAT, 'CANCELLED'::TEXT;
END;
$$ LANGUAGE plpgsql STABLE;


-- 4. getDashboardSalesByType
-- Returns sales grouped by type
CREATE OR REPLACE FUNCTION get_dashboard_sales_by_type()
RETURNS SETOF chart_data_point AS $$
BEGIN
     -- Return dummy data for MVP
    RETURN QUERY SELECT 0.0::FLOAT, 'SALES'::TEXT;
END;
$$ LANGUAGE plpgsql STABLE;
