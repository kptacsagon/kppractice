-- ============================================================
-- Profile Images Storage Setup (run once in Supabase SQL Editor)
-- Creates profile-images bucket + policies used by farmer profile upload
-- ============================================================

-- Create storage bucket for profile photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-images', 'profile-images', true)
ON CONFLICT (id) DO NOTHING;

-- Helpful policies (idempotent)
DROP POLICY IF EXISTS "Public can view profile images" ON storage.objects;
CREATE POLICY "Public can view profile images"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'profile-images');

DROP POLICY IF EXISTS "Authenticated can upload profile images" ON storage.objects;
CREATE POLICY "Authenticated can upload profile images"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'profile-images'
    AND auth.role() = 'authenticated'
  );

DROP POLICY IF EXISTS "Users can update own profile images" ON storage.objects;
CREATE POLICY "Users can update own profile images"
  ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'profile-images'
    AND split_part(name, '_', 2) = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'profile-images'
    AND split_part(name, '_', 2) = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can delete own profile images" ON storage.objects;
CREATE POLICY "Users can delete own profile images"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'profile-images'
    AND split_part(name, '_', 2) = auth.uid()::text
  );

-- Quick check
SELECT id, name, public
FROM storage.buckets
WHERE id = 'profile-images';
