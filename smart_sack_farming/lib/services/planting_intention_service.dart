import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/planting_intention.dart';

/// Service to predict market saturation based on farmer planting intentions
/// 
/// How it works:
/// 1. Farmers input their planting plans (crop, quantity, land area, expected yield)
/// 2. System aggregates all farmer intentions for the same crop/season/barangay
/// 3. Calculates total expected supply vs market demand
/// 4. Predicts price impact and profit impact for each farmer
/// 5. Recommends whether to plant or switch crops

class PlantingIntentionService {
  static final _client = Supabase.instance.client;

  /// Submit farmer's planting intention
  Future<void> submitPlantingIntention(PlantingIntention intention) async {
    try {
      await _client
          .from('planting_intentions')
          .insert(intention.toJson());
    } catch (e) {
      print('Error submitting planting intention: $e');
      rethrow;
    }
  }

  /// Update existing planting intention
  Future<void> updatePlantingIntention(PlantingIntention intention) async {
    try {
      await _client
          .from('planting_intentions')
          .update(intention.toJson())
          .eq('id', intention.id);
    } catch (e) {
      print('Error updating planting intention: $e');
      rethrow;
    }
  }

  /// Get farmer's planting intentions
  Future<List<PlantingIntention>> getMyPlantingIntentions(String farmerId) async {
    try {
      final res = await _client
          .from('planting_intentions')
          .select()
          .eq('farmer_id', farmerId)
          .eq('status', 'planning');
      return (res as List)
          .map((e) => PlantingIntention.fromJson(e))
          .toList();
    } catch (e) {
      print('Error fetching planting intentions: $e');
      return [];
    }
  }

  /// Get all planting intentions for a crop/season/barangay
  Future<List<PlantingIntention>> getPlantingIntentionsByCrop({
    required String cropName,
    required String season,
    required String barangay,
  }) async {
    try {
      final res = await _client
          .from('planting_intentions')
          .select()
          .eq('crop_name', cropName)
          .eq('planting_season', season)
          .eq('barangay', barangay)
          .eq('status', 'planning');
      return (res as List)
          .map((e) => PlantingIntention.fromJson(e))
          .toList();
    } catch (e) {
      print('Error fetching crop intentions: $e');
      return [];
    }
  }

  /// CORE FUNCTION: Predict market saturation based on planting intentions
  Future<SaturationPrediction> predictMarketSaturation({
    required String cropName,
    required String season,
    required String barangay,
    required double baselineHistoricalPrice, // Historical avg price (₱/kg)
    required double estimatedMarketDemandKg, // Market capacity for this crop
    required double avgProductionCosts, // Average cost per kg
  }) async {
    // Step 1: Get all farmer intentions for this crop/season/barangay
    final intentions = await getPlantingIntentionsByCrop(
      cropName: cropName,
      season: season,
      barangay: barangay,
    );

    // Step 2: Calculate total supply expected
    double totalPlannedQuantityKg = 0;
    double estimatedTotalHarvestKg = 0;

    for (final intention in intentions) {
      totalPlannedQuantityKg += intention.plannedQuantityKg;
      estimatedTotalHarvestKg += intention.expectedHarvestKg;
    }

    // Step 3: Calculate supply-to-demand ratio
    final supplyDemandRatio = estimatedMarketDemandKg > 0
        ? estimatedTotalHarvestKg / estimatedMarketDemandKg
        : 0;

    // Step 4: Predict price impact based on supply/demand
    // Formula: Each 10% oversupply = ~5% price drop
    final oversupplyPercent = ((supplyDemandRatio - 1.0) * 100).clamp(-100, 500);
    final predictedPriceImpactPercent = oversupplyPercent * 0.5; // -5% for every 10% oversupply

    // Step 5: Calculate forecasted price
    final forecastedPricePerKg = baselineHistoricalPrice * (1 + (predictedPriceImpactPercent / 100));

    // Step 6: Determine saturation level
    String saturationLevel;
    if (supplyDemandRatio < 0.8) {
      saturationLevel = 'undersupply'; // Good! Demand exceeds supply
    } else if (supplyDemandRatio < 1.0) {
      saturationLevel = 'safe'; // Balanced
    } else if (supplyDemandRatio < 1.3) {
      saturationLevel = 'caution'; // 30% oversupply - watch out
    } else {
      saturationLevel = 'danger'; // >30% oversupply - risky
    }

    // Step 7: Calculate profit impact per farmer (average)
    double profitImpactPerFarmer = 0;
    if (intentions.isNotEmpty) {
      // Average farm profit impact
      double totalProfitChange = 0;
      
      for (final intention in intentions) {
        final oldRevenue = intention.expectedHarvestKg * baselineHistoricalPrice;
        final newRevenue = intention.expectedHarvestKg * forecastedPricePerKg;
        final revenueLoss = newRevenue - oldRevenue;
        
        // Assume 30% of revenue is profit margin
        final profitLoss = revenueLoss * 0.30;
        totalProfitChange += profitLoss;
      }
      
      profitImpactPerFarmer = totalProfitChange / intentions.length;
    }

    // Step 8: Generate recommendation
    String recommendation;
    if (supplyDemandRatio < 0.8) {
      recommendation = '✅ PLANT - Undersupply! High demand, low competition. Prices likely to stay strong or rise.';
    } else if (supplyDemandRatio < 1.0) {
      recommendation = '✅ SAFE TO PLANT - Balanced market. Supply meets demand. Prices stable.';
    } else if (supplyDemandRatio < 1.3) {
      recommendation = '⚠️ CAUTION - Market becoming crowded. ${(supplyDemandRatio * 100 - 100).toStringAsFixed(0)}% oversupply expected. Prices may drop ₱${(baselineHistoricalPrice * (predictedPriceImpactPercent / 100).abs()).toStringAsFixed(2)}/kg. Consider crop rotation.';
    } else {
      recommendation = '❌ HIGH RISK - Severe oversupply (${(supplyDemandRatio * 100 - 100).toStringAsFixed(0)}% excess supply). Prices will drop significantly to ₱${forecastedPricePerKg.toStringAsFixed(2)}/kg. Plant alternative crop instead.';
    }

    return SaturationPrediction(
      cropName: cropName,
      season: season,
      barangay: barangay,
      totalFarmersPlanting: intentions.length,
      totalPlannedQuantityKg: totalPlannedQuantityKg,
      estimatedTotalHarvestKg: estimatedTotalHarvestKg,
      estimatedMarketDemandKg: estimatedMarketDemandKg,
      supplyDemandRatio: supplyDemandRatio,
      predictedPriceImpactPercent: predictedPriceImpactPercent,
      saturationLevel: saturationLevel,
      forecastedPricePerKg: forecastedPricePerKg,
      profitImpactPerFarmer: profitImpactPerFarmer,
      recommendation: recommendation,
    );
  }

