import '../models/agrisense_dss_model.dart';

class AgriSenseDssService {
  static const List<String> supportedRegions = <String>[
    'Region VII (Central Visayas)',
    'Region VI (Western Visayas)',
    'Region X (Northern Mindanao)',
  ];

  static const List<String> supportedSeasons = <String>['Dry', 'Wet'];

  static final Map<String, _CropMarketProfile> _profiles =
      <String, _CropMarketProfile>{
        'Tomato': const _CropMarketProfile(
          baselineDemandMt: 980,
          baselineSupplyMt: 1040,
          baselinePricePerKg: 50,
          yieldMtPerHa: 26,
          demandGrowthRate: 0.02,
          priceMomentum: -0.03,
          demandStability: 0.61,
          seasonSuitability: <String, double>{'Dry': 1.06, 'Wet': 0.95},
        ),
        'Onion': const _CropMarketProfile(
          baselineDemandMt: 720,
          baselineSupplyMt: 650,
          baselinePricePerKg: 84,
          yieldMtPerHa: 14,
          demandGrowthRate: 0.03,
          priceMomentum: 0.02,
          demandStability: 0.79,
          seasonSuitability: <String, double>{'Dry': 1.08, 'Wet': 0.92},
        ),
        'Eggplant': const _CropMarketProfile(
          baselineDemandMt: 810,
          baselineSupplyMt: 780,
          baselinePricePerKg: 43,
          yieldMtPerHa: 19,
          demandGrowthRate: 0.01,
          priceMomentum: 0.01,
          demandStability: 0.74,
          seasonSuitability: <String, double>{'Dry': 1.02, 'Wet': 1.01},
        ),
        'Cabbage': const _CropMarketProfile(
          baselineDemandMt: 540,
          baselineSupplyMt: 600,
          baselinePricePerKg: 37,
          yieldMtPerHa: 23,
          demandGrowthRate: 0.01,
          priceMomentum: -0.01,
          demandStability: 0.65,
          seasonSuitability: <String, double>{'Dry': 0.93, 'Wet': 1.06},
        ),
        'Chili': const _CropMarketProfile(
          baselineDemandMt: 490,
          baselineSupplyMt: 430,
          baselinePricePerKg: 126,
          yieldMtPerHa: 8,
          demandGrowthRate: 0.03,
          priceMomentum: 0.03,
          demandStability: 0.82,
          seasonSuitability: <String, double>{'Dry': 1.04, 'Wet': 0.98},
        ),
        'Okra': const _CropMarketProfile(
          baselineDemandMt: 410,
          baselineSupplyMt: 390,
          baselinePricePerKg: 48,
          yieldMtPerHa: 11,
          demandGrowthRate: 0.02,
          priceMomentum: 0.01,
          demandStability: 0.76,
          seasonSuitability: <String, double>{'Dry': 0.98, 'Wet': 1.04},
        ),
      };

  static const Map<String, double> _regionDemandFactors = <String, double>{
    'Region VII (Central Visayas)': 1.00,
    'Region VI (Western Visayas)': 0.98,
    'Region X (Northern Mindanao)': 1.04,
  };

  static const Map<String, double> _regionSupplyFactors = <String, double>{
    'Region VII (Central Visayas)': 1.00,
    'Region VI (Western Visayas)': 1.03,
    'Region X (Northern Mindanao)': 0.96,
  };

  List<String> get supportedCrops => _profiles.keys.toList()..sort();

  AgriSenseResult evaluate(AgriSenseInput input) {
    final profile = _profiles[input.cropType];
    if (profile == null) {
      throw Exception('Unsupported crop type: ${input.cropType}');
    }

    final seasonKey = input.season.trim();
    final seasonFactor = profile.seasonSuitability[seasonKey] ?? 1.0;
    final regionDemandFactor = _regionDemandFactors[input.region] ?? 1.0;
    final regionSupplyFactor = _regionSupplyFactors[input.region] ?? 1.0;

    final projectedDemand =
        profile.baselineDemandMt *
        seasonFactor *
        regionDemandFactor *
        (1 + profile.demandGrowthRate);

    final projectedSupply =
        (profile.baselineSupplyMt +
            (input.plannedAreaHa * profile.yieldMtPerHa)) *
        regionSupplyFactor;

    final safeDemand = projectedDemand <= 0 ? 1.0 : projectedDemand;
    final osi = projectedSupply / safeDemand;
    final srsScore = osi * 100;

    final pressureEffect = (osi - 1.0) * 0.18;
    final projectedPrice =
        (profile.baselinePricePerKg *
                (1 + profile.priceMomentum - pressureEffect))
            .clamp(5, 10000)
            .toDouble();

    final trend = _priceTrend(
      baselinePrice: profile.baselinePricePerKg,
      projectedPrice: projectedPrice,
    );

    final riskTier = _riskTier(srsScore);
    final rules = <String>[];

    String summary;
    String primaryAction;

    if (srsScore > 100) {
      rules.add('Rule Set 1: Oversupply Condition');
      summary =
          'High oversupply risk detected for ${input.cropType} in ${input.region}.';
      primaryAction =
          'Reduce planned volume and switch part of area to alternatives.';
    } else if (trend == 'decreasing' && srsScore >= 81) {
      rules.add('Rule Set 2: Price Decline Condition');
      summary =
          'Moderate oversupply pressure with weakening price trend for ${input.cropType}.';
      primaryAction = 'Plant conservatively and avoid full-area expansion.';
    } else if (srsScore < 60 && trend != 'decreasing') {
      rules.add('Rule Set 3: Safe Condition');
      summary =
          '${input.cropType} is currently within safer supply-demand bounds.';
      primaryAction =
          'Proceed with planting plan and monitor weekly price updates.';
    } else {
      summary = 'Mixed market signals detected; keep planning flexible.';
      primaryAction = 'Maintain a balanced area split across two crops.';
    }

    final confidence = _confidenceLabel(input: input);
    final priceBand = _priceBand(confidence: confidence);

    final alternatives = _buildAlternatives(
      inputCrop: input.cropType,
      season: seasonKey,
      region: input.region,
    );

    return AgriSenseResult(
      input: input,
      forecast: AgriSenseForecast(
        srsScore: srsScore,
        projectedDemandMt: projectedDemand,
        projectedSupplyMt: projectedSupply,
        projectedPricePerKg: projectedPrice,
        priceForecastMin: projectedPrice * (1 - priceBand),
        priceForecastMax: projectedPrice * (1 + priceBand),
        priceTrend: trend,
        confidence: confidence,
      ),
      recommendation: AgriSenseRecommendation(
        osi: osi,
        riskTier: riskTier,
        summary: summary,
        primaryAction: primaryAction,
        triggeredRules: rules,
        alternatives: alternatives,
      ),
    );
  }

