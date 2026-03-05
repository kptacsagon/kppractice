import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/market_price_model.dart';

/// Financial forecasting service that simulates potential profit margins,
/// compares recommended vs saturated crops, and provides risk assessment.
class FinancialForecastService {
  final SupabaseClient _client;

  FinancialForecastService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ================================================================
  // COST STRUCTURE (₱ per hectare)
  // ================================================================
  static const Map<String, Map<String, double>> _costBreakdown = {
    'Rice': {
      'Seeds': 5000,
      'Fertilizer': 12000,
      'Pesticides': 5000,
      'Labor': 15000,
      'Water': 4000,
      'Equipment': 4000,
    },
    'Corn': {
      'Seeds': 4000,
      'Fertilizer': 8000,
      'Pesticides': 4000,
      'Labor': 8000,
      'Water': 3000,
      'Equipment': 3000,
    },
    'Tomato': {
      'Seeds': 8000,
      'Fertilizer': 15000,
      'Pesticides': 8000,
      'Labor': 18000,
      'Water': 5000,
      'Equipment': 6000,
    },
    'Lettuce': {
      'Seeds': 6000,
      'Fertilizer': 10000,
      'Pesticides': 5000,
      'Labor': 16000,
      'Water': 6000,
      'Equipment': 7000,
    },
    'Eggplant': {
      'Seeds': 5000,
      'Fertilizer': 14000,
      'Pesticides': 7000,
      'Labor': 17000,
      'Water': 5000,
      'Equipment': 7000,
    },
    'Sweet Potato': {
      'Seeds': 4000,
      'Fertilizer': 8000,
      'Pesticides': 3000,
      'Labor': 12000,
      'Water': 4000,
      'Equipment': 4000,
    },
    'Carrot': {
      'Seeds': 5000,
      'Fertilizer': 10000,
      'Pesticides': 5000,
      'Labor': 15000,
      'Water': 5000,
      'Equipment': 5000,
    },
    'Cabbage': {
      'Seeds': 4000,
      'Fertilizer': 10000,
      'Pesticides': 5000,
      'Labor': 12000,
      'Water': 4000,
      'Equipment': 5000,
    },
    'Watermelon': {
      'Seeds': 6000,
      'Fertilizer': 12000,
      'Pesticides': 5000,
      'Labor': 15000,
      'Water': 6000,
      'Equipment': 6000,
    },
    'Basil': {
      'Seeds': 3000,
      'Fertilizer': 6000,
      'Pesticides': 3000,
      'Labor': 10000,
      'Water': 4000,
      'Equipment': 4000,
    },
    'Pepper': {
      'Seeds': 6000,
      'Fertilizer': 13000,
      'Pesticides': 6000,
      'Labor': 16000,
      'Water': 5000,
      'Equipment': 6000,
    },
    'Spinach': {
      'Seeds': 3000,
      'Fertilizer': 7000,
      'Pesticides': 4000,
      'Labor': 12000,
      'Water': 5000,
      'Equipment': 4000,
    },
  };

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
  };

  /// Generate a full financial forecast for a crop.
  Future<CropForecast> forecastCrop({
    required String cropType,
    required double areaHa,
    int? growthDays,
  }) async {
    final prices = await _fetchMarketPrices();
    final price = prices[cropType];
    final days = growthDays ?? 90;

    // Cost calculation
    final costMap = _costBreakdown[cropType] ??
        {
          'Seeds': 5000,
          'Fertilizer': 10000,
          'Pesticides': 5000,
          'Labor': 12000,
          'Water': 4000,
          'Equipment': 4000,
        };
    final totalCostPerHa =
        costMap.values.fold<double>(0, (s, v) => s + v);
    final totalCost = totalCostPerHa * areaHa;
    final costBreakdown = costMap.map((k, v) => MapEntry(k, v * areaHa));

    // Revenue calculation
    final yieldPerHa = _avgYieldPerHa[cropType] ?? 5000;
    final totalYieldKg = yieldPerHa * areaHa;
    final currentPrice = price?.pricePerKg ?? 30.0;
    final harvestPrice = price?.projectPrice(days) ?? currentPrice;

    // Scenarios: best, expected, worst
    final bestRevenue = totalYieldKg * harvestPrice * 1.2;
    final expectedRevenue = totalYieldKg * harvestPrice;
    final worstRevenue = totalYieldKg * harvestPrice * 0.7;

    return CropForecast(
      cropType: cropType,
      areaHa: areaHa,
      costBreakdown: costBreakdown,
      totalCost: totalCost,
      expectedYieldKg: totalYieldKg,
      currentPricePerKg: currentPrice,
      projectedPricePerKg: harvestPrice,
      priceTrend: price?.trend ?? 'stable',
      bestCaseRevenue: bestRevenue,
      expectedRevenue: expectedRevenue,
      worstCaseRevenue: worstRevenue,
      bestCaseProfit: bestRevenue - totalCost,
      expectedProfit: expectedRevenue - totalCost,
      worstCaseProfit: worstRevenue - totalCost,
      profitMargin: expectedRevenue > 0
          ? ((expectedRevenue - totalCost) / expectedRevenue * 100)
          : 0,
      breakEvenYieldKg:
          harvestPrice > 0 ? totalCost / harvestPrice : 0,
      breakEvenPricePerKg:
          totalYieldKg > 0 ? totalCost / totalYieldKg : 0,
      roiPercent: totalCost > 0
          ? ((expectedRevenue - totalCost) / totalCost * 100)
          : 0,
    );
  }

  /// Compare multiple crops side by side.
  Future<List<CropForecast>> compareCrops({
    required List<String> cropTypes,
    required double areaHa,
  }) async {
    final forecasts = <CropForecast>[];
    for (final crop in cropTypes) {
      final f = await forecastCrop(cropType: crop, areaHa: areaHa);
      forecasts.add(f);
    }
    // Sort by expected profit descending
    forecasts.sort((a, b) => b.expectedProfit.compareTo(a.expectedProfit));
    return forecasts;
  }

  /// Calculate actual P&L by comparing forecast to real expenses.
  Future<ActualVsForecast> calculateActualVsForecast({
    required String projectId,
    required String cropType,
    required double areaHa,
  }) async {
    // Get actual expenses from the project
    final expenseData = await _client
        .from('expenses')
        .select()
        .eq('project_id', projectId);

    double actualCost = 0;
    final actualBreakdown = <String, double>{};
    for (final e in expenseData) {
      final amount =
          (e['amount'] is num) ? (e['amount'] as num).toDouble() : 0.0;
      final category = e['category'] ?? 'Other';
      actualCost += amount;
      actualBreakdown[category] =
          (actualBreakdown[category] ?? 0) + amount;
    }

    // Get forecast
    final forecast =
        await forecastCrop(cropType: cropType, areaHa: areaHa);

    return ActualVsForecast(
      forecast: forecast,
      actualCost: actualCost,
      actualCostBreakdown: actualBreakdown,
      costVariance: actualCost - forecast.totalCost,
      costVariancePercent: forecast.totalCost > 0
          ? ((actualCost - forecast.totalCost) / forecast.totalCost * 100)
          : 0,
    );
  }

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
}

