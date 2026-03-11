-- ============================================================
-- Smart Sack Farming – Migration v5: Buyer Marketplace
-- ============================================================
-- DESCRIPTION: Adds buyer role and crop reservation marketplace
-- where buyers can purchase/reserve oversaturated crops from farmers.
-- ============================================================

-- ============================================================
-- SECTION 1: UPDATE PROFILES TABLE FOR BUYER ROLE
-- ============================================================

-- Add 'buyer' to the role check constraint
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
  CHECK (role IN ('farmer', 'admin', 'mao', 'buyer'));

-- ============================================================
-- SECTION 2: BUYER PROFILES (extends profiles with buyer-specific info)
-- ============================================================

CREATE TABLE IF NOT EXISTS buyer_profiles (
  id            UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  business_name VARCHAR(255),
  business_type VARCHAR(100) CHECK (business_type IN (
    'Retailer', 'Wholesaler', 'Restaurant', 'Food Processor', 
    'Exporter', 'Market Vendor', 'Individual', 'Other'
  )),
  contact_phone VARCHAR(50),
  delivery_address TEXT,
  preferred_crops TEXT[], -- Array of preferred crop names
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_buyer_profiles_business ON buyer_profiles(business_type);

-- ============================================================
-- SECTION 3: CROP LISTINGS (Oversaturated crops for sale)
-- ============================================================

CREATE TABLE IF NOT EXISTS crop_listings (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  saturation_record_id UUID REFERENCES saturation_records(id) ON DELETE SET NULL,
  
  -- Crop info
  crop_name           VARCHAR(100) NOT NULL,
  crop_icon           VARCHAR(10),
  quantity_kg         DECIMAL(12,2) NOT NULL CHECK (quantity_kg > 0),
  available_quantity_kg DECIMAL(12,2) NOT NULL CHECK (available_quantity_kg >= 0),
  price_per_kg        DECIMAL(10,2) NOT NULL CHECK (price_per_kg > 0),
  
  -- Condition info
  saturation_level    VARCHAR(10) NOT NULL DEFAULT 'high'
                      CHECK (saturation_level IN ('low', 'medium', 'high')),
  quality_grade       VARCHAR(10) DEFAULT 'B'
                      CHECK (quality_grade IN ('A', 'B', 'C')),
  harvest_date        DATE,
  expiry_date         DATE,
  
  -- Location & Details
  farm_location       VARCHAR(255),
  description         TEXT,
  image_url           TEXT,
  
  -- Farmer info (denormalized for performance)
  farmer_name         VARCHAR(255),
  farmer_phone        VARCHAR(50),
  
  -- Status
  status              VARCHAR(20) NOT NULL DEFAULT 'available'
                      CHECK (status IN ('available', 'reserved', 'sold', 'expired', 'cancelled')),
  
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_crop_listing_farmer ON crop_listings(farmer_id);
CREATE INDEX IF NOT EXISTS idx_crop_listing_crop ON crop_listings(crop_name);
CREATE INDEX IF NOT EXISTS idx_crop_listing_status ON crop_listings(status);
CREATE INDEX IF NOT EXISTS idx_crop_listing_saturation ON crop_listings(saturation_level);
CREATE INDEX IF NOT EXISTS idx_crop_listing_harvest ON crop_listings(harvest_date);

-- ============================================================
-- SECTION 4: CROP RESERVATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS crop_reservations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id      UUID NOT NULL REFERENCES crop_listings(id) ON DELETE CASCADE,
  buyer_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  farmer_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Reservation details
  quantity_kg     DECIMAL(12,2) NOT NULL CHECK (quantity_kg > 0),
  price_per_kg    DECIMAL(10,2) NOT NULL,
  total_amount    DECIMAL(15,2) NOT NULL,
  
  -- Status tracking
  status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'confirmed', 'ready_for_pickup', 
                                    'completed', 'cancelled', 'rejected')),
  
  -- Dates
  reservation_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  pickup_date      DATE,
  completed_date   TIMESTAMPTZ,
  
  -- Notes
  buyer_notes     TEXT,
  farmer_notes    TEXT,
  cancellation_reason TEXT,
  
  -- Contact info snapshot
  buyer_name      VARCHAR(255),
  buyer_phone     VARCHAR(50),
  delivery_address TEXT,
  
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reservation_listing ON crop_reservations(listing_id);
CREATE INDEX IF NOT EXISTS idx_reservation_buyer ON crop_reservations(buyer_id);
CREATE INDEX IF NOT EXISTS idx_reservation_farmer ON crop_reservations(farmer_id);
CREATE INDEX IF NOT EXISTS idx_reservation_status ON crop_reservations(status);

-- ============================================================
-- SECTION 5: ENABLE RLS
-- ============================================================

ALTER TABLE buyer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE crop_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE crop_reservations ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- SECTION 6: RLS POLICIES
-- ============================================================

-- buyer_profiles
DROP POLICY IF EXISTS "Users can view own buyer profile" ON buyer_profiles;
CREATE POLICY "Users can view own buyer profile"
  ON buyer_profiles FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can insert own buyer profile" ON buyer_profiles;
CREATE POLICY "Users can insert own buyer profile"
  ON buyer_profiles FOR INSERT WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "Users can update own buyer profile" ON buyer_profiles;
CREATE POLICY "Users can update own buyer profile"
  ON buyer_profiles FOR UPDATE USING (auth.uid() = id);

