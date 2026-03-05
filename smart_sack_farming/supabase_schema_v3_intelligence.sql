-- ============================================================
-- Smart Sack Farming – Intelligence Layer Schema v3
-- ============================================================
-- HOW TO APPLY
--   1. Go to Supabase → SQL Editor → New Query
--   2. Paste this entire file
--   3. Click "Run"
--
-- NOTE: This is an ADDITIVE migration. It does NOT drop v2
--       tables. Run supabase_schema.sql (v2) first if needed.
-- ============================================================

-- ============================================================
-- SECTION 1: NEW TABLES FOR INTELLIGENCE LAYER
-- ============================================================

-- 1. market_prices — reference price data for crops
DROP TABLE IF EXISTS market_prices CASCADE;
CREATE TABLE market_prices (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crop_type      VARCHAR(100) NOT NULL,
  price_per_kg   DECIMAL(10,2) NOT NULL,
  price_date     DATE NOT NULL DEFAULT CURRENT_DATE,
  region         VARCHAR(100) NOT NULL DEFAULT 'local',
  source         VARCHAR(100) DEFAULT 'manual',
  trend          VARCHAR(10) DEFAULT 'stable'
                 CHECK (trend IN ('rising', 'stable', 'falling')),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mp_crop   ON market_prices(crop_type);
CREATE INDEX idx_mp_date   ON market_prices(price_date);
CREATE INDEX idx_mp_region ON market_prices(region);

-- 2. agronomic_logbook — ongoing farm event diary
DROP TABLE IF EXISTS agronomic_logbook CASCADE;
CREATE TABLE agronomic_logbook (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  saturation_id   UUID REFERENCES saturation_records(id) ON DELETE SET NULL,
  project_id      UUID REFERENCES farming_projects(id) ON DELETE SET NULL,
  event_type      VARCHAR(50) NOT NULL
                  CHECK (event_type IN (
                    'fertilizer_application', 'pesticide_application',
                    'irrigation', 'weeding', 'pruning', 'soil_testing',
                    'seed_treatment', 'transplanting', 'harvesting',
                    'observation', 'weather_event', 'other'
                  )),
  event_date      DATE NOT NULL DEFAULT CURRENT_DATE,
  description     TEXT NOT NULL,
  quantity        DECIMAL(10,2),
  quantity_unit   VARCHAR(50),
  cost            DECIMAL(12,2) DEFAULT 0,
  crop_affected   VARCHAR(100),
  field_area_ha   DECIMAL(10,2),
  image_url       TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_log_farmer ON agronomic_logbook(farmer_id);
CREATE INDEX idx_log_type   ON agronomic_logbook(event_type);
CREATE INDEX idx_log_date   ON agronomic_logbook(event_date);
CREATE INDEX idx_log_sat    ON agronomic_logbook(saturation_id);
CREATE INDEX idx_log_proj   ON agronomic_logbook(project_id);

-- 3. crop_recommendations — generated planting recommendations
DROP TABLE IF EXISTS crop_recommendations CASCADE;
CREATE TABLE crop_recommendations (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recommended_crop     VARCHAR(100) NOT NULL,
  companion_crops      TEXT[],
  suitability_score    DECIMAL(5,2) NOT NULL DEFAULT 0,
  season               VARCHAR(20) NOT NULL,
  soil_moisture        DECIMAL(5,2),
  saturation_level     VARCHAR(10) DEFAULT 'medium',
  estimated_revenue    DECIMAL(15,2) DEFAULT 0,
  estimated_cost       DECIMAL(15,2) DEFAULT 0,
  estimated_profit     DECIMAL(15,2) DEFAULT 0,
  risk_level           VARCHAR(10) DEFAULT 'medium'
                       CHECK (risk_level IN ('low', 'medium', 'high')),
  regional_saturation  DECIMAL(5,2) DEFAULT 0,
  reason               TEXT,
  is_intercrop         BOOLEAN DEFAULT FALSE,
  expected_harvest     DATE,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_rec_farmer ON crop_recommendations(farmer_id);
CREATE INDEX idx_rec_crop   ON crop_recommendations(recommended_crop);
CREATE INDEX idx_rec_season ON crop_recommendations(season);

-- 4. supply_projections — forward-looking harvest supply data
DROP TABLE IF EXISTS supply_projections CASCADE;
CREATE TABLE supply_projections (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crop_type           VARCHAR(100) NOT NULL,
  projected_yield_kg  DECIMAL(12,2) NOT NULL DEFAULT 0,
  harvest_window_start DATE NOT NULL,
  harvest_window_end   DATE NOT NULL,
  farmer_count        INT DEFAULT 0,
  total_area_ha       DECIMAL(10,2) DEFAULT 0,
  risk_of_oversupply  DECIMAL(5,2) DEFAULT 0,
  suggested_action    TEXT,
  region              VARCHAR(100) DEFAULT 'local',
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sp_crop    ON supply_projections(crop_type);
CREATE INDEX idx_sp_harvest ON supply_projections(harvest_window_start);

-- 5. subsidy_allocations — tracks disaster subsidy verification
DROP TABLE IF EXISTS subsidy_allocations CASCADE;
CREATE TABLE subsidy_allocations (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  calamity_report_id UUID NOT NULL REFERENCES calamity_reports(id) ON DELETE CASCADE,
  farmer_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  verified_by        UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  verification_date  DATE,
  subsidy_amount     DECIMAL(15,2) DEFAULT 0,
  status             VARCHAR(20) NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending', 'verified', 'approved', 'disbursed', 'rejected')),
  verification_notes TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sub_calamity ON subsidy_allocations(calamity_report_id);
CREATE INDEX idx_sub_farmer   ON subsidy_allocations(farmer_id);
CREATE INDEX idx_sub_status   ON subsidy_allocations(status);

-- 6. harvest_schedules — harvest synchronization tracking
DROP TABLE IF EXISTS harvest_schedules CASCADE;
CREATE TABLE harvest_schedules (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  saturation_id   UUID REFERENCES saturation_records(id) ON DELETE SET NULL,
  crop_type       VARCHAR(100) NOT NULL,
  planned_harvest DATE NOT NULL,
  actual_harvest  DATE,
  estimated_yield DECIMAL(12,2) DEFAULT 0,
  area_ha         DECIMAL(10,2) DEFAULT 0,
  status          VARCHAR(20) DEFAULT 'planned'
                  CHECK (status IN ('planned', 'in_progress', 'completed', 'delayed')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_hs_farmer  ON harvest_schedules(farmer_id);
CREATE INDEX idx_hs_crop    ON harvest_schedules(crop_type);
CREATE INDEX idx_hs_harvest ON harvest_schedules(planned_harvest);
CREATE INDEX idx_hs_status  ON harvest_schedules(status);

-- ============================================================
-- SECTION 2: ENABLE RLS ON NEW TABLES
-- ============================================================

ALTER TABLE market_prices        ENABLE ROW LEVEL SECURITY;
ALTER TABLE agronomic_logbook    ENABLE ROW LEVEL SECURITY;
ALTER TABLE crop_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE supply_projections   ENABLE ROW LEVEL SECURITY;
ALTER TABLE subsidy_allocations  ENABLE ROW LEVEL SECURITY;
ALTER TABLE harvest_schedules    ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- SECTION 3: RLS POLICIES
-- ============================================================

-- market_prices (anyone can read, admins can write)
CREATE POLICY "Anyone can view market prices"
  ON market_prices FOR SELECT USING (true);
CREATE POLICY "Admins insert market prices"
  ON market_prices FOR INSERT WITH CHECK (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );
CREATE POLICY "Admins update market prices"
  ON market_prices FOR UPDATE USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );

-- agronomic_logbook
CREATE POLICY "Farmers view own logbook"
  ON agronomic_logbook FOR SELECT USING (auth.uid() = farmer_id);
CREATE POLICY "Admins view all logbooks"
  ON agronomic_logbook FOR SELECT USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );
CREATE POLICY "Farmers insert own logbook"
  ON agronomic_logbook FOR INSERT WITH CHECK (auth.uid() = farmer_id);
CREATE POLICY "Farmers update own logbook"
  ON agronomic_logbook FOR UPDATE USING (auth.uid() = farmer_id);
CREATE POLICY "Farmers delete own logbook"
  ON agronomic_logbook FOR DELETE USING (auth.uid() = farmer_id);

-- crop_recommendations
CREATE POLICY "Farmers view own recommendations"
  ON crop_recommendations FOR SELECT USING (auth.uid() = farmer_id);
CREATE POLICY "Admins view all recommendations"
  ON crop_recommendations FOR SELECT USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );
CREATE POLICY "System insert recommendations"
  ON crop_recommendations FOR INSERT WITH CHECK (auth.uid() = farmer_id);
CREATE POLICY "Farmers delete own recommendations"
  ON crop_recommendations FOR DELETE USING (auth.uid() = farmer_id);

-- supply_projections (anyone can read, system generates)
CREATE POLICY "Anyone can view supply projections"
  ON supply_projections FOR SELECT USING (true);
CREATE POLICY "Admins manage supply projections"
  ON supply_projections FOR ALL USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );
CREATE POLICY "Authenticated insert projections"
  ON supply_projections FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- subsidy_allocations
CREATE POLICY "Farmers view own subsidies"
  ON subsidy_allocations FOR SELECT USING (auth.uid() = farmer_id);
CREATE POLICY "Admins manage all subsidies"
  ON subsidy_allocations FOR ALL USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );

-- harvest_schedules
CREATE POLICY "Farmers view own schedules"
  ON harvest_schedules FOR SELECT USING (auth.uid() = farmer_id);
CREATE POLICY "Admins view all schedules"
  ON harvest_schedules FOR SELECT USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );
CREATE POLICY "Farmers insert own schedules"
  ON harvest_schedules FOR INSERT WITH CHECK (auth.uid() = farmer_id);
CREATE POLICY "Farmers update own schedules"
  ON harvest_schedules FOR UPDATE USING (auth.uid() = farmer_id);
CREATE POLICY "Farmers delete own schedules"
  ON harvest_schedules FOR DELETE USING (auth.uid() = farmer_id);

-- ============================================================
-- SECTION 4: TRIGGERS FOR updated_at
-- ============================================================

CREATE TRIGGER trg_market_prices_updated        BEFORE UPDATE ON market_prices        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_agronomic_logbook_updated     BEFORE UPDATE ON agronomic_logbook    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_supply_projections_updated    BEFORE UPDATE ON supply_projections   FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_subsidy_allocations_updated   BEFORE UPDATE ON subsidy_allocations  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_harvest_schedules_updated     BEFORE UPDATE ON harvest_schedules    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- SECTION 5: SEED MARKET PRICE DATA
-- ============================================================

INSERT INTO market_prices (crop_type, price_per_kg, price_date, region, trend) VALUES
  ('Rice',         42.00, CURRENT_DATE, 'local', 'stable'),
  ('Corn',         25.00, CURRENT_DATE, 'local', 'rising'),
  ('Tomato',       35.00, CURRENT_DATE, 'local', 'falling'),
  ('Lettuce',      60.00, CURRENT_DATE, 'local', 'stable'),
  ('Eggplant',     30.00, CURRENT_DATE, 'local', 'stable'),
  ('Sweet Potato', 28.00, CURRENT_DATE, 'local', 'rising'),
  ('Carrot',       45.00, CURRENT_DATE, 'local', 'stable'),
  ('Cabbage',      22.00, CURRENT_DATE, 'local', 'falling'),
  ('Watermelon',   18.00, CURRENT_DATE, 'local', 'stable'),
  ('Basil',        120.00, CURRENT_DATE, 'local', 'rising'),
  ('Pepper',       55.00, CURRENT_DATE, 'local', 'stable'),
  ('Spinach',      50.00, CURRENT_DATE, 'local', 'rising'),
  ('Wheat',        30.00, CURRENT_DATE, 'local', 'stable'),
  ('Maize',        22.00, CURRENT_DATE, 'local', 'falling'),
  ('Cotton',       65.00, CURRENT_DATE, 'local', 'rising'),
  ('Sugarcane',    5.00, CURRENT_DATE, 'local', 'stable'),
  ('Pulses',       90.00, CURRENT_DATE, 'local', 'rising');

-- ============================================================
-- DONE! Intelligence layer schema v3 is ready.
-- ============================================================
