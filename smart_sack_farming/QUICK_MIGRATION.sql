-- Quick Migration: Add missing columns to profiles table
-- Run this in your Supabase SQL Editor to enable address and other farmer fields

-- Add missing columns if they don't exist
ALTER TABLE profiles 
  ADD COLUMN IF NOT EXISTS age INT CHECK (age > 0 AND age <= 120),
  ADD COLUMN IF NOT EXISTS sex VARCHAR(20) CHECK (sex IN ('male', 'female', 'other')),
  ADD COLUMN IF NOT EXISTS date_of_birth DATE,
  ADD COLUMN IF NOT EXISTS address TEXT,
  ADD COLUMN IF NOT EXISTS land_size_ha DECIMAL(10,2);

-- Update the trigger function to include address extraction
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    email,
    full_name,
    role,
    age,
    sex,
    date_of_birth,
    phone,
    address,
    land_size_ha
  )
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    COALESCE(NEW.raw_user_meta_data->>'role', 'farmer'),
    NULLIF(NEW.raw_user_meta_data->>'age', '')::INT,
    LOWER(NULLIF(NEW.raw_user_meta_data->>'sex', '')),
    NULLIF(NEW.raw_user_meta_data->>'date_of_birth', '')::DATE,
    NEW.raw_user_meta_data->>'phone',
    NEW.raw_user_meta_data->>'address',
    NULLIF(NEW.raw_user_meta_data->>'land_size_ha', '')::DECIMAL
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Done! The app will now save address for new farmers.
-- Existing farmers will get address when they update their profile.
