-- ============================================================
-- Buyer Messages Setup (run once in Supabase SQL Editor)
-- Creates/updates buyer_crop_requests table used by Message Admin
-- ============================================================

CREATE TABLE IF NOT EXISTS public.buyer_crop_requests (
  id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id                   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  buyer_name                 VARCHAR(255),
  listing_id                 UUID,
  farmer_id                  UUID,
  crop_name                  VARCHAR(100) NOT NULL,
  requested_quantity_kg      DECIMAL(12,2) NOT NULL CHECK (requested_quantity_kg > 0),
  preferred_collection_date  DATE,
  notes                      TEXT,
  status                     VARCHAR(20) NOT NULL DEFAULT 'pending'
                             CHECK (status IN ('pending', 'reviewed', 'approved', 'rejected')),
  created_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.buyer_crop_requests
  ADD COLUMN IF NOT EXISTS listing_id UUID,
  ADD COLUMN IF NOT EXISTS farmer_id UUID,
  ADD COLUMN IF NOT EXISTS preferred_collection_date DATE;

CREATE INDEX IF NOT EXISTS idx_bcr_buyer   ON public.buyer_crop_requests(buyer_id);
CREATE INDEX IF NOT EXISTS idx_bcr_crop    ON public.buyer_crop_requests(crop_name);
CREATE INDEX IF NOT EXISTS idx_bcr_created ON public.buyer_crop_requests(created_at);

ALTER TABLE public.buyer_crop_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Buyers view own crop requests" ON public.buyer_crop_requests;
CREATE POLICY "Buyers view own crop requests"
  ON public.buyer_crop_requests FOR SELECT
  USING (auth.uid() = buyer_id);

DROP POLICY IF EXISTS "Admins view all crop requests" ON public.buyer_crop_requests;
CREATE POLICY "Admins view all crop requests"
  ON public.buyer_crop_requests FOR SELECT
  USING ((auth.jwt()->'user_metadata'->>'role') IN ('admin','mao'));

DROP POLICY IF EXISTS "Buyers insert own crop requests" ON public.buyer_crop_requests;
CREATE POLICY "Buyers insert own crop requests"
  ON public.buyer_crop_requests FOR INSERT
  WITH CHECK (auth.uid() = buyer_id);

DROP POLICY IF EXISTS "Admins update crop requests" ON public.buyer_crop_requests;
CREATE POLICY "Admins update crop requests"
  ON public.buyer_crop_requests FOR UPDATE
  USING ((auth.jwt()->'user_metadata'->>'role') IN ('admin','mao'));

DROP POLICY IF EXISTS "Admins delete crop requests" ON public.buyer_crop_requests;
CREATE POLICY "Admins delete crop requests"
  ON public.buyer_crop_requests FOR DELETE
  USING ((auth.jwt()->'user_metadata'->>'role') IN ('admin','mao'));

-- Ensure trigger function exists
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_buyer_crop_requests_updated ON public.buyer_crop_requests;
CREATE TRIGGER trg_buyer_crop_requests_updated
  BEFORE UPDATE ON public.buyer_crop_requests
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Refresh PostgREST schema cache (important)
NOTIFY pgrst, 'reload schema';

-- Quick check
SELECT to_regclass('public.buyer_crop_requests') AS table_created;
