-- =============================================================================
-- Supabase Migration: Crop Cycling Monitoring System
-- Version: 1.0
-- Date: May 17, 2026
-- Purpose: Comprehensive crop rotation tracking, soil health monitoring, 
--          disease/pest risk assessment, and rotation recommendations
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- =============================================================================
-- SECTION 1: FARMER FIELDS/PLOTS MANAGEMENT
-- =============================================================================

CREATE TABLE IF NOT EXISTS farmer_fields (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  farmer_id UUID NOT NULL,
  field_name VARCHAR(255) NOT NULL,
  location_municipality VARCHAR(255) NOT NULL,
  location_barangay VARCHAR(255),
  area_hectares DECIMAL(10, 2) NOT NULL,
  soil_type VARCHAR(100) NOT NULL, -- 'clay', 'loam', 'sandy', 'sandy_loam', 'clay_loam'
  soil_ph DECIMAL(4, 2),
  irrigation_type VARCHAR(100), -- 'rainfed', 'irrigated', 'mixed'
  elevation_meters INTEGER,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_farmer_fields_farmer_id ON farmer_fields(farmer_id);
CREATE INDEX idx_farmer_fields_municipality ON farmer_fields(location_municipality);

-- =============================================================================
-- SECTION 2: CROP ROTATION HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS crop_rotation_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  field_id UUID NOT NULL,
  farmer_id UUID NOT NULL,
  crop_type VARCHAR(100) NOT NULL,
  planting_date DATE NOT NULL,
  harvest_date DATE,
  area_planted_hectares DECIMAL(10, 2),
  yield_kg DECIMAL(15, 2),
  status VARCHAR(50) DEFAULT 'active', -- 'active', 'harvested', 'abandoned'
  disease_observed BOOLEAN DEFAULT false,
  disease_notes TEXT,
  pest_observed BOOLEAN DEFAULT false,
  pest_notes TEXT,
  soil_observations TEXT,
  input_notes TEXT,
  recorded_by_farmer BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  FOREIGN KEY (field_id) REFERENCES farmer_fields(id) ON DELETE CASCADE
);

CREATE INDEX idx_crop_rotation_field_id ON crop_rotation_history(field_id);
CREATE INDEX idx_crop_rotation_farmer_id ON crop_rotation_history(farmer_id);
CREATE INDEX idx_crop_rotation_planting_date ON crop_rotation_history(planting_date);
CREATE INDEX idx_crop_rotation_crop_type ON crop_rotation_history(crop_type);

-- =============================================================================
-- SECTION 3: RECOMMENDED CROP CYCLES
-- =============================================================================

CREATE TABLE IF NOT EXISTS recommended_crop_cycles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  soil_type VARCHAR(100) NOT NULL,
  cycle_name VARCHAR(255) NOT NULL,
  cycle_description TEXT,
  crops_in_cycle TEXT[] NOT NULL, -- Array of crop types
  cycle_duration_months INTEGER NOT NULL,
  soil_health_benefit VARCHAR(255),
  pest_disease_mitigation TEXT,
  nitrogen_fixation BOOLEAN DEFAULT false,
  recommended_order INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_recommended_cycles_soil_type ON recommended_crop_cycles(soil_type);

-- Pre-populate with common crop cycles
INSERT INTO recommended_crop_cycles (soil_type, cycle_name, cycle_description, crops_in_cycle, cycle_duration_months, soil_health_benefit, pest_disease_mitigation, nitrogen_fixation, recommended_order)
VALUES 
  ('loam', 'Tomato-Legume-Eggplant', 'High-value vegetables with soil restoration', ARRAY['Tomato', 'Mungbean', 'Eggplant'], 12, 'Nitrogen restoration via mungbean', 'Breaks tomato/eggplant pest cycles', true, 1),
  ('loam', 'Onion-Rice-Cabbage', 'Mixed high-demand crops', ARRAY['Onion', 'Rice', 'Cabbage'], 12, 'Rice reduces soil compaction', 'Diverse crop types reduce pest buildup', false, 2),
  ('clay', 'Cabbage-Legume-Eggplant', 'Clay-suitable rotation', ARRAY['Cabbage', 'Mungbean', 'Eggplant'], 12, 'Legumes improve clay structure', 'Breaks brassica pests', true, 1),
  ('sandy_loam', 'Chili-Corn-Okra', 'Drought-tolerant rotation', ARRAY['Chili', 'Corn', 'Okra'], 9, 'Corn provides organic matter', 'Diverse host plants reduce pest pressure', false, 1),
  ('sandy', 'Okra-Legume-Chili', 'Sandy soil improvement', ARRAY['Okra', 'Mungbean', 'Chili'], 12, 'Legumes restore nitrogen in poor soils', 'Breaks chili/okra diseases', true, 1)
