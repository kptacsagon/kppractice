-- RLS Policies for agrisense_farms
-- Run this in Supabase SQL Editor → agrisense_farms table currently blocks all writes.

-- Enable RLS (may already be on)
ALTER TABLE agrisense_farms ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Farmers can insert own farms" ON agrisense_farms;
DROP POLICY IF EXISTS "Farmers can view own farms" ON agrisense_farms;
DROP POLICY IF EXISTS "Authenticated can view all farms" ON agrisense_farms;
DROP POLICY IF EXISTS "Farmers can update own farms" ON agrisense_farms;
DROP POLICY IF EXISTS "Farmers can delete own farms" ON agrisense_farms;

-- INSERT: any authenticated user can register a farm
CREATE POLICY "Farmers can insert own farms"
ON agrisense_farms
FOR INSERT
TO authenticated
WITH CHECK (true);

-- SELECT: authenticated users can read all farms (MAO/BAO need this)
CREATE POLICY "Authenticated can view all farms"
ON agrisense_farms
FOR SELECT
TO authenticated
USING (true);

-- UPDATE: authenticated users can update (BAO verification)
CREATE POLICY "Farmers can update own farms"
ON agrisense_farms
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- DELETE: authenticated users can delete (for draft cleanup)
CREATE POLICY "Farmers can delete own farms"
ON agrisense_farms
FOR DELETE
TO authenticated
USING (true);
