-- Farm Registry Module — Full Schema Migration
-- Run this in Supabase SQL Editor to unlock all PRD fields.
-- Safe to run multiple times (uses IF NOT EXISTS / ADD COLUMN IF NOT EXISTS).

ALTER TABLE agrisense_farms
  ADD COLUMN IF NOT EXISTS province TEXT NOT NULL DEFAULT 'Iloilo',
  ADD COLUMN IF NOT EXISTS sitio TEXT,
  ADD COLUMN IF NOT EXISTS ownership_type TEXT NOT NULL DEFAULT 'Owner',
  ADD COLUMN IF NOT EXISTS primary_crop TEXT,
  ADD COLUMN IF NOT EXISTS secondary_crop TEXT,
  ADD COLUMN IF NOT EXISTS farming_method TEXT DEFAULT 'Conventional',
  ADD COLUMN IF NOT EXISTS crop_seasonality TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS expected_yield_kg NUMERIC,
  ADD COLUMN IF NOT EXISTS harvests_per_year INTEGER,
  ADD COLUMN IF NOT EXISTS terrain_type TEXT,
  ADD COLUMN IF NOT EXISTS soil_notes TEXT,
  ADD COLUMN IF NOT EXISTS irrigation_type TEXT DEFAULT 'Rainfed',
  ADD COLUMN IF NOT EXISTS water_sources TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS irrigation_notes TEXT,
  ADD COLUMN IF NOT EXISTS distance_to_market_km NUMERIC,
  ADD COLUMN IF NOT EXISTS transportation_access TEXT,
  ADD COLUMN IF NOT EXISTS road_type TEXT,
  ADD COLUMN IF NOT EXISTS travel_time_to_market_min INTEGER,
  ADD COLUMN IF NOT EXISTS flood_prone TEXT DEFAULT 'Unknown',
  ADD COLUMN IF NOT EXISTS landslide_risk TEXT DEFAULT 'Unknown',
  ADD COLUMN IF NOT EXISTS drought_risk TEXT DEFAULT 'Unknown',
  ADD COLUMN IF NOT EXISTS vulnerability_notes TEXT,
  ADD COLUMN IF NOT EXISTS centroid_lat NUMERIC,
  ADD COLUMN IF NOT EXISTS centroid_lng NUMERIC,
  ADD COLUMN IF NOT EXISTS verification_status TEXT NOT NULL DEFAULT 'Draft',
  ADD COLUMN IF NOT EXISTS privacy_consent_given BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS rejection_reason_code TEXT,
  ADD COLUMN IF NOT EXISTS rejection_note TEXT;

-- Index for fast status filtering
CREATE INDEX IF NOT EXISTS idx_agrisense_farms_status
  ON agrisense_farms (verification_status);

-- Index for barangay aggregation (Phase 3 analytics)
CREATE INDEX IF NOT EXISTS idx_agrisense_farms_barangay
  ON agrisense_farms (barangay, municipality);