ON CONFLICT DO NOTHING;

-- =============================================================================
-- SECTION 4: CROP CYCLING COMPLIANCE & MONITORING
-- =============================================================================

CREATE TABLE IF NOT EXISTS crop_cycling_monitoring (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  field_id UUID NOT NULL,
  farmer_id UUID NOT NULL,
  monitoring_date DATE NOT NULL,
  
  -- Rotation Status
  is_following_recommended_cycle BOOLEAN,
  recommended_cycle_id UUID,
  recommended_next_crop VARCHAR(100),
  days_until_next_planting INTEGER,
  
  -- Soil Health Indicators
  soil_fatigue_risk VARCHAR(50), -- 'low', 'medium', 'high'
  consecutive_same_crop INTEGER DEFAULT 0,
  years_since_legume_crop DECIMAL(3, 1) DEFAULT 0,
  
  -- Disease/Pest Risk
  disease_pressure_level VARCHAR(50), -- 'low', 'medium', 'high'
  pest_pressure_level VARCHAR(50), -- 'low', 'medium', 'high'
  monoculture_risk_score DECIMAL(5, 2) DEFAULT 0, -- 0-100
  
  -- Recommendations
  recommended_action TEXT,
  urgency_level VARCHAR(50), -- 'low', 'medium', 'high'
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  FOREIGN KEY (field_id) REFERENCES farmer_fields(id) ON DELETE CASCADE,
  FOREIGN KEY (recommended_cycle_id) REFERENCES recommended_crop_cycles(id)
);

CREATE INDEX idx_crop_cycling_monitoring_field_id ON crop_cycling_monitoring(field_id);
CREATE INDEX idx_crop_cycling_monitoring_farmer_id ON crop_cycling_monitoring(farmer_id);
CREATE INDEX idx_crop_cycling_monitoring_date ON crop_cycling_monitoring(monitoring_date);

-- =============================================================================
-- SECTION 5: CROP COMPATIBILITY MATRIX
-- =============================================================================

CREATE TABLE IF NOT EXISTS crop_compatibility (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  crop_a VARCHAR(100) NOT NULL,
  crop_b VARCHAR(100) NOT NULL,
  compatibility_score DECIMAL(3, 2), -- 0-1 (1 = excellent rotation pair)
  reason TEXT,
  can_follow BOOLEAN DEFAULT true, -- Can crop_b follow crop_a?
  notes TEXT
);

CREATE INDEX idx_crop_compatibility_crops ON crop_compatibility(crop_a, crop_b);

