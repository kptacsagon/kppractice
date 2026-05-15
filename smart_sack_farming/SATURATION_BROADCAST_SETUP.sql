-- Saturation Broadcast Alerts Table
-- Stores alerts sent by MAO/Admin to notify farmers about crop saturation

CREATE TABLE IF NOT EXISTS public.saturation_broadcasts (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id              UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  admin_name            VARCHAR(255),
  municipality          VARCHAR(255),
  title                 VARCHAR(255) NOT NULL,
  description           TEXT NOT NULL,
  
  -- Saturation data included in broadcast
  high_saturation_crops TEXT[] DEFAULT ARRAY[]::TEXT[],  -- Crops with high saturation
  medium_saturation_crops TEXT[] DEFAULT ARRAY[]::TEXT[], -- Crops with medium saturation
  low_saturation_crops  TEXT[] DEFAULT ARRAY[]::TEXT[],   -- Crops with low saturation (good to plant)
  
  -- Recommendations
  recommendations       TEXT,
  
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Saturation Broadcast Recipients (tracks who has read the alert)
CREATE TABLE IF NOT EXISTS public.saturation_broadcast_recipients (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  broadcast_id          UUID NOT NULL REFERENCES public.saturation_broadcasts(id) ON DELETE CASCADE,
  farmer_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  farmer_name           VARCHAR(255),
  is_read               BOOLEAN DEFAULT FALSE,
  read_at               TIMESTAMPTZ,
  
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(broadcast_id, farmer_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_saturation_broadcasts_admin ON public.saturation_broadcasts(admin_id);
CREATE INDEX IF NOT EXISTS idx_saturation_broadcasts_created ON public.saturation_broadcasts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_saturation_broadcast_recipients_farmer ON public.saturation_broadcast_recipients(farmer_id);
CREATE INDEX IF NOT EXISTS idx_saturation_broadcast_recipients_broadcast ON public.saturation_broadcast_recipients(broadcast_id);
CREATE INDEX IF NOT EXISTS idx_saturation_broadcast_recipients_unread ON public.saturation_broadcast_recipients(is_read);

-- Enable Row Level Security
ALTER TABLE public.saturation_broadcasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saturation_broadcast_recipients ENABLE ROW LEVEL SECURITY;

-- Policies for saturation_broadcasts
DROP POLICY IF EXISTS "Admins create broadcasts" ON public.saturation_broadcasts;
CREATE POLICY "Admins create broadcasts"
  ON public.saturation_broadcasts FOR INSERT
  WITH CHECK ((auth.jwt()->'user_metadata'->>'role') IN ('admin','mao'));

DROP POLICY IF EXISTS "Admins view own broadcasts" ON public.saturation_broadcasts;
CREATE POLICY "Admins view own broadcasts"
  ON public.saturation_broadcasts FOR SELECT
  USING (auth.uid() = admin_id OR (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao'));

DROP POLICY IF EXISTS "Farmers view all broadcasts" ON public.saturation_broadcasts;
CREATE POLICY "Farmers view all broadcasts"
  ON public.saturation_broadcasts FOR SELECT
  USING ((auth.jwt()->'user_metadata'->>'role') = 'farmer');

DROP POLICY IF EXISTS "Admins update broadcasts" ON public.saturation_broadcasts;
CREATE POLICY "Admins update broadcasts"
  ON public.saturation_broadcasts FOR UPDATE
  USING (auth.uid() = admin_id OR (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao'));

-- Policies for saturation_broadcast_recipients
DROP POLICY IF EXISTS "Farmers view own broadcast records" ON public.saturation_broadcast_recipients;
CREATE POLICY "Farmers view own broadcast records"
  ON public.saturation_broadcast_recipients FOR SELECT
  USING (auth.uid() = farmer_id OR (auth.jwt()->'user_metadata'->>'role') IN ('admin','mao'));

DROP POLICY IF EXISTS "Admins view all broadcast records" ON public.saturation_broadcast_recipients;
CREATE POLICY "Admins view all broadcast records"
  ON public.saturation_broadcast_recipients FOR SELECT
  USING ((auth.jwt()->'user_metadata'->>'role') IN ('admin','mao'));

DROP POLICY IF EXISTS "Farmers update own broadcast records" ON public.saturation_broadcast_recipients;
CREATE POLICY "Farmers update own broadcast records"
  ON public.saturation_broadcast_recipients FOR UPDATE
  USING (auth.uid() = farmer_id);

-- Trigger to update timestamps
DROP TRIGGER IF EXISTS trg_saturation_broadcasts_updated ON public.saturation_broadcasts;
CREATE TRIGGER trg_saturation_broadcasts_updated
  BEFORE UPDATE ON public.saturation_broadcasts
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_saturation_broadcast_recipients_updated ON public.saturation_broadcast_recipients;
CREATE TRIGGER trg_saturation_broadcast_recipients_updated
  BEFORE UPDATE ON public.saturation_broadcast_recipients
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Function to create a broadcast and notify all farmers
CREATE OR REPLACE FUNCTION public.broadcast_saturation_alert(
  p_admin_id UUID,
  p_admin_name VARCHAR,
  p_municipality VARCHAR,
  p_title VARCHAR,
  p_description TEXT,
  p_high_saturation_crops TEXT[],
  p_medium_saturation_crops TEXT[],
  p_low_saturation_crops TEXT[],
  p_recommendations TEXT
)
RETURNS UUID AS $$
DECLARE
  v_broadcast_id UUID;
  v_farmer_record RECORD;
BEGIN
  -- Insert the broadcast record
  INSERT INTO public.saturation_broadcasts (
    admin_id,
    admin_name,
    municipality,
    title,
    description,
    high_saturation_crops,
    medium_saturation_crops,
    low_saturation_crops,
    recommendations
  ) VALUES (
    p_admin_id,
    p_admin_name,
    p_municipality,
    p_title,
    p_description,
    p_high_saturation_crops,
    p_medium_saturation_crops,
    p_low_saturation_crops,
    p_recommendations
  ) RETURNING id INTO v_broadcast_id;

  -- Notify all farmers in the system
  FOR v_farmer_record IN
    SELECT id, full_name FROM public.profiles
    WHERE role = 'farmer'
  LOOP
    INSERT INTO public.saturation_broadcast_recipients (
      broadcast_id,
      farmer_id,
      farmer_name,
      is_read
    ) VALUES (
      v_broadcast_id,
      v_farmer_record.id,
      v_farmer_record.full_name,
      FALSE
    );
  END LOOP;

  RETURN v_broadcast_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Sample broadcast for testing
-- SELECT public.broadcast_saturation_alert(
--   '550e8400-e29b-41d4-a716-446655440000'::UUID,
--   'Test Admin',
--   'San Mateo',
--   'High Saturation Alert: Rice Oversupply',
--   'Multiple farmers have reported high soil saturation levels for rice cultivation. Consider planting alternative crops like corn or cassava.',
--   ARRAY['Rice', 'Tomato'],
--   ARRAY['Corn', 'Squash'],
--   ARRAY['Cassava', 'Sweet Potato'],
--   'Plant drought-resistant crops or delay planting until saturation decreases.'
-- );

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Verify tables created
SELECT 
  table_name 
FROM information_schema.tables 
WHERE table_name IN ('saturation_broadcasts', 'saturation_broadcast_recipients');