-- crop_listings (publicly visible)
DROP POLICY IF EXISTS "Anyone can view available crop listings" ON crop_listings;
CREATE POLICY "Anyone can view available crop listings"
  ON crop_listings FOR SELECT USING (true);
DROP POLICY IF EXISTS "Farmers can insert own crop listings" ON crop_listings;
CREATE POLICY "Farmers can insert own crop listings"
  ON crop_listings FOR INSERT WITH CHECK (auth.uid() = farmer_id);
DROP POLICY IF EXISTS "Farmers can update own crop listings" ON crop_listings;
CREATE POLICY "Farmers can update own crop listings"
  ON crop_listings FOR UPDATE USING (auth.uid() = farmer_id);
DROP POLICY IF EXISTS "Farmers can delete own crop listings" ON crop_listings;
CREATE POLICY "Farmers can delete own crop listings"
  ON crop_listings FOR DELETE USING (auth.uid() = farmer_id);

-- crop_reservations
DROP POLICY IF EXISTS "Buyers can view own reservations" ON crop_reservations;
CREATE POLICY "Buyers can view own reservations"
  ON crop_reservations FOR SELECT USING (auth.uid() = buyer_id);
DROP POLICY IF EXISTS "Farmers can view reservations for their listings" ON crop_reservations;
CREATE POLICY "Farmers can view reservations for their listings"
  ON crop_reservations FOR SELECT USING (auth.uid() = farmer_id);
DROP POLICY IF EXISTS "Admins can view all reservations" ON crop_reservations;
CREATE POLICY "Admins can view all reservations"
  ON crop_reservations FOR SELECT USING (
    (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao')
  );
DROP POLICY IF EXISTS "Buyers can create reservations" ON crop_reservations;
CREATE POLICY "Buyers can create reservations"
  ON crop_reservations FOR INSERT WITH CHECK (auth.uid() = buyer_id);
DROP POLICY IF EXISTS "Farmers can update reservation status" ON crop_reservations;
CREATE POLICY "Farmers can update reservation status"
  ON crop_reservations FOR UPDATE USING (auth.uid() = farmer_id);
DROP POLICY IF EXISTS "Buyers can update own pending reservations" ON crop_reservations;
CREATE POLICY "Buyers can update own pending reservations"
  ON crop_reservations FOR UPDATE USING (auth.uid() = buyer_id AND status = 'pending');

-- ============================================================
-- SECTION 7: TRIGGERS
-- ============================================================

-- Auto-update updated_at for new tables
DROP TRIGGER IF EXISTS update_buyer_profiles_updated_at ON buyer_profiles;
CREATE TRIGGER update_buyer_profiles_updated_at
  BEFORE UPDATE ON buyer_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_crop_listings_updated_at ON crop_listings;
CREATE TRIGGER update_crop_listings_updated_at
  BEFORE UPDATE ON crop_listings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_crop_reservations_updated_at ON crop_reservations;
CREATE TRIGGER update_crop_reservations_updated_at
  BEFORE UPDATE ON crop_reservations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- SECTION 8: HELPER FUNCTION - Update listing availability
-- ============================================================

CREATE OR REPLACE FUNCTION update_listing_availability()
RETURNS TRIGGER AS $$
BEGIN
  -- When a reservation is confirmed, reduce available quantity
  IF NEW.status = 'confirmed' AND (OLD.status IS NULL OR OLD.status = 'pending') THEN
    UPDATE crop_listings 
    SET available_quantity_kg = available_quantity_kg - NEW.quantity_kg,
        status = CASE 
          WHEN available_quantity_kg - NEW.quantity_kg <= 0 THEN 'reserved'
          ELSE status
        END
    WHERE id = NEW.listing_id;
  END IF;
  
  -- When a reservation is cancelled/rejected, restore available quantity
  IF NEW.status IN ('cancelled', 'rejected') AND OLD.status IN ('pending', 'confirmed') THEN
    UPDATE crop_listings 
    SET available_quantity_kg = LEAST(available_quantity_kg + NEW.quantity_kg, quantity_kg),
        status = CASE 
          WHEN status = 'reserved' THEN 'available'
          ELSE status
        END
    WHERE id = NEW.listing_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_reservation_status_change ON crop_reservations;
CREATE TRIGGER on_reservation_status_change
  AFTER UPDATE OF status ON crop_reservations
  FOR EACH ROW EXECUTE FUNCTION update_listing_availability();

-- For new reservations that are immediately confirmed
DROP TRIGGER IF EXISTS on_reservation_insert ON crop_reservations;
CREATE TRIGGER on_reservation_insert
  AFTER INSERT ON crop_reservations
  FOR EACH ROW 
  WHEN (NEW.status = 'confirmed')
  EXECUTE FUNCTION update_listing_availability();

-- ============================================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================================
-- Uncomment below to insert sample crop listings
/*
INSERT INTO crop_listings (farmer_id, crop_name, crop_icon, quantity_kg, available_quantity_kg, price_per_kg, saturation_level, quality_grade, farm_location, description)
VALUES 
  ('YOUR_FARMER_UUID', 'Rice', '🌾', 500, 500, 45.00, 'high', 'B', 'Barangay Poblacion', 'Oversaturated rice from monsoon season, selling at discount'),
  ('YOUR_FARMER_UUID', 'Corn', '🌽', 300, 300, 35.00, 'high', 'B', 'Barangay Poblacion', 'High moisture corn, good for animal feed');
*/