-- Pre-populate compatibility data
INSERT INTO crop_compatibility (crop_a, crop_b, compatibility_score, reason, can_follow, notes)
VALUES 
  ('Tomato', 'Mungbean', 0.95, 'Mungbean fixes nitrogen after tomato depletion', true, 'Excellent rotation'),
  ('Tomato', 'Eggplant', 0.40, 'Both susceptible to similar pests/diseases', true, 'Risky - same family'),
  ('Onion', 'Rice', 0.90, 'Rice breaks onion pest cycle, doesn''t deplete similar nutrients', true, 'Good rotation'),
  ('Onion', 'Cabbage', 0.70, 'Both are cool-season crops, moderate compatibility', true, 'Acceptable'),
  ('Eggplant', 'Cabbage', 0.75, 'Different pest susceptibility', true, 'Good rotation'),
  ('Cabbage', 'Mungbean', 0.95, 'Legume restores nitrogen depleted by brassica', true, 'Excellent'),
  ('Chili', 'Corn', 0.80, 'Corn provides organic matter for chili growth', true, 'Good'),
  ('Okra', 'Mungbean', 0.85, 'Legume improves soil structure', true, 'Good rotation'),
  ('Mungbean', 'Tomato', 0.95, 'Legume-rich soil perfect for heavy feeder tomato', true, 'Excellent'),
  ('Rice', 'Onion', 0.85, 'Breaks onion cycles, rice residue enriches soil', true, 'Good'),
  ('Tomato', 'Tomato', 0.20, 'Monoculture high risk for disease buildup', false, 'Avoid same crop'),
  ('Eggplant', 'Eggplant', 0.25, 'Monoculture increases pest pressure', false, 'Avoid same crop'),
  ('Onion', 'Onion', 0.30, 'Monoculture depletes specific nutrients', false, 'Avoid same crop')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- SECTION 6: CROP CYCLING ALERTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS crop_cycling_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  farmer_id UUID NOT NULL,
  field_id UUID NOT NULL,
  alert_type VARCHAR(100) NOT NULL, -- 'monoculture_risk', 'disease_pressure', 'soil_fatigue', 'legume_overdue'
  alert_title VARCHAR(255) NOT NULL,
  alert_message TEXT NOT NULL,
  recommended_action TEXT,
  severity VARCHAR(50), -- 'low', 'medium', 'high', 'critical'
  is_read BOOLEAN DEFAULT false,
  action_taken BOOLEAN DEFAULT false,
  action_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  FOREIGN KEY (field_id) REFERENCES farmer_fields(id) ON DELETE CASCADE
);

CREATE INDEX idx_alerts_farmer_id ON crop_cycling_alerts(farmer_id);
CREATE INDEX idx_alerts_field_id ON crop_cycling_alerts(field_id);
CREATE INDEX idx_alerts_severity ON crop_cycling_alerts(severity);
CREATE INDEX idx_alerts_is_read ON crop_cycling_alerts(is_read);

-- =============================================================================
-- SECTION 7: CROP CYCLING RECOMMENDATIONS ENGINE
-- =============================================================================

CREATE OR REPLACE FUNCTION analyze_crop_cycling_for_field(
  p_field_id UUID,
  p_monitoring_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  field_id UUID,
  current_crop VARCHAR,
  last_harvest_date DATE,
  days_since_harvest INTEGER,
  recommended_next_crop VARCHAR,
  soil_fatigue_risk VARCHAR,
  disease_pressure_level VARCHAR,
  pest_pressure_level VARCHAR,
  monoculture_risk_score DECIMAL,
  recommended_action TEXT,
  urgency_level VARCHAR
) AS $$
DECLARE
  v_farmer_id UUID;
  v_soil_type VARCHAR(100);
  v_current_crop VARCHAR(100);
  v_last_crop VARCHAR(100);
  v_last_harvest_date DATE;
  v_consecutive_count INTEGER;
  v_years_since_legume DECIMAL(3, 1);
  v_recommended_cycle_id UUID;
  v_recommended_next_crop VARCHAR(100);
  v_compatibility_score DECIMAL(3, 2);
  v_soil_fatigue VARCHAR(50);
  v_disease_level VARCHAR(50);
  v_pest_level VARCHAR(50);
  v_monoculture_risk DECIMAL(5, 2);
  v_action_text TEXT;
  v_urgency VARCHAR(50);
