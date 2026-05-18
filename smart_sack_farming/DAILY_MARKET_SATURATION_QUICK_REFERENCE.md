# Daily Market Saturation System - Quick Reference

## 🎯 Saturation Levels At A Glance

| Level | Color | Icon | Status | Recommendation | Action |
|-------|-------|------|--------|-----------------|--------|
| CRITICALLY_SATURATED | 🔴 Red | ⚠️ Warning | Supply > 2x Demand | **DO NOT PLANT** | Avoid this crop entirely |
| SATURATED | 🔴 Red | 📉 Down | Supply > Demand | **AVOID PLANTING** | Plant with extreme caution |
| BALANCED | 🟡 Amber | ➡️ Flat | Supply ≈ Demand | **SAFE TO PLANT** | Good planting conditions |
| UNDERSUPPLIED | 🟢 Green | 📈 Up | Demand > Supply | **HIGHLY RECOMMENDED** | Excellent opportunity |

---

## 🚀 Quick Start (5 minutes)

### Step 1: Run Database Migration
```sql
-- Copy entire content of supabase_migration_daily_market_saturation.sql
-- Paste into Supabase SQL Editor
-- Execute
SELECT 'Migration complete' AS status;
```

### Step 2: Record a Market Purchase
```dart
await DailyMarketSaturationService().recordMarketPurchase(
  municipality: 'Cebu City',
  cropType: 'Tomato',
  quantityPurchasedKg: 450,
  numBuyers: 8,
  averagePricePerKg: 55.00,
);
```

### Step 3: View Dashboard
```dart
// Navigate to this screen
DailyMarketSaturationDashboard()
```

### Step 4: Get Recommendations
- Green (UNDERSUPPLIED) ➜ Plant this!
- Amber (BALANCED) ➜ Safe to plant
- Red (SATURATED) ➜ Avoid planting

---

## 📊 Most Used Code Snippets

### Get Today's Saturation
```dart
final service = DailyMarketSaturationService();
final statuses = await service.getTodaySaturationStatus();

for (final status in statuses) {
  print('${status.cropType}: ${status.saturationLevel}');
  print('Demand: ${status.dailyDemandKg} kg');
  print('Supply: ${status.dailySupplyKg} kg');
}
```

### Get Critical Alerts Only
```dart
final alerts = await DailyMarketSaturationService().getCriticalSaturationAlerts();

for (final alert in alerts) {
  print('🔴 ${alert.cropType} - Supply is ${alert.saturationRatio}% of demand');
}
```

### Get Saturation for One Crop
```dart
final status = await DailyMarketSaturationService().getDailySaturationStatus(
  municipality: 'Cebu City',
  cropType: 'Tomato',
);

if (status?.isSaturated ?? false) {
  print('❌ Market is SATURATED');
} else {
  print('✅ Market is NOT saturated');
}
```

### Get 7-Day Trend
```dart
final trend = await DailyMarketSaturationService().getSaturationTrend(
  municipality: 'Cebu City',
  cropType: 'Tomato',
  days: 7,
);

// trend[0] = oldest day, trend[6] = most recent
bool improving = trend.last.saturationRatio < trend.first.saturationRatio;
```

### Broadcast Alert to Farmers
```dart
await SaturationBroadcastService().broadcastDailyMarketSaturationAlert(
  adminName: 'Juan Dela Cruz',
  municipality: 'Cebu City',
  title: 'Market Update: Jan 15, 2024',
  description: 'Based on yesterday\'s market purchases',
  criticallySaturatedCrops: ['Cabbage'],
  saturatedCrops: ['Tomato'],
  balancedCrops: ['Onion'],
  undersuppliedCrops: ['Chili'],
  recommendations: '🔴 AVOID Cabbage | 🟡 Caution Tomato | 🟢 PLANT Chili',
);
```

---

## 📝 SQL Queries Cheat Sheet

### Check Sample Data
```sql
-- See market purchases
SELECT * FROM daily_market_purchases LIMIT 10;

-- See saturation status
SELECT * FROM daily_saturation_status LIMIT 10;
```

