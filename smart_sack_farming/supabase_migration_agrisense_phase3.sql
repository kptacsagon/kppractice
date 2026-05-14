-- AgriSense DSS Phase 3: FIP extensions + Alerts + CSI/PDEW/MPI/DPAC core tables

-- 1. Extend Farmer Intelligence Profile fields
ALTER TABLE agrisense_farmer_profiles
  ADD COLUMN IF NOT EXISTS preferred_crops TEXT[],
  ADD COLUMN IF NOT EXISTS market_access VARCHAR(150),
  ADD COLUMN IF NOT EXISTS language_preference VARCHAR(50),
  ADD COLUMN IF NOT EXISTS literacy_preference VARCHAR(50),
  ADD COLUMN IF NOT EXISTS financial_profile JSONB;

-- 2. Crop History (last 3 seasons)
CREATE TABLE IF NOT EXISTS agrisense_crop_histories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID REFERENCES agrisense_farmer_profiles(id) ON DELETE CASCADE,
    season_name VARCHAR(100) NOT NULL,
    crop_type VARCHAR(100) NOT NULL,
    area_ha DECIMAL(10,2) NOT NULL,
    yield_kg DECIMAL(12,2) NOT NULL,
    planting_date DATE,
    harvest_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agrisense_crop_histories_farmer
  ON agrisense_crop_histories(farmer_id);

-- 3. DA Program Enrollments
CREATE TABLE IF NOT EXISTS agrisense_program_enrollments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID REFERENCES agrisense_farmer_profiles(id) ON DELETE CASCADE,
    program_name VARCHAR(150) NOT NULL,
    status VARCHAR(50) NOT NULL,
    enrolled_date DATE,
    expiry_date DATE,
    reference_number VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agrisense_program_enrollments_farmer
  ON agrisense_program_enrollments(farmer_id);

-- 4. AgriSense Alerts
CREATE TABLE IF NOT EXISTS agrisense_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID REFERENCES agrisense_farmer_profiles(id) ON DELETE CASCADE,
    module VARCHAR(50) NOT NULL,
    alert_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    cta_label VARCHAR(80),
    cta_action VARCHAR(120),
    triggered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_agrisense_alerts_farmer
  ON agrisense_alerts(farmer_id, triggered_at DESC);

-- 5. CSI Saturation Scores
CREATE TABLE IF NOT EXISTS agrisense_saturation_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    municipality VARCHAR(100) NOT NULL,
    crop_type VARCHAR(100) NOT NULL,
    season_name VARCHAR(100) NOT NULL,
    srs_score DECIMAL(8,2) NOT NULL,
    projected_supply_mt DECIMAL(12,2) NOT NULL,
    projected_demand_mt DECIMAL(12,2) NOT NULL,
    price_forecast_min DECIMAL(10,2),
    price_forecast_max DECIMAL(10,2),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agrisense_saturation_scores_lookup
  ON agrisense_saturation_scores(municipality, crop_type, season_name);

-- 6. Pest & Disease Reports (PDEW)
CREATE TABLE IF NOT EXISTS agrisense_pest_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID REFERENCES agrisense_farmer_profiles(id) ON DELETE CASCADE,
    farm_id UUID REFERENCES agrisense_farms(id) ON DELETE SET NULL,
    municipality VARCHAR(100) NOT NULL,
    crop_type VARCHAR(100) NOT NULL,
    pest_type VARCHAR(120) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    photo_url TEXT,
    status VARCHAR(50) DEFAULT 'Pending',
    reported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agrisense_pest_reports_municipality
  ON agrisense_pest_reports(municipality, crop_type, reported_at DESC);

-- 7. Price Alerts (MPI)
CREATE TABLE IF NOT EXISTS agrisense_price_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID REFERENCES agrisense_farmer_profiles(id) ON DELETE CASCADE,
    crop_type VARCHAR(100) NOT NULL,
    target_price DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agrisense_price_alerts_farmer
  ON agrisense_price_alerts(farmer_id, crop_type);
