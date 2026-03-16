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
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS organization VARCHAR(255);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS age INT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS sex VARCHAR(20);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS land_size_ha DECIMAL(10,2);

-- ── buyer_crop_requests (buyer -> admin crop contact) ───────
CREATE TABLE IF NOT EXISTS buyer_crop_requests (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id              UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  buyer_name            VARCHAR(255),
  listing_id            UUID,
  farmer_id             UUID,
  crop_name             VARCHAR(100) NOT NULL,
  requested_quantity_kg DECIMAL(12,2) NOT NULL CHECK (requested_quantity_kg > 0),
  preferred_collection_date DATE,
  notes                 TEXT,
  status                VARCHAR(20) NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'reviewed', 'approved', 'rejected')),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bcr_buyer   ON buyer_crop_requests(buyer_id);
CREATE INDEX IF NOT EXISTS idx_bcr_crop    ON buyer_crop_requests(crop_name);
CREATE INDEX IF NOT EXISTS idx_bcr_created ON buyer_crop_requests(created_at);

ALTER TABLE buyer_crop_requests ADD COLUMN IF NOT EXISTS listing_id UUID;
ALTER TABLE buyer_crop_requests ADD COLUMN IF NOT EXISTS farmer_id UUID;
ALTER TABLE buyer_crop_requests ADD COLUMN IF NOT EXISTS preferred_collection_date DATE;

ALTER TABLE buyer_crop_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Buyers view own crop requests" ON buyer_crop_requests;
CREATE POLICY "Buyers view own crop requests"
  ON buyer_crop_requests FOR SELECT USING (auth.uid() = buyer_id);

DROP POLICY IF EXISTS "Admins view all crop requests" ON buyer_crop_requests;
CREATE POLICY "Admins view all crop requests"
  ON buyer_crop_requests FOR SELECT USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );

DROP POLICY IF EXISTS "Buyers insert own crop requests" ON buyer_crop_requests;
CREATE POLICY "Buyers insert own crop requests"
  ON buyer_crop_requests FOR INSERT WITH CHECK (auth.uid() = buyer_id);

DROP POLICY IF EXISTS "Admins update crop requests" ON buyer_crop_requests;
CREATE POLICY "Admins update crop requests"
  ON buyer_crop_requests FOR UPDATE USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );

DROP POLICY IF EXISTS "Admins delete crop requests" ON buyer_crop_requests;
CREATE POLICY "Admins delete crop requests"
  ON buyer_crop_requests FOR DELETE USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );

DROP TRIGGER IF EXISTS trg_buyer_crop_requests_updated ON buyer_crop_requests;
CREATE TRIGGER trg_buyer_crop_requests_updated
  BEFORE UPDATE ON buyer_crop_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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
    organization,
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
    NEW.raw_user_meta_data->>'organization',
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
