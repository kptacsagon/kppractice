-- Daily Market Saturation Schema
-- Tracks actual market purchases per day to calculate real-time saturation
-- Run this migration to enable daily saturation-based DSS calculations

-- 1. Daily Market Purchases Table
-- Tracks actual product purchases in the market per day
CREATE TABLE IF NOT EXISTS public.daily_market_purchases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    municipality VARCHAR(100) NOT NULL,
    crop_type VARCHAR(100) NOT NULL,
    purchase_date DATE NOT NULL,
    quantity_purchased_kg DECIMAL(12,2) NOT NULL CHECK (quantity_purchased_kg > 0),
    num_buyers INT DEFAULT 1,
    average_price_per_kg DECIMAL(10,2),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dmp_municipality_crop_date 
    ON public.daily_market_purchases(municipality, crop_type, purchase_date);
CREATE INDEX IF NOT EXISTS idx_dmp_crop_date 
    ON public.daily_market_purchases(crop_type, purchase_date);
CREATE INDEX IF NOT EXISTS idx_dmp_purchase_date 
    ON public.daily_market_purchases(purchase_date);

ALTER TABLE public.daily_market_purchases ENABLE ROW LEVEL SECURITY;

-- Policies for daily_market_purchases
DROP POLICY IF EXISTS "Admins can manage daily market purchases" ON public.daily_market_purchases;
CREATE POLICY "Admins can manage daily market purchases"
    ON public.daily_market_purchases FOR ALL
    USING ((auth.jwt()->'user_metadata'->>'role') IN ('admin','mao'));

DROP POLICY IF EXISTS "Public can view daily market purchases" ON public.daily_market_purchases;
CREATE POLICY "Public can view daily market purchases"
    ON public.daily_market_purchases FOR SELECT
    USING (true);

-- 2. Daily Saturation Status Table
-- Stores calculated saturation status per crop per municipality per day
CREATE TABLE IF NOT EXISTS public.daily_saturation_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    municipality VARCHAR(100) NOT NULL,
    crop_type VARCHAR(100) NOT NULL,
    status_date DATE NOT NULL,
    daily_demand_kg DECIMAL(12,2) NOT NULL DEFAULT 0, -- Total purchased that day
    daily_supply_kg DECIMAL(12,2) NOT NULL DEFAULT 0, -- Expected yield available
    saturation_ratio DECIMAL(5,2), -- Supply / Demand * 100
    is_saturated BOOLEAN NOT NULL, -- TRUE if supply > demand
    saturation_level VARCHAR(20), -- 'CRITICALLY_SATURATED', 'SATURATED', 'BALANCED', 'UNDERSUPPLIED'
    num_transactions INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_dss_municipality_crop_date 
    ON public.daily_saturation_status(municipality, crop_type, status_date);
CREATE INDEX IF NOT EXISTS idx_dss_crop_date 
    ON public.daily_saturation_status(crop_type, status_date);
CREATE INDEX IF NOT EXISTS idx_dss_is_saturated 
    ON public.daily_saturation_status(is_saturated, status_date);

ALTER TABLE public.daily_saturation_status ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view daily saturation status" ON public.daily_saturation_status;
CREATE POLICY "Public can view daily saturation status"
    ON public.daily_saturation_status FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Admins can manage saturation status" ON public.daily_saturation_status;
CREATE POLICY "Admins can manage saturation status"
    ON public.daily_saturation_status FOR ALL
    USING ((auth.jwt()->'user_metadata'->>'role') IN ('admin','mao'));

-- 3. Update Trigger for updated_at
CREATE OR REPLACE FUNCTION update_daily_market_purchases_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_daily_market_purchases_updated ON public.daily_market_purchases;
CREATE TRIGGER trg_daily_market_purchases_updated
    BEFORE UPDATE ON public.daily_market_purchases
    FOR EACH ROW EXECUTE FUNCTION update_daily_market_purchases_timestamp();

CREATE OR REPLACE FUNCTION update_daily_saturation_status_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_daily_saturation_status_updated ON public.daily_saturation_status;
CREATE TRIGGER trg_daily_saturation_status_updated
    BEFORE UPDATE ON public.daily_saturation_status
    FOR EACH ROW EXECUTE FUNCTION update_daily_saturation_status_timestamp();

-- 4. Function to Calculate Daily Saturation Status
-- Call this daily to update saturation calculations
CREATE OR REPLACE FUNCTION calculate_daily_saturation_status()
RETURNS TABLE (
    municipality VARCHAR,
    crop_type VARCHAR,
    status_date DATE,
    daily_demand_kg DECIMAL,
    daily_supply_kg DECIMAL,
    saturation_ratio DECIMAL,
    is_saturated BOOLEAN,
    saturation_level VARCHAR
) AS $$
DECLARE
    v_date DATE := CURRENT_DATE - INTERVAL '1 day';
    v_municipality VARCHAR;
    v_crop_type VARCHAR;
    v_demand DECIMAL;
    v_supply DECIMAL;
    v_ratio DECIMAL;
    v_saturated BOOLEAN;
    v_level VARCHAR;
