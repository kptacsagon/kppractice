// ─────────────────────────────────────────────────────────────────────────────
// AgriSat Real Data — verified field data from 2025
//
// Source: Field harvest tables (Jan–Dec 2025) + weekly market price monitoring
//         (Jul–Dec 2025) for 5 pakbet high-value crops.
//
// Feeds:
//   • PPI Engine                  — kWeeklyPrices, kPriceBaselines, PpiThresholds
//   • Supply Forecast             — kHarvestData.production, newlyPlanted
//   • MAR denominator (Q_total)   — kHarvestData.production
//   • BAW Farmer Tracker          — kHarvestData.farmersTotal
//   • Municipal Crop Calendar     — kCropCalendar, kSaturationRiskMonths
//   • MAO KPI Dashboard           — kAnnualTotals, kPpiResults
//   • Alert/Advisory Service      — PpiThresholds, kSaturationRiskMonths
//   • MAO Advisory Panel          — kSystemInsights
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ── Crop registry ─────────────────────────────────────────────────────────────

const List<String> kAgriSatCropKeys = [
  'ampalaya', 'stringBeans', 'eggplant', 'okra', 'squash',
];

const Map<String, String> kCropDisplayNames = {
  'ampalaya': 'Ampalaya',
  'stringBeans': 'String Beans',
  'eggplant': 'Eggplant',
  'okra': 'Okra',
  'squash': 'Squash',
};

const Map<String, String> kCropLocalNames = {
  'ampalaya': 'Ampalaya',
  'stringBeans': 'Sitaw',
  'eggplant': 'Talong',
  'okra': 'Okra',
  'squash': 'Kalabasa',
};

// ── Weekly retail prices, Jul–Dec 2025 (₱/kg) ────────────────────────────────

const Map<String, List<double>> kWeeklyPrices = {
  'ampalaya': [
    100,80,100,100,100,100,100,75,70,75,80,80,80,80,80,90,90,100,50,100,
    100,100,100,120,100,150,110,120,100,80,100,100,100,
  ],
  'stringBeans': [
    100,110,60,110,100,110,105,100,100,105,105,100,80,120,100,100,100,110,
    110,115,120,100,
  ],
  'eggplant': [
    65,72,100,60,80,100,65,65,80,72,100,80,80,65,70,70,75,80,80,80,80,80,
    80,80,60,60,80,80,150,140,180,110,100,80,70,100,125,
  ],
  'okra': [
    30,60,110,80,110,130,110,130,60,130,120,110,150,110,150,150,160,160,
    120,90,70,120,130,130,110,105,160,130,130,100,90,90,90,100,90,100,
    150,150,150,150,150,130,
  ],
  'squash': [
    40,45,40,50,40,50,40,50,45,60,50,50,55,65,65,60,60,70,70,80,60,50,50,
    50,30,50,35,35,30,40,35,30,35,25,30,30,30,80,
  ],
};

// 6-month rolling baseline (avg Jul–Dec) for PPI computation
const Map<String, double> kPriceBaselines = {
  'ampalaya': 94,
  'stringBeans': 102,
  'eggplant': 86,
  'okra': 113,
  'squash': 50,
};

// ── PPI alert thresholds ─────────────────────────────────────────────────────

class PpiThresholds {
  static const double severeDrop = -25;   // MAO activates market intervention
  static const double saturation = -15;   // MAO advisory to all BAWs
  static const double caution = -10;      // BAW alerts farmers
  static const double stableLow = -5;
  static const double stableHigh = 10;
  static const double highDemand = 10;    // Recommend increased planting
}

// ── Monthly harvest data, Jan(0)–Dec(11) 2025 ────────────────────────────────

class CropMonthlyData {
  final List<double> production;      // MT per month
  final List<double> areaHarvested;   // HA per month
  final List<double> newlyPlanted;    // HA per month — forward supply signal
  final List<int> farmersTotal;
  final List<int> farmersMale;
  final List<int> farmersFemale;
  const CropMonthlyData({
    required this.production,
    required this.areaHarvested,
    required this.newlyPlanted,
    required this.farmersTotal,
    required this.farmersMale,
    required this.farmersFemale,
  });
}

