# Daily Market Saturation System - Implementation Checklist

## Phase 1: Database Setup (Complete in Supabase)

### Step 1: Run Migration
- [ ] Open Supabase SQL Editor
- [ ] Copy entire content from `supabase_migration_daily_market_saturation.sql`
- [ ] Paste into SQL Editor
- [ ] Execute the migration
- [ ] Verify tables created:
  ```sql
  \dt daily_market_purchases
  \dt daily_saturation_status
  ```
- [ ] Verify function created:
  ```sql
  SELECT routine_name FROM information_schema.routines 
  WHERE routine_name = 'calculate_daily_saturation_status';
  ```

### Step 2: Enable Row Level Security (RLS) Policies
- [ ] Verify all RLS policies are created:
  ```sql
  SELECT policy_name, table_name FROM information_schema.table_constraints 
  WHERE table_name IN ('daily_market_purchases', 'daily_saturation_status');
  ```
- [ ] Test public read access works
- [ ] Test admin insert/update access works

### Step 3: Verify Sample Data
- [ ] Check sample data was inserted:
  ```sql
  SELECT COUNT(*) FROM daily_market_purchases;
  -- Should show 16 sample records
  ```
- [ ] Check saturation status was calculated:
  ```sql
  SELECT * FROM daily_saturation_status ORDER BY status_date DESC LIMIT 5;
  ```

---

## Phase 2: Backend Integration (Dart Services)

### Step 4: Add Daily Market Service
- [ ] `lib/services/daily_market_saturation_service.dart` created
- [ ] File contains:
  - [ ] `DailyMarketPurchase` model
  - [ ] `DailySaturationStatus` model
  - [ ] `DailyMarketSaturationService` class
  - [ ] All required methods implemented

### Step 5: Update Saturation Broadcast Service
- [ ] Open `lib/services/saturation_broadcast_service.dart`
- [ ] Verify imports include `daily_market_saturation_service.dart`
- [ ] Verify new methods exist:
  - [ ] `getSaturationAnalysisForBroadcast()` (updated)
  - [ ] `broadcastDailyMarketSaturationAlert()` (new)
  - [ ] `getSaturationAnalysisForBroadcastLegacy()` (legacy support)

### Step 6: Compile & Test Services
- [ ] Run: `flutter pub get`
- [ ] Fix any import errors
- [ ] Build: `flutter build apk --debug` (or appropriate platform)
- [ ] Verify no compilation errors

---

## Phase 3: Frontend Implementation

### Step 7: Add Dashboard Screen
- [ ] File created: `lib/screens/daily_market_saturation_dashboard.dart`
- [ ] Contains:
  - [ ] `DailyMarketSaturationDashboard` stateful widget
  - [ ] Critical alerts section
  - [ ] Saturation status grid
  - [ ] Crop-specific detail cards
  - [ ] Recommendations based on saturation level

### Step 8: Add Route in Navigation
- [ ] Update `lib/main.dart` or your router:
  ```dart
  // Add to your routes/navigation
  '/saturation-dashboard': (context) => const DailyMarketSaturationDashboard(),
  ```

### Step 9: Add Navigation Button
- [ ] Add button/menu item to existing screens pointing to dashboard
- [ ] Examples:
  - [ ] Add to farmer dashboard
  - [ ] Add to admin panel
  - [ ] Add to home screen menu

---

## Phase 4: Data Entry Points

### Step 10: Implement Market Purchase Recording
Create a form/screen to record daily market purchases:

```dart
// Example: In a Market Admin screen
class RecordMarketPurchaseScreen extends StatefulWidget {
  // UI for entering:
  // - Municipality
  // - Crop type
  // - Quantity purchased (kg)
  // - Number of buyers
  // - Average price per kg
  // 
  // On submit:
  // await DailyMarketSaturationService().recordMarketPurchase(...)
}
```

- [ ] Create purchase recording form/screen
- [ ] Add validation for all fields
- [ ] Add success/error handling
- [ ] Test with sample data

### Step 11: Update Buyer Crop Requests Flow
- [ ] When a buyer crop request is approved/completed:
  - [ ] Record as market purchase
  - [ ] Link to purchase record for tracking

