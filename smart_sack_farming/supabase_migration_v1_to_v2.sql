-- ============================================================
-- Smart Sack Farming – Migration v1 → v2
-- Run this in Supabase → SQL Editor to fix column names
-- WITHOUT losing existing data.
-- ============================================================

-- ── expenses ────────────────────────────────────────────────
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='expenses' AND column_name='date') THEN
    ALTER TABLE expenses RENAME COLUMN date TO expense_date;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='expenses' AND column_name='user_id') THEN
    ALTER TABLE expenses RENAME COLUMN user_id TO farmer_id;
  END IF;
END $$;

-- Add missing columns to expenses if not present
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS phase VARCHAR(20) NOT NULL DEFAULT 'planting';
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS farmer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- ── farming_projects ────────────────────────────────────────
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='farming_projects' AND column_name='area') THEN
    ALTER TABLE farming_projects RENAME COLUMN area TO area_hectares;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='farming_projects' AND column_name='user_id') THEN
    ALTER TABLE farming_projects RENAME COLUMN user_id TO farmer_id;
  END IF;
END $$;

-- ── calamity_reports ────────────────────────────────────────
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='calamity_reports' AND column_name='type') THEN
    ALTER TABLE calamity_reports RENAME COLUMN type TO calamity_type;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='calamity_reports' AND column_name='date') THEN
    ALTER TABLE calamity_reports RENAME COLUMN date TO date_occurred;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='calamity_reports' AND column_name='area_affected') THEN
    ALTER TABLE calamity_reports RENAME COLUMN area_affected TO affected_area_acres;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='calamity_reports' AND column_name='user_id') THEN
    ALTER TABLE calamity_reports RENAME COLUMN user_id TO farmer_id;
  END IF;
END $$;

-- ── production_reports ──────────────────────────────────────
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='production_reports' AND column_name='area') THEN
    ALTER TABLE production_reports RENAME COLUMN area TO area_hectares;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='production_reports' AND column_name='yield') THEN
    ALTER TABLE production_reports RENAME COLUMN yield TO yield_kg;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='production_reports' AND column_name='user_id') THEN
    ALTER TABLE production_reports RENAME COLUMN user_id TO farmer_id;
  END IF;
END $$;

-- ── equipment ───────────────────────────────────────────────
ALTER TABLE equipment ADD COLUMN IF NOT EXISTS condition VARCHAR(50) NOT NULL DEFAULT 'Good';

-- ── profiles ────────────────────────────────────────────────
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone VARCHAR(50);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- ── Notify PostgREST to reload schema cache ─────────────────
NOTIFY pgrst, 'reload schema';

-- ============================================================
-- DONE! Column names updated to v2 schema.
-- ============================================================
