# Crop Cycling Monitoring - AgriSense DSS Module
## Comprehensive Implementation Guide

**Version**: 1.0  
**Date**: May 17, 2026  
**Module Owner**: AgriTech Development Team  
**Status**: Ready for Supabase Deployment & Integration

---

## Table of Contents
1. [Overview](#overview)
2. [What is Crop Cycling Monitoring?](#what-is-crop-cycling)
3. [System Architecture](#system-architecture)
4. [Database Schema](#database-schema)
5. [Implementation Checklist](#implementation-checklist)
6. [Service API Reference](#service-api-reference)
7. [UI Screens & Navigation](#ui-screens)
8. [Data Entry Workflows](#data-entry)
9. [Reporting & Analytics](#reporting)
10. [Troubleshooting](#troubleshooting)

---

## Overview

The **Crop Cycling Monitoring System** is a comprehensive sub-module of AgriSense DSS that helps farmers optimize crop rotation practices. It:

- **Tracks** complete crop rotation history per field
- **Monitors** soil health indicators (disease/pest observations)
- **Alerts** farmers about monoculture risks and soil fatigue
- **Recommends** optimal crop cycles based on soil type and climate
- **Assesses** disease/pest pressure buildup from consecutive plantings
- **Guides** crop compatibility and rotation planning

### Key Benefits
- ✅ Reduce soil fatigue and maintain soil health
- ✅ Break pest and disease cycles through proper rotation
- ✅ Improve farm productivity with scientifically-backed crop cycles
- ✅ Prevent crop oversaturation through diversification
- ✅ Restore soil nitrogen with legume crops

---

## What is Crop Cycling Monitoring?

### Definition
Crop cycling (crop rotation) is the practice of growing different crops sequentially in the same field to:
1. **Restore soil nutrients** - Different crops have different nutrient needs
2. **Break pest cycles** - Pests specific to one crop starve without their host
3. **Reduce disease buildup** - Soil-borne diseases accumulate with monoculture
4. **Improve soil structure** - Legumes and deep-rooted crops improve soil
5. **Reduce chemical inputs** - Diverse crops need fewer pesticides

### Crop Cycling Categories

#### 🔴 CRITICAL MONOCULTURE (Risk Score > 75%)
- **Status**: Same crop planted 3+ consecutive times
- **Risk**: Severe soil depletion, pest/disease explosion
- **Action**: MUST change crops immediately

#### 🟠 HIGH MONOCULTURE RISK (Risk Score 50-75%)
- **Status**: Same crop planted 2 consecutive times
- **Risk**: Significant soil fatigue, pest pressure building
- **Action**: Plan rotation for next season

#### 🟡 MEDIUM RISK (Risk Score 25-50%)
- **Status**: Legume crop overdue (>2 years since planting)
- **Risk**: Soil nitrogen depletion
- **Action**: Consider planting nitrogen-fixing legume

#### 🟢 GOOD PRACTICE (Risk Score < 25%)
- **Status**: Proper rotation being followed
- **Risk**: Low
- **Action**: Continue current practices, plan ahead

---

## System Architecture

### Component Diagram
```
┌─────────────────────────────────────────────────────────┐
│         CropCyclingMonitoringDashboard (UI)             │
│    [Field Selection] [Risk Assessment] [History]        │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────────────────────────────────────┐
│    CropCyclingMonitoringService (Business Logic)        │
│  ├─ Field Management                                    │
│  ├─ Rotation History Tracking                           │
│  ├─ Risk Assessment & Analysis                          │
│  ├─ Cycle Recommendations                               │
│  └─ Alert Management                                    │
└────────────────┬────────────────────────────────────────┘
                 │
         ┌───────┴────────┐
         │                │
    ┌────▼─────────┐  ┌───▼──────────────┐
    │   Supabase   │  │  PostgreSQL DB   │
    │    Client    │  │                  │
    └─────────────┘  └──────────────────┘
                     ├─ farmer_fields
                     ├─ crop_rotation_history
                     ├─ crop_cycling_monitoring
                     ├─ crop_cycling_alerts
                     ├─ recommended_crop_cycles
                     └─ crop_compatibility
```

### Data Flow
1. **Farmer records crop** → Service records in `crop_rotation_history`
2. **System analyzes history** → `analyze_crop_cycling_for_field()` function
3. **Monitoring data generated** → Stored in `crop_cycling_monitoring`
4. **Risk assessment shown** → UI displays in dashboard
5. **Alerts created** → If risks detected, alerts created
6. **Recommendations provided** → Based on soil type & history

---

## Database Schema

### Table: `farmer_fields`
Represents a farmer's field or plot

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| farmer_id | UUID | Foreign key to farmers |
| field_name | VARCHAR | User-friendly field name |
| location_municipality | VARCHAR | City/Municipality name |
| location_barangay | VARCHAR | Barangay/District name |
| area_hectares | DECIMAL | Field size in hectares |
| soil_type | VARCHAR | 'clay', 'loam', 'sandy', 'sandy_loam', 'clay_loam' |
| soil_ph | DECIMAL | Soil pH value (4-8) |
| irrigation_type | VARCHAR | 'rainfed', 'irrigated', 'mixed' |
| elevation_meters | INTEGER | Elevation in meters |
| is_active | BOOLEAN | Field is still in use |
| created_at | TIMESTAMPTZ | Record creation timestamp |
| updated_at | TIMESTAMPTZ | Last update timestamp |

### Table: `crop_rotation_history`
Each planting record in a field

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| field_id | UUID | FK to farmer_fields |
| farmer_id | UUID | FK to farmers |
| crop_type | VARCHAR | Crop name (Tomato, Onion, etc.) |
| planting_date | DATE | When crop was planted |
| harvest_date | DATE | When crop was harvested |
| area_planted_hectares | DECIMAL | Area used for this crop |
| yield_kg | DECIMAL | Total harvest in kg |
| status | VARCHAR | 'active', 'harvested', 'abandoned' |
| disease_observed | BOOLEAN | Disease presence flagged |
| disease_notes | TEXT | Description of disease |
| pest_observed | BOOLEAN | Pest presence flagged |
| pest_notes | TEXT | Description of pest |
| soil_observations | TEXT | Farmer's soil notes |
| input_notes | TEXT | Fertilizer, seeds, methods |
| recorded_by_farmer | BOOLEAN | True if farmer entered data |
| created_at | TIMESTAMPTZ | Record creation time |
| updated_at | TIMESTAMPTZ | Last update time |

### Table: `recommended_crop_cycles`
Pre-configured rotation cycles based on soil type

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| soil_type | VARCHAR | Target soil type |
| cycle_name | VARCHAR | User-friendly name |
| cycle_description | TEXT | Detailed explanation |
| crops_in_cycle | TEXT[] | Array of crops in sequence |
| cycle_duration_months | INTEGER | How long the full cycle takes |
| soil_health_benefit | VARCHAR | What soil benefit it provides |
| pest_disease_mitigation | TEXT | How it breaks pest/disease cycles |
| nitrogen_fixation | BOOLEAN | Does it include nitrogen fixation |
| recommended_order | INTEGER | Priority order (lower = more recommended) |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Update timestamp |

### Table: `crop_cycling_monitoring`
Auto-generated monitoring and risk assessment data

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| field_id | UUID | FK to farmer_fields |
| farmer_id | UUID | FK to farmers |
| monitoring_date | DATE | When assessment was made |
| is_following_recommended_cycle | BOOLEAN | Farmer following recommendation |
| recommended_cycle_id | UUID | FK to recommended_crop_cycles |
| recommended_next_crop | VARCHAR | What to plant next |
| days_until_next_planting | INTEGER | Days until recommended planting |
| soil_fatigue_risk | VARCHAR | 'low', 'medium', 'high' |
| consecutive_same_crop | INTEGER | Number of times same crop planted |
| years_since_legume_crop | DECIMAL | Years since last legume |
| disease_pressure_level | VARCHAR | 'low', 'medium', 'high' |
| pest_pressure_level | VARCHAR | 'low', 'medium', 'high' |
| monoculture_risk_score | DECIMAL | 0-100 score |
| recommended_action | TEXT | Specific recommendation |
| urgency_level | VARCHAR | 'low', 'medium', 'high', 'critical' |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Update timestamp |

### Table: `crop_compatibility`
Matrix of which crops can follow which crops

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| crop_a | VARCHAR | First crop in sequence |
| crop_b | VARCHAR | Second crop in sequence |
| compatibility_score | DECIMAL | 0-1 (1 = excellent pair) |
| reason | TEXT | Why this pairing works |
| can_follow | BOOLEAN | Can crop_b follow crop_a |
| notes | TEXT | Additional details |

**Example Pairings**:
- Tomato → Mungbean (0.95) - Legume restores nitrogen
- Tomato → Eggplant (0.40) - Same family, risky
- Mungbean → Tomato (0.95) - Excellent rotation
- Onion → Cabbage (0.70) - Acceptable compatibility

### Table: `crop_cycling_alerts`
Notifications sent to farmers about rotation risks

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| farmer_id | UUID | FK to farmers |
| field_id | UUID | FK to farmer_fields |
| alert_type | VARCHAR | 'monoculture_risk', 'disease_pressure', 'soil_fatigue', 'legume_overdue' |
| alert_title | VARCHAR | Short alert title |
| alert_message | TEXT | Detailed alert message |
| recommended_action | TEXT | What farmer should do |
| severity | VARCHAR | 'low', 'medium', 'high', 'critical' |
| is_read | BOOLEAN | Farmer has viewed alert |
| action_taken | BOOLEAN | Farmer has acted on alert |
| action_notes | TEXT | What action was taken |
| created_at | TIMESTAMPTZ | When alert was created |
| resolved_at | TIMESTAMPTZ | When alert was resolved |

---

## Implementation Checklist

### Phase 1: Database Setup
- [ ] Copy `supabase_migration_crop_cycling_monitoring.sql` content
- [ ] Open Supabase Dashboard → SQL Editor
- [ ] Paste entire SQL migration
- [ ] Click "Run" and verify success (no errors)
- [ ] Verify tables created:
  ```sql
  \dt farmer_fields
  \dt crop_rotation_history
  \dt recommended_crop_cycles
  \dt crop_cycling_monitoring
  \dt crop_compatibility
  \dt crop_cycling_alerts
  ```

### Phase 2: Dart Models & Service
- [ ] Copy `lib/models/crop_cycling_model.dart` to project
- [ ] Copy `lib/services/crop_cycling_monitoring_service.dart` to project
- [ ] Run `flutter pub get` to update dependencies
- [ ] Verify no compilation errors:
  ```bash
  flutter analyze
  ```

### Phase 3: UI Implementation
- [ ] Copy `lib/screens/farmer/crop_cycling_monitoring_dashboard.dart` to project
- [ ] Update main navigation to include crop cycling route:
  ```dart
  // In main.dart or router configuration
  '/crop-cycling': (context) => CropCyclingMonitoringDashboard(
    farmerId: userId,
  ),
  ```
- [ ] Add navigation button in farmer home screen

### Phase 4: Data Entry Points
- [ ] Create `RecordCropPlantingScreen` for farmers to log crops
- [ ] Create `RecordHarvestScreen` for harvest data entry
- [ ] Create `AddFieldScreen` for field registration
- [ ] Integrate into farmer dashboard

### Phase 5: Automated Monitoring
- [ ] Call `refresh_crop_cycling_monitoring()` function
  ```dart
  // In a background job or weekly scheduler
  await _supabase.rpc('refresh_crop_cycling_monitoring');
  ```
- [ ] Set up alert generation triggers
- [ ] Verify monitoring data populates correctly

### Phase 6: Testing
- [ ] Test field creation workflow
- [ ] Test crop recording (multiple crops per field)
- [ ] Test risk assessment with sample data
- [ ] Test alert generation
- [ ] Test rotation recommendations
- [ ] Verify Supabase RLS policies work correctly

### Phase 7: Documentation & Training
- [ ] Prepare farmer training materials
- [ ] Create video tutorial for crop cycling entry
- [ ] Document all alert types for support staff
- [ ] Create FAQ document

### Phase 8: Monitoring & Maintenance
- [ ] Set up daily monitoring refresh job
- [ ] Monitor alert accuracy (false positives)
- [ ] Collect farmer feedback on recommendations
- [ ] Track adoption metrics (% of farmers using)

### Phase 9: Optimization
- [ ] Analyze query performance
- [ ] Add indexes for frequently queried fields
- [ ] Optimize alert generation logic
- [ ] Consider caching for recommendation engine

---

## Service API Reference

### CropCyclingMonitoringService Methods

#### Field Management
```dart
// Get all fields for a farmer
Future<List<FarmerField>> getFarmerFields(String farmerId)

// Get specific field details
Future<FarmerField> getFieldById(String fieldId)

// Create a new field
Future<FarmerField> createField({
  required String farmerId,
  required String fieldName,
  required String locationMunicipality,
  String? locationBarangay,
  required double areaHectares,
  required String soilType,
  double? soilPh,
  String? irrigationType,
  int? elevationMeters,
})

// Update field information
Future<FarmerField> updateField(String fieldId, Map<String, dynamic> updates)
```

#### Rotation History
```dart
// Record a new crop planting
Future<CropRotationHistory> recordCropPlanting({
  required String fieldId,
  required String farmerId,
  required String cropType,
  required DateTime plantingDate,
  double? areaPlantedHectares,
  bool diseaseObserved = false,
  String? diseaseNotes,
  bool pestObserved = false,
  String? pestNotes,
  String? soilObservations,
  String? inputNotes,
})

// Get rotation history for a field
Future<List<CropRotationHistory>> getFieldRotationHistory(String fieldId)

// Record harvest information
Future<CropRotationHistory> recordHarvest(
  String plantingId, {
  required DateTime harvestDate,
  double? yieldKg,
  String? soilObservations,
})

// Get active crops
Future<List<CropRotationHistory>> getActiveCrops(String farmerId)
```

#### Monitoring & Analysis
```dart
// Get monitoring data for a field
Future<CropCyclingMonitoring?> getFieldMonitoring(String fieldId)

// Get all farmer's monitoring data
Future<List<CropCyclingMonitoring>> getFarmerMonitoring(String farmerId)

// Get critical risk fields
Future<List<CropCyclingMonitoring>> getCriticalRiskFields(String farmerId)

// Assess monoculture risk
Future<Map<String, dynamic>> assessMonocultureRisk(String fieldId)

// Get legume planting status
Future<Map<String, dynamic>> getLegumePlantingStatus(String fieldId)

// Get soil health trend
Future<Map<String, dynamic>> getSoilHealthTrend(String fieldId)
```

#### Recommendations
```dart
// Get recommended crop cycles for soil type
Future<List<RecommendedCropCycle>> getRecommendedCycles(String soilType)

// Check compatibility between two crops
Future<CropCompatibility?> getCropCompatibility(String cropA, String cropB)

// Get compatible next crops
Future<List<CropCompatibility>> getCompatibleNextCrops(String currentCrop)

// Get incompatible crops
Future<List<String>> getIncompatibleCrops(String currentCrop)
```

#### Alerts
```dart
// Get unread alerts
Future<List<CropCyclingAlert>> getUnreadAlerts(String farmerId)

// Get filtered alerts
Future<List<CropCyclingAlert>> getFarmerAlerts(
  String farmerId, {
  String? alertType,
  String? severity,
  bool? unreadOnly,
})

// Get field alerts
Future<List<CropCyclingAlert>> getFieldAlerts(String fieldId)

// Mark alert as read
Future<void> markAlertAsRead(String alertId)

// Record action on alert
Future<void> recordAlertAction(String alertId, {required String actionNotes})
```

---

## UI Screens

### Crop Cycling Monitoring Dashboard
**File**: `lib/screens/farmer/crop_cycling_monitoring_dashboard.dart`

**Features**:
1. **Alert Banner** - Shows critical alerts at top
2. **Field Selector** - Filter chips to select which field to view
3. **Field Overview** - Location, area, soil type, irrigation
4. **Risk Assessment Cards** - Soil fatigue, disease, pest pressure
5. **Monoculture Risk Score** - 0-100 visual indicator
6. **Rotation History Timeline** - All crops planted with details
7. **Recommended Cycles** - Best rotations for soil type
8. **Alert Management** - View and manage field alerts

**Access Point**:
```dart
// In farmer home or navigation
GestureDetector(
  onTap: () => Navigator.pushNamed(context, '/crop-cycling'),
  child: Card(
    child: Column(
      children: [
        Icon(Icons.agriculture),
        Text('Crop Cycling Monitor'),
      ],
    ),
  ),
)
```

### Recommended Data Entry Screens
*(To be implemented)*

#### 1. Add Field Screen
- Field name, location, area, soil type
- Soil pH and irrigation method
- Elevation and other characteristics

#### 2. Record Crop Planting Screen
- Select field
- Choose crop type
- Planting date
- Area planted
- Notes on inputs

#### 3. Record Harvest Screen
- Select active crop
- Harvest date
- Yield in kg
- Disease/pest observations
- Soil observations

#### 4. Manage Alerts Screen
- View all alerts with filtering
- Mark as read
- Record actions taken
- Provide feedback

---

## Data Entry Workflows

### Workflow 1: Farmer Starts Using System
```
1. Create Field Profile
   ├─ Field name: "North Plot"
   ├─ Area: 0.5 hectares
   ├─ Soil type: "loam"
   └─ Location: "Cebu City, Mabolo"

2. Record First Crop
   ├─ Crop: "Tomato"
   ├─ Planting date: 2026-05-17
   └─ Area: 0.5 ha

3. System enables monitoring
   └─ Can now view rotations and get recommendations
```

### Workflow 2: Recording Harvest & Planting Next Crop
```
1. Record Harvest
   ├─ Select active Tomato planting
   ├─ Harvest date: 2026-08-20
   ├─ Yield: 2500 kg
   └─ Observations: "Some early blight detected"

2. System analyzes
   ├─ Disease pressure detected
   ├─ Monoculture risk: 50% (second consecutive)
   └─ Alert generated: "Avoid planting Tomato again"

3. Plan Next Crop
   ├─ View recommended cycles for loam soil
   ├─ Compatible options: Mungbean (0.95), Eggplant (0.40)
   ├─ Plan Mungbean for next season
   └─ Record planting when ready
```

### Workflow 3: Responding to Alerts
```
1. Farmer sees CRITICAL alert
   "Tomato planted 3 consecutive times - monoculture risk"

2. Options:
   a. Plant different crop immediately
   b. Record notes about why continuing Tomato
   c. View recommended alternatives

3. Take action
   └─ Either rotate or document reasoning
```

---

## Reporting & Analytics

### Key Metrics to Track
1. **Farmer Compliance Rate**
   - % of farmers following recommended cycles

2. **Monoculture Prevalence**
   - Average consecutive plantings per field

3. **Disease/Pest Pressure**
   - % of plantings with disease/pest observations

4. **Legume Adoption**
   - % of farmers planting nitrogen-fixing crops

5. **Alert Response Time**
   - How quickly farmers act on alerts

### Recommended Reports
```dart
// Get field-level summary
Map summary = await service.getFieldRotationSummary(fieldId);

// Get farmer-level trend
List<CropCyclingMonitoring> monitoring = 
  await service.getFarmerMonitoring(farmerId);

// Get critical fields needing intervention
List<CropCyclingMonitoring> critical = 
  await service.getCriticalRiskFields(farmerId);
```

---

## Troubleshooting

### Issue: "No monitoring data available"
**Cause**: No crop rotation history recorded yet
**Solution**: 
1. Record at least one crop planting
2. Wait for system to generate monitoring data
3. Check `crop_cycling_monitoring` table is populated

### Issue: "Risk score seems too high"
**Cause**: Monoculture risk assessment is conservative
**Why**: 
- Consecutive same crop = 25 points per occurrence
- Legume overdue = 25 points
- Poor compatibility = 25 points
**Solution**: Review recommendations and rotate crops

### Issue: "Alerts not being generated"
**Cause**: `refresh_crop_cycling_monitoring()` not run recently
**Solution**:
```sql
-- Manually run monitoring refresh
SELECT refresh_crop_cycling_monitoring();
```

### Issue: "Compatibility score missing"
**Cause**: Crop pair not in `crop_compatibility` table
**Solution**: 
1. Add new pairing to `crop_compatibility`
2. Provide compatibility_score (0-1)
3. Add reason and notes

### Issue: "Performance slow on large dataset"
**Cause**: Missing indexes or heavy functions
**Solution**:
1. Check indexes exist:
   ```sql
   CREATE INDEX idx_rotation_field_date ON crop_rotation_history(field_id, planting_date DESC);
   ```
2. Use pagination for history queries
3. Cache monitoring results

---

## Quick Start Guide for Farmers

### 5-Minute Setup
1. **Create Your First Field**
   - Name: Your field name
   - Soil type: Choose from dropdown
   - Area: Measure in hectares
   - Location: Your municipality

2. **Record Your Current Crop**
   - Crop name
   - Planting date
   - Area planted

3. **View Recommendations**
   - System suggests best crops for next season
   - See why pairing works

### Daily Checklist
- [ ] Check for new alerts
- [ ] Record any disease/pest observations
- [ ] Note crop performance
- [ ] Plan for harvest date

---

## Integration with AgriSense DSS

### Navigation Integration
Add to farmer dashboard navigation:
```dart
ListTile(
  leading: const Icon(Icons.nature),
  title: const Text('Crop Cycling Monitor'),
  subtitle: const Text('Optimize your crop rotation'),
  onTap: () => Navigator.pushNamed(context, '/crop-cycling'),
)
```

### Cross-Module Integration
- **Saturation Intelligence**: Use crop diversity data
- **Market Intelligence**: Recommend crops with good market demand
- **Weather Advisor**: Factor in seasonal crop suitability
- **Farm Financial Planner**: Include crop rotation costs

---

## Support & Questions

For issues, questions, or suggestions:
1. Check troubleshooting section above
2. Review SQL migration for schema details
3. Check service API reference for method usage
4. Consult Dart model documentation for data structures

---

**END OF DOCUMENTATION**