### View Saturated Crops
```sql
SELECT municipality, crop_type, saturation_ratio, saturation_level
FROM daily_saturation_status
WHERE is_saturated = true
ORDER BY saturation_ratio DESC;
```

### View Undersupplied Crops (Opportunities)
```sql
SELECT municipality, crop_type, saturation_ratio
FROM daily_saturation_status
WHERE saturation_level = 'UNDERSUPPLIED'
ORDER BY saturation_ratio ASC;
```

### Get Average Daily Demand per Crop
```sql
SELECT crop_type, 
       ROUND(AVG(daily_demand_kg), 2) as avg_daily_demand_kg,
       COUNT(*) as days_tracked
FROM daily_saturation_status
GROUP BY crop_type
ORDER BY avg_daily_demand_kg DESC;
```

### Trigger Calculation (Manual)
```sql
SELECT * FROM calculate_daily_saturation_status();
```

### Check Specific Crop Trend
```sql
SELECT status_date, crop_type, daily_demand_kg, daily_supply_kg, saturation_level
FROM daily_saturation_status
WHERE crop_type = 'Tomato'
  AND municipality = 'Cebu City'
ORDER BY status_date DESC
LIMIT 10;
```

---

## 🔧 Common Tasks

### Task: Record Today's Market Purchases
```dart
// Morning: Collect this data from market agents
List<Map<String, dynamic>> purchases = [
  {'municipality': 'Cebu City', 'cropType': 'Tomato', 'quantity': 450, 'buyers': 8, 'price': 55},
  {'municipality': 'Cebu City', 'cropType': 'Onion', 'quantity': 320, 'buyers': 6, 'price': 85},
  {'municipality': 'Mandaue City', 'cropType': 'Chili', 'quantity': 120, 'buyers': 4, 'price': 130},
];

// Afternoon: Record in system
for (final purchase in purchases) {
  await DailyMarketSaturationService().recordMarketPurchase(
    municipality: purchase['municipality'],
    cropType: purchase['cropType'],
    quantityPurchasedKg: purchase['quantity'].toDouble(),
    numBuyers: purchase['buyers'],
    averagePricePerKg: purchase['price'].toDouble(),
  );
}
```

### Task: Generate Daily Alert Report
```dart
// Get analysis
final analysis = await SaturationBroadcastService().getSaturationAnalysisForBroadcast();

// Generate report
print('=== Market Saturation Report ===');
print('Critically Saturated: ${analysis['critically_saturated_crops']}');
print('Saturated: ${analysis['high_saturation_crops']}');
print('Balanced: ${analysis['medium_saturation_crops']}');
print('Undersupplied: ${analysis['low_saturation_crops']}');
print('Analysis Date: ${analysis['analysis_date']}');
```

### Task: Identify Best Crops to Plant
```dart
final undersupplied = await DailyMarketSaturationService().getSaturatedCropsForMunicipality(
  municipality: 'Cebu City',
);

final bestCrops = undersupplied
  .where((s) => s.saturationLevel == 'UNDERSUPPLIED')
  .toList()
  ..sort((a, b) => a.saturationRatio.compareTo(b.saturationRatio));

print('Top crops to plant:');
for (final crop in bestCrops.take(3)) {
  print('🚀 ${crop.cropType} - Demand is ${(100 - crop.saturationRatio).toStringAsFixed(0)}% higher than supply');
}
```

### Task: Check if Crop is Saturated
```dart
final status = await DailyMarketSaturationService().getDailySaturationStatus(
  municipality: 'Cebu City',
  cropType: 'Tomato',
);

if (status == null) {
  print('No data for this crop');
} else if (status.isSaturated) {
  print('❌ SATURATED - Do not plant');
  print('Saturation: ${status.saturationRatio}%');
} else {
  print('✅ NOT saturated - Safe to plant');
}
```

---

## ❓ Troubleshooting Quick Fixes

### Problem: Dashboard shows no data
**Solution:**
1. Check if market purchases exist:
   ```sql
   SELECT COUNT(*) FROM daily_market_purchases WHERE purchase_date = CURRENT_DATE - 1;
   ```