  /// Compare multiple crops for the same season/barangay
  /// Helps farmer choose BEST crop to plant
  Future<List<SaturationPrediction>> compareCropOptions({
    required List<String> cropNames,
    required String season,
    required String barangay,
    required Map<String, double> baselinePrices, // crop -> price
    required Map<String, double> marketDemands, // crop -> demand (kg)
    required Map<String, double> productionCosts, // crop -> cost
  }) async {
    final predictions = <SaturationPrediction>[];

    for (final crop in cropNames) {
      try {
        final prediction = await predictMarketSaturation(
          cropName: crop,
          season: season,
          barangay: barangay,
          baselineHistoricalPrice: baselinePrices[crop] ?? 0,
          estimatedMarketDemandKg: marketDemands[crop] ?? 10000,
          avgProductionCosts: productionCosts[crop] ?? 1000,
        );
        predictions.add(prediction);
      } catch (e) {
        print('Error comparing crop $crop: $e');
      }
    }

    // Sort by profitability (highest profit impact first)
    predictions.sort((a, b) => b.profitImpactPerFarmer.compareTo(a.profitImpactPerFarmer));
    return predictions;
  }

  /// Get saturation summary for dashboard
  Future<List<SaturationPrediction>> getSaturationSummary({
    required String season,
    required String barangay,
  }) async {
    try {
      // Get all unique crops in this season/barangay
      final res = await _client
          .from('planting_intentions')
          .select('crop_name')
          .eq('planting_season', season)
          .eq('barangay', barangay)
          .eq('status', 'planning')
          .distinct();

      final crops = (res as List)
          .map((e) => (e as Map)['crop_name'] as String?)
          .whereType<String>()
          .toList();

      final predictions = <SaturationPrediction>[];
      for (final crop in crops) {
        try {
          // Use default market assumptions if not available
          final pred = await predictMarketSaturation(
            cropName: crop,
            season: season,
            barangay: barangay,
            baselineHistoricalPrice: 12.0, // Default ₱12/kg
            estimatedMarketDemandKg: 50000, // Default 50 tons
            avgProductionCosts: 5000, // Default ₱5000
          );
          predictions.add(pred);
        } catch (e) {
          print('Error predicting saturation for $crop: $e');
        }
      }

      return predictions;
    } catch (e) {
      print('Error getting saturation summary: $e');
      return [];
    }
  }
}
