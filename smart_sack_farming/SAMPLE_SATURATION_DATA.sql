-- Sample Saturation Records for Heat Map Testing
-- This script populates the saturation_records table with test data

INSERT INTO saturation_records (
  farmer_id,
  primary_crop,
  companion_crops,
  soil_moisture,
  saturation_level,
  planting_date,
  expected_harvest,
  field_size_ha,
  pesticides,
  fertilizer_type,
  irrigation_method,
  soil_type,
  expected_yield_kg,
  notes
) VALUES
-- Rice records
('550e8400-e29b-41d4-a716-446655440000', 'Rice', ARRAY['Azolla', 'Water Lettuce'], 75.5, 'high', '2026-05-01', '2026-08-15', 2.5, 'Insecticide ABC', 'NPK 16-16-16', 'Flood Irrigation', 'Clay Loam', 4500, 'Growing well, oversaturated'),
('550e8400-e29b-41d4-a716-446655440001', 'Rice', ARRAY['Sesbania', 'Azolla'], 72.3, 'high', '2026-04-15', '2026-08-01', 3.2, 'Fungicide XYZ', 'NPK 20-10-10', 'Flood Irrigation', 'Silty Clay', 5200, 'Excellent growth'),
('550e8400-e29b-41d4-a716-446655440002', 'Rice', ARRAY['Azolla'], 68.7, 'medium', '2026-05-10', '2026-08-20', 2.8, 'Organic Pesticide', 'Compost', 'Drip Irrigation', 'Clay', 4800, 'Good saturation levels'),

-- Corn records
('550e8400-e29b-41d4-a716-446655440003', 'Corn', ARRAY['Beans', 'Squash'], 45.2, 'low', '2026-04-01', '2026-07-15', 1.8, 'Herbicide DEF', 'NPK 15-15-15', 'Sprinkler', 'Sandy Loam', 3500, 'Low moisture, needs irrigation'),
('550e8400-e29b-41d4-a716-446655440004', 'Corn', ARRAY['Pumpkin'], 52.8, 'medium', '2026-04-20', '2026-07-25', 2.2, 'Fungicide GHI', 'NPK 18-10-10', 'Drip Irrigation', 'Loam', 4200, 'Optimal growth conditions'),
('550e8400-e29b-41d4-a716-446655440005', 'Corn', ARRAY['Beans', 'Watermelon'], 58.5, 'medium', '2026-05-05', '2026-08-10', 2.0, 'Insecticide JKL', 'Organic Fertilizer', 'Flood Irrigation', 'Loamy Clay', 4100, 'Good progress'),

-- Tomato records
('550e8400-e29b-41d4-a716-446655440006', 'Tomato', ARRAY['Basil', 'Carrot'], 65.3, 'medium', '2026-03-15', '2026-07-30', 0.8, 'Fungicide MNO', 'NPK 10-20-20', 'Drip Irrigation', 'Loam', 2500, 'Healthy plants, moderate moisture'),
('550e8400-e29b-41d4-a716-446655440007', 'Tomato', ARRAY['Basil', 'Onion'], 71.9, 'high', '2026-03-20', '2026-08-05', 1.0, 'Organic Spray', 'Compost + NPK', 'Drip Irrigation', 'Sandy Loam', 2800, 'High saturation, requires drainage'),
('550e8400-e29b-41d4-a716-446655440008', 'Tomato', ARRAY['Parsley'], 48.2, 'low', '2026-03-25', '2026-07-20', 0.9, 'Insecticide PQR', 'NPK 12-15-18', 'Sprinkler', 'Sandy', 2200, 'Drought conditions, monitor irrigation'),

-- Cabbage records
('550e8400-e29b-41d4-a716-446655440009', 'Cabbage', ARRAY['Carrot', 'Beet'], 62.4, 'medium', '2026-02-01', '2026-06-15', 1.5, 'Fungicide STU', 'NPK 14-14-14', 'Drip Irrigation', 'Clay Loam', 3200, 'Normal growth'),
('550e8400-e29b-41d4-a716-446655440010', 'Cabbage', ARRAY['Onion'], 56.8, 'medium', '2026-02-10', '2026-06-25', 1.3, 'Organic Pesticide', 'Organic', 'Sprinkler', 'Loam', 3000, 'Moderate conditions'),
('550e8400-e29b-41d4-a716-446655440011', 'Cabbage', ARRAY['Carrot', 'Lettuce'], 77.1, 'high', '2026-02-15', '2026-06-30', 1.6, 'Fungicide VWX', 'NPK 16-12-8', 'Flood Irrigation', 'Silty Clay', 3400, 'Oversaturated, good growth'),

