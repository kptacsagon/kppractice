-- Fix profiles role CHECK constraint to include mao and baw roles

ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE profiles ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('farmer', 'admin', 'mao', 'baw', 'buyer'));
