# Predictive Market Saturation System
## How Farmers Can Plan Better Crops

**Version:** 1.0  
**Date:** May 20, 2026  
**Purpose:** Help farmers predict market saturation BEFORE planting based on their own planting intentions

---

## Problem It Solves

**Old Way (Reactive):**
- Farmer plants Okra (same as everyone else)
- At harvest: market is oversupplied → prices crash → farmer loses money

**New Way (Predictive):**
- Farmer inputs: "I want to plant 500kg Okra on 1 hectare"
- System aggregates all farmer intentions → predicts: "20 farmers are planting 10,000kg total"
- System shows: "Market will have 30% oversupply → prices drop 15% → NOT profitable"
- Farmer switches to Cabbage instead → profits saved! ✅

---

## How It Works

### Step 1: Farmer Enters Planting Intention

```
Screen: "Add Your Planting Plan"

Input:
  ├─ Crop: "Okra"
  ├─ Quantity to plant: 500 kg
  ├─ Land area: 1.0 hectares
  └─ Expected yield per hectare: 500 kg/ha

Expected harvest = 1.0 ha × 500 kg/ha = 500 kg
```

### Step 2: System Collects All Farmer Intentions

System queries: "How many farmers are planning to plant Okra in Dry Season 2026 in San Jose barangay?"

```
Farmer A: 500 kg (1.0 ha)
Farmer B: 1000 kg (2.0 ha)
Farmer C: 800 kg (1.6 ha)
Farmer D: 700 kg (1.4 ha)
─────────────────────
TOTAL:  3000 kg from 4 farmers
```

### Step 3: Calculate Expected Market Supply

```
Expected Total Harvest = SUM(Land Area × Expected Yield per Ha)
                       = (1.0 + 2.0 + 1.6 + 1.4) × 500 kg/ha
                       = 3000 kg
```

### Step 4: Compare Supply vs Market Demand

```
Estimated Market Demand for Okra = 2000 kg (based on historical data)
Expected Total Supply = 3000 kg
───────────────────────────────────
Supply-to-Demand Ratio = 3000 / 2000 = 1.5

Interpretation:
  > 1.0 = OVERSUPPLY (too much crop)
  1.5 = 50% OVERSUPPLY! ⚠️
```

### Step 5: Predict Price Impact

**Formula:** Each 10% oversupply = ~5% price drop

```
Oversupply % = (1.5 - 1.0) × 100 = 50% oversupply
Price Impact = 50% × 0.5 = -25% price drop

Historical price: ₱12/kg
Predicted price: ₱12 × (1 - 0.25) = ₱9/kg ⬇️
```

### Step 6: Calculate Profit Impact

```
Farmer A's situation:

Old scenario (no oversupply):
  Revenue = 500 kg × ₱12/kg = ₱6,000
  Costs (approx) = ₱3,000
  Profit = ₱3,000

New scenario (with 50% oversupply):
  Revenue = 500 kg × ₱9/kg = ₱4,500
  Costs (same) = ₱3,000
  Profit = ₱1,500 ⬇️ LOSS of ₱1,500!
```

### Step 7: Generate Recommendation

```
Result: ❌ HIGH RISK

"Severe oversupply (50% excess supply) expected. 
Prices will drop significantly to ₱9/kg. 
Plant alternative crop instead."

Better options:
  ✅ Cabbage: Supply-Demand Ratio = 0.8 (undersupply!) → ₱15/kg
  ✅ Eggplant: Supply-Demand Ratio = 1.1 (slight oversupply) → ₱11/kg
```

---

## Saturation Levels Explained

| Level | Ratio | Signal | Action |
|---|---|---|---|
| **Undersupply** | < 0.8 | Demand > Supply | ✅ **PLANT** - High demand, good prices |
| **Safe** | 0.8 - 1.0 | Balanced | ✅ **SAFE** - Normal market conditions |
| **Caution** | 1.0 - 1.3 | 30% Oversupply | ⚠️ **WATCH** - Prices may drop |
| **Danger** | > 1.3 | >30% Oversupply | ❌ **AVOID** - Heavy losses likely |

---

## Real Example

### Your Okra Scenario

You saw this on screen:
```
AgriFinancial DSS > OKRA (May 2026)
├─ PPI: -6.7% (prices 6.7% lower than normal)
├─ MAR: 75% (25% waste/unsold)
└─ IUR: 25% (high unsold inventory)
```

**WITH THE NEW SYSTEM:**

```
Market Saturation Forecast:
├─ Farmers Planning Okra in May: 18 farmers
├─ Total Planned: 9,000 kg
├─ Market Demand: 5,000 kg
├─ Supply-Demand Ratio: 1.8 (80% OVERSUPPLY!)
├─ Predicted Price: ₱8.50/kg (was ₱12/kg)
├─ Your Profit Impact: -₱2,250
└─ Recommendation: ❌ AVOID - Plant Cabbage instead
```

---

## Database Structure

### planting_intentions Table

```sql
CREATE TABLE planting_intentions (
  id: UUID (primary key)
  farmer_id: UUID (references users)
  crop_id: TEXT ("okra", "cabbage", etc.)
  crop_name: TEXT ("Okra", "Cabbage", etc.)
  barangay: TEXT ("San Jose", "Tubungan", etc.)
  
  -- The farmer's plan:
  planned_quantity_kg: DECIMAL (e.g., 500)
  land_area_ha: DECIMAL (e.g., 1.0)
  expected_yield_per_ha_kg: DECIMAL (e.g., 500)
  
  -- Timing:
  planting_season: TEXT ("Dry Season 2026", "Wet Season 2026")
  status: TEXT ("planning", "confirmed", "harvesting")
  
  -- Tracking:
  recorded_at: TIMESTAMP
  created_at: TIMESTAMP
  updated_at: TIMESTAMP
);
```