BEGIN
  -- Get farmer and field info
  SELECT f.farmer_id, f.soil_type INTO v_farmer_id, v_soil_type
  FROM farmer_fields f
  WHERE f.id = p_field_id
  LIMIT 1;

  -- Get current and recent crop history
  SELECT crh.crop_type, crh.harvest_date
  INTO v_current_crop, v_last_harvest_date
  FROM crop_rotation_history crh
  WHERE crh.field_id = p_field_id
  ORDER BY crh.planting_date DESC
  LIMIT 1;

  -- Get previous crop for compatibility check
  SELECT crh.crop_type INTO v_last_crop
  FROM crop_rotation_history crh
  WHERE crh.field_id = p_field_id
    AND crh.crop_type != COALESCE(v_current_crop, '')
  ORDER BY crh.planting_date DESC
  LIMIT 1;

  -- Count consecutive plantings of same crop
  SELECT COUNT(*) INTO v_consecutive_count
  FROM crop_rotation_history crh
  WHERE crh.field_id = p_field_id
    AND crh.crop_type = COALESCE(v_current_crop, '');

  -- Calculate years since last legume crop
  SELECT COALESCE(
    EXTRACT(YEAR FROM AGE(p_monitoring_date, MAX(crh.planting_date)))::DECIMAL(3, 1),
    999.0
  ) INTO v_years_since_legume
  FROM crop_rotation_history crh
  WHERE crh.field_id = p_field_id
    AND crh.crop_type IN ('Mungbean', 'Peanut', 'Cowpea', 'Soybean');

  -- Get recommended cycle for soil type
  SELECT id INTO v_recommended_cycle_id
  FROM recommended_crop_cycles
  WHERE soil_type = v_soil_type
  ORDER BY recommended_order ASC
  LIMIT 1;

  -- Determine recommended next crop
  SELECT COALESCE((crops_in_cycle)[2], (crops_in_cycle)[1])
  INTO v_recommended_next_crop
  FROM recommended_crop_cycles
  WHERE id = v_recommended_cycle_id;

  -- Get compatibility score if there's a previous crop
  IF v_last_crop IS NOT NULL THEN
    SELECT compatibility_score INTO v_compatibility_score
    FROM crop_compatibility
    WHERE (crop_a = v_last_crop AND crop_b = COALESCE(v_current_crop, ''))
    LIMIT 1;
  END IF;

  -- Assess soil fatigue risk
  IF v_consecutive_count > 2 THEN
    v_soil_fatigue := 'high';
  ELSIF v_consecutive_count > 1 THEN
    v_soil_fatigue := 'medium';
  ELSE
    v_soil_fatigue := 'low';
  END IF;

  -- Assess disease pressure
  IF v_consecutive_count > 2 OR v_years_since_legume > 2 THEN
    v_disease_level := 'high';
  ELSIF v_consecutive_count > 1 THEN
    v_disease_level := 'medium';
  ELSE
    v_disease_level := 'low';
  END IF;

  -- Assess pest pressure (similar logic)
  IF v_consecutive_count > 2 THEN
    v_pest_level := 'high';
  ELSIF v_consecutive_count > 1 THEN
    v_pest_level := 'medium';
  ELSE
    v_pest_level := 'low';
  END IF;

  -- Calculate monoculture risk score (0-100)
  v_monoculture_risk := (v_consecutive_count * 25.0) + 
                        (CASE WHEN v_years_since_legume > 2 THEN 25 ELSE 0 END) +
                        (CASE WHEN COALESCE(v_compatibility_score, 1.0) < 0.5 THEN 25 ELSE 0 END);
  v_monoculture_risk := LEAST(100, GREATEST(0, v_monoculture_risk));

  -- Generate action recommendation
  v_action_text := '';
  v_urgency := 'low';

  IF v_consecutive_count > 2 THEN
    v_action_text := 'CRITICAL: ' || v_current_crop || ' has been planted consecutively ' || v_consecutive_count || ' times. Implement crop rotation immediately.';
    v_urgency := 'critical';
  ELSIF v_consecutive_count = 2 THEN
    v_action_text := 'HIGH RISK: ' || v_current_crop || ' monoculture detected. Plan rotation to ' || COALESCE(v_recommended_next_crop, 'a different crop') || ' for next season.';
    v_urgency := 'high';
  ELSIF v_years_since_legume > 2 THEN
    v_action_text := 'Consider planting a legume crop (Mungbean, Peanut) to restore soil nitrogen.';
    v_urgency := 'medium';
  ELSE
    v_action_text := 'Current rotation looks good. Plan ahead for next season using recommended cycles.';
    v_urgency := 'low';
  END IF;

  RETURN QUERY SELECT
    p_field_id,
    v_current_crop,
    v_last_harvest_date,
    COALESCE((p_monitoring_date - v_last_harvest_date)::INTEGER, 0),
    v_recommended_next_crop,
    v_soil_fatigue,
    v_disease_level,
    v_pest_level,
    v_monoculture_risk,
    v_action_text,
    v_urgency;
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================================================
-- SECTION 8: AUTO-GENERATE MONITORING DATA
-- =============================================================================

