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
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS age INT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS sex VARCHAR(20);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS land_size_ha DECIMAL(10,2);

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

-- ── Notify PostgREST to reload schema cache ─────────────────
NOTIFY pgrst, 'reload schema';

-- ============================================================
-- DONE! Column names updated to v2 schema.
-- ============================================================