  List<AgriSenseAlternative> _buildAlternatives({
    required String inputCrop,
    required String season,
    required String region,
  }) {
    final regionDemandFactor = _regionDemandFactors[region] ?? 1.0;
    final regionSupplyFactor = _regionSupplyFactors[region] ?? 1.0;

    final ranked =
        _profiles.entries.where((entry) => entry.key != inputCrop).map((entry) {
          final crop = entry.key;
          final profile = entry.value;
          final seasonScore = profile.seasonSuitability[season] ?? 1.0;
          final demand =
              profile.baselineDemandMt *
              seasonScore *
              regionDemandFactor *
              (1 + profile.demandGrowthRate);
          final supply = profile.baselineSupplyMt * regionSupplyFactor;
          final osi = supply / (demand <= 0 ? 1.0 : demand);
          final score =
              (profile.demandStability * 0.45) +
              (seasonScore.clamp(0, 1.2) * 0.25) +
              ((1.2 - osi.clamp(0, 1.4)) * 0.20) +
              ((profile.priceMomentum + 0.1).clamp(0, 0.2) * 0.10);
          final trend = profile.priceMomentum >= 0.015
              ? 'increasing'
              : profile.priceMomentum <= -0.015
              ? 'decreasing'
              : 'stable';

          return _AlternativeScore(
            crop: crop,
            score: score,
            seasonScore: seasonScore,
            demandStability: profile.demandStability,
            trend: trend,
          );
        }).toList()..sort((a, b) => b.score.compareTo(a.score));

    return ranked.take(3).map((candidate) {
      return AgriSenseAlternative(
        cropType: candidate.crop,
        demandStability: candidate.demandStability,
        priceTrend: candidate.trend,
        seasonalSuitability: candidate.seasonScore,
        reason:
            '${candidate.crop} has better demand stability and seasonal fit for $season season.',
      );
    }).toList();
  }

  String _priceTrend({
    required double baselinePrice,
    required double projectedPrice,
  }) {
    final ratio = projectedPrice / (baselinePrice <= 0 ? 1.0 : baselinePrice);
    if (ratio >= 1.05) return 'increasing';
    if (ratio <= 0.95) return 'decreasing';
    return 'stable';
  }

  String _riskTier(double srsScore) {
    if (srsScore > 100) return 'dark_red';
    if (srsScore >= 81) return 'red';
    if (srsScore >= 61) return 'amber';
    return 'green';
  }

  double _priceBand({required String confidence}) {
    switch (confidence) {
      case 'high':
        return 0.08;
      case 'medium':
        return 0.12;
      default:
        return 0.18;
    }
  }

  String _confidenceLabel({required AgriSenseInput input}) {
    if (input.cropType.isNotEmpty &&
        input.region.isNotEmpty &&
        input.season.isNotEmpty &&
        input.plannedAreaHa > 0) {
      return 'high';
    }
    if (input.cropType.isNotEmpty && input.region.isNotEmpty) {
      return 'medium';
    }
    return 'low';
  }
}

class _CropMarketProfile {
  final double baselineDemandMt;
  final double baselineSupplyMt;
  final double baselinePricePerKg;
  final double yieldMtPerHa;
  final double demandGrowthRate;
  final double priceMomentum;
  final double demandStability;
  final Map<String, double> seasonSuitability;

  const _CropMarketProfile({
    required this.baselineDemandMt,
    required this.baselineSupplyMt,
    required this.baselinePricePerKg,
    required this.yieldMtPerHa,
    required this.demandGrowthRate,
    required this.priceMomentum,
    required this.demandStability,
    required this.seasonSuitability,
  });
}

class _AlternativeScore {
  final String crop;
  final double score;
  final double seasonScore;
  final double demandStability;
  final String trend;

  const _AlternativeScore({
    required this.crop,
    required this.score,
    required this.seasonScore,
    required this.demandStability,
    required this.trend,
  });
}
