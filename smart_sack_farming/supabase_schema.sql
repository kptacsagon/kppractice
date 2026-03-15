-- ============================================================
-- Smart Sack Farming – Complete Supabase Database Schema v2
-- ============================================================
-- HOW TO APPLY
--   1. Go to Supabase → SQL Editor → New Query
--   2. Paste this entire file
--   3. Click "Run"
--
-- NOTE: If you already have v1 tables, this script drops them
--       first, so all old data will be lost.
-- ============================================================

-- ============================================================
-- SECTION 0: EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- SECTION 1: DROP OLD TABLES (safe re-run)
-- ============================================================
DROP TABLE IF EXISTS rental_requests   CASCADE;
DROP TABLE IF EXISTS saturation_records CASCADE;
DROP TABLE IF EXISTS expenses          CASCADE;
DROP TABLE IF EXISTS production_reports CASCADE;
DROP TABLE IF EXISTS calamity_reports   CASCADE;
DROP TABLE IF EXISTS equipment         CASCADE;
DROP TABLE IF EXISTS farming_projects   CASCADE;
DROP TABLE IF EXISTS profiles          CASCADE;

-- ============================================================
-- SECTION 2: TABLES
-- ============================================================

-- 1. profiles — extends Supabase Auth
CREATE TABLE profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       VARCHAR(255) NOT NULL,
  full_name   VARCHAR(255),
  role        VARCHAR(20) NOT NULL DEFAULT 'farmer'
              CHECK (role IN ('farmer', 'admin', 'mao')),
  age         INT CHECK (age > 0 AND age <= 120),
  sex         VARCHAR(20) CHECK (sex IN ('male', 'female', 'other')),
  date_of_birth DATE,
  phone       VARCHAR(50),
  address     TEXT,
  land_size_ha DECIMAL(10,2),
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_role  ON profiles(role);

