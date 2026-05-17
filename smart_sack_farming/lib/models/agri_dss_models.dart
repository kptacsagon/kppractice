import 'package:flutter/material.dart';

// ─── Perishability Tier ───────────────────────────────────────────────────────
enum PerishabilityTier { highlyPerishable, moderatelyPerishable, storable }

PerishabilityTier perishabilityOf(String commodity) {
  const highly = ['Pechay', 'Kangkong', 'Lettuce', 'Spinach', 'Milk', 'Tomato'];
  const moderate = ['Eggplant', 'Ampalaya (Bitter Gourd)', 'Okra',
    'Sitaw (String Beans)', 'Squash', 'Upo', 'Patola',
    'Banana', 'Mango', 'Sweet Potato (Kamote)', 'Cassava'];
  if (highly.any((c) => commodity.toLowerCase().contains(c.toLowerCase()))) {
    return PerishabilityTier.highlyPerishable;
  }
  if (moderate.any((c) => commodity.toLowerCase().contains(c.toLowerCase()))) {
    return PerishabilityTier.moderatelyPerishable;
  }
  return PerishabilityTier.storable;
}

// ─── Cropping Cycle ───────────────────────────────────────────────────────────
class CroppingCycle {
  final String id;
  final String farmerId;
  final String commodity;
  final String barangay;
  final String municipality;
  final String seasonName;
  final DateTime? plantingDate;
  final DateTime? harvestDate;

  final double totalProductionKg;
  final double quantitySoldKg;
  final double unsoldInventoryKg;

  final double marketPricePhp;
  final double baselinePricePhp;

  final double inputCostPhp;
  final double laborCostPhp;
  final double landCostPhp;
  final double transportCostPhp;

  final String? dataSource;
  final String confidenceLevel; // High / Medium / Low
  final DateTime recordedAt;

  const CroppingCycle({
    required this.id,
    required this.farmerId,
    required this.commodity,
    required this.barangay,
    required this.municipality,
    required this.seasonName,
    this.plantingDate,
    this.harvestDate,
    required this.totalProductionKg,
    required this.quantitySoldKg,
    required this.unsoldInventoryKg,
    required this.marketPricePhp,
    required this.baselinePricePhp,
    this.inputCostPhp = 0,
    this.laborCostPhp = 0,
    this.landCostPhp = 0,
    this.transportCostPhp = 0,
    this.dataSource,
    this.confidenceLevel = 'Medium',
    required this.recordedAt,
  });

  // ── Three proxy metrics ──────────────────────────────────────────────────
  double get mar => totalProductionKg > 0 ? quantitySoldKg / totalProductionKg : 0;
  double get ppi => baselinePricePhp > 0
      ? ((marketPricePhp - baselinePricePhp) / baselinePricePhp) * 100
      : 0;
  double get iur => totalProductionKg > 0 ? unsoldInventoryKg / totalProductionKg : 0;

  // ── Revenue & Margin ─────────────────────────────────────────────────────
  double get grossRevenue => quantitySoldKg * marketPricePhp;
  double get grossMargin  => grossRevenue - inputCostPhp - laborCostPhp;
  double get netMargin    => grossMargin - landCostPhp - transportCostPhp;
  double get marginRate   => grossRevenue > 0 ? (netMargin / grossRevenue) * 100 : 0;
  double get totalCost    => inputCostPhp + laborCostPhp + landCostPhp + transportCostPhp;

  PerishabilityTier get perishability => perishabilityOf(commodity);