-- Squash records
('550e8400-e29b-41d4-a716-446655440012', 'Squash', ARRAY['Corn', 'Beans'], 38.5, 'low', '2026-04-10', '2026-08-05', 2.5, 'Insecticide YZ', 'NPK 12-8-16', 'Drip Irrigation', 'Sandy', 2800, 'Low moisture detected'),
('550e8400-e29b-41d4-a716-446655440013', 'Squash', ARRAY['Beans'], 54.3, 'medium', '2026-04-25', '2026-08-20', 2.3, 'Fungicide ABC', 'Organic Compost', 'Sprinkler', 'Loam', 3100, 'Good conditions'),
('550e8400-e29b-41d4-a716-446655440014', 'Squash', ARRAY['Corn', 'Beans', 'Basil'], 69.7, 'high', '2026-05-01', '2026-08-25', 2.4, 'Organic Spray', 'NPK 10-10-20', 'Drip Irrigation', 'Clay Loam', 3400, 'High moisture levels'),

-- Lettuce records
('550e8400-e29b-41d4-a716-446655440015', 'Lettuce', ARRAY['Spinach'], 64.2, 'medium', '2026-03-01', '2026-05-15', 0.5, 'Organic Pesticide', 'Organic', 'Drip Irrigation', 'Loam', 800, 'Ready for harvest'),
('550e8400-e29b-41d4-a716-446655440016', 'Lettuce', ARRAY['Radish'], 73.5, 'high', '2026-03-05', '2026-05-20', 0.6, 'Fungicide DEF', 'Compost', 'Sprinkler', 'Sandy Loam', 900, 'Oversaturated but thriving'),
('550e8400-e29b-41d4-a716-446655440017', 'Lettuce', ARRAY[], 42.8, 'low', '2026-03-10', '2026-05-25', 0.4, 'Insecticide GHI', 'NPK 8-10-12', 'Drip Irrigation', 'Sandy', 650, 'Low moisture warning'),

-- Pumpkin records
('550e8400-e29b-41d4-a716-446655440018', 'Pumpkin', ARRAY['Corn', 'Beans'], 51.6, 'medium', '2026-04-05', '2026-09-15', 3.0, 'Fungicide JKL', 'NPK 10-10-20', 'Drip Irrigation', 'Loamy Sand', 4500, 'Strong vines developing'),
('550e8400-e29b-41d4-a716-446655440019', 'Pumpkin', ARRAY['Beans'], 74.2, 'high', '2026-04-15', '2026-09-20', 3.2, 'Organic Spray', 'Organic Compost', 'Flood Irrigation', 'Clay Loam', 5000, 'Excellent growth, high moisture'),
('550e8400-e29b-41d4-a716-446655440020', 'Pumpkin', ARRAY[], 47.3, 'low', '2026-04-20', '2026-09-25', 2.8, 'Insecticide MNO', 'NPK 12-8-16', 'Sprinkler', 'Sandy', 4000, 'Monitor water supply'),

-- Bean records
('550e8400-e29b-41d4-a716-446655440021', 'Bean', ARRAY['Corn'], 55.7, 'medium', '2026-05-01', '2026-07-30', 1.2, 'Organic Pesticide', 'NPK 8-12-16', 'Drip Irrigation', 'Loam', 1800, 'Nodulation progressing'),
('550e8400-e29b-41d4-a716-446655440022', 'Bean', ARRAY['Squash', 'Corn'], 66.4, 'medium', '2026-05-10', '2026-08-05', 1.4, 'Fungicide PQR', 'Organic Nitrogen', 'Sprinkler', 'Loamy Clay', 2000, 'Healthy nitrogen fixation'),
('550e8400-e29b-41d4-a716-446655440023', 'Bean', ARRAY['Corn'], 73.8, 'high', '2026-05-15', '2026-08-10', 1.3, 'Insecticide STU', 'Compost', 'Flood Irrigation', 'Clay', 2100, 'Oversaturated but productive');

-- Verify inserted records
SELECT COUNT(*) as total_records, primary_crop, saturation_level, ROUND(AVG(soil_moisture), 2) as avg_moisture
FROM saturation_records
GROUP BY primary_crop, saturation_level
ORDER BY primary_crop, saturation_level;
