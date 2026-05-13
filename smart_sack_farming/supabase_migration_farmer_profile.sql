-- Supabase SQL Migration: Farmer Profile Setup
-- Ensures profiles table has all required fields and proper RLS policies

-- 1. Alter profiles table to add missing columns if they don't exist
ALTER TABLE IF EXISTS public.profiles
ADD COLUMN IF NOT EXISTS address text NOT NULL DEFAULT '',
ADD COLUMN IF NOT EXISTS age smallint,
ADD COLUMN IF NOT EXISTS sex text DEFAULT 'Prefer not to say',
ADD COLUMN IF NOT EXISTS date_of_birth date,
ADD COLUMN IF NOT EXISTS land_size_ha numeric(10, 2),
ADD COLUMN IF NOT EXISTS profile_complete boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS profile_photo_url text,
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- 2. Enable RLS on profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.profiles;

-- 4. Create RLS Policies

-- Policy: Users can view their own profile
CREATE POLICY "Users can view their own profile"
  ON public.profiles
  FOR SELECT
  USING (
    auth.uid() = id OR
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

-- Policy: Users can update their own profile
CREATE POLICY "Users can update their own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Policy: Admins can view all profiles
CREATE POLICY "Admins can view all profiles"
  ON public.profiles
  FOR SELECT
  USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

-- Policy: Admins can update any profile
CREATE POLICY "Admins can update any profile"
  ON public.profiles
  FOR UPDATE
  USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

-- Policy: Enable insert for authenticated users
CREATE POLICY "Enable insert for authenticated users"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- 5. Create complete_profile() RPC function
DROP FUNCTION IF EXISTS public.complete_profile(
  p_user_id uuid,
  p_address text,
  p_age smallint,
  p_sex text,
  p_date_of_birth date,
  p_land_size_ha numeric
);

CREATE OR REPLACE FUNCTION public.complete_profile(
  p_user_id uuid,
  p_address text,
  p_age smallint,
  p_sex text,
  p_date_of_birth date,
  p_land_size_ha numeric DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result json;
  v_profile_row record;
BEGIN
  -- Verify user is updating their own profile or is an admin
  IF auth.uid() != p_user_id THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    ) THEN
      RETURN json_build_object(
        'success', false,
        'message', 'Unauthorized: You can only update your own profile'
      );
    END IF;
  END IF;

  -- Update the profile
  UPDATE public.profiles
  SET
    address = COALESCE(p_address, address),
    age = COALESCE(p_age, age),
    sex = COALESCE(p_sex, sex),
    date_of_birth = COALESCE(p_date_of_birth, date_of_birth),
    land_size_ha = COALESCE(p_land_size_ha, land_size_ha),
    profile_complete = true,
    updated_at = now()
  WHERE id = p_user_id
  RETURNING * INTO v_profile_row;

  IF v_profile_row IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Profile not found'
    );
  END IF;

  v_result := json_build_object(
    'success', true,
    'message', 'Profile completed successfully',
    'profile', json_build_object(
      'id', v_profile_row.id,
      'email', v_profile_row.email,
      'full_name', v_profile_row.full_name,
      'role', v_profile_row.role,
      'address', v_profile_row.address,
      'age', v_profile_row.age,
      'sex', v_profile_row.sex,
      'date_of_birth', v_profile_row.date_of_birth,
      'land_size_ha', v_profile_row.land_size_ha,
      'profile_complete', v_profile_row.profile_complete,
      'updated_at', v_profile_row.updated_at
    )
  );

  RETURN v_result;
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'message', 'Error completing profile: ' || SQLERRM
  );
END;
$$;

-- 6. Grant permissions on the function
GRANT EXECUTE ON FUNCTION public.complete_profile TO authenticated;

-- 7. Create an index for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_profile_complete ON public.profiles(profile_complete);

-- 8. Add a constraint to ensure sex has valid values
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS valid_sex;
ALTER TABLE public.profiles
ADD CONSTRAINT valid_sex CHECK (sex IN ('Male', 'Female', 'Prefer not to say'));

-- 9. Add a constraint for age to be reasonable
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS valid_age;
ALTER TABLE public.profiles
ADD CONSTRAINT valid_age CHECK (age IS NULL OR (age >= 13 AND age <= 120));

-- 10. Add a constraint for land size to be positive
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS valid_land_size;
ALTER TABLE public.profiles
ADD CONSTRAINT valid_land_size CHECK (land_size_ha IS NULL OR land_size_ha > 0);

-- 11. Storage bucket for profile photos
-- Note: Create this bucket manually in Supabase Storage or run:
-- INSERT INTO storage.buckets (id, name, public) VALUES ('profile-photos', 'profile-photos', true);
-- Then add this policy:
-- CREATE POLICY "Users can upload their own photos" ON storage.objects
--   FOR INSERT WITH CHECK (bucket_id = 'profile-photos' AND (auth.uid())::text = (storage.foldername(name))[1]);
-- CREATE POLICY "Users can view all photos" ON storage.objects
--   FOR SELECT USING (bucket_id = 'profile-photos');
-- CREATE POLICY "Users can delete their own photos" ON storage.objects
--   FOR DELETE USING (bucket_id = 'profile-photos' AND (auth.uid())::text = (storage.foldername(name))[1]);

-- Verify RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables 
WHERE tablename = 'profiles' AND schemaname = 'public';
