class AgriSenseInput {
  final String cropType;
  final String region;
  final double plannedAreaHa;
  final String season;

  const AgriSenseInput({
    required this.cropType,
    required this.region,
    required this.plannedAreaHa,
    required this.season,
  });
}

class AgriSenseForecast {
  final double srsScore;
  final double projectedDemandMt;
  final double projectedSupplyMt;
  final double projectedPricePerKg;
  final double priceForecastMin;
  final double priceForecastMax;
  final String priceTrend;
  final String confidence;

  const AgriSenseForecast({
    required this.srsScore,
    required this.projectedDemandMt,
    required this.projectedSupplyMt,
    required this.projectedPricePerKg,
    required this.priceForecastMin,
    required this.priceForecastMax,
    required this.priceTrend,
    required this.confidence,
  });
}

class AgriSenseAlternative {
  final String cropType;
  final double demandStability;
  final String priceTrend;
  final double seasonalSuitability;
  final String reason;

  const AgriSenseAlternative({
    required this.cropType,
    required this.demandStability,
    required this.priceTrend,
    required this.seasonalSuitability,
    required this.reason,
  });
}

class AgriSenseRecommendation {
  final double osi;
  final String riskTier;
  final String summary;
  final String primaryAction;
  final List<String> triggeredRules;
  final List<AgriSenseAlternative> alternatives;

  const AgriSenseRecommendation({
    required this.osi,
    required this.riskTier,
    required this.summary,
    required this.primaryAction,
    required this.triggeredRules,
    required this.alternatives,
  });
}

class AgriSenseResult {
  final AgriSenseInput input;
  final AgriSenseForecast forecast;
  final AgriSenseRecommendation recommendation;

  const AgriSenseResult({
    required this.input,
    required this.forecast,
    required this.recommendation,
  });
}