const Map<String, CropMonthlyData> kHarvestData = {
  'ampalaya': CropMonthlyData(
    production: [2.50,2.25,6.00,5.50,2.50,1.75,2.00,3.00,6.00,6.00,9.00,6.00],
    areaHarvested: [0.25,0.25,0.75,0.50,0.50,0.50,0.50,0.25,0.50,0.50,0.75,0.50],
    newlyPlanted: [1.00,0.75,0.00,0.00,0.25,0.50,0.50,0.50,0.50,0.25,0.75,0.00],
    farmersTotal: [105,105,105,105,115,150,150,110,110,110,125,135],
    farmersMale: [80,80,80,80,85,100,100,75,75,75,85,95],
    farmersFemale: [25,25,25,25,30,50,50,35,35,35,40,40],
  ),
  'stringBeans': CropMonthlyData(
    production: [0.00,0.75,1.25,1.08,0.75,1.25,1.25,13.75,8.25,5.50,5.50,5.25],
    areaHarvested: [0.50,0.00,0.25,0.50,0.50,0.50,0.50,1.25,0.75,1.00,0.50,0.00],
    newlyPlanted: [0.50,0.25,0.25,0.25,0.25,0.75,0.75,0.50,1.00,0.25,0.50,0.75],
    farmersTotal: [110,110,110,110,105,125,125,90,100,85,90,95],
    farmersMale: [75,75,75,75,70,85,85,50,55,45,50,50],
    farmersFemale: [35,35,35,35,35,40,40,40,45,40,40,45],
  ),
  'squash': CropMonthlyData(
    production: [1.20,1.25,10.35,7.50,0.00,0.00,0.00,17.50,14.00,10.50,17.50,17.50],
    areaHarvested: [0.10,0.10,1.10,1.00,0.00,0.00,0.00,1.25,1.00,0.75,1.25,1.25],
    newlyPlanted: [1.00,1.50,0.00,0.75,0.00,1.00,0.75,1.50,0.75,0.75,1.50,1.25],
    farmersTotal: [135,135,135,135,145,170,170,95,100,110,120,135],
    farmersMale: [95,95,95,95,95,95,95,75,75,80,80,85],
    farmersFemale: [40,40,40,40,50,75,75,20,25,30,40,50],
  ),
  'eggplant': CropMonthlyData(
    production: [0.45,5.25,8.75,5.50,7.50,6.50,7.50,7.50,11.25,11.25,11.25,4.23],
    areaHarvested: [0.50,0.75,1.25,1.25,1.25,1.25,1.00,0.50,0.75,0.75,0.75,0.00],
    newlyPlanted: [0.75,0.50,0.25,0.50,0.50,0.75,0.75,0.25,0.00,1.00,1.00,1.50],
    farmersTotal: [125,125,125,125,125,225,225,115,115,120,130,170],
    farmersMale: [100,100,100,100,100,150,150,95,95,95,100,135],
    farmersFemale: [25,25,25,25,25,75,75,20,20,25,30,45],
  ),
  'okra': CropMonthlyData(
    production: [1.25,1.15,5.25,5.50,0.00,0.50,0.75,3.13,3.13,6.25,1.25,0.00],
    areaHarvested: [1.00,1.00,1.00,1.00,1.75,0.25,0.50,0.75,0.50,0.75,0.50,0.00],
    newlyPlanted: [0.75,0.75,0.25,0.25,0.50,0.50,0.50,0.25,0.25,0.50,0.75,0.00],
    farmersTotal: [145,145,145,145,145,155,155,70,80,80,85,0],
    farmersMale: [95,95,95,95,95,95,95,40,45,45,50,0],
    farmersFemale: [50,50,50,50,50,60,60,30,35,35,35,0],
  ),
};

// ── Annual totals 2025 (from harvest table headers) ──────────────────────────

class CropAnnualTotal {
  final int totalFarmers;
  final int male;
  final int female;
  final double totalHaPlanted;
  final double haHarvested;
  final double productionMT;
  const CropAnnualTotal({
    required this.totalFarmers,
    required this.male,
    required this.female,
    required this.totalHaPlanted,
    required this.haHarvested,
    required this.productionMT,
  });
}