```dart
// After approved buyer request
await DailyMarketSaturationService().recordMarketPurchase(
  municipality: farmer.municipality,
  cropType: request.cropType,
  quantityPurchasedKg: request.requestedQuantityKg,
  numBuyers: 1, // From buyer_crop_requests
  averagePricePerKg: currentMarketPrice,
);
```

---

## Phase 5: Automated Calculations

### Step 12: Schedule Daily Saturation Calculation
Option A: Using Supabase Cron Extension:
```sql
-- Execute once to enable cron
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule calculation to run daily at midnight
SELECT cron.schedule(
  'calculate_daily_saturation',
  '0 0 * * *', -- UTC midnight
  'SELECT calculate_daily_saturation_status()'
);

-- Verify cron job
SELECT * FROM cron.job;
```

Option B: Call from Flutter app (daily background task):
```dart
// In your app initialization or periodic task handler
if (shouldCalculateSaturation()) { // Once per day
  await Supabase.instance.client.rpc('calculate_daily_saturation_status');
}
```

- [ ] Implement one of the above approaches
- [ ] Test that calculation runs correctly
- [ ] Verify results in database daily

---

## Phase 6: Testing

### Step 13: Unit Testing
- [ ] Create `test/services/daily_market_saturation_service_test.dart`
- [ ] Test service methods:
  ```dart
  test('recordMarketPurchase should insert data', () async { });
  test('getDailySaturationStatus should retrieve correct status', () async { });
  test('getSaturatedCropsForMunicipality should filter correctly', () async { });
  test('getCriticalSaturationAlerts should show only critical', () async { });
  ```

### Step 14: Integration Testing
- [ ] Test in development environment
- [ ] Steps:
  1. [ ] Clear all sample data
  2. [ ] Add custom test market purchase
  3. [ ] Run calculation function
  4. [ ] Verify saturation status calculated correctly
  5. [ ] Check dashboard displays data
  6. [ ] Verify recommendations are correct

### Step 15: UI Testing
- [ ] Open dashboard screen
- [ ] Verify all sections load without errors:
  - [ ] Critical alerts section
  - [ ] Crop saturation cards
  - [ ] Detailed statistics
  - [ ] Recommendations show correctly
- [ ] Test refresh functionality
- [ ] Test municipality filter (if implemented)

---

## Phase 7: Documentation & Training

### Step 16: Update Documentation
- [ ] Review `DAILY_MARKET_SATURATION_GUIDE.md`
- [ ] Update examples with your actual municipalities/crops
- [ ] Add screenshots of the dashboard
- [ ] Document data entry process
- [ ] Create troubleshooting guide for your team

### Step 17: User Training
- [ ] Train admins/MAO staff on:
  - [ ] How to record market purchases
  - [ ] How to interpret saturation levels
  - [ ] How to make crop recommendations
- [ ] Train farmers on:
  - [ ] How to read the dashboard
  - [ ] Understanding saturation levels
  - [ ] Making planting decisions

---

## Phase 8: Monitoring & Maintenance

### Step 18: Monitor Data Quality
- [ ] Daily: Check that market purchases are being recorded
  ```sql
  SELECT DATE(purchase_date), COUNT(*) 
  FROM daily_market_purchases 
  GROUP BY DATE(purchase_date) 
  ORDER BY DATE(purchase_date) DESC;
  ```

- [ ] Weekly: Verify saturation calculations
  ```sql
  SELECT * FROM daily_saturation_status 
  WHERE status_date >= CURRENT_DATE - 7
  ORDER BY status_date DESC;
  ```

- [ ] Monitor for missing data
  ```sql
  -- Check for days with no purchases
  SELECT DISTINCT DATE(CURRENT_DATE - (INTERVAL '1 day' * generate_series(1, 30)))
  EXCEPT
  SELECT DISTINCT DATE(purchase_date) FROM daily_market_purchases;
  ```

### Step 19: Backup & Recovery
- [ ] Ensure Supabase backups are enabled
- [ ] Test backup restoration once
- [ ] Document data recovery procedure