BEGIN
    -- Get all unique municipality/crop combinations from yesterday's purchases
    FOR v_municipality, v_crop_type IN
        SELECT DISTINCT municipality, crop_type 
        FROM daily_market_purchases 
        WHERE purchase_date = v_date
    LOOP
        -- Calculate yesterday's demand
        SELECT COALESCE(SUM(quantity_purchased_kg), 0)
        INTO v_demand
        FROM daily_market_purchases
        WHERE municipality = v_municipality 
        AND crop_type = v_crop_type 
        AND purchase_date = v_date;

        -- Calculate yesterday's available supply from saturation_records
        SELECT COALESCE(SUM(expected_yield_kg), 0)
        INTO v_supply
        FROM saturation_records
        WHERE LOWER(REPLACE(barangay, ' ', '')) = LOWER(REPLACE(v_municipality, ' ', ''))
        AND primary_crop = v_crop_type;

        -- Calculate saturation ratio
        IF v_demand > 0 THEN
            v_ratio := ROUND((v_supply::DECIMAL / v_demand::DECIMAL) * 100, 2);
        ELSE
            v_ratio := 0;
        END IF;

        -- Determine if saturated
        v_saturated := v_supply > v_demand;

        -- Determine saturation level
        IF v_supply > v_demand * 2 THEN
            v_level := 'CRITICALLY_SATURATED';
        ELSIF v_supply > v_demand THEN
            v_level := 'SATURATED';
        ELSIF v_supply >= v_demand * 0.8 THEN
            v_level := 'BALANCED';
        ELSE
            v_level := 'UNDERSUPPLIED';
        END IF;

        -- Insert or update saturation status
        INSERT INTO daily_saturation_status 
        (municipality, crop_type, status_date, daily_demand_kg, daily_supply_kg, 
         saturation_ratio, is_saturated, saturation_level)
        VALUES (v_municipality, v_crop_type, v_date, v_demand, v_supply, 
                v_ratio, v_saturated, v_level)
        ON CONFLICT (municipality, crop_type, status_date) 
        DO UPDATE SET
            daily_demand_kg = EXCLUDED.daily_demand_kg,
            daily_supply_kg = EXCLUDED.daily_supply_kg,
            saturation_ratio = EXCLUDED.saturation_ratio,
            is_saturated = EXCLUDED.is_saturated,
            saturation_level = EXCLUDED.saturation_level,
            updated_at = NOW();

        -- Return the result
        RETURN QUERY
        SELECT v_municipality, v_crop_type, v_date, v_demand, v_supply, 
               v_ratio, v_saturated, v_level;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 5. Sample Data for Testing
-- Insert sample daily market purchases for the last 7 days
INSERT INTO public.daily_market_purchases 
(municipality, crop_type, purchase_date, quantity_purchased_kg, num_buyers, average_price_per_kg)
VALUES
    -- Day -7
    ('Cebu City', 'Tomato', CURRENT_DATE - 7, 450, 8, 55),
    ('Cebu City', 'Onion', CURRENT_DATE - 7, 320, 6, 85),
    -- Day -6
    ('Cebu City', 'Tomato', CURRENT_DATE - 6, 480, 9, 52),
    ('Cebu City', 'Onion', CURRENT_DATE - 6, 350, 7, 82),
    -- Day -5
    ('Cebu City', 'Tomato', CURRENT_DATE - 5, 420, 8, 58),
    ('Cebu City', 'Cabbage', CURRENT_DATE - 5, 280, 5, 40),
    -- Day -4
    ('Cebu City', 'Chili', CURRENT_DATE - 4, 120, 4, 130),
    ('Cebu City', 'Eggplant', CURRENT_DATE - 4, 360, 7, 45),
    -- Day -3
    ('Mandaue City', 'Tomato', CURRENT_DATE - 3, 350, 6, 56),
    ('Mandaue City', 'Onion', CURRENT_DATE - 3, 280, 5, 86),
    -- Day -2
    ('Mandaue City', 'Cabbage', CURRENT_DATE - 2, 240, 4, 38),
    ('Mandaue City', 'Eggplant', CURRENT_DATE - 2, 300, 6, 44),
    -- Day -1 (Yesterday)
    ('Cebu City', 'Tomato', CURRENT_DATE - 1, 500, 10, 53),
    ('Cebu City', 'Onion', CURRENT_DATE - 1, 380, 8, 83),
    ('Mandaue City', 'Tomato', CURRENT_DATE - 1, 400, 8, 54),
    ('Mandaue City', 'Cabbage', CURRENT_DATE - 1, 320, 6, 39)
ON CONFLICT DO NOTHING;

-- Execute saturation calculation for yesterday
SELECT calculate_daily_saturation_status();

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Verification
SELECT 'Daily market purchases table created' AS status;
SELECT * FROM daily_saturation_status ORDER BY status_date DESC, municipality, crop_type LIMIT 10;
