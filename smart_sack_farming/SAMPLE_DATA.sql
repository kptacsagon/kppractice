-- ============================================================
-- Sample Data Setup (run after setup SQLs in Supabase SQL Editor)
-- Inserts sample barangays, farmers, and planting records for testing
-- ============================================================

-- Insert sample barangays
INSERT INTO public.barangays (name, municipality, province, region) VALUES
('Barangay A', 'Municipality X', 'Province Y', 'Region Z'),
('Barangay B', 'Municipality X', 'Province Y', 'Region Z'),
('Barangay C', 'Municipality X', 'Province Y', 'Region Z')
ON CONFLICT (name) DO NOTHING;

-- Note: For farmers and planting_records, you need actual user IDs from auth.users.
-- Replace 'dummy-user-id-1' etc. with real UUIDs from your Supabase auth.users table.
-- You can get user IDs by running: SELECT id, email FROM auth.users;

-- Insert sample farmers (replace with real user IDs)
-- Assuming you have users with roles 'farmer'
INSERT INTO public.farmers (id, name, address, barangay_id, land_area_ha, contact_number) VALUES
('dummy-user-id-1', 'Juan Dela Cruz', '123 Main St, Barangay A', (SELECT id FROM public.barangays WHERE name = 'Barangay A'), 2.5, '09123456789'),
('dummy-user-id-2', 'Maria Santos', '456 Oak Ave, Barangay B', (SELECT id FROM public.barangays WHERE name = 'Barangay B'), 1.8, '09987654321'),
('dummy-user-id-3', 'Pedro Reyes', '789 Pine Rd, Barangay C', (SELECT id FROM public.barangays WHERE name = 'Barangay C'), 3.2, '09112233445')
ON CONFLICT (id) DO NOTHING;

-- Insert sample planting records (with farmer_id NULL for testing projections)
INSERT INTO public.planting_records (farmer_id, crop_name, area_planted_ha, estimated_yield_mt, planting_date, status) VALUES
(NULL, 'okra', 1.0, 2.5, '2026-03-01', 'growing'),
(NULL, 'eggplant', 0.5, 1.2, '2026-03-05', 'growing'),
(NULL, 'stringbeans', 1.2, 3.0, '2026-03-10', 'growing'),
(NULL, 'ampalaya', 0.8, 2.0, '2026-03-15', 'growing'),
(NULL, 'squash', 1.5, 4.0, '2026-03-20', 'growing')
ON CONFLICT DO NOTHING;

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';