-- AgriSense DSS Phase 2: Advanced Analytics Schema
-- This migration sets up Market Demand Intelligence, Weather & Climate, and Recommendation models.

-- 1. Market Demand Intelligence
CREATE TABLE IF NOT EXISTS agrisense_market_demands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    municipality VARCHAR(100) NOT NULL,
    crop_type VARCHAR(100) NOT NULL,
    season_name VARCHAR(100) NOT NULL,
    projected_demand_kg DECIMAL(12,2) NOT NULL,
    confidence_score VARCHAR(20) DEFAULT 'Medium', -- High, Medium, Low
    data_source VARCHAR(100), -- PSA, DA, Municipal Trading, Historical
    recorded_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Daily Market Prices (For profitability calculation)
CREATE TABLE IF NOT EXISTS agrisense_market_prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    municipality VARCHAR(100) NOT NULL,
    crop_type VARCHAR(100) NOT NULL,
    price_per_kg DECIMAL(10,2) NOT NULL,
    recorded_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Weather & Climate Module
CREATE TABLE IF NOT EXISTS agrisense_weather_forecasts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    municipality VARCHAR(100) NOT NULL,
    forecast_date DATE NOT NULL,
    condition VARCHAR(100), -- Sunny, Rainy, Typhoon, Drought
    rainfall_probability_percent INT,
    advisory_message TEXT,
    severity_level VARCHAR(20) DEFAULT 'Normal', -- Normal, Warning, Critical
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Crop Recommendations Log
CREATE TABLE IF NOT EXISTS agrisense_crop_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID REFERENCES agrisense_farmer_profiles(id) ON DELETE CASCADE,
    farm_id UUID REFERENCES agrisense_farms(id) ON DELETE CASCADE,
    recommended_crop VARCHAR(100) NOT NULL,
    recommendation_score DECIMAL(5,2) NOT NULL, -- Out of 100
    category VARCHAR(50), -- Highly Recommended, Recommended, Moderate, Not Recommended
    factors JSONB, -- Stores the formula breakdown (Demand, Soil, Irrigation, Profitability, Seasonality)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Update trigger for updated_at timestamps
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_agrisense_market_demands_modtime
BEFORE UPDATE ON agrisense_market_demands
FOR EACH ROW EXECUTE FUNCTION update_modified_column();
