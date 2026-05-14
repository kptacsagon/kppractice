class AgrisenseSaturationScore {
  final String? id;
  final String municipality;
  final String cropType;
  final String seasonName;
  final double srsScore;
  final double projectedSupplyMt;
  final double projectedDemandMt;
  final double? priceForecastMin;
  final double? priceForecastMax;
  final DateTime lastUpdated;

  AgrisenseSaturationScore({
    this.id,
    required this.municipality,
    required this.cropType,
    required this.seasonName,
    required this.srsScore,
    required this.projectedSupplyMt,
    required this.projectedDemandMt,
    this.priceForecastMin,
    this.priceForecastMax,
    required this.lastUpdated,
  });

  factory AgrisenseSaturationScore.fromJson(Map<String, dynamic> json) {
    return AgrisenseSaturationScore(
      id: json['id'],
      municipality: json['municipality'],
      cropType: json['crop_type'],
      seasonName: json['season_name'],
      srsScore: (json['srs_score'] as num).toDouble(),
      projectedSupplyMt: (json['projected_supply_mt'] as num).toDouble(),
      projectedDemandMt: (json['projected_demand_mt'] as num).toDouble(),
      priceForecastMin: json['price_forecast_min'] == null
          ? null
          : (json['price_forecast_min'] as num).toDouble(),
      priceForecastMax: json['price_forecast_max'] == null
          ? null
          : (json['price_forecast_max'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'municipality': municipality,
      'crop_type': cropType,
      'season_name': seasonName,
      'srs_score': srsScore,
      'projected_supply_mt': projectedSupplyMt,
      'projected_demand_mt': projectedDemandMt,
      'price_forecast_min': priceForecastMin,
      'price_forecast_max': priceForecastMax,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