---

## Code Files

### 1. **Model** (`lib/models/planting_intention.dart`)
- `PlantingIntention` - stores farmer's planting plan
- `SaturationPrediction` - stores prediction results

### 2. **Service** (`lib/services/planting_intention_service.dart`)
- `submitPlantingIntention()` - save farmer's plan
- `predictMarketSaturation()` - **CORE FUNCTION** - calculates prediction
- `compareCropOptions()` - compare multiple crops
- `getSaturationSummary()` - dashboard overview

### 3. **UI Screen** (`lib/screens/features/planting_intention_screen.dart`)
- Input section: farmer enters their plan
- My Plans section: shows farmer's intentions
- Market Predictions section: shows saturation forecast

### 4. **Database** (`supabase_migration_planting_intentions.sql`)
- Creates `planting_intentions` table
- Adds row-level security
- Creates indexes for performance
- Adds `planting_intentions_summary` view for analysis

---

## Key Calculations

### 1. Expected Harvest
```dart
expectedHarvestKg = landAreaHa * expectedYieldPerHaKg
```

### 2. Supply-to-Demand Ratio
```dart
supplyDemandRatio = totalExpectedHarvest / marketDemand
```

### 3. Price Impact Prediction
```dart
oversupplyPercent = (supplyDemandRatio - 1.0) * 100
priceImpactPercent = oversupplyPercent * 0.5  // -5% per 10% oversupply

forecastedPrice = baselinePrice * (1 + priceImpactPercent/100)
```

### 4. Profit Impact
```dart
oldProfit = (expectedHarvest * baselinePrice) * 0.30  // assume 30% margin
newProfit = (expectedHarvest * forecastedPrice) * 0.30

profitImpact = newProfit - oldProfit
```

---

## How to Use

### For Farmers

1. **Go to Planting Intention Screen**
   ```
   Menu → Financial Model → Planting Plans
   ```

2. **Enter your planting plan**
   ```
   Crop: Okra
   Quantity: 500 kg
   Land: 1.0 ha
   Yield: 500 kg/ha
   ```

3. **See market saturation forecast**
   ```
   System shows:
   - How many other farmers are planting same crop
   - Total supply expected
   - Market demand
   - Price prediction
   - YOUR profit impact
   ```

4. **Compare crops**
   ```
   "If I plant Cabbage instead:
   - Supply ratio: 0.9 (good!)
   - Predicted price: ₱15/kg
   - My profit: +₱2,500 ✅"
   ```

5. **Make informed decision**
   - Plant high-demand crop → better profit
   - Avoid saturated crops → avoid losses

---

## Example Scenario

**Farmer Juan in San Jose, Dry Season 2026:**

```
Juan thinks: "I'll plant Okra like everyone else"

System shows:
├─ 18 farmers planning Okra
├─ 9,000 kg total supply
├─ Market only needs 5,000 kg
├─ Price will drop 30% to ₱8.50/kg
└─ Your profit: ₱1,500 (vs. normal ₱3,500)

Compare options:
├─ Okra: DANGER ❌ (ratio 1.8)
├─ Cabbage: SAFE ✅ (ratio 0.9) → ₱15/kg profit ₱4,000
└─ Eggplant: CAUTION ⚠️ (ratio 1.2) → ₱11/kg profit ₱2,500

Juan chooses: Cabbage
Result: +₱500 profit vs. if he planted Okra! 🎉
```

---

## Integration Points

### Connect to AgriFinancial Module

```dart
// In AIS Crop Viability screen:
// Add recommendation based on market saturation

// BEFORE (just looked at historical data):
// PPI = +8%, IUR = 20% → "Plant Okra"

// NOW (includes predictive saturation):
// PPI = +8% BUT saturation ratio = 1.8 → "AVOID: Market oversupplied"
```

### Connect to Crop Cycling

```dart
// Suggest crops for next cycle based on:
// 1. Your farm profit history
// 2. Other farmers' planting plans (market saturation)
// 3. Complementary crop rotation
```

---

## Benefits

| For Farmers | Impact |
|---|---|
| **Know market before planting** | Avoid planting saturated crops |
| **Compare crops** | Choose most profitable option |
| **Predict price drops** | Plan finances accordingly |
| **Join coordination** | Work with other farmers to diversify |
| **Reduce waste** | Plant only what market needs |

| For Cooperatives/Buyers | Impact |
|---|---|
| **Forecast supply** | Plan procurement and pricing |
| **Identify gaps** | Recommend high-demand crops |
| **Prevent gluts** | Coordinate planting across members |
| **Fair pricing** | Base on predicted supply/demand |

---

## Future Enhancements

1. **Real-time alerts**: "12 farmers just added Okra plans! Saturation now 1.6"
2. **Farmer coordination**: "Join group planting Cabbage to reduce competition"
3. **Price guarantees**: "If you plant Cabbage, cooperative guarantees ₱15/kg"
4. **Insurance**: "Saturation insurance: if price drops > 20%, we cover loss"
5. **Marketplace integration**: "Buyers already waiting for 3000kg Cabbage"
6. **Weather factors**: "Dry season = lower Okra yield → less oversupply"
7. **Storage options**: "High market saturation? Store 30% for off-season sales"

---

## Success Metrics

- **Adoption**: % of farmers using planting intention feature
- **Accuracy**: % of predictions within ±10% of actual prices
- **Profit**: Average farmer profit improvement
- **Market diversity**: Crops planted per barangay (reduced concentration)
- **Coordination**: % of farmers successfully coordinating planting