CREATE OR REPLACE FUNCTION refresh_crop_cycling_monitoring()
RETURNS TABLE (field_id UUID, monitoring_count INTEGER) AS $$
DECLARE
  v_field_id UUID;
  v_analysis RECORD;
BEGIN
  FOR v_field_id IN SELECT DISTINCT field_id FROM crop_rotation_history LOOP
    SELECT * INTO v_analysis FROM analyze_crop_cycling_for_field(v_field_id);
    
    INSERT INTO crop_cycling_monitoring (
      field_id,
      farmer_id,
      monitoring_date,
      recommended_cycle_id,
      recommended_next_crop,
      soil_fatigue_risk,
      disease_pressure_level,
      pest_pressure_level,
      monoculture_risk_score,
      recommended_action,
      urgency_level
    )
    SELECT
      v_analysis.field_id,
      (SELECT farmer_id FROM farmer_fields WHERE id = v_analysis.field_id),
      CURRENT_DATE,
      (SELECT id FROM recommended_crop_cycles WHERE soil_type = (SELECT soil_type FROM farmer_fields WHERE id = v_analysis.field_id) LIMIT 1),
      v_analysis.recommended_next_crop,
      v_analysis.soil_fatigue_risk,
      v_analysis.disease_pressure_level,
      v_analysis.pest_pressure_level,
      v_analysis.monoculture_risk_score,
      v_analysis.recommended_action,
      v_analysis.urgency_level
    ON CONFLICT DO NOTHING;
    
    RETURN QUERY SELECT v_analysis.field_id, 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- SECTION 9: ROW-LEVEL SECURITY
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE farmer_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE crop_rotation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE crop_cycling_monitoring ENABLE ROW LEVEL SECURITY;
ALTER TABLE crop_cycling_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE recommended_crop_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE crop_compatibility ENABLE ROW LEVEL SECURITY;

-- Policies for farmer_fields
CREATE POLICY "Farmers can view their own fields" ON farmer_fields
  FOR SELECT USING (
    farmer_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'mao', 'technician')
    )
  );

CREATE POLICY "Farmers can manage their own fields" ON farmer_fields
  FOR ALL USING (
    farmer_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'mao')
    )
  );

-- Policies for crop_rotation_history
CREATE POLICY "Farmers can view their rotation history" ON crop_rotation_history
  FOR SELECT USING (
    farmer_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'mao', 'technician')
    )
  );

CREATE POLICY "Farmers can manage their rotation records" ON crop_rotation_history
  FOR ALL USING (
    farmer_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'mao')
    )
  );

-- Policies for crop_cycling_monitoring (public read, role-based write)
CREATE POLICY "Farmers can view their monitoring data" ON crop_cycling_monitoring
  FOR SELECT USING (
    farmer_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'mao', 'technician')
    )
  );

CREATE POLICY "System can update monitoring data" ON crop_cycling_monitoring
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'mao', 'system')
    )
  );

-- Policies for crop_cycling_alerts
CREATE POLICY "Farmers can view their alerts" ON crop_cycling_alerts
  FOR SELECT USING (
    farmer_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'mao', 'technician')
    )
  );

CREATE POLICY "System can manage alerts" ON crop_cycling_alerts
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'mao', 'system')
    )
  );