---

## Phase 9: Optimization (Optional)

### Step 20: Performance Tuning
If handling high data volume:
- [ ] Add indexes for frequently queried columns:
  ```sql
  CREATE INDEX IF NOT EXISTS idx_dss_status_date_crop 
    ON daily_saturation_status(status_date, crop_type);
  
  CREATE INDEX IF NOT EXISTS idx_dmp_date_municipality 
    ON daily_market_purchases(purchase_date, municipality);
  ```

- [ ] Archive old data (> 1 year) to separate table
- [ ] Implement data aggregation for long-term trends

### Step 21: Enhanced Features
- [ ] Add historical trend visualization
- [ ] Create predictive alerts for coming saturation
- [ ] Implement SMS/notification alerts for critical saturation
- [ ] Add crop recommendation engine using saturation data
- [ ] Create price forecasting based on saturation

---

## Testing Checklist Summary

### Data Entry Tests
- [ ] Can record market purchase without errors
- [ ] Valid data is accepted
- [ ] Invalid data is rejected with error message
- [ ] Duplicate entries are handled correctly

### Calculation Tests
- [ ] Saturation status calculation is accurate
- [ ] Supply > Demand correctly identifies SATURATED status
- [ ] Saturation ratio calculation is correct
- [ ] Levels are assigned correctly (CRITICAL, SATURATED, etc.)

### UI/Display Tests
- [ ] Dashboard loads without errors
- [ ] Critical alerts display prominently
- [ ] All crop cards display correct data
- [ ] Color coding matches saturation level
- [ ] Icons are intuitive
- [ ] Recommendations are clear and actionable
- [ ] Refresh button works
- [ ] No loading spinners stuck indefinitely

### User Acceptance Tests
- [ ] Admins can understand saturation status
- [ ] Farmers can make informed planting decisions
- [ ] System is faster/more accurate than manual analysis
- [ ] Data entry process is simple
- [ ] Dashboard is accessible to intended users

---

## Troubleshooting Guide

### Issue: No saturation data appears in dashboard
**Solution:**
1. Check if market purchases were recorded:
   ```sql
   SELECT COUNT(*) FROM daily_market_purchases;
   ```
2. Check if calculation function was executed:
   ```sql
   SELECT COUNT(*) FROM daily_saturation_status;
   ```
3. Manually trigger calculation:
   ```sql
   SELECT calculate_daily_saturation_status();
   ```

### Issue: Saturation ratios seem incorrect
**Solution:**
1. Verify supply data is present:
   ```sql
   SELECT COUNT(*) FROM saturation_records WHERE primary_crop = 'Tomato';
   ```
2. Check municipality name consistency
3. Manually inspect a specific calculation:
   ```sql
   SELECT * FROM daily_market_purchases 
   WHERE crop_type = 'Tomato' AND purchase_date = CURRENT_DATE - 1;
   ```

### Issue: Service compilation errors
**Solution:**
1. Run: `flutter pub get`
2. Check for import path errors
3. Verify Supabase dependency is up to date
4. Clean build: `flutter clean && flutter pub get`

---

## Go-Live Checklist

Before launching to production:

- [ ] All database tables created and verified
- [ ] All Dart services implemented and tested
- [ ] Dashboard screens created and tested
- [ ] Data entry forms working correctly
- [ ] Daily calculation scheduled
- [ ] Sample data cleared from production database
- [ ] User training completed
- [ ] Documentation available to users
- [ ] Monitoring plan in place
- [ ] Backup/recovery plan tested
- [ ] Admins trained on data management
- [ ] Support team ready for questions

---

## Post-Launch

### First Month
- [ ] Monitor data quality daily
- [ ] Address any user questions immediately
- [ ] Make UI improvements based on feedback
- [ ] Adjust saturation thresholds if needed

### Quarterly Review
- [ ] Analyze data quality metrics
- [ ] Collect user feedback
- [ ] Plan optimization/enhancements
- [ ] Update documentation based on learnings

---

**Document Version:** 1.0
**Last Updated:** January 2024
**Status:** Ready for Implementation