const Map<String, CropAnnualTotal> kAnnualTotals = {
  'ampalaya':    CropAnnualTotal(totalFarmers: 1425, male: 1010, female: 415, totalHaPlanted: 17.00, haHarvested: 5.75, productionMT: 52.50),
  'stringBeans': CropAnnualTotal(totalFarmers: 1255, male: 790,  female: 465, totalHaPlanted: 16.25, haHarvested: 6.25, productionMT: 49.58),
  'squash':      CropAnnualTotal(totalFarmers: 1585, male: 1060, female: 525, totalHaPlanted: 25.95, haHarvested: 7.80, productionMT: 97.30),
  'eggplant':    CropAnnualTotal(totalFarmers: 1725, male: 1310, female: 415, totalHaPlanted: 21.75, haHarvested: 10.25, productionMT: 86.93),
  'okra':        CropAnnualTotal(totalFarmers: 1350, male: 845,  female: 505, totalHaPlanted: 111.75, haHarvested: 9.50, productionMT: 29.90),
};

// ── Cropping calendar ────────────────────────────────────────────────────────
// Values: 'plant' | 'grow' | 'harvest' | 'off'    Index: 0=Jan, 11=Dec

const Map<String, List<String>> kCropCalendar = {
  'ampalaya':    ['grow','harvest','harvest','harvest','plant','grow','grow','harvest','harvest','harvest','harvest','harvest'],
  'stringBeans': ['off','off','plant','grow','grow','plant','grow','harvest','harvest','harvest','harvest','harvest'],
  'squash':      ['plant','grow','harvest','harvest','off','plant','grow','harvest','harvest','harvest','harvest','harvest'],
  'eggplant':    ['plant','grow','harvest','harvest','harvest','harvest','harvest','harvest','harvest','harvest','harvest','harvest'],
  'okra':        ['grow','harvest','harvest','harvest','off','plant','plant','harvest','harvest','harvest','harvest','off'],
};

// Months (0-indexed) where supply surge causes saturation
const Map<String, List<int>> kSaturationRiskMonths = {
  'ampalaya':    [10],         // Nov (9.00 MT peak)
  'stringBeans': [7,8,9,10],   // Aug–Nov (13.75 MT spike in Aug)
  'squash':      [7,8,9,10,11],// Aug–Dec — CRITICAL SATURATION WINDOW
  'eggplant':    [8,9,10],     // Sep–Nov (11.25 MT each month)
  'okra':        [9],          // Oct (6.25 MT peak)
};

const int kAdvisoryLeadDays = 45;

// ── Pre-computed PPI results (latest week, Dec 2025) ─────────────────────────

class CropPpiResult {
  final double baseline;
  final double worstPPI;
  final double latestPPI;
  final double latestPrice;
  final String alert;  // 'CAUTION' | 'STABLE' | 'SEVERE' | 'HIGH_DEMAND' | 'SATURATION'
  const CropPpiResult({
    required this.baseline,
    required this.worstPPI,
    required this.latestPPI,
    required this.latestPrice,
    required this.alert,
  });
}

const Map<String, CropPpiResult> kPpiResults = {
  'ampalaya':    CropPpiResult(baseline: 94,  worstPPI: -46.8, latestPPI:  6.4,  latestPrice: 100, alert: 'CAUTION'),
  'stringBeans': CropPpiResult(baseline: 102, worstPPI: -41.2, latestPPI:  7.8,  latestPrice: 110, alert: 'STABLE'),
  'squash':      CropPpiResult(baseline: 50,  worstPPI: -50.0, latestPPI: -34.0, latestPrice: 33,  alert: 'SEVERE'),
  'eggplant':    CropPpiResult(baseline: 86,  worstPPI: -30.2, latestPPI: 27.9,  latestPrice: 110, alert: 'HIGH_DEMAND'),
  'okra':        CropPpiResult(baseline: 113, worstPPI: -73.5, latestPPI: 28.3,  latestPrice: 145, alert: 'HIGH_DEMAND'),
};

// ── MAO advisory insights ────────────────────────────────────────────────────

