/// Farmer's planting intention for next season
/// Used to predict market saturation BEFORE planting

class PlantingIntention {
  final String id;
  final String farmerId;
  final String cropId;
  final String cropName;
  final String barangay;
  
  /// How much farmer plans to plant (kg or quantity)
  final double plannedQuantityKg;
  
  /// Land area (hectares) for this crop
  final double landAreaHa;
  
  /// Expected yield per hectare (based on farm history)
  final double expectedYieldPerHaKg;
  
  /// Season/month they plan to plant
  final String plantingSeason;
  
  /// Timestamp when intention was recorded
  final DateTime recordedAt;
  
  /// Status: planning, confirmed, harvesting
  final String status;

  PlantingIntention({
    required this.id,
    required this.farmerId,
    required this.cropId,
    required this.cropName,
    required this.barangay,
    required this.plannedQuantityKg,
    required this.landAreaHa,
    required this.expectedYieldPerHaKg,
    required this.plantingSeason,
    required this.recordedAt,
    this.status = 'planning',
  });

  /// Expected total harvest if everything goes well
  double get expectedHarvestKg => landAreaHa * expectedYieldPerHaKg;

  factory PlantingIntention.fromJson(Map<String, dynamic> json) => PlantingIntention(
    id: json['id'] ?? '',
    farmerId: json['farmer_id'] ?? '',
    cropId: json['crop_id'] ?? '',
    cropName: json['crop_name'] ?? '',
    barangay: json['barangay'] ?? '',
    plannedQuantityKg: (json['planned_quantity_kg'] as num?)?.toDouble() ?? 0,
    landAreaHa: (json['land_area_ha'] as num?)?.toDouble() ?? 0,
    expectedYieldPerHaKg: (json['expected_yield_per_ha_kg'] as num?)?.toDouble() ?? 0,
    plantingSeason: json['planting_season'] ?? '',
    recordedAt: DateTime.parse(json['recorded_at'] as String? ?? DateTime.now().toIso8601String()),
    status: json['status'] ?? 'planning',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmer_id': farmerId,
    'crop_id': cropId,
    'crop_name': cropName,
    'barangay': barangay,
    'planned_quantity_kg': plannedQuantityKg,
    'land_area_ha': landAreaHa,
    'expected_yield_per_ha_kg': expectedYieldPerHaKg,
    'planting_season': plantingSeason,
    'recorded_at': recordedAt.toIso8601String(),
    'status': status,
  };
}

/// Market saturation prediction based on planting intentions
class SaturationPrediction {
  final String cropName;
  final String season;
  final String barangay;
  
  /// Number of farmers planning to plant this crop
  final int totalFarmersPlanting;
  
  /// Total quantity all farmers plan to plant (kg)
  final double totalPlannedQuantityKg;
  
  /// Estimated total harvest (kg)
  final double estimatedTotalHarvestKg;
  
  /// Estimated market demand (kg) - based on market data
  final double estimatedMarketDemandKg;
  
  /// Supply-to-demand ratio
  /// >1.0 = oversupply, <1.0 = undersupply
  final double supplyDemandRatio;
  
  /// Predicted price impact (%)
  /// Negative = price will drop, Positive = price will rise
  final double predictedPriceImpactPercent;
  
  /// Saturation level: safe, caution, danger
  final String saturationLevel;
  
  /// Price forecast (₱/kg)
  final double forecastedPricePerKg;
  
  /// Profit impact (₱) if all farmers plant this crop
  final double profitImpactPerFarmer;
  
  /// Recommendation
  final String recommendation;

  SaturationPrediction({
    required this.cropName,
    required this.season,
    required this.barangay,
    required this.totalFarmersPlanting,
    required this.totalPlannedQuantityKg,
    required this.estimatedTotalHarvestKg,
    required this.estimatedMarketDemandKg,
    required this.supplyDemandRatio,
    required this.predictedPriceImpactPercent,
    required this.saturationLevel,
    required this.forecastedPricePerKg,
    required this.profitImpactPerFarmer,
    required this.recommendation,
  });

  factory SaturationPrediction.fromJson(Map<String, dynamic> json) => SaturationPrediction(
    cropName: json['crop_name'] ?? '',
    season: json['season'] ?? '',
    barangay: json['barangay'] ?? '',
    totalFarmersPlanting: (json['total_farmers_planting'] as num?)?.toInt() ?? 0,
    totalPlannedQuantityKg: (json['total_planned_quantity_kg'] as num?)?.toDouble() ?? 0,
    estimatedTotalHarvestKg: (json['estimated_total_harvest_kg'] as num?)?.toDouble() ?? 0,
    estimatedMarketDemandKg: (json['estimated_market_demand_kg'] as num?)?.toDouble() ?? 0,
    supplyDemandRatio: (json['supply_demand_ratio'] as num?)?.toDouble() ?? 0,
    predictedPriceImpactPercent: (json['predicted_price_impact_percent'] as num?)?.toDouble() ?? 0,
    saturationLevel: json['saturation_level'] ?? 'unknown',
    forecastedPricePerKg: (json['forecasted_price_per_kg'] as num?)?.toDouble() ?? 0,
    profitImpactPerFarmer: (json['profit_impact_per_farmer'] as num?)?.toDouble() ?? 0,
    recommendation: json['recommendation'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'crop_name': cropName,
    'season': season,
    'barangay': barangay,
    'total_farmers_planting': totalFarmersPlanting,
    'total_planned_quantity_kg': totalPlannedQuantityKg,
    'estimated_total_harvest_kg': estimatedTotalHarvestKg,
    'estimated_market_demand_kg': estimatedMarketDemandKg,
    'supply_demand_ratio': supplyDemandRatio,
    'predicted_price_impact_percent': predictedPriceImpactPercent,
    'saturation_level': saturationLevel,
    'forecasted_price_per_kg': forecastedPricePerKg,
    'profit_impact_per_farmer': profitImpactPerFarmer,
    'recommendation': recommendation,
  };
}
