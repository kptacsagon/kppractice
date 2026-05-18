# Daily Market-Based Saturation System

## Overview
The saturation system has been redesigned to base saturation on **actual daily market purchases** instead of projected supply/demand ratios. This provides real-time, market-driven insights into crop availability.

## Key Concepts

### Saturation Definition
A crop is **SATURATED** when:
- **Daily Supply > Daily Demand**
- Supply exceeds the actual purchases made in the market on that day

### Saturation Levels
The system categorizes saturation into four levels:

1. **CRITICALLY_SATURATED** (🔴 Critical Risk)
   - Daily Supply > 2x Daily Demand
   - Severe oversupply, prices will likely drop significantly
   - Recommendation: Do NOT plant this crop or reduce plantings

2. **SATURATED** (🔴 High Risk)
   - Daily Supply > Daily Demand (but < 2x)
   - Market oversupply, prices may decrease
   - Recommendation: Exercise caution when planning

3. **BALANCED** (🟡 Medium - Optimal)
   - Daily Supply ≈ Daily Demand (80% - 100%)
   - Market equilibrium, stable prices expected
   - Recommendation: Safe to plant

4. **UNDERSUPPLIED** (🟢 Opportunity)
   - Daily Demand > Daily Supply
   - Shortage in market, prices likely to increase
   - Recommendation: Highly recommended to plant

## Database Schema

### Table: `daily_market_purchases`
Tracks actual product purchases in the market per day.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| municipality | VARCHAR(100) | Location of the purchase |
| crop_type | VARCHAR(100) | Type of crop purchased |
| purchase_date | DATE | Date of the market purchase |
| quantity_purchased_kg | DECIMAL(12,2) | **DAILY DEMAND** - actual amount sold |
| num_buyers | INT | Number of buyers involved in the transaction |
| average_price_per_kg | DECIMAL(10,2) | Market price per kg on that day |
| created_at | TIMESTAMPTZ | Timestamp of record creation |
| updated_at | TIMESTAMPTZ | Timestamp of last update |

**How to Record Data:**
```sql
-- Record a tomato purchase in Cebu City
INSERT INTO daily_market_purchases 
(municipality, crop_type, purchase_date, quantity_purchased_kg, num_buyers, average_price_per_kg)
VALUES ('Cebu City', 'Tomato', '2024-01-15', 450.5, 8, 55.00);
```

### Table: `daily_saturation_status`
Stores calculated saturation status per crop per municipality per day.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| municipality | VARCHAR(100) | Location |
| crop_type | VARCHAR(100) | Crop type |
| status_date | DATE | Date of saturation status |
| daily_demand_kg | DECIMAL(12,2) | Total purchased that day |
| daily_supply_kg | DECIMAL(12,2) | Expected available yield |
| saturation_ratio | DECIMAL(5,2) | (Supply/Demand) * 100 |
| is_saturated | BOOLEAN | TRUE if supply > demand |
| saturation_level | VARCHAR(20) | Level category (see above) |
| created_at | TIMESTAMPTZ | Record creation time |
| updated_at | TIMESTAMPTZ | Last update time |

**Automatically Calculated:**
This table is populated by the `calculate_daily_saturation_status()` function which:
1. Sums all daily market purchases per crop
2. Sums expected yields from available supply
3. Compares supply vs demand
4. Calculates saturation status

## Dart Services

### DailyMarketSaturationService
Main service for managing daily market data and saturation calculations.

**Key Methods:**

#### Record a Market Purchase
```dart
final service = DailyMarketSaturationService();

await service.recordMarketPurchase(
  municipality: 'Cebu City',
  cropType: 'Tomato',
  quantityPurchasedKg: 450.5,
  numBuyers: 8,
  averagePricePerKg: 55.00,
);
```

#### Get Today's Saturation Status
```dart
final statuses = await service.getTodaySaturationStatus();

for (final status in statuses) {
  print('${status.cropType}: ${status.saturationLevel}');
  print('Demand: ${status.dailyDemandKg} kg');
  print('Supply: ${status.dailySupplyKg} kg');
  print('${status.getSaturationMessage()}');
}
```