2. Run calculation:
   ```sql
   SELECT calculate_daily_saturation_status();
   ```
3. Check results:
   ```sql
   SELECT * FROM daily_saturation_status WHERE status_date = CURRENT_DATE - 1;
   ```

### Problem: Service won't compile
**Solution:**
```bash
flutter pub get          # Get dependencies
flutter clean            # Clear build cache
flutter pub get          # Get again
flutter build apk        # Test build
```

### Problem: Saturation numbers don't make sense
**Solution:**
1. Check supply data exists:
   ```sql
   SELECT COUNT(*) FROM saturation_records WHERE primary_crop = 'Tomato';
   ```
2. Check municipality spelling matches exactly
3. Verify purchase data:
   ```sql
   SELECT * FROM daily_market_purchases 
   WHERE crop_type = 'Tomato' 
   AND purchase_date = CURRENT_DATE - 1;
   ```

---

## 📱 Mobile UI Reference

### Dashboard Layout
```
┌─────────────────────────────┐
│  Market Saturation Status   │
│  (Refresh) (Date: Jan 15)   │
├─────────────────────────────┤
│                             │
│  🔴 CRITICAL ALERTS        │
│  ├─ Cabbage: 250% supply   │
│  └─ Eggplant: 220% supply  │
│                             │
├─────────────────────────────┤
│  Saturation by Crop:        │
│                             │
│  📉 TOMATO (SATURATED)      │
│  Demand: 450 kg            │
│  Supply: 600 kg            │
│  ⚠️ AVOID PLANTING         │
│                             │
│  ➡️ ONION (BALANCED)        │
│  Demand: 320 kg            │
│  Supply: 350 kg            │
│  ✅ SAFE TO PLANT          │
│                             │
│  📈 CHILI (UNDERSUPPLIED)   │
│  Demand: 120 kg            │
│  Supply: 80 kg             │
│  🚀 HIGHLY RECOMMENDED     │
│                             │
└─────────────────────────────┘
```

---

## 🔐 User Permissions

### Market Admin
- ✅ Record market purchases
- ✅ View saturation dashboard
- ✅ Broadcast alerts

### Farmer
- ✅ View saturation dashboard
- ✅ See recommendations
- ❌ Record purchases
- ❌ Broadcast alerts

### System Admin
- ✅ All permissions
- ✅ Manage data
- ✅ Run calculations

---

## ⚡ Performance Tips

### Optimize Query Performance
```sql
-- Add indexes if not exists (migration should do this)
CREATE INDEX idx_dss_date_crop ON daily_saturation_status(status_date, crop_type);
CREATE INDEX idx_dmp_date_muni ON daily_market_purchases(purchase_date, municipality);
```

### Load Data Efficiently in Dart
```dart
// ❌ Don't do this in a loop
for (final crop in crops) {
  final status = await service.getDailySaturationStatus(
    municipality: municipality,
    cropType: crop,
  );
}

// ✅ Do this instead
final statuses = await service.getTodaySaturationStatus();
```

---

## 📞 Support Contacts

For issues:
1. Check this guide
2. Check `DAILY_MARKET_SATURATION_GUIDE.md` for details
3. Check `DAILY_MARKET_SATURATION_IMPLEMENTATION.md` for integration help
4. Review sample data and test queries provided

---

## 📅 Daily Checklist

### Each Day
- [ ] Market agents record purchases
- [ ] Check no purchases missing
- [ ] Dashboard updated with latest data
- [ ] Check for critical alerts
- [ ] Broadcast recommendations if needed

### Each Week
- [ ] Review saturation trends
- [ ] Verify data quality
- [ ] Check for data entry errors
- [ ] Update farmer recommendations

### Each Month
- [ ] Analyze monthly patterns
- [ ] Plan next month's crops
- [ ] Review system performance
- [ ] Collect user feedback

---

**Last Updated:** January 2024
**Quick Reference Version:** 1.0
**Best For:** Quick lookups and daily operations