class SystemInsight {
  final String crop;
  final String severity;  // 'CRITICAL' | 'WARNING' | 'OPPORTUNITY' | 'CAUTION'
  final String message;
  const SystemInsight({
    required this.crop,
    required this.severity,
    required this.message,
  });
}

const List<SystemInsight> kSystemInsights = [
  SystemInsight(crop: 'squash', severity: 'CRITICAL',
    message: 'Squash market saturation confirmed. Production 17.50 MT/month sustained Aug–Dec while prices dropped 64% (₱70→₱25/kg). Activate MAO intervention immediately.'),
  SystemInsight(crop: 'stringBeans', severity: 'WARNING',
    message: 'String Beans production spikes 11x in August (1.25→13.75 MT). Issue staggered harvest advisory in June before next cycle.'),
  SystemInsight(crop: 'eggplant', severity: 'OPPORTUNITY',
    message: 'Eggplant demand strong — prices rose ₱125–180/kg in Nov–Dec despite peak production. Recommend increased planting next cycle.'),
  SystemInsight(crop: 'okra', severity: 'OPPORTUNITY',
    message: 'Okra at ₱145/kg — 28% above baseline. Strong demand. Recommend cooperative bulk selling to institutional buyers now.'),
  SystemInsight(crop: 'ampalaya', severity: 'CAUTION',
    message: 'Ampalaya peaked at 9.00 MT in November. Monitor closely — single-week ₱50/kg dip (−46.8% PPI) shows vulnerability.'),
];

// ── Month name utilities ─────────────────────────────────────────────────────

const List<String> kMonthAbbreviations = [
  'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec',
];

const List<String> kMonthNames = [
  'January','February','March','April','May','June',
  'July','August','September','October','November','December',
];

// ─────────────────────────────────────────────────────────────────────────────
// Helper service — computations + lookups
// ─────────────────────────────────────────────────────────────────────────────

class AgriSatData {
  /// Compute Price Performance Index: ((current - baseline) / baseline) × 100
  static double computePPI(String cropKey, double currentPrice) {
    final base = kPriceBaselines[cropKey];
    if (base == null || base == 0) return 0;
    return ((currentPrice - base) / base) * 100;
  }

  /// Classify PPI into alert severity.
  /// Returns: 'SEVERE' | 'SATURATION' | 'CAUTION' | 'STABLE' | 'HIGH_DEMAND'
  static String getAlertLevel(double ppi) {
    if (ppi <= PpiThresholds.severeDrop) return 'SEVERE';
    if (ppi <= PpiThresholds.saturation) return 'SATURATION';
    if (ppi <= PpiThresholds.caution) return 'CAUTION';
    if (ppi >= PpiThresholds.highDemand) return 'HIGH_DEMAND';
    return 'STABLE';
  }

  static Color getAlertColor(String level) {
    switch (level) {
      case 'SEVERE':      return const Color(0xFFB91C1C);
      case 'SATURATION':  return const Color(0xFFDC2626);
      case 'CAUTION':     return const Color(0xFFF59E0B);
      case 'HIGH_DEMAND': return const Color(0xFF1B7737);
      default:            return const Color(0xFF64748B);
    }
  }

  static String getAlertEmoji(String level) {
    switch (level) {
      case 'SEVERE':      return '🚨';
      case 'SATURATION':  return '🔴';
      case 'CAUTION':     return '🟡';
      case 'HIGH_DEMAND': return '🟢';
      default:            return '⚪';
    }
  }

  static String getAlertLabel(String level) {
    switch (level) {
      case 'SEVERE':      return 'Severe Price Drop';
      case 'SATURATION':  return 'Market Saturated';
      case 'CAUTION':     return 'Price Watch';
      case 'HIGH_DEMAND': return 'High Demand';
      default:            return 'Stable Market';
    }
  }

  /// Is the given month (0-indexed) a saturation risk for the crop?
  static bool isSaturationRiskMonth(String cropKey, int monthIdx) {
    return kSaturationRiskMonths[cropKey]?.contains(monthIdx) ?? false;
  }

