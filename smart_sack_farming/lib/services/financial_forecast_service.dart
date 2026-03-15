import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/market_price_model.dart';

/// Financial forecasting service that simulates potential profit margins,
/// compares recommended vs saturated crops, and provides risk assessment.
class FinancialForecastService {
  final SupabaseClient _client;

  FinancialForecastService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ================================================================
  // COST STRUCTURE (₱ per hectare) — Philippine Agronomic Data
  // Sources: PhilRice, DA-BAS, PSA crop statistics
  // Updated March 2026 with PSA OpenSTAT Iloilo data
  // ================================================================
  static const Map<String, Map<String, double>> _costBreakdown = {
    // Rice (Palay): PhilRice avg irrigated ₱45K-55K/ha
    'Rice': {
      'Seeds': 6000,       // Certified seeds 40-60kg @ ₱100-150/kg
      'Fertilizer': 14000, // Urea + Complete, 6-8 bags
      'Pesticides': 5000,  // Insecticide, herbicide, fungicide
      'Labor': 18000,      // Land prep, transplanting, weeding, harvest
      'Water/Irrigation': 5000,
      'Equipment Rental': 4000,
    },
    // Corn (Mais): DA avg ₱30K-40K/ha
    'Corn': {
      'Seeds': 5000,       // Hybrid seeds 15-20kg
      'Fertilizer': 10000, // 6 bags Urea + Complete
      'Pesticides': 4000,
      'Labor': 12000,
      'Water/Irrigation': 3000,
      'Equipment Rental': 4000,
    },
    // Coconut (Niyog): Established plantation ₱15K-25K/ha/yr
    'Coconut': {
      'Seeds/Seedlings': 2000,
      'Fertilizer': 6000,
      'Pesticides': 2000,
      'Labor': 8000,
      'Water/Irrigation': 1000,
      'Equipment Rental': 2000,
    },
    // Sugarcane (Tubo): DA avg ₱50K-80K/ha
    'Sugarcane': {
      'Seeds/Cane Points': 8000,
      'Fertilizer': 16000,
      'Pesticides': 6000,
      'Labor': 25000,      // Heavy labor for harvest
      'Water/Irrigation': 5000,
      'Equipment Rental': 8000,
    },
    // Banana (Saging): ₱40K-60K/ha establishment
    'Banana': {
      'Seedlings/Suckers': 10000,
      'Fertilizer': 12000,
      'Pesticides': 5000,
      'Labor': 15000,
      'Water/Irrigation': 4000,
      'Equipment Rental': 4000,
    },
    // Banana Saba: PSA Iloilo ₱36-39/kg, stable market
    'Banana Saba': {
      'Seedlings/Suckers': 8000,
      'Fertilizer': 10000,
      'Pesticides': 4000,
      'Labor': 14000,
      'Water/Irrigation': 4000,
      'Equipment Rental': 3000,
    },
    // Banana Lakatan: PSA Iloilo ₱80-87/kg, premium price
    'Banana Lakatan': {
      'Seedlings/Suckers': 12000,
      'Fertilizer': 14000,
      'Pesticides': 6000,
      'Labor': 16000,
      'Water/Irrigation': 5000,
      'Equipment Rental': 4000,
    },
    // Vegetables (mixed): ₱50K-80K/ha
    'Vegetables': {
      'Seeds': 8000,
      'Fertilizer': 15000,
      'Pesticides': 8000,
      'Labor': 20000,
      'Water/Irrigation': 6000,
      'Equipment Rental': 5000,
    },
    // Root Crops (Kamote/Gabi): ₱25K-35K/ha
    'Root Crops': {
      'Planting Material': 4000,
      'Fertilizer': 6000,
      'Pesticides': 3000,
      'Labor': 12000,
      'Water/Irrigation': 3000,
      'Equipment Rental': 3000,
    },
    // Sweet Potato: PSA Iloilo ₱52-73/kg
    'Sweet Potato': {
      'Planting Material': 4000,
      'Fertilizer': 6000,
      'Pesticides': 3000,
      'Labor': 12000,
      'Water/Irrigation': 3000,
      'Equipment Rental': 3000,
    },
    // Mango: Established orchard ₱25K-40K/ha/season
    'Mango': {
      'Flower Inducer': 6000,
      'Fertilizer': 8000,
      'Pesticides/Spraying': 8000,
      'Labor': 10000,
      'Water/Irrigation': 3000,
      'Equipment Rental': 3000,
    },
    // Eggplant (Talong): ₱50K-65K/ha, PSA Iloilo ₱86-140/kg
    'Eggplant': {
      'Seeds': 5000,
      'Fertilizer': 14000,
      'Pesticides': 7000,
      'Labor': 18000,
      'Water/Irrigation': 5000,
      'Equipment Rental': 6000,
    },
    // Tomato (Kamatis): ₱55K-75K/ha, PSA Iloilo ₱84-113/kg
    'Tomato': {
      'Seeds': 8000,
      'Fertilizer': 16000,
      'Pesticides': 8000,
      'Labor': 20000,
      'Water/Irrigation': 6000,
      'Equipment Rental': 6000,
    },
    // Onion (Sibuyas): ₱80K-120K/ha
    'Onion': {
      'Seeds/Bulbs': 20000,
      'Fertilizer': 18000,
      'Pesticides': 10000,
      'Labor': 22000,
      'Water/Irrigation': 8000,
      'Equipment Rental': 6000,
    },
    // Squash (Kalabasa): PSA Iloilo ₱29-51/kg
    'Squash': {
      'Seeds': 3000,
      'Fertilizer': 8000,
      'Pesticides': 4000,
      'Labor': 10000,
      'Water/Irrigation': 3000,
      'Equipment Rental': 3000,
    },
    // Radish (Labanos): PSA Iloilo ₱61-113/kg, volatile
    'Radish': {
      'Seeds': 4000,
      'Fertilizer': 8000,
      'Pesticides': 4000,
      'Labor': 12000,
      'Water/Irrigation': 4000,
      'Equipment Rental': 3000,
    },
    // Potato (Patatas): PSA Iloilo ₱103-133/kg, high value
    'Potato': {
      'Seeds/Tubers': 40000,  // Seed potatoes are expensive
      'Fertilizer': 18000,
      'Pesticides': 10000,
      'Labor': 20000,
      'Water/Irrigation': 8000,
      'Equipment Rental': 6000,
    },
    // Carrot: PSA estimate ₱80/kg
    'Carrot': {
      'Seeds': 8000,
      'Fertilizer': 12000,
      'Pesticides': 6000,
      'Labor': 15000,
      'Water/Irrigation': 5000,
      'Equipment Rental': 4000,
    },
    // Cabbage (Repolyo): PSA estimate ₱65/kg
    'Cabbage': {
      'Seeds': 6000,
      'Fertilizer': 14000,
      'Pesticides': 8000,
      'Labor': 16000,
      'Water/Irrigation': 5000,
      'Equipment Rental': 4000,
    },
    // Lettuce: Higher input cost
    'Lettuce': {
      'Seeds': 10000,
      'Fertilizer': 12000,
      'Pesticides': 6000,
      'Labor': 18000,
      'Water/Irrigation': 6000,
      'Equipment Rental': 4000,
    },
    // Watermelon (Pakwan)
    'Watermelon': {
      'Seeds': 5000,
      'Fertilizer': 10000,
      'Pesticides': 5000,
      'Labor': 14000,
      'Water/Irrigation': 5000,
      'Equipment Rental': 4000,
    },
    // Pepper (Sili)
    'Pepper': {
      'Seeds': 6000,
      'Fertilizer': 12000,
      'Pesticides': 7000,
      'Labor': 16000,
      'Water/Irrigation': 5000,
      'Equipment Rental': 4000,
    },
    // Basil (Balanoy)
    'Basil': {
      'Seeds': 3000,
      'Fertilizer': 6000,
      'Pesticides': 3000,
      'Labor': 10000,
      'Water/Irrigation': 3000,
      'Equipment Rental': 2000,
    },
    // Spinach (Alugbati)
    'Spinach': {
      'Seeds': 4000,
      'Fertilizer': 8000,
      'Pesticides': 4000,
      'Labor': 12000,
      'Water/Irrigation': 4000,
      'Equipment Rental': 3000,
    },
  };

