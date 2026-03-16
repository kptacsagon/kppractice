-- ============================================================
-- Barangay Setup (run once in Supabase SQL Editor)
-- Creates barangays table for location data in the farming app
-- ============================================================

CREATE TABLE IF NOT EXISTS public.barangays (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        VARCHAR(255) NOT NULL UNIQUE,
  municipality VARCHAR(255),
  province    VARCHAR(255),
  region      VARCHAR(255),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_barangays_name ON public.barangays(name);

ALTER TABLE public.barangays ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read barangays
DROP POLICY IF EXISTS "Users can view barangays" ON public.barangays;
CREATE POLICY "Users can view barangays"
  ON public.barangays FOR SELECT
  USING (auth.role() = 'authenticated');

-- Only admins can insert/update/delete barangays
DROP POLICY IF EXISTS "Admins manage barangays" ON public.barangays;
CREATE POLICY "Admins manage barangays"
  ON public.barangays FOR ALL
  USING ((auth.jwt()->'user_metadata'->>'role') IN ('admin','mao'));

-- Ensure trigger function exists (if not already from other tables)
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_barangays_updated ON public.barangays;
CREATE TRIGGER trg_barangays_updated
  BEFORE UPDATE ON public.barangays
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Quick check
SELECT to_regclass('public.barangays') AS table_created;