  /// Get crop stage for the month: 'plant' | 'grow' | 'harvest' | 'off'
  static String getCurrentStage(String cropKey, int monthIdx) {
    final calendar = kCropCalendar[cropKey];
    if (calendar == null || monthIdx < 0 || monthIdx >= calendar.length) return 'off';
    return calendar[monthIdx];
  }

  static double getLatestPrice(String cropKey) {
    final prices = kWeeklyPrices[cropKey];
    if (prices == null || prices.isEmpty) return 0;
    return prices.last;
  }

  static double getPreviousWeekPrice(String cropKey) {
    final prices = kWeeklyPrices[cropKey];
    if (prices == null || prices.length < 2) return 0;
    return prices[prices.length - 2];
  }

  /// 'up' | 'down' | 'stable' (week-over-week)
  static String getPriceDirection(String cropKey) {
    final latest = getLatestPrice(cropKey);
    final prev = getPreviousWeekPrice(cropKey);
    if (prev == 0) return 'stable';
    final change = ((latest - prev) / prev) * 100;
    if (change > 2) return 'up';
    if (change < -2) return 'down';
    return 'stable';
  }

  /// Week-over-week change percentage (negative = price dropped)
  static double getWeekOverWeekChange(String cropKey) {
    final latest = getLatestPrice(cropKey);
    final prev = getPreviousWeekPrice(cropKey);
    if (prev == 0) return 0;
    return ((latest - prev) / prev) * 100;
  }

  /// Find cropKey from a display name (English or local). Falls back to partial match.
  static String? cropKeyFromName(String name) {
    final lower = name.toLowerCase().trim();
    for (final e in kCropDisplayNames.entries) {
      if (e.value.toLowerCase() == lower) return e.key;
    }
    for (final e in kCropLocalNames.entries) {
      if (e.value.toLowerCase() == lower) return e.key;
    }
    if (lower.contains('ampalaya') || lower.contains('bitter')) return 'ampalaya';
    if (lower.contains('string') || lower.contains('sitaw') || lower.contains('bean')) return 'stringBeans';
    if (lower.contains('squash') || lower.contains('kalabasa') || lower.contains('pumpkin')) return 'squash';
    if (lower.contains('eggplant') || lower.contains('talong')) return 'eggplant';
    if (lower.contains('okra')) return 'okra';
    return null;
  }

  /// Annual production in kg (MT × 1000)
  static double getAnnualProductionKg(String cropKey) {
    final t = kAnnualTotals[cropKey];
    return (t?.productionMT ?? 0) * 1000;
  }

  /// Get latest reported farmer count for a crop (most recent non-zero)
  static int getLatestFarmerCount(String cropKey) {
    final data = kHarvestData[cropKey];
    if (data == null) return 0;
    for (int i = data.farmersTotal.length - 1; i >= 0; i--) {
      if (data.farmersTotal[i] > 0) return data.farmersTotal[i];
    }
    return 0;
  }

  /// Get advisory message for a specific crop
  static SystemInsight? getInsightForCrop(String cropKey) {
    for (final i in kSystemInsights) {
      if (i.crop == cropKey) return i;
    }
    return null;
  }

  /// All insights with CRITICAL or WARNING severity (for MAO alert panels)
  static List<SystemInsight> getCriticalInsights() {
    return kSystemInsights
        .where((i) => i.severity == 'CRITICAL' || i.severity == 'WARNING')
        .toList();
  }

  /// Saturation risk for current calendar month
  static List<String> getCropsAtRiskThisMonth(int monthIdx) {
    final atRisk = <String>[];
    kSaturationRiskMonths.forEach((crop, months) {
      if (months.contains(monthIdx)) atRisk.add(crop);
    });
    return atRisk;
  }
}

// ── Canonical crop name lists — use these everywhere instead of hardcoded arrays ──

/// Official AgriSat crop list — use this everywhere instead of hardcoded arrays.
const List<String> kOfficialCropNames = [
  'Ampalaya', 'String Beans', 'Eggplant', 'Okra', 'Squash',
];

/// Maps display name → crop key for reverse lookup
const Map<String, String> kCropNameToKey = {
  'Ampalaya':     'ampalaya',
  'String Beans': 'stringBeans',
  'Eggplant':     'eggplant',
  'Okra':         'okra',
  'Squash':       'squash',
};
