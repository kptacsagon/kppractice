-- ============================================================
-- Smart Sack Farming – Migration v2 → v3
-- Business Logic & Data Integrity Upgrade
-- ============================================================
-- HOW TO APPLY:
--   1. Go to Supabase → SQL Editor → New Query
--   2. Paste this entire file
--   3. Click "Run"
--
-- This migration is SAFE to re-run (uses IF NOT EXISTS / IF EXISTS).
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. farming_projects: Add yield, market price & completion fields
-- ────────────────────────────────────────────────────────────

ALTER TABLE farming_projects
  ADD COLUMN IF NOT EXISTS expected_yield_kg       DECIMAL(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS actual_yield_kg         DECIMAL(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS market_price_per_kg     DECIMAL(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS expected_revenue        DECIMAL(15,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS actual_sale_price_per_kg DECIMAL(10,2) DEFAULT 0;

-- ────────────────────────────────────────────────────────────
-- 2. calamity_reports: Add project FK, crop stage, financial loss
-- ────────────────────────────────────────────────────────────

ALTER TABLE calamity_reports
  ADD COLUMN IF NOT EXISTS project_id               UUID REFERENCES farming_projects(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS crop_stage               VARCHAR(50),
  ADD COLUMN IF NOT EXISTS estimated_financial_loss  DECIMAL(15,2) DEFAULT 0;

-- Index for querying calamities by project
CREATE INDEX IF NOT EXISTS idx_cal_project ON calamity_reports(project_id);

-- ────────────────────────────────────────────────────────────
-- 3. production_reports: Add quality class
-- ────────────────────────────────────────────────────────────

ALTER TABLE production_reports
  ADD COLUMN IF NOT EXISTS quality_class VARCHAR(10)
    CHECK (quality_class IN ('A', 'B', 'C'));

-- ────────────────────────────────────────────────────────────
-- 4. expenses: Update phase constraint to include 'sowing' & 'post-harvest'
-- ────────────────────────────────────────────────────────────

-- Drop and re-add the CHECK constraint (safe approach)
DO $$
BEGIN
  -- Drop old constraint if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.constraint_column_usage
    WHERE table_name = 'expenses' AND column_name = 'phase'
  ) THEN
    ALTER TABLE expenses DROP CONSTRAINT IF EXISTS expenses_phase_check;
  END IF;
  
  -- Add updated constraint
  ALTER TABLE expenses ADD CONSTRAINT expenses_phase_check
    CHECK (phase IN ('planting', 'sowing', 'growing', 'harvest', 'post-harvest'));
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ────────────────────────────────────────────────────────────
-- 5. Market prices table (if not exists)
-- ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS market_prices (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crop_type   VARCHAR(100) NOT NULL,
  price_per_kg DECIMAL(10,2) NOT NULL,
  price_date  DATE NOT NULL DEFAULT CURRENT_DATE,
  trend       VARCHAR(20) DEFAULT 'stable'
              CHECK (trend IN ('rising', 'stable', 'falling')),
  source      VARCHAR(255),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mp_crop ON market_prices(crop_type);
CREATE INDEX IF NOT EXISTS idx_mp_date ON market_prices(price_date);

-- Enable RLS on market_prices
ALTER TABLE market_prices ENABLE ROW LEVEL SECURITY;

-- Anyone can read market prices
DROP POLICY IF EXISTS "Anyone can view market prices" ON market_prices;
CREATE POLICY "Anyone can view market prices"
  ON market_prices FOR SELECT USING (true);

-- Only admins can insert/update market prices
DROP POLICY IF EXISTS "Admins manage market prices" ON market_prices;
CREATE POLICY "Admins manage market prices"
  ON market_prices FOR ALL USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin', 'mao')
  );

-- ────────────────────────────────────────────────────────────
-- 6. Seed market prices with Philippine farmgate prices (PSA/DA-BAS)
-- ────────────────────────────────────────────────────────────

-- Delete existing prices and insert fresh seed data (idempotent)
DELETE FROM market_prices WHERE source = 'PSA/DA-BAS Initial Seed';

INSERT INTO market_prices (crop_type, price_per_kg, price_date, trend, source) VALUES
  ('Rice (Palay)',       21.00, CURRENT_DATE, 'stable',  'PSA/DA-BAS Initial Seed'),
  ('Corn (Mais)',        15.00, CURRENT_DATE, 'stable',  'PSA/DA-BAS Initial Seed'),
  ('Coconut (Niyog)',    28.00, CURRENT_DATE, 'rising',  'PSA/DA-BAS Initial Seed'),
  ('Sugarcane (Tubo)',    3.50, CURRENT_DATE, 'stable',  'PSA/DA-BAS Initial Seed'),
  ('Banana (Saging)',    18.00, CURRENT_DATE, 'stable',  'PSA/DA-BAS Initial Seed'),
  ('Vegetables (Gulay)', 25.00, CURRENT_DATE, 'falling', 'PSA/DA-BAS Initial Seed'),
  ('Root Crops',         22.00, CURRENT_DATE, 'stable',  'PSA/DA-BAS Initial Seed'),
  ('Mango',              35.00, CURRENT_DATE, 'rising',  'PSA/DA-BAS Initial Seed'),
  ('Eggplant',           30.00, CURRENT_DATE, 'stable',  'PSA/DA-BAS Initial Seed'),
  ('Tomato',             28.00, CURRENT_DATE, 'falling', 'PSA/DA-BAS Initial Seed'),
  ('Onion',              55.00, CURRENT_DATE, 'rising',  'PSA/DA-BAS Initial Seed');

-- ============================================================
-- DONE! Migration v2 → v3 complete.
-- ============================================================
