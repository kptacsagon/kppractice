-- ============================================================
-- Smart Sack Farming – P&L Intelligence Migration v4
-- ============================================================
-- HOW TO APPLY
--   1. Go to Supabase → SQL Editor → New Query
--   2. Paste this entire file
--   3. Click "Run"
--
-- NOTE: This is an ADDITIVE migration. It adds new columns
--       to farming_projects for yield-based analytics.
--       Run AFTER supabase_schema.sql (v2) and v3 intelligence.
-- ============================================================

-- ── Add yield & market price columns to farming_projects ────────

ALTER TABLE farming_projects
  ADD COLUMN IF NOT EXISTS expected_yield_kg  DECIMAL(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS actual_yield_kg    DECIMAL(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS market_price_per_kg DECIMAL(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS expected_revenue   DECIMAL(15,2) DEFAULT 0;

-- ── Create index for performance ───────────────────────────────

CREATE INDEX IF NOT EXISTS idx_fp_crop ON farming_projects(crop_type);

-- ── Backfill market prices into existing projects ──────────────
-- This sets market_price_per_kg from the market_prices table
-- for any project that doesn't have one yet.

UPDATE farming_projects fp
SET market_price_per_kg = mp.price_per_kg
FROM (
  SELECT DISTINCT ON (crop_type) crop_type, price_per_kg
  FROM market_prices
  ORDER BY crop_type, price_date DESC
) mp
WHERE fp.crop_type = mp.crop_type
  AND (fp.market_price_per_kg IS NULL OR fp.market_price_per_kg = 0);

-- ── Auto-compute expected_revenue for existing projects ────────

UPDATE farming_projects
SET expected_revenue = expected_yield_kg * market_price_per_kg
WHERE expected_yield_kg > 0
  AND market_price_per_kg > 0
  AND (expected_revenue IS NULL OR expected_revenue = 0);

-- ============================================================
-- DONE! farming_projects now supports yield-based P&L analytics.
-- ============================================================