  factory CroppingCycle.fromJson(Map<String, dynamic> j) => CroppingCycle(
    id: j['id'] as String,
    farmerId: j['farmer_id'] as String,
    commodity: j['commodity'] as String,
    barangay: j['barangay'] as String,
    municipality: (j['municipality'] as String?) ?? 'Tubungan',
    seasonName: j['season_name'] as String,
    plantingDate: j['planting_date'] != null ? DateTime.tryParse(j['planting_date']) : null,
    harvestDate: j['harvest_date'] != null ? DateTime.tryParse(j['harvest_date']) : null,
    totalProductionKg: _d(j['total_production_kg']),
    quantitySoldKg: _d(j['quantity_sold_kg']),
    unsoldInventoryKg: _d(j['unsold_inventory_kg']),
    marketPricePhp: _d(j['market_price_php']),
    baselinePricePhp: _d(j['baseline_price_php']),
    inputCostPhp: _d(j['input_cost_php']),
    laborCostPhp: _d(j['labor_cost_php']),
    landCostPhp: _d(j['land_cost_php']),
    transportCostPhp: _d(j['transport_cost_php']),
    dataSource: j['data_source'] as String?,
    confidenceLevel: (j['confidence_level'] as String?) ?? 'Medium',
    recordedAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'farmer_id': farmerId,
    'commodity': commodity,
    'barangay': barangay,
    'municipality': municipality,
    'season_name': seasonName,
    if (plantingDate != null) 'planting_date': plantingDate!.toIso8601String().split('T').first,
    if (harvestDate != null) 'harvest_date': harvestDate!.toIso8601String().split('T').first,
    'total_production_kg': totalProductionKg,
    'quantity_sold_kg': quantitySoldKg,
    'unsold_inventory_kg': unsoldInventoryKg,
    'market_price_php': marketPricePhp,
    'baseline_price_php': baselinePricePhp,
    'input_cost_php': inputCostPhp,
    'labor_cost_php': laborCostPhp,
    'land_cost_php': landCostPhp,
    'transport_cost_php': transportCostPhp,
    if (dataSource != null) 'data_source': dataSource,
    'confidence_level': confidenceLevel,
  };

  static double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
}

// ─── Market Destination ───────────────────────────────────────────────────────
class MarketDestination {
  final String name;
  final String type; // local_lgu / regional_hub / provincial_market
  final double pricePerKg;
  final double transportCostPerKg;
  final double ppi;

  const MarketDestination({
    required this.name,
    required this.type,
    required this.pricePerKg,
    required this.transportCostPerKg,
    required this.ppi,
  });

  double get effectiveNetPrice => pricePerKg * (1 + ppi / 100) - transportCostPerKg;
}

// ─── Alert Severity ───────────────────────────────────────────────────────────
enum AlertSeverity { opportunity, info, warning, critical }

extension AlertSeverityX on AlertSeverity {
  Color get color {
    switch (this) {
      case AlertSeverity.opportunity: return const Color(0xFF16A34A);
      case AlertSeverity.info:        return const Color(0xFF2563EB);
      case AlertSeverity.warning:     return const Color(0xFFF59E0B);
      case AlertSeverity.critical:    return const Color(0xFFDC2626);
    }
  }
  IconData get icon {
    switch (this) {
      case AlertSeverity.opportunity: return Icons.trending_up_rounded;
      case AlertSeverity.info:        return Icons.info_rounded;
      case AlertSeverity.warning:     return Icons.warning_amber_rounded;
      case AlertSeverity.critical:    return Icons.dangerous_rounded;
    }
  }
  String get label {
    switch (this) {
      case AlertSeverity.opportunity: return 'Opportunity';
      case AlertSeverity.info:        return 'Info';
      case AlertSeverity.warning:     return 'Warning';
      case AlertSeverity.critical:    return 'Critical';
    }
  }
}

// ─── Financial Alert ──────────────────────────────────────────────────────────
class FinancialAlert {
  final String type;
  final String title;
  final String description;
  final String recommendation;
  final String commodity;
  final AlertSeverity severity;
  final DateTime triggeredAt;

  const FinancialAlert({
    required this.type,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.commodity,
    required this.severity,
    required this.triggeredAt,
  });
}

// ─── MAO Aggregation Row ──────────────────────────────────────────────────────
class MaoAggregationRow {
  final String barangay;
  final int farmerCount;
  final double avgMar;
  final double avgPpi;
  final double avgIur;
  final double totalNetMarginPhp;
  final int alertCount;
  final String dominantCommodity;

  const MaoAggregationRow({
    required this.barangay,
    required this.farmerCount,
    required this.avgMar,
    required this.avgPpi,
    required this.avgIur,
    required this.totalNetMarginPhp,
    required this.alertCount,
    required this.dominantCommodity,
  });
}
