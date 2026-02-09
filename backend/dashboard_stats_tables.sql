-- ============================================
-- TABLE-BACKED DASHBOARD STATISTICS (MVP)
-- ============================================

-- 1. getDashboardUsers
DROP FUNCTION IF EXISTS get_dashboard_users();
DROP TYPE IF EXISTS dashboard_users_stats CASCADE;
DROP TABLE IF EXISTS dashboard_users_stats_table CASCADE;

CREATE TABLE dashboard_users_stats_table (
    "usersCount" INT,
    "vendorsCount" INT,
    "restaurantsCount" INT,
    "ridersCount" INT
);

CREATE OR REPLACE FUNCTION get_dashboard_users()
RETURNS SETOF dashboard_users_stats_table AS $$
DECLARE
    v_stats dashboard_users_stats_table%ROWTYPE;
BEGIN
    SELECT COUNT(*) INTO v_stats."usersCount" FROM users WHERE user_type = 'CUSTOMER';
    SELECT COUNT(*) INTO v_stats."vendorsCount" FROM users WHERE user_type = 'VENDOR';
    SELECT COUNT(*) INTO v_stats."restaurantsCount" FROM restaurants;
    SELECT COUNT(*) INTO v_stats."ridersCount" FROM riders;
    RETURN NEXT v_stats;
END;
$$ LANGUAGE plpgsql STABLE;


-- 2. getDashboardUsersByYear
DROP FUNCTION IF EXISTS get_dashboard_users_by_year(int);
DROP TYPE IF EXISTS dashboard_users_year_stats CASCADE;
DROP TABLE IF EXISTS dashboard_users_year_stats_table CASCADE;

CREATE TABLE dashboard_users_year_stats_table (
    "usersCount" INT,
    "vendorsCount" INT,
    "restaurantsCount" INT,
    "ridersCount" INT,
    "percentageChange" JSON
);

CREATE OR REPLACE FUNCTION get_dashboard_users_by_year(year int)
RETURNS SETOF dashboard_users_year_stats_table AS $$
DECLARE
    v_stats dashboard_users_year_stats_table%ROWTYPE;
BEGIN
    SELECT COUNT(*) INTO v_stats."usersCount" FROM users WHERE user_type = 'CUSTOMER';
    SELECT COUNT(*) INTO v_stats."vendorsCount" FROM users WHERE user_type = 'VENDOR';
    SELECT COUNT(*) INTO v_stats."restaurantsCount" FROM restaurants;
    SELECT COUNT(*) INTO v_stats."ridersCount" FROM riders;
    
    v_stats."percentageChange" := json_build_object(
        'usersPercent', 0,
        'vendorsPercent', 0,
        'restaurantsPercent', 0,
        'ridersPercent', 0
    );

    RETURN NEXT v_stats;
END;
$$ LANGUAGE plpgsql STABLE;


-- 3 & 4. Orders and Sales by Type
DROP FUNCTION IF EXISTS get_dashboard_orders_by_type();
DROP FUNCTION IF EXISTS get_dashboard_sales_by_type();
DROP TYPE IF EXISTS chart_data_point CASCADE;
DROP TABLE IF EXISTS chart_data_point_table CASCADE;

CREATE TABLE chart_data_point_table (
    "value" FLOAT,
    "label" TEXT
);

CREATE OR REPLACE FUNCTION get_dashboard_orders_by_type()
RETURNS SETOF chart_data_point_table AS $$
BEGIN
    RETURN QUERY SELECT 0.0::FLOAT, 'PENDING'::TEXT;
    RETURN QUERY SELECT 0.0::FLOAT, 'DELIVERED'::TEXT;
    RETURN QUERY SELECT 0.0::FLOAT, 'CANCELLED'::TEXT;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION get_dashboard_sales_by_type()
RETURNS SETOF chart_data_point_table AS $$
BEGIN
    RETURN QUERY SELECT 0.0::FLOAT, 'SALES'::TEXT;
END;
$$ LANGUAGE plpgsql STABLE;
