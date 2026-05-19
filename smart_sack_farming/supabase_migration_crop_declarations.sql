-- AgriSense DSS PRD §5.1 — crop_declarations table

CREATE TABLE IF NOT EXISTS crop_declarations (
  id              TEXT PRIMARY KEY,
  farmer_id       UUID NOT NULL,
  farmer_name     TEXT NOT NULL DEFAULT '',
  crop_id         TEXT NOT NULL,
  crop_name       TEXT NOT NULL,
  barangay        TEXT,
  farm_lot        TEXT,
  area_planted_ha NUMERIC(8,4) NOT NULL,
  planting_date   TIMESTAMPTZ NOT NULL,
  expected_harvest_date TIMESTAMPTZ NOT NULL,
  actual_harvest_date   TIMESTAMPTZ,
  estimated_volume_kg   NUMERIC(10,2) NOT NULL,
  actual_volume_kg      NUMERIC(10,2),
  farming_method  TEXT,
  remarks         TEXT,
  status          TEXT NOT NULL DEFAULT 'pending_review'
                  CHECK (status IN ('pending_review','validated','returned','harvested','cancelled')),
  technician_id   UUID,
  at_notes        TEXT,
  submitted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  validated_at    TIMESTAMPTZ
);

-- PRD §6.2 — required indexes
CREATE INDEX IF NOT EXISTS idx_crop_declarations_farmer    ON crop_declarations(farmer_id);
CREATE INDEX IF NOT EXISTS idx_crop_declarations_status    ON crop_declarations(status);
CREATE INDEX IF NOT EXISTS idx_crop_declarations_barangay  ON crop_declarations(barangay);
CREATE INDEX IF NOT EXISTS idx_crop_declarations_harvest   ON crop_declarations(expected_harvest_date);

-- RLS (PRD §6.1)
ALTER TABLE crop_declarations ENABLE ROW LEVEL SECURITY;

-- Farmers can see only their own
DROP POLICY IF EXISTS "farmers_own_declarations" ON crop_declarations;
CREATE POLICY "farmers_own_declarations" ON crop_declarations
  FOR SELECT USING (auth.uid() = farmer_id);

DROP POLICY IF EXISTS "farmers_insert_own" ON crop_declarations;
CREATE POLICY "farmers_insert_own" ON crop_declarations
  FOR INSERT WITH CHECK (auth.uid() = farmer_id);

-- BAW/MAO can see/update all (simplified: any authenticated non-anon)
DROP POLICY IF EXISTS "baw_mao_read_all" ON crop_declarations;
CREATE POLICY "baw_mao_read_all" ON crop_declarations
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "baw_mao_update" ON crop_declarations;
CREATE POLICY "baw_mao_update" ON crop_declarations
  FOR UPDATE USING (auth.role() = 'authenticated');