#### Get Critical Saturation Alerts
```dart
final criticalAlerts = await service.getCriticalSaturationAlerts();

for (final alert in criticalAlerts) {
  print('🔴 CRITICAL: ${alert.cropType} in ${alert.municipality}');
  print('Supply is ${alert.saturationRatio}% of demand!');
}
```

#### Check Saturation Trend (Last 7 Days)
```dart
final trend = await service.getSaturationTrend(
  municipality: 'Cebu City',
  cropType: 'Tomato',
  days: 7,
);

// Analyze the trend
bool gettingWorse = trend.last.saturationRatio > trend.first.saturationRatio;
```

#### Get Average Daily Demand
```dart
final avgDemand = await service.getAverageDailyDemand(
  cropType: 'Tomato',
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 1, 31),
);

print('Average daily tomato demand: $avgDemand kg');
```

### SaturationBroadcastService (Updated)
Now uses daily market data for broadcasting alerts.

#### Get Daily Market-Based Saturation Analysis
```dart
final analysis = await SaturationBroadcastService().getSaturationAnalysisForBroadcast();

print('Critically Saturated: ${analysis['critically_saturated_crops']}');
print('Saturated: ${analysis['high_saturation_crops']}');
print('Balanced: ${analysis['medium_saturation_crops']}');
print('Undersupplied: ${analysis['low_saturation_crops']}');
print('Analysis Date: ${analysis['analysis_date']}');
print('Basis: ${analysis['saturation_basis']}');
```

#### Broadcast Daily Market Alert
```dart
await SaturationBroadcastService().broadcastDailyMarketSaturationAlert(
  adminName: 'Juan Dela Cruz',
  municipality: 'Cebu City',
  title: 'Market Saturation Update - Jan 15, 2024',
  description: 'Based on actual market purchases from yesterday.',
  criticallySaturatedCrops: ['Cabbage', 'Eggplant'],
  saturatedCrops: ['Tomato'],
  balancedCrops: ['Onion'],
  undersuppliedCrops: ['Chili'],
  recommendations: 'Farmers should AVOID planting Cabbage and Eggplant. Chili is in high demand!',
);
```

## Database Functions

### calculate_daily_saturation_status()
Automatically calculates saturation for the previous day.

**Usage:**
```sql
-- Call this function daily (via cron job) to update saturation
SELECT calculate_daily_saturation_status();

-- Or schedule it: Run every day at midnight
-- CREATE EXTENSION IF NOT EXISTS pg_cron;
-- SELECT cron.schedule('calculate_saturation', '0 0 * * *', 'SELECT calculate_daily_saturation_status()');
```

## Migration Steps

### 1. Run the Database Migration
Execute [supabase_migration_daily_market_saturation.sql](../supabase_migration_daily_market_saturation.sql) in Supabase SQL Editor:

```bash
# Copy the entire migration file content
# Paste into Supabase SQL Editor
# Execute
```

### 2. Update Your UI
Replace old saturation logic with `DailyMarketSaturationService`:

**Before (Projection-based):**
```dart
final dssService = AgriSenseDssService();
final result = dssService.evaluate(input); // Used projected supply/demand
```

**After (Daily market-based):**
```dart
final saturationService = DailyMarketSaturationService();
final status = await saturationService.getDailySaturationStatus(
  municipality: 'Cebu City',
  cropType: 'Tomato',
);
```

### 3. Start Recording Market Purchases
When buyers purchase crops, record them:

```dart
await DailyMarketSaturationService().recordMarketPurchase(
  municipality: municipality,
  cropType: cropType,
  quantityPurchasedKg: quantity,
  numBuyers: numBuyers,
  averagePricePerKg: price,
);
```

### 4. Update Your Dashboard/Alerts
Change displays from "Projected" to "Market-Based" saturation:

```dart
// Old
"Projected saturation: ${result.saturation}%"

// New
final status = await service.getDailySaturationStatus(
  municipality: municipality,
  cropType: cropType,
);
print("Market saturation (yesterday): ${status.saturationLevel}");
```

## Sample Data
Sample data is included in the migration file with 7 days of market purchases for testing:

- Cebu City: Tomato, Onion, Cabbage, Chili, Eggplant
- Mandaue City: Tomato, Onion, Cabbage, Eggplant

Data can be viewed:
```sql
SELECT * FROM daily_saturation_status ORDER BY status_date DESC LIMIT 20;
```

## Examples: Interpreting Results

### Example 1: Tomato in Cebu City
```
Date: 2024-01-14
Daily Demand: 450 kg (actual purchases)
Daily Supply: 600 kg (expected harvest available)
Saturation Ratio: 133%
Status: SATURATED

Interpretation:
- Farmers have 600kg available
- Only 450kg was sold
- 150kg surplus remains unsold
- Prices likely dropping
- Recommendation: Don't increase tomato production
```

### Example 2: Chili in Cebu City
```
Date: 2024-01-14
Daily Demand: 120 kg (actual purchases)
Daily Supply: 80 kg (expected harvest available)
Saturation Ratio: 67%
Status: UNDERSUPPLIED

Interpretation:
- Farmers only have 80kg available
- 120kg was demanded/purchased
- 40kg shortage
- Prices likely increasing
- Recommendation: Plant more chili!
```

## Advanced Features

### 1. Saturation Trend Analysis
Track saturation changes over time to identify patterns:

```dart
// 7-day trend
final trend = await service.getSaturationTrend(
  municipality: 'Cebu City',
  cropType: 'Tomato',
  days: 7,
);

// Plot a graph to see improvements/worsening
```

### 2. Regional Comparison
Compare saturation across different municipalities:

```dart
final statusCebu = await service.getDailySaturationStatus(
  municipality: 'Cebu City',
  cropType: 'Tomato',
);

final statusMandaue = await service.getDailySaturationStatus(
  municipality: 'Mandaue City',
  cropType: 'Tomato',
);

// If Cebu is saturated but Mandaue is not, supply could be moved
```

### 3. Supply-to-Demand Ratio
Get exact ratio for precise planning:

```dart
final ratio = await service.getSupplyToDemandRatio(
  municipality: 'Cebu City',
  cropType: 'Tomato',
);

if (ratio != null && ratio > 2.0) {
  // Critical oversupply
}
```

## Data Entry Best Practices

### Daily Recording Process
1. **Market agents** record all purchases at market close
2. Include municipality, crop type, total quantity, number of buyers, average price
3. System calculates supply vs demand comparison overnight
4. Alerts broadcast next morning to farmers

### Data Quality
- Record purchases from ALL market channels (wholesale, retail, direct)
- Use consistent municipality names
- Record prices in the same currency
- Update supply data regularly from saturation_records

## Troubleshooting

### Q: Why is saturation status NULL for a crop?
**A:** Supply data not found. Ensure saturation_records has data for that crop in the municipality.

### Q: Calculations seem wrong
**A:** Check that:
1. Daily purchases were recorded correctly
2. Supply data in saturation_records is current
3. Function was executed: `SELECT calculate_daily_saturation_status();`

### Q: How do I reset data for testing?
```sql
-- Clear sample data
DELETE FROM daily_market_purchases WHERE purchase_date < '2024-01-01';
DELETE FROM daily_saturation_status WHERE status_date < '2024-01-01';

-- Recalculate
SELECT calculate_daily_saturation_status();
```

## Migration from Old System

The old projection-based saturation system (agrisense_saturation_scores) is still available but deprecated. You can run both in parallel during transition:

```dart
// New system (recommended)
final dailyStatus = await dailyMarketService.getDailySaturationStatus(...);

// Old system (legacy)
// final projectionStatus = await agriseneceDssService.evaluate(...);
```

---

**Last Updated:** January 2024
**System Version:** Daily Market Saturation v1.0
