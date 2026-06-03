// ─────────────────────────────────────────────────────────────────────────────
// Financial Model Assumptions — AgriSense DSS Financial Forecasting Module
// PRD v1.0 · Tubungan, Iloilo, Philippines
//
// Sources:
//   §5.2  Monthly Market Demand (MAO market records)
//   §5.3  Price Data & Elasticity (DA / PSA Iloilo 2025)
//   §5.4  Production Cost Defaults (DA/MAO reference, ₱/ha)
//   §5.5  Loss Rate Data (DA / MAO field records)
//   §6    Computation Engine formulas
//   §7    Scenario Analysis Framework drivers
// ─────────────────────────────────────────────────────────────────────────────

// ── Crop key mapping ─────────────────────────────────────────────────────────
const kFmCropKeys = ['ampalaya', 'string_beans', 'squash', 'eggplant', 'okra'];

/// Maps snake_case crop key → display name
const Map<String, String> kCropKeyToName = {
  'ampalaya':    'Ampalaya (Bitter Gourd)',
  'string_beans': 'String Beans',
  'squash':      'Squash',
  'eggplant':    'Eggplant',
  'okra':        'Okra',
};

// ── §5.1  Yield per hectare (kg/ha) — DA/MAO Iloilo reference ─────────────
const Map<String, double> kYieldPerHa = {
  'ampalaya':    9000,   // 9 MT/ha (bitter gourd)
  'string_beans': 8000,  // 8 MT/ha
  'squash':      15000,  // 15 MT/ha
  'eggplant':    20000,  // 20 MT/ha
  'okra':        10000,  // 10 MT/ha
};

// ── §5.2  Monthly market demand (kg/month) — MAO market survey estimates ────
const Map<String, double> kMonthlyDemand = {
  'okra':         50000,
  'eggplant':     60000,
  'ampalaya':     45000,
  'squash':       40000,
  'string_beans': 38000,
};

// ── §5.3  Base prices (₱/kg) — 2025 average farmgate ────────────────────────
const Map<String, double> kFmBasePrices = {
  'ampalaya':    94.0,   // from kPriceBaselines (Jul–Dec 2025 avg)
  'string_beans': 102.0,
  'squash':       50.0,
  'eggplant':     86.0,
  'okra':        113.0,
};

// ── §5.3  Price elasticity coefficients ─────────────────────────────────────
// Interpretation: -0.4 means 10% supply increase → 4% price decrease
const Map<String, double> kPriceElasticity = {
  'ampalaya':    -0.40,
  'string_beans': -0.30,
  'squash':      -0.50,  // high sensitivity — confirmed by 2025 collapse
  'eggplant':    -0.35,
  'okra':        -0.40,
};

// ── §5.5  Pre-harvest loss rates (decimal) ───────────────────────────────────
const Map<String, double> kPreHarvestLoss = {
  'okra':         0.05,
  'eggplant':     0.04,
  'squash':       0.03,
  'ampalaya':     0.06,
  'string_beans': 0.05,
};

// ── §5.5  Post-harvest loss rates (decimal) ──────────────────────────────────
const Map<String, double> kPostHarvestLoss = {
  'okra':         0.08,
  'eggplant':     0.10,
  'squash':       0.05,
  'ampalaya':     0.09,
  'string_beans': 0.07,
};

// ── §5.4  Default production costs (₱/ha) — MAO reference values ─────────────
// Farmers enter actuals in Crop Cycle Journal; these are forecasting defaults
const Map<String, double> kDefaultCostPerHa = {
  'land_prep':        4000,   // plowing + harrowing
  'seeds':            4750,   // mid of ₱3,500–₱6,000
  'fertilizer':       8500,   // mid of ₱7,000–₱10,000 (inorganic + organic)
  'pesticides':       3000,   // mid of ₱2,000–₱4,000
  'labor_planting':   3000,
  'labor_weeding':    2500,
  'labor_harvesting': 4000,   // per harvest cycle
  'irrigation':       2250,   // mid of ₱1,500–₱3,000 (if irrigated)
  'transport':        2000,   // mid of ₱1,500–₱2,500 to market
};

// Total default cost per ha (sum of all above)
double get kTotalDefaultCostPerHa =>
    kDefaultCostPerHa.values.fold(0.0, (s, v) => s + v);

// ── §7  Scenario Analysis Framework drivers ──────────────────────────────────
class ScenarioDrivers {
  final double priceMult;      // multiplier on base price
  final double yieldMult;      // multiplier on yield per ha
  final double demandMult;     // multiplier on monthly demand
  final double postHarvestLoss; // fixed post-harvest loss rate (decimal)
  final double supplyMult;     // multiplier on competing supply / MSF

  const ScenarioDrivers({
    required this.priceMult,
    required this.yieldMult,
    required this.demandMult,
    required this.postHarvestLoss,
    required this.supplyMult,
  });
}

const kScenarioBest = ScenarioDrivers(
  priceMult: 1.15,    // +15% above baseline
  yieldMult: 1.10,    // +10% above average
  demandMult: 1.20,   // High demand +20%
  postHarvestLoss: 0.03, // 3% (optimistic)
  supplyMult: 0.80,   // Low competing supply
);

const kScenarioExpected = ScenarioDrivers(
  priceMult: 1.00,    // Baseline
  yieldMult: 1.00,    // Historical average
  demandMult: 1.00,   // Baseline demand
  postHarvestLoss: 0.08, // Crop average (mid)
  supplyMult: 1.00,   // Normal supply
);

const kScenarioWorst = ScenarioDrivers(
  priceMult: 0.75,    // -25% below baseline
  yieldMult: 0.80,    // -20% below average
  demandMult: 0.80,   // Low demand -20%
  postHarvestLoss: 0.18, // 18% (high loss)
  supplyMult: 1.35,   // High competing supply +35%
);

// ── MSI thresholds (§6.5) ────────────────────────────────────────────────────
class MsiStatus {
  final String label;
  final String action;
  final int colorValue;
  const MsiStatus({required this.label, required this.action, required this.colorValue});
}

MsiStatus getMsiStatus(double msi) {
  if (msi < 0.80) return const MsiStatus(
    label: 'Undersupply', action: 'Opportunity — high-demand crop',
    colorValue: 0xFF1B7737,
  );
  if (msi <= 1.00) return const MsiStatus(
    label: 'Balanced', action: 'Green — monitor only',
    colorValue: 0xFF16A34A,
  );
  if (msi <= 1.30) return const MsiStatus(
    label: 'Moderate Oversupply Risk', action: 'Diversification nudge recommended',
    colorValue: 0xFFF59E0B,
  );
  return const MsiStatus(
    label: 'Critical Oversupply', action: 'MAO advisory — recommend crop substitution',
    colorValue: 0xFFDC2626,
  );
}
