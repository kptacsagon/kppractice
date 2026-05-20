-- Supabase Migration: Create Planting Intentions Table
-- Purpose: Store farmer planting plans for market saturation prediction
-- Date: 2026-05-20

-- Create planting_intentions table
CREATE TABLE IF NOT EXISTS planting_intentions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Farmer identification
  farmer_id UUID NOT NULL REFERENCES auth.users(id),
  
  -- Crop details
  crop_id TEXT NOT NULL,
  crop_name TEXT NOT NULL,
  
  -- Location
  barangay TEXT NOT NULL,
  
  -- Planting plan details
  planned_quantity_kg DECIMAL(12, 2) NOT NULL DEFAULT 0,
  land_area_ha DECIMAL(8, 2) NOT NULL DEFAULT 0,
  expected_yield_per_ha_kg DECIMAL(10, 2) NOT NULL DEFAULT 0,
  
  -- Season/Timing
  planting_season TEXT NOT NULL,
  
  -- Status tracking
  status TEXT NOT NULL DEFAULT 'planning',
  
  -- Timestamps
  recorded_at TIMESTAMP NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_quantity CHECK (planned_quantity_kg >= 0),
  CONSTRAINT valid_land_area CHECK (land_area_ha > 0),
  CONSTRAINT valid_yield CHECK (expected_yield_per_ha_kg >= 0)
);

-- Create indexes for common queries
CREATE INDEX idx_planting_intentions_farmer_id ON planting_intentions(farmer_id);
CREATE INDEX idx_planting_intentions_crop_season_barangay 
  ON planting_intentions(crop_name, planting_season, barangay, status);
CREATE INDEX idx_planting_intentions_status ON planting_intentions(status);
CREATE INDEX idx_planting_intentions_season ON planting_intentions(planting_season);

-- Add RLS (Row Level Security) policies
ALTER TABLE planting_intentions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own planting intentions
CREATE POLICY "Users can view own planting intentions"
  ON planting_intentions FOR SELECT
  USING (auth.uid() = farmer_id);

-- Policy: Users can insert own planting intentions
CREATE POLICY "Users can insert own planting intentions"
  ON planting_intentions FOR INSERT
  WITH CHECK (auth.uid() = farmer_id);

-- Policy: Users can update own planting intentions
CREATE POLICY "Users can update own planting intentions"
  ON planting_intentions FOR UPDATE
  USING (auth.uid() = farmer_id)
  WITH CHECK (auth.uid() = farmer_id);

-- Policy: Users can delete own planting intentions
CREATE POLICY "Users can delete own planting intentions"
  ON planting_intentions FOR DELETE
  USING (auth.uid() = farmer_id);

-- Policy: Admins can view all planting intentions (for aggregate analysis)
CREATE POLICY "Admins can view all planting intentions"
  ON planting_intentions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role IN ('admin', 'coordinator')
    )
  );

-- Create a view for market saturation analysis
CREATE VIEW planting_intentions_summary AS
SELECT
  crop_name,
  planting_season,
  barangay,
  COUNT(DISTINCT farmer_id) as total_farmers_planning,
  SUM(planned_quantity_kg) as total_planned_quantity_kg,
  SUM(land_area_ha * expected_yield_per_ha_kg) as estimated_total_harvest_kg,
  AVG(expected_yield_per_ha_kg) as avg_expected_yield_per_ha,
  MIN(recorded_at) as first_recorded,
  MAX(recorded_at) as last_updated
FROM planting_intentions
WHERE status = 'planning'
GROUP BY crop_name, planting_season, barangay;

-- Grant access to the summary view
GRANT SELECT ON planting_intentions_summary TO authenticated;