  // Average yield per hectare (kg) — Philippine DA/BAS statistics
  // Updated March 2026 with PSA OpenSTAT data
  static const Map<String, double> _avgYieldPerHa = {
    'Rice': 4200,          // National avg irrigated: 4.0-4.5 MT/ha
    'Corn': 4800,          // Yellow corn avg: 4.5-5.5 MT/ha
    'Coconut': 5000,       // ~5 MT copra/ha/yr (mature plantation)
    'Sugarcane': 65000,    // 55-75 MT cane/ha
    'Banana': 22000,       // 18-30 MT/ha/yr (Cavendish)
    'Banana Saba': 20000,  // Cooking banana, slightly lower yield
    'Banana Lakatan': 18000, // Premium banana, lower yield
    'Vegetables': 15000,   // Varies widely; mixed estimate
    'Root Crops': 12000,   // Sweet potato 10-15 MT/ha
    'Sweet Potato': 12000, // PSA data: 10-15 MT/ha
    'Mango': 8000,         // 6-10 MT/ha (bearing trees)
    'Eggplant': 25000,     // 20-30 MT/ha
    'Tomato': 20000,       // 15-25 MT/ha
    'Onion': 15000,        // 12-18 MT/ha
    'Squash': 18000,       // 15-20 MT/ha, hardy crop
    'Radish': 15000,       // Fast crop, 12-18 MT/ha
    'Potato': 15000,       // Higher altitude, 12-18 MT/ha
    'Carrot': 20000,       // 15-25 MT/ha
    'Cabbage': 35000,      // High yield 30-40 MT/ha
    'Lettuce': 20000,      // 15-25 MT/ha
    'Watermelon': 30000,   // 25-35 MT/ha
    'Pepper': 15000,       // 10-20 MT/ha
    'Basil': 5000,         // Herb, lower yield
    'Spinach': 12000,      // 10-15 MT/ha
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
