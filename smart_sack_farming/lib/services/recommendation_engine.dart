import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crop_data.dart';
import '../models/market_price_model.dart';
import '../models/recommendation_model.dart';

/// Multi-Dimensional Crop Recommendation & Predictive Risk Engine.
///
/// ## Crop Score Model (5 weighted factors)
/// ```
/// Score = P×0.35 + C×0.20 + M×0.20 + S×0.15 + D×0.10
/// ```
/// - **P** Profit Score: `crop_profit / max_profit` (normalized 0–1)
/// - **C** Climate Score: 1.0 (peak) / 0.6 (adjacent) / 0.3 (off-season)
/// - **M** Market Risk Score: `1 − (regional_saturation / 100)`
/// - **S** Soil Score: `1 − (|actual − optimal| / 100)`
/// - **D** Diversification Score: 0.8–1.0 (intercrop) / 0.5 (single)
///
/// ## Predictive Risk Model (4 weighted factors)
/// ```
/// Risk = W×0.30 + MR×0.30 + CS×0.20 + F×0.20
/// ```
/// - **W** Weather Risk: seasonal rainfall adequacy
/// - **MR** Market Risk: harvest overlap / oversupply probability
/// - **CS** Crop Sensitivity: agronomic vulnerability coefficients
/// - **F** Financial Risk: cost-to-budget ratio exposure
class RecommendationEngine {
  final SupabaseClient _client;