/// Complete financial forecast for a single crop.
class CropForecast {
  final String cropType;
  final double areaHa;
  final Map<String, double> costBreakdown;
  final double totalCost;
  final double expectedYieldKg;
  final double currentPricePerKg;
  final double projectedPricePerKg;
  final String priceTrend;
  final double bestCaseRevenue;
  final double expectedRevenue;
  final double worstCaseRevenue;
  final double bestCaseProfit;
  final double expectedProfit;
  final double worstCaseProfit;
  final double profitMargin;
  final double breakEvenYieldKg;
  final double breakEvenPricePerKg;
  final double roiPercent;

  CropForecast({
    required this.cropType,
    required this.areaHa,
    required this.costBreakdown,
    required this.totalCost,
    required this.expectedYieldKg,
    required this.currentPricePerKg,
    required this.projectedPricePerKg,
    required this.priceTrend,
    required this.bestCaseRevenue,
    required this.expectedRevenue,
    required this.worstCaseRevenue,
    required this.bestCaseProfit,
    required this.expectedProfit,
    required this.worstCaseProfit,
    required this.profitMargin,
    required this.breakEvenYieldKg,
    required this.breakEvenPricePerKg,
    required this.roiPercent,
  });

  String get profitLabel =>
      expectedProfit >= 0 ? 'Profitable' : 'Loss Expected';

  String get trendEmoji {
    switch (priceTrend) {
      case 'rising':
        return '📈';
      case 'falling':
        return '📉';
      default:
        return '➡️';
    }
  }
}

/// Comparison of forecast vs actual expenses.
class ActualVsForecast {
  final CropForecast forecast;
  final double actualCost;
  final Map<String, double> actualCostBreakdown;
  final double costVariance;
  final double costVariancePercent;

  ActualVsForecast({
    required this.forecast,
    required this.actualCost,
    required this.actualCostBreakdown,
    required this.costVariance,
    required this.costVariancePercent,
  });

  bool get isOverBudget => costVariance > 0;
  String get varianceLabel =>
      isOverBudget ? 'Over Budget' : 'Under Budget';
}