-- Public read for reference tables
CREATE POLICY "Everyone can view crop compatibility" ON crop_compatibility
  FOR SELECT USING (true);

CREATE POLICY "Everyone can view recommended cycles" ON recommended_crop_cycles
  FOR SELECT USING (true);

-- =============================================================================
-- SECTION 10: SAMPLE DATA FOR TESTING
-- =============================================================================

INSERT INTO farmer_fields (farmer_id, field_name, location_municipality, location_barangay, area_hectares, soil_type, soil_ph, irrigation_type, elevation_meters)
VALUES
  ('ca481a02-7075-44c2-9dee-b23a478654bf', 'North Field - Plot A', 'Cebu City', 'Mabolo', 0.5, 'loam', 6.8, 'irrigated', 50),
  ('ca481a02-7075-44c2-9dee-b23a478654bf', 'South Field - Plot B', 'Cebu City', 'Mabolo', 0.75, 'clay_loam', 7.0, 'rainfed', 45),
  ('ca481a02-7075-44c2-9dee-b23a478654bf', 'West Field - Plot C', 'Mandaue City', 'Tipolo', 1.0, 'sandy_loam', 6.5, 'irrigated', 60)
ON CONFLICT DO NOTHING;

INSERT INTO crop_rotation_history (field_id, farmer_id, crop_type, planting_date, harvest_date, area_planted_hectares, yield_kg, status, disease_observed, pest_observed)
VALUES
  ((SELECT id FROM farmer_fields WHERE field_name = 'North Field - Plot A' LIMIT 1), 'ca481a02-7075-44c2-9dee-b23a478654bf', 'Tomato', '2025-11-01', '2026-02-15', 0.5, 2500, 'harvested', false, true),
  ((SELECT id FROM farmer_fields WHERE field_name = 'North Field - Plot A' LIMIT 1), 'ca481a02-7075-44c2-9dee-b23a478654bf', 'Tomato', '2026-03-01', NULL, 0.5, NULL, 'active', false, false),
  ((SELECT id FROM farmer_fields WHERE field_name = 'South Field - Plot B' LIMIT 1), 'ca481a02-7075-44c2-9dee-b23a478654bf', 'Onion', '2025-09-01', '2026-01-20', 0.75, 3200, 'harvested', false, false),
  ((SELECT id FROM farmer_fields WHERE field_name = 'South Field - Plot B' LIMIT 1), 'ca481a02-7075-44c2-9dee-b23a478654bf', 'Cabbage', '2026-02-01', NULL, 0.75, NULL, 'active', false, true),
  ((SELECT id FROM farmer_fields WHERE field_name = 'West Field - Plot C' LIMIT 1), 'ca481a02-7075-44c2-9dee-b23a478654bf', 'Chili', '2025-06-01', '2026-01-10', 1.0, 1800, 'harvested', true, true),
  ((SELECT id FROM farmer_fields WHERE field_name = 'West Field - Plot C' LIMIT 1), 'ca481a02-7075-44c2-9dee-b23a478654bf', 'Chili', '2026-02-15', NULL, 1.0, NULL, 'active', true, false)
ON CONFLICT DO NOTHING;

-- =============================================================================
-- SECTION 11: REFRESH MONITORING DATA
-- =============================================================================

SELECT refresh_crop_cycling_monitoring();

-- =============================================================================
-- END OF MIGRATION
-- =============================================================================
-- Summary:
-- - Created farmer_fields table for field/plot management
-- - Created crop_rotation_history to track plantings per field
-- - Created recommended_crop_cycles with pre-populated best practices
-- - Created crop_cycling_monitoring for auto-generated monitoring
-- - Created crop_cycling_alerts for risk notifications
-- - Created crop_compatibility matrix for rotation recommendations
-- - Implemented analyze_crop_cycling_for_field() function for analysis
-- - Implemented refresh_crop_cycling_monitoring() for auto-updates
-- - Configured RLS policies for multi-role access control
-- - Added sample test data
-- =============================================================================