  RecommendationEngine({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ================================================================
  // COST ESTIMATES PER HECTARE (₱)
  // ================================================================
  static const Map<String, double> _costPerHectare = {
    'Rice': 45000,
    'Corn': 30000,
    'Tomato': 60000,
    'Lettuce': 50000,
    'Eggplant': 55000,
    'Sweet Potato': 35000,
    'Carrot': 45000,
    'Cabbage': 40000,
    'Watermelon': 50000,
    'Basil': 30000,
    'Pepper': 52000,
    'Spinach': 35000,
    'Wheat': 28000,
    'Maize': 25000,
    'Cotton': 40000,
    'Sugarcane': 55000,
    'Pulses': 22000,
  };

  // Average yield per hectare (kg)
  static const Map<String, double> _avgYieldPerHa = {
    'Rice': 4500,
    'Corn': 6000,
    'Tomato': 25000,
    'Lettuce': 20000,
    'Eggplant': 30000,
    'Sweet Potato': 15000,
    'Carrot': 20000,
    'Cabbage': 35000,
    'Watermelon': 30000,
    'Basil': 5000,
    'Pepper': 15000,
    'Spinach': 12000,
    'Wheat': 3500,
    'Maize': 5500,
    'Cotton': 2000,
    'Sugarcane': 70000,
    'Pulses': 1200,
  };

  // ================================================================
  // MAIN ENTRY POINT
  // ================================================================

  /// Generate recommendations using the multi-dimensional scoring model
  /// and predictive risk model for a farmer.
  Future<List<CropRecommendation>> generateRecommendations({
    required String farmerId,
    required double fieldAreaHa,
    DateTime? plantingDate,
    double? budgetLimit,
  }) async {
    final now = plantingDate ?? DateTime.now();
    final month = now.month;
    final season = SeasonHelper.getSeasonFromMonth(month);
    final seasonName = SeasonHelper.getSeasonName(season);
    final waterAvailability = _estimateWaterAvailability(month);

    // Fetch market data
    final marketPrices = await _fetchMarketPrices();
    final regionalData = await _fetchRegionalSaturation();

    // ── Phase 1: Compute raw financials for all crops ──
    // (needed to normalize profit scores across the set)
    final profitMap = <String, double>{};
    for (final crop in CropData.allCrops) {
      final cost = (_costPerHectare[crop.name] ?? 40000) * fieldAreaHa;
      final yieldKg = (_avgYieldPerHa[crop.name] ?? 5000) * fieldAreaHa;
      final price = marketPrices[crop.name];
      final pricePerKg = price?.pricePerKg ?? 30.0;
      final harvestDays = _parseGrowthDays(crop.growthDuration);
      final projectedPrice = price?.projectPrice(harvestDays) ?? pricePerKg;
      profitMap[crop.name] = yieldKg * projectedPrice - cost;
    }
    final maxProfit = profitMap.values.reduce(max);

    // Effective budget for financial risk (default = 2× average cost)
    final effectiveBudget = budgetLimit ??
        (_costPerHectare.values.reduce((a, b) => a + b) /
                _costPerHectare.length *
                fieldAreaHa *
                2.0);

    // ── Phase 2: Score every crop ──
    final recommendations = <CropRecommendation>[];

    for (final crop in CropData.allCrops) {
      final cropRegionalPct = regionalData[crop.name] ?? 0.0;
      final satLevel = crop.analyzeSaturation(waterAvailability);
      final price = marketPrices[crop.name];

      // ─── Multi-Dimensional Crop Score Model ────────────────
      final profitScore = _calcProfitScore(
          profitMap[crop.name] ?? 0, maxProfit);
      final climateScore = _calcClimateScore(crop, month);
      final marketRiskScore = _calcMarketRiskScore(cropRegionalPct);
      final soilScore = _calcSoilScore(crop, waterAvailability);
      const diversificationScore = 0.5; // single crop baseline

      final suitabilityScore = _compositeScore(
        profitScore: profitScore,
        climateScore: climateScore,
        marketRiskScore: marketRiskScore,
        soilScore: soilScore,
        diversificationScore: diversificationScore,
      );

      // ─── Predictive Risk Model ─────────────────────────────
      final weatherRisk = _calcWeatherRisk(month, crop);
      final mktRisk = _calcMarketRisk(cropRegionalPct, price);
      final cropSens = _calcCropSensitivity(crop, month, waterAvailability);
      final estCost = (_costPerHectare[crop.name] ?? 40000) * fieldAreaHa;
      final finRisk = _calcFinancialRisk(estCost, effectiveBudget);

      final totalRisk = _compositeRisk(
        weatherRisk: weatherRisk,
        marketRisk: mktRisk,
        cropSensitivity: cropSens,
        financialRisk: finRisk,
      );
      final riskLevel = _riskLabel(totalRisk);

      // ─── Financial projections ─────────────────────────────
      final estimatedYield =
          (_avgYieldPerHa[crop.name] ?? 5000) * fieldAreaHa;
      final pricePerKg = price?.pricePerKg ?? 30.0;
      final harvestDays = _parseGrowthDays(crop.growthDuration);
      final projectedPrice = price?.projectPrice(harvestDays) ?? pricePerKg;
      final estimatedRevenue = estimatedYield * projectedPrice;
      final estimatedProfit = estimatedRevenue - estCost;

      // ─── Reason text ───────────────────────────────────────
      final reason = _buildReason(
        crop: crop,
        satLevel: satLevel,
        climateScore: climateScore,
        cropRegionalPct: cropRegionalPct,
        price: price,
        totalRisk: totalRisk,
        riskLevel: riskLevel,
        profitScore: profitScore,
        soilScore: soilScore,
      );

      final expectedHarvest = now.add(Duration(days: harvestDays));

      recommendations.add(CropRecommendation(
        id: '',
        farmerId: farmerId,
        recommendedCrop: crop.name,
        companionCrops: [],
        suitabilityScore: suitabilityScore,
        season: seasonName,
        waterAvailability: waterAvailability,
        saturationLevel: satLevel.name,
        estimatedRevenue: estimatedRevenue,
        estimatedCost: estCost,
        estimatedProfit: estimatedProfit,
        riskLevel: riskLevel,
        regionalSaturation: cropRegionalPct,
        reason: reason,
        isIntercrop: false,
        expectedHarvest: expectedHarvest,
        // Score breakdown
        profitScore: profitScore,
        climateScore: climateScore,
        marketRiskScore: marketRiskScore,
        soilScore: soilScore,
        diversificationScore: diversificationScore,
        // Risk breakdown
        weatherRisk: weatherRisk,
        marketRisk: mktRisk,
        cropSensitivity: cropSens,
        financialRisk: finRisk,
        totalRiskScore: totalRisk,
      ));
    }

    // Sort by suitability score descending
    recommendations.sort(
        (a, b) => b.suitabilityScore.compareTo(a.suitabilityScore));

    // ── Phase 3: Intercropping recommendations ──
    final intercrops = _generateIntercroppingRecommendations(
      recommendations: recommendations,
      fieldAreaHa: fieldAreaHa,
      waterAvailability: waterAvailability,
      season: seasonName,
      farmerId: farmerId,
      plantingDate: now,
      marketPrices: marketPrices,
      regionalData: regionalData,
      maxProfit: maxProfit,
      month: month,
      effectiveBudget: effectiveBudget,
    );
    recommendations.addAll(intercrops);

    // Save to database
    await _saveRecommendations(recommendations);

    return recommendations;
  }

  // ================================================================
  // MULTI-DIMENSIONAL CROP SCORE MODEL
  // Each sub-score returns 0.0 – 1.0
  // ================================================================

  /// **Profit Score** (weight 0.35): normalized by max profit across all crops.
  double _calcProfitScore(double cropProfit, double maxProfit) {
    if (maxProfit <= 0) return 0.0;
    return (cropProfit / maxProfit).clamp(0.0, 1.0);
  }

  /// **Climate Score** (weight 0.20):
  /// 1.0 = peak planting month, 0.6 = adjacent month, 0.3 = off-season.
  double _calcClimateScore(CropData crop, int month) {
    const monthAbbr = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final currentMonth = monthAbbr[month - 1];
    if (crop.bestPlantingMonths.contains(currentMonth)) return 1.0;
    final prevMonth = monthAbbr[(month - 2) % 12];
    final nextMonth = monthAbbr[month % 12];
    if (crop.bestPlantingMonths.contains(prevMonth) ||
        crop.bestPlantingMonths.contains(nextMonth)) {
      return 0.6;
    }
    return 0.3;
  }

  /// **Market Risk Score** (weight 0.20):
  /// `1 − (regional_saturation% / 100)` — low saturation = high score.
  double _calcMarketRiskScore(double regionalPct) {
    return (1.0 - (regionalPct / 100.0)).clamp(0.0, 1.0);
  }

  /// **Soil Score** (weight 0.15):
  /// `1 − (|actual_moisture − optimal_midpoint| / 100)`.
  double _calcSoilScore(CropData crop, double moisture) {
    final optimal = (crop.idealMoistureMin + crop.idealMoistureMax) / 2.0;
    return (1.0 - ((moisture - optimal).abs() / 100.0)).clamp(0.0, 1.0);
  }

  /// **Composite weighted score** → 0–100 scale for display.
  double _compositeScore({
    required double profitScore,
    required double climateScore,
    required double marketRiskScore,
    required double soilScore,
    required double diversificationScore,
  }) {
    final raw = profitScore * 0.35 +
        climateScore * 0.20 +
        marketRiskScore * 0.20 +
        soilScore * 0.15 +
        diversificationScore * 0.10;
    return (raw * 100.0).clamp(0.0, 100.0);
  }

  // ================================================================
  // PREDICTIVE RISK MODEL
  // Each sub-risk returns 0.0 – 1.0 (probability)
  // ================================================================

  /// **Weather Risk** (weight 0.30):
  /// Based on monsoon adequacy for the crop during the planting month.
  /// Monsoon months (Jun–Sep) provide adequate rainfall → lower risk for
  /// water-loving crops, higher risk for drought-tolerant ones if flooded.
  double _calcWeatherRisk(int month, CropData crop) {
    final isMonsoon = month >= 6 && month <= 9;
    final isDry = month >= 3 && month <= 5;

    if (isMonsoon) {
      // Monsoon: flood risk for flood-sensitive crops
      return crop.floodSensitivity * 0.7;
    } else if (isDry) {
      // Dry season: drought risk
      return crop.droughtSensitivity * 0.7;
    } else {
      // Transition months: moderate across both
      return ((crop.floodSensitivity + crop.droughtSensitivity) / 2.0) * 0.4;
    }
  }

  /// **Market Risk** (weight 0.30):
  /// Based on harvest overlap count (regional saturation) and price trend.
  double _calcMarketRisk(double regionalPct, MarketPrice? price) {
    // Saturation component: higher saturation → higher oversupply risk
    final saturationRisk = (regionalPct / 100.0).clamp(0.0, 1.0);

    // Price trend component
    double trendRisk = 0.3; // stable baseline
    if (price != null) {
      if (price.trend == 'falling') {
        trendRisk = 0.7;
      } else if (price.trend == 'rising') {
        trendRisk = 0.1;
      }
    }

    // Weighted blend: 60% saturation, 40% price trend
    return (saturationRisk * 0.6 + trendRisk * 0.4).clamp(0.0, 1.0);
  }

  /// **Crop Sensitivity** (weight 0.20):
  /// Selects the dominant sensitivity based on current season conditions.
  double _calcCropSensitivity(CropData crop, int month, double moisture) {
    final isMonsoon = month >= 6 && month <= 9;
    final isDry = month >= 3 && month <= 5;

    if (isMonsoon && moisture > 70) {
      // High moisture + monsoon → flood sensitivity dominates
      return crop.floodSensitivity;
    } else if (isDry && moisture < 40) {
      // Low moisture + dry → drought sensitivity dominates
      return crop.droughtSensitivity;
    } else if (isDry) {
      // Dry season → heat sensitivity
      return crop.heatSensitivity;
    }
    // Default: composite average
    return crop.sensitivityCoefficient;
  }

  /// **Financial Risk** (weight 0.20):
  /// `cost / budget` — higher ratio = higher risk of capital shortfall.
  double _calcFinancialRisk(double estimatedCost, double budget) {
    if (budget <= 0) return 1.0;
    return (estimatedCost / budget).clamp(0.0, 1.0);
  }

  /// **Composite risk probability** → 0.0–1.0.
  double _compositeRisk({
    required double weatherRisk,
    required double marketRisk,
    required double cropSensitivity,
    required double financialRisk,
  }) {
    return (weatherRisk * 0.30 +
            marketRisk * 0.30 +
            cropSensitivity * 0.20 +
            financialRisk * 0.20)
        .clamp(0.0, 1.0);
  }

  /// Convert risk probability to label: LOW / MEDIUM / HIGH.
  String _riskLabel(double totalRisk) {
    if (totalRisk >= 0.70) return 'high';
    if (totalRisk >= 0.40) return 'medium';
    return 'low';
  }

  // ================================================================
  // INTERCROPPING GENERATOR
  // ================================================================

  List<CropRecommendation> _generateIntercroppingRecommendations({
    required List<CropRecommendation> recommendations,
    required double fieldAreaHa,
    required double waterAvailability,
    required String season,
    required String farmerId,
    required DateTime plantingDate,
    required Map<String, MarketPrice?> marketPrices,
    required Map<String, double> regionalData,
    required double maxProfit,
    required int month,
    required double effectiveBudget,
  }) {
    final intercrops = <CropRecommendation>[];
    if (recommendations.length < 3) return intercrops;

    // Take top 5 single-crop recommendations
    final top = recommendations.take(5).toList();

    for (int i = 0; i < top.length; i++) {
      final primary = top[i];
      final primaryCropData = CropData.allCrops.firstWhere(
        (c) => c.name == primary.recommendedCrop,
        orElse: () => CropData.allCrops.first,
      );

      // Find compatible companions
      final companions =
          CropData.getCompanionCrops(primaryCropData, waterAvailability);
      if (companions.isEmpty) continue;

      // Pick top 2 companions by their individual scores
      final companionNames =
          companions.take(2).map((c) => c.name).toList();

      // Intercrop financial estimate (70% primary + 30% companion revenue)
      final companionPrice = companionNames.isNotEmpty
          ? (marketPrices[companionNames.first]?.pricePerKg ?? 30.0)
          : 30.0;
      final companionYield =
          (_avgYieldPerHa[companionNames.isNotEmpty ? companionNames.first : ''] ??
                  5000) *
              fieldAreaHa *
              0.3;
      final primaryYield =
          (_avgYieldPerHa[primary.recommendedCrop] ?? 5000) *
              fieldAreaHa *
              0.7;
      final primaryPrice =
          marketPrices[primary.recommendedCrop]?.pricePerKg ?? 30.0;
      final totalRevenue =
          primaryYield * primaryPrice + companionYield * companionPrice;
      final totalCost = primary.estimatedCost * 1.15;
      final totalProfit = totalRevenue - totalCost;

      final harvestDays =
          _parseGrowthDays(primaryCropData.growthDuration);

      // ── Recalculate scores with diversification bonus ──
      final profitScore = maxProfit > 0
          ? (totalProfit / maxProfit).clamp(0.0, 1.0)
          : 0.0;
      final climateScore = primary.climateScore;
      final cropRegionalPct = regionalData[primary.recommendedCrop] ?? 0.0;
      final marketRiskScore = _calcMarketRiskScore(cropRegionalPct);
      final soilScore = primary.soilScore;
      // Intercropping bonus: 0.8 base + 0.1 per companion (max 1.0)
      final diversificationScore =
          (0.8 + 0.1 * companionNames.length).clamp(0.0, 1.0);

      final suitability = _compositeScore(
        profitScore: profitScore,
        climateScore: climateScore,
        marketRiskScore: marketRiskScore,
        soilScore: soilScore,
        diversificationScore: diversificationScore,
      );

      // Risk is reduced by diversification — scale down by 15%
      final weatherRisk = primary.weatherRisk * 0.85;
      final mktRisk = primary.marketRisk * 0.85;
      final cropSens = primary.cropSensitivity * 0.90;
      final finRisk = _calcFinancialRisk(totalCost, effectiveBudget);
      final totalRisk = _compositeRisk(
        weatherRisk: weatherRisk,
        marketRisk: mktRisk,
        cropSensitivity: cropSens,
        financialRisk: finRisk,
      );
      final riskLevel = _riskLabel(totalRisk);

      intercrops.add(CropRecommendation(
        id: '',
        farmerId: farmerId,
        recommendedCrop: primary.recommendedCrop,
        companionCrops: companionNames,
        suitabilityScore: suitability,
        season: season,
        waterAvailability: waterAvailability,
        saturationLevel: primary.saturationLevel,
        estimatedRevenue: totalRevenue,
        estimatedCost: totalCost,
        estimatedProfit: totalProfit,
        riskLevel: riskLevel,
        regionalSaturation: cropRegionalPct,
        reason:
            'Intercropping ${primary.recommendedCrop} with ${companionNames.join(" & ")} '
            'diversifies income (div. score: ${(diversificationScore * 100).toStringAsFixed(0)}%), '
            'reduces predictive risk by ~15%, and optimizes land use. '
            'Companion crops complement water availability needs.',
        isIntercrop: true,
        expectedHarvest: plantingDate.add(Duration(days: harvestDays)),
        profitScore: profitScore,
        climateScore: climateScore,
        marketRiskScore: marketRiskScore,
        soilScore: soilScore,
        diversificationScore: diversificationScore,
        weatherRisk: weatherRisk,
        marketRisk: mktRisk,
        cropSensitivity: cropSens,
        financialRisk: finRisk,
        totalRiskScore: totalRisk,
      ));
    }

    return intercrops;
  }

  // ================================================================
  // UTILITY METHODS
  // ================================================================

  double _estimateWaterAvailability(int month) {
    // Philippine seasonal water availability estimation
    if (month >= 6 && month <= 9) {
      return 65 + (month % 3) * 8;   // Monsoon: high
    } else if (month >= 3 && month <= 5) {
      return 35 + (month % 3) * 5;   // Dry season: low
    } else {
      return 45 + (month % 4) * 7;   // Transition: moderate
    }
  }

  String _buildReason({
    required CropData crop,
    required SaturationLevel satLevel,
    required double climateScore,
    required double cropRegionalPct,
    required MarketPrice? price,
    required double totalRisk,
    required String riskLevel,
    required double profitScore,
    required double soilScore,
  }) {
    final parts = <String>[];

    // Soil assessment
    if (soilScore >= 0.8) {
      parts.add('Water availability is ideal for ${crop.name} (score: ${(soilScore * 100).toStringAsFixed(0)}%).');
    } else if (satLevel == SaturationLevel.high) {
      parts.add(
          'Over-saturated for ${crop.name} (score: ${(soilScore * 100).toStringAsFixed(0)}%); consider drainage.');
    } else {
      parts.add(
          'Water availability below ideal for ${crop.name} (score: ${(soilScore * 100).toStringAsFixed(0)}%); irrigation may help.');
    }

    // Climate
    if (climateScore >= 0.9) {
      parts.add('Currently in peak planting season.');
    } else if (climateScore >= 0.5) {
      parts.add('Planting season is acceptable but not optimal.');
    } else {
      parts.add('Off-season — climate conditions are unfavorable.');
    }

    // Regional saturation
    if (cropRegionalPct >= 30) {
      parts.add(
          'Warning: ${cropRegionalPct.toStringAsFixed(0)}% regional saturation — high oversupply risk.');
    } else if (cropRegionalPct >= 15) {
      parts.add(
          '${cropRegionalPct.toStringAsFixed(0)}% regional saturation — moderate competition.');
    } else {
      parts.add('Low regional saturation — good market opportunity.');
    }

    // Price trend
    if (price != null) {
      if (price.trend == 'rising') {
        parts.add('Market price trending upward (₱${price.pricePerKg}/kg).');
      } else if (price.trend == 'falling') {
        parts.add('Market price declining (₱${price.pricePerKg}/kg) — watch closely.');
      } else {
        parts.add('Market price stable at ₱${price.pricePerKg}/kg.');
      }
    }

    // Risk summary
    parts.add(
        'Predictive risk: ${(totalRisk * 100).toStringAsFixed(0)}% ($riskLevel). '
        'Profit potential: ${(profitScore * 100).toStringAsFixed(0)}%.');

    return parts.join(' ');
  }

  int _parseGrowthDays(String growthDuration) {
    final numbers = RegExp(r'\d+').allMatches(growthDuration).toList();
    if (numbers.length >= 2) {
      final mn = int.parse(numbers[0].group(0)!);
      final mx = int.parse(numbers[1].group(0)!);
      return ((mn + mx) / 2).round();
    }
    if (numbers.length == 1) {
      return int.parse(numbers[0].group(0)!);
    }
    return 90;
  }

  // ================================================================
  // DATA FETCHING
  // ================================================================

  Future<Map<String, MarketPrice?>> _fetchMarketPrices() async {
    try {
      final data = await _client
          .from('market_prices')
          .select()
          .order('price_date', ascending: false);
      final prices = <String, MarketPrice?>{};
      for (final row in data) {
        final mp = MarketPrice.fromJson(row);
        prices.putIfAbsent(mp.cropType, () => mp);
      }
      return prices;
    } catch (e) {
      return {};
    }
  }

  /// Fetches what % of all current saturation_records each crop represents.
  Future<Map<String, double>> _fetchRegionalSaturation() async {
    try {
      final data =
          await _client.from('saturation_records').select('primary_crop');
      if (data.isEmpty) return {};
      final counts = <String, int>{};
      for (final row in data) {
        final crop = row['primary_crop'] as String;
        counts[crop] = (counts[crop] ?? 0) + 1;
      }
      final total = data.length;
      return counts.map((k, v) => MapEntry(k, (v / total) * 100));
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveRecommendations(
      List<CropRecommendation> recommendations) async {
    try {
      if (recommendations.isNotEmpty) {
        await _client
            .from('crop_recommendations')
            .delete()
            .eq('farmer_id', recommendations.first.farmerId);
      }
      final rows = recommendations.map((r) => r.toJson()).toList();
      if (rows.isNotEmpty) {
        await _client.from('crop_recommendations').insert(rows);
      }
    } catch (e) {
      print('Warning: Could not persist recommendations: $e');
    }
  }

  /// Fetch previously saved recommendations.
  Future<List<CropRecommendation>> getSavedRecommendations(
      String farmerId) async {
    try {
      final data = await _client
          .from('crop_recommendations')
          .select()
          .eq('farmer_id', farmerId)
          .order('suitability_score', ascending: false);
      return List<CropRecommendation>.from(
          data.map((r) => CropRecommendation.fromJson(r)));
    } catch (e) {
      return [];
    }
  }
}
