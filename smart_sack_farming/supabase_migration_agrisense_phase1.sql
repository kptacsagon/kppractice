-- AgriSense DSS Phase 1: Core MVP Schema
-- This migration sets up the Farmer Profiling, GIS Farm Registry, and Seasonal Crop Submissions.
-- It requires the PostGIS extension for polygon tracking.

-- 1. Enable PostGIS extension for GIS mapping (Requires Supabase with PostGIS enabled)
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Farmer Profiles Table (Permanent Data)
CREATE TABLE IF NOT EXISTS agrisense_farmer_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    rsbsa_number VARCHAR(100) UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    age INT,
    sex VARCHAR(20),
    civil_status VARCHAR(50),
    contact_number VARCHAR(50),
    address TEXT,
    barangay VARCHAR(100) NOT NULL,
    municipality VARCHAR(100) NOT NULL,
    province VARCHAR(100) NOT NULL,
    farming_experience_years INT,
    irrigation_access VARCHAR(100),
    farming_method VARCHAR(100),
    equipment_owned TEXT[], -- Array of strings
    primary_crops TEXT[], -- Array of strings
    farm_ownership_type VARCHAR(100),
    verification_status VARCHAR(50) DEFAULT 'Pending', -- Pending, Verified, Rejected
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Farm Registry & GIS Table
CREATE TABLE IF NOT EXISTS agrisense_farms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID REFERENCES agrisense_farmer_profiles(id) ON DELETE CASCADE,
    farm_name VARCHAR(255),
    barangay VARCHAR(100) NOT NULL,
    municipality VARCHAR(100) NOT NULL,
    total_area_hectares DECIMAL(10,2) NOT NULL,
    soil_classification VARCHAR(100),
    irrigation_classification VARCHAR(100),
    -- PostGIS spatial column for polygon boundaries
    boundary_polygon GEOMETRY(POLYGON, 4326),
    -- Center point coordinate for quick map rendering
    center_point GEOMETRY(POINT, 4326),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Spatial Index for fast GIS queries
CREATE INDEX IF NOT EXISTS idx_agrisense_farms_boundary ON agrisense_farms USING GIST (boundary_polygon);

-- 5. Seasonal Crop Submissions Table (Forecasting Data)
CREATE TABLE IF NOT EXISTS agrisense_seasonal_crops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID REFERENCES agrisense_farms(id) ON DELETE CASCADE,
    farmer_id UUID REFERENCES agrisense_farmer_profiles(id),
    season_name VARCHAR(100) NOT NULL, -- e.g., 'Wet Season 2026'
    crop_type VARCHAR(100) NOT NULL,
    seed_variety VARCHAR(100),
    planting_date DATE NOT NULL,
    expected_harvest_date DATE NOT NULL,
    planned_planting_area_ha DECIMAL(10,2) NOT NULL,
    estimated_yield_kg DECIMAL(10,2) NOT NULL,
    target_market VARCHAR(100),
    status VARCHAR(50) DEFAULT 'Draft', -- Draft, Submitted, Verified, Active Planting, Harvest Recorded, Closed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_harvest_date CHECK (expected_harvest_date > planting_date)
);

-- Note: To detect overlapping farm boundaries, we can use PostGIS functions like ST_Intersects(boundary_polygon) in backend logic.
