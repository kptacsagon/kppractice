-- ============================================================
-- Farmers Setup (run once in Supabase SQL Editor)
-- Creates farmers table for farmer details in the farming app
-- ============================================================

CREATE TABLE IF NOT EXISTS public.farmers (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name          VARCHAR(255) NOT NULL,
  address       TEXT,
  barangay_id   UUID REFERENCES public.barangays(id),
  land_area_ha  DECIMAL(10,2),
  contact_number VARCHAR(20),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_farmers_barangay ON public.farmers(barangay_id);

ALTER TABLE public.farmers ENABLE ROW LEVEL SECURITY;

-- Farmers can view/edit their own profile
DROP POLICY IF EXISTS "Farmers manage own profile" ON public.farmers;
CREATE POLICY "Farmers manage own profile"
  ON public.farmers FOR ALL
  USING (auth.uid() = id);

-- Admins can view all farmers
DROP POLICY IF EXISTS "Admins view all farmers" ON public.farmers;
CREATE POLICY "Admins view all farmers"
  ON public.farmers FOR SELECT
  USING ((auth.jwt()->'user_metadata'->>'role') IN ('admin','mao'));

-- Ensure trigger function exists (if not already from other tables)
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_farmers_updated ON public.farmers;
CREATE TRIGGER trg_farmers_updated
  BEFORE UPDATE ON public.farmers
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Quick check
SELECT to_regclass('public.farmers') AS table_created;