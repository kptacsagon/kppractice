-- ============================================================
-- Smart Sack Farming – Migration v3 → v4
-- Adds yield-based revenue & analytics columns to farming_projects
-- ============================================================
-- HOW TO APPLY
--   1. Go to Supabase → SQL Editor → New Query
--   2. Paste this entire file
--   3. Click "Run"
--
-- NOTE: This is ADDITIVE — no data is dropped.
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- SECTION 1: Add yield & market price columns to farming_projects
-- ────────────────────────────────────────────────────────────

ALTER TABLE farming_projects
  ADD COLUMN IF NOT EXISTS expected_yield_kg   DECIMAL(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS actual_yield_kg     DECIMAL(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS market_price_per_kg DECIMAL(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS expected_revenue    DECIMAL(15,2) DEFAULT 0;

-- Index for quick yield-based queries
CREATE INDEX IF NOT EXISTS idx_fp_crop_type ON farming_projects(crop_type);

-- ────────────────────────────────────────────────────────────
-- SECTION 2: Auto-populate market_price_per_kg from market_prices
-- ────────────────────────────────────────────────────────────
-- For existing projects that have 0 market price, backfill
-- from the latest market_prices entry for that crop.

UPDATE farming_projects fp
SET market_price_per_kg = mp.price_per_kg
FROM (
  SELECT DISTINCT ON (crop_type) crop_type, price_per_kg
  FROM market_prices
  ORDER BY crop_type, price_date DESC
) mp
WHERE fp.crop_type = mp.crop_type
  AND (fp.market_price_per_kg IS NULL OR fp.market_price_per_kg = 0);

-- ────────────────────────────────────────────────────────────
-- SECTION 3: RLS policies for new columns (inherit existing)
-- ────────────────────────────────────────────────────────────
-- No new RLS needed — the existing farming_projects policies
-- already cover SELECT/INSERT/UPDATE on all columns.

-- ────────────────────────────────────────────────────────────
-- DONE! farming_projects now supports yield-based analytics.
-- ────────────────────────────────────────────────────────────