-- 2. saturation_records — crop planting data from saturation module
CREATE TABLE saturation_records (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  primary_crop      VARCHAR(100) NOT NULL,
  companion_crops   TEXT[],
  soil_moisture     DECIMAL(5,2),
  saturation_level  VARCHAR(10) NOT NULL DEFAULT 'low'
                    CHECK (saturation_level IN ('low', 'medium', 'high')),
  planting_date     DATE NOT NULL,
  expected_harvest  DATE,
  field_size_ha     DECIMAL(10,2),
  pesticides        TEXT,
  fertilizer_type   VARCHAR(100),
  irrigation_method VARCHAR(100),
  soil_type         VARCHAR(100),
  expected_yield_kg DECIMAL(12,2),
  notes             TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_saturation_farmer ON saturation_records(farmer_id);
CREATE INDEX idx_saturation_crop   ON saturation_records(primary_crop);
CREATE INDEX idx_saturation_date   ON saturation_records(planting_date);

-- 3. farming_projects — P&L calculator projects
CREATE TABLE farming_projects (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  crop_type               VARCHAR(100) NOT NULL,
  area_hectares           DECIMAL(10,2) NOT NULL DEFAULT 0,
  planting_date           DATE NOT NULL,
  harvest_date            DATE,
  revenue                 DECIMAL(15,2) NOT NULL DEFAULT 0,
  status                  VARCHAR(20) NOT NULL DEFAULT 'active'
                          CHECK (status IN ('active', 'completed', 'cancelled')),
  -- Yield & market price fields
  expected_yield_kg       DECIMAL(12,2) DEFAULT 0,
  actual_yield_kg         DECIMAL(12,2) DEFAULT 0,
  market_price_per_kg     DECIMAL(10,2) DEFAULT 0,     -- projected price at planting
  expected_revenue        DECIMAL(15,2) DEFAULT 0,
  actual_sale_price_per_kg DECIMAL(10,2) DEFAULT 0,    -- actual price recorded on completion
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_fp_farmer ON farming_projects(farmer_id);
CREATE INDEX idx_fp_status ON farming_projects(status);

-- 4. expenses — linked to farming projects
CREATE TABLE expenses (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id   UUID NOT NULL REFERENCES farming_projects(id) ON DELETE CASCADE,
  farmer_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category     VARCHAR(100) NOT NULL,
  description  TEXT,
  amount       DECIMAL(12,2) NOT NULL,
  expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
  phase        VARCHAR(20) NOT NULL DEFAULT 'planting'
               CHECK (phase IN ('planting', 'sowing', 'growing', 'harvest', 'post-harvest')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_expenses_project ON expenses(project_id);
CREATE INDEX idx_expenses_farmer  ON expenses(farmer_id);
CREATE INDEX idx_expenses_date    ON expenses(expense_date);

-- 5. equipment — rental marketplace
CREATE TABLE equipment (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name               VARCHAR(255) NOT NULL,
  description        TEXT,
  category           VARCHAR(100) NOT NULL
                     CHECK (category IN (
                       'Tractor','Plow','Harvester','Sprayer',
                       'Irrigation','Seeder','Trailer','Hand Tool','Other'
                     )),
  daily_rental_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  quantity           INT NOT NULL DEFAULT 1 CHECK (quantity >= 0),
  condition          VARCHAR(50) NOT NULL DEFAULT 'Good'
                     CHECK (condition IN ('New','Good','Fair','Poor')),
  is_available       BOOLEAN NOT NULL DEFAULT TRUE,
  image_url          TEXT,
  owner_name         VARCHAR(255),
  owner_phone        VARCHAR(50),
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_equip_owner    ON equipment(owner_id);
CREATE INDEX idx_equip_category ON equipment(category);
CREATE INDEX idx_equip_avail    ON equipment(is_available);

-- 6. rental_requests — farmer requests equipment from owner
CREATE TABLE rental_requests (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipment_id  UUID NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
  requester_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  owner_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  start_date    DATE NOT NULL,
  end_date      DATE NOT NULL,
  total_cost    DECIMAL(12,2) NOT NULL DEFAULT 0,
  status        VARCHAR(20) NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'approved', 'rejected', 'returned')),
  notes         TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (end_date >= start_date)
);

CREATE INDEX idx_rr_equip     ON rental_requests(equipment_id);
CREATE INDEX idx_rr_requester ON rental_requests(requester_id);
CREATE INDEX idx_rr_owner     ON rental_requests(owner_id);
CREATE INDEX idx_rr_status    ON rental_requests(status);

-- 7. calamity_reports
CREATE TABLE calamity_reports (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id                UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id               UUID REFERENCES farming_projects(id) ON DELETE SET NULL,  -- optional link
  calamity_type            VARCHAR(100) NOT NULL,
  severity                 VARCHAR(10) NOT NULL DEFAULT 'MEDIUM'
                           CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH')),
  date_occurred            DATE NOT NULL,
  affected_area_acres      DECIMAL(10,2) DEFAULT 0,
  affected_crops           TEXT,
  crop_stage               VARCHAR(50),         -- 'Seedling', 'Vegetative', 'Flowering', 'Ready for Harvest'
  description              TEXT,
  damage_estimate          DECIMAL(15,2) DEFAULT 0,
  estimated_financial_loss DECIMAL(15,2) DEFAULT 0,
  farmer_name              VARCHAR(255),
  image_url                TEXT,
  status                   VARCHAR(20) NOT NULL DEFAULT 'reported'
                           CHECK (status IN ('reported', 'verified', 'resolved')),
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cal_farmer   ON calamity_reports(farmer_id);
CREATE INDEX idx_cal_type     ON calamity_reports(calamity_type);
CREATE INDEX idx_cal_date     ON calamity_reports(date_occurred);
CREATE INDEX idx_cal_severity ON calamity_reports(severity);
CREATE INDEX idx_cal_project  ON calamity_reports(project_id);

-- 8. production_reports
CREATE TABLE production_reports (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  crop_type      VARCHAR(100) NOT NULL,
  area_hectares  DECIMAL(10,2) NOT NULL DEFAULT 0,
  planting_date  DATE NOT NULL,
  harvest_date   DATE,
  yield_kg       DECIMAL(12,2) NOT NULL DEFAULT 0,
  quality_rating INT CHECK (quality_rating BETWEEN 1 AND 5),
  quality_class  VARCHAR(10) CHECK (quality_class IN ('A', 'B', 'C')),
  notes          TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_prod_farmer  ON production_reports(farmer_id);
CREATE INDEX idx_prod_crop    ON production_reports(crop_type);
CREATE INDEX idx_prod_harvest ON production_reports(harvest_date);

-- 9. market_prices — crop price tracking for forecasts
CREATE TABLE market_prices (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crop_type    VARCHAR(100) NOT NULL,
  price_per_kg DECIMAL(10,2) NOT NULL,
  price_date   DATE NOT NULL DEFAULT CURRENT_DATE,
  trend        VARCHAR(20) DEFAULT 'stable'
               CHECK (trend IN ('rising', 'stable', 'falling')),
  source       VARCHAR(255),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mp_crop ON market_prices(crop_type);
CREATE INDEX idx_mp_date ON market_prices(price_date);

-- ============================================================
-- SECTION 3: ENABLE ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE profiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE saturation_records  ENABLE ROW LEVEL SECURITY;
ALTER TABLE farming_projects    ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses            ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment           ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_requests     ENABLE ROW LEVEL SECURITY;
ALTER TABLE calamity_reports    ENABLE ROW LEVEL SECURITY;
ALTER TABLE production_reports  ENABLE ROW LEVEL SECURITY;
ALTER TABLE market_prices       ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- SECTION 4: RLS POLICIES
-- ============================================================

-- profiles
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admins can view all profiles"
  ON profiles FOR SELECT USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- saturation_records
CREATE POLICY "Farmers see own saturation records"
  ON saturation_records FOR SELECT USING (auth.uid() = farmer_id);
CREATE POLICY "Admins see all saturation records"
  ON saturation_records FOR SELECT USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );
CREATE POLICY "Farmers insert own saturation records"
  ON saturation_records FOR INSERT WITH CHECK (auth.uid() = farmer_id);
CREATE POLICY "Farmers update own saturation records"
  ON saturation_records FOR UPDATE USING (auth.uid() = farmer_id);
CREATE POLICY "Farmers delete own saturation records"
  ON saturation_records FOR DELETE USING (auth.uid() = farmer_id);

-- farming_projects
CREATE POLICY "Users view own projects"
  ON farming_projects FOR SELECT USING (auth.uid() = farmer_id);
CREATE POLICY "Admins view all projects"
  ON farming_projects FOR SELECT USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );
CREATE POLICY "Users insert own projects"
  ON farming_projects FOR INSERT WITH CHECK (auth.uid() = farmer_id);
CREATE POLICY "Users update own projects"
  ON farming_projects FOR UPDATE USING (auth.uid() = farmer_id);
CREATE POLICY "Users delete own projects"
  ON farming_projects FOR DELETE USING (auth.uid() = farmer_id);

-- expenses
CREATE POLICY "Users view own expenses"
  ON expenses FOR SELECT USING (auth.uid() = farmer_id);
CREATE POLICY "Admins view all expenses"
  ON expenses FOR SELECT USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );
CREATE POLICY "Users insert own expenses"
  ON expenses FOR INSERT WITH CHECK (auth.uid() = farmer_id);
CREATE POLICY "Users update own expenses"
  ON expenses FOR UPDATE USING (auth.uid() = farmer_id);
CREATE POLICY "Users delete own expenses"
  ON expenses FOR DELETE USING (auth.uid() = farmer_id);

-- equipment (anyone can browse, owner can modify)
CREATE POLICY "Anyone can view equipment"
  ON equipment FOR SELECT USING (true);
CREATE POLICY "Owners insert own equipment"
  ON equipment FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Owners update own equipment"
  ON equipment FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Owners delete own equipment"
  ON equipment FOR DELETE USING (auth.uid() = owner_id);

-- rental_requests
CREATE POLICY "Requesters view own rental requests"
  ON rental_requests FOR SELECT USING (auth.uid() = requester_id);
CREATE POLICY "Owners view rental requests for their equipment"
  ON rental_requests FOR SELECT USING (auth.uid() = owner_id);
CREATE POLICY "Admins view all rental requests"
  ON rental_requests FOR SELECT USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );
CREATE POLICY "Users insert own rental requests"
  ON rental_requests FOR INSERT WITH CHECK (auth.uid() = requester_id);
CREATE POLICY "Owners can update rental request status"
  ON rental_requests FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Requesters can delete pending requests"
  ON rental_requests FOR DELETE USING (auth.uid() = requester_id AND status = 'pending');

-- calamity_reports
CREATE POLICY "Farmers view own calamity reports"
  ON calamity_reports FOR SELECT USING (auth.uid() = farmer_id);
CREATE POLICY "Admins view all calamity reports"
  ON calamity_reports FOR SELECT USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );
CREATE POLICY "Farmers insert own calamity reports"
  ON calamity_reports FOR INSERT WITH CHECK (auth.uid() = farmer_id);
CREATE POLICY "Farmers update own calamity reports"
  ON calamity_reports FOR UPDATE USING (auth.uid() = farmer_id);
CREATE POLICY "Farmers delete own calamity reports"
  ON calamity_reports FOR DELETE USING (auth.uid() = farmer_id);

-- production_reports
CREATE POLICY "Farmers view own production reports"
  ON production_reports FOR SELECT USING (auth.uid() = farmer_id);
CREATE POLICY "Admins view all production reports"
  ON production_reports FOR SELECT USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );
CREATE POLICY "Farmers insert own production reports"
  ON production_reports FOR INSERT WITH CHECK (auth.uid() = farmer_id);
CREATE POLICY "Farmers update own production reports"
  ON production_reports FOR UPDATE USING (auth.uid() = farmer_id);
CREATE POLICY "Farmers delete own production reports"
  ON production_reports FOR DELETE USING (auth.uid() = farmer_id);

-- market_prices (anyone can read, admins manage)
DROP POLICY IF EXISTS "Anyone can view market prices" ON market_prices;
CREATE POLICY "Anyone can view market prices"
  ON market_prices FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins manage market prices" ON market_prices;
CREATE POLICY "Admins manage market prices"
  ON market_prices FOR ALL USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );

-- ============================================================
-- SECTION 5: TRIGGERS
-- ============================================================

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    email,
    full_name,
    role,
    age,
    sex,
    date_of_birth,
    phone,
    address,
    land_size_ha
  )
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    COALESCE(NEW.raw_user_meta_data->>'role', 'farmer'),
    NULLIF(NEW.raw_user_meta_data->>'age', '')::INT,
    LOWER(NULLIF(NEW.raw_user_meta_data->>'sex', '')),
    NULLIF(NEW.raw_user_meta_data->>'date_of_birth', '')::DATE,
    NEW.raw_user_meta_data->>'phone',
    NEW.raw_user_meta_data->>'address',
    NULLIF(NEW.raw_user_meta_data->>'land_size_ha', '')::DECIMAL
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated           BEFORE UPDATE ON profiles           FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_saturation_records_updated  BEFORE UPDATE ON saturation_records  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_farming_projects_updated    BEFORE UPDATE ON farming_projects    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_expenses_updated            BEFORE UPDATE ON expenses            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_equipment_updated           BEFORE UPDATE ON equipment           FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_rental_requests_updated     BEFORE UPDATE ON rental_requests     FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_calamity_reports_updated    BEFORE UPDATE ON calamity_reports    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_production_reports_updated  BEFORE UPDATE ON production_reports  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_market_prices_updated       BEFORE UPDATE ON market_prices       FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- SECTION 6: STORAGE BUCKET FOR IMAGES (optional)
-- ============================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('farm-images', 'farm-images', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Anyone can view farm images"           ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload farm images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own farm images"      ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own farm images"      ON storage.objects;

CREATE POLICY "Anyone can view farm images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'farm-images');

CREATE POLICY "Authenticated users can upload farm images"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'farm-images' AND auth.role() = 'authenticated');

CREATE POLICY "Users can update own farm images"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'farm-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own farm images"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'farm-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ============================================================
-- DONE! Your database schema v2 is ready.
-- ============================================================
