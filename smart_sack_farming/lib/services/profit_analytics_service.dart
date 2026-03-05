import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_model.dart';

/// Central service for farmer-oriented P&L intelligence:
///   • Yield-based revenue calculation
///   • ROI, Break-even, Cost-per-hectare
///   • Risk assessment (saturation + market + calamity)
///   • Forecast vs Actual comparison
///   • Multi-project comparison data
///   • Market price lookup
class ProfitAnalyticsService {
  final _client = Supabase.instance.client;

  // ── Market Price Lookup ──────────────────────────────────────────

  /// Fetch latest market price for a crop (from market_prices table)
  Future<double> getMarketPrice(String cropType) async {
    try {
      final data = await _client
          .from('market_prices')
          .select('price_per_kg')
          .eq('crop_type', cropType)
          .order('price_date', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data != null && data['price_per_kg'] is num) {
        return (data['price_per_kg'] as num).toDouble();
      }
    } catch (_) {}
    return 0;
  }

  /// Fetch market trend for a crop
  Future<String> getMarketTrend(String cropType) async {
    try {
      final data = await _client
          .from('market_prices')
          .select('trend')
          .eq('crop_type', cropType)
          .order('price_date', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data != null && data['trend'] is String) {
        return data['trend'] as String;
      }
    } catch (_) {}
    return 'stable';
  }

  /// Get all market prices for comparison
  Future<Map<String, double>> getAllMarketPrices() async {
    final Map<String, double> prices = {};
    try {
      final data = await _client
          .from('market_prices')
          .select('crop_type, price_per_kg')
          .order('price_date', ascending: false);
      for (var row in data) {
        final crop = row['crop_type'] as String? ?? '';
        if (crop.isNotEmpty && !prices.containsKey(crop)) {
          prices[crop] = (row['price_per_kg'] as num?)?.toDouble() ?? 0;
        }
      }
    } catch (_) {}
    return prices;
  }

  // ── Risk Assessment ──────────────────────────────────────────────

  /// Build a risk assessment for a project by cross-referencing
  /// saturation_records, market_prices, and calamity_reports.
  Future<RiskAssessment> assessRisk({
    required String farmerId,
    required String cropType,
    required double areaHectares,
  }) async {
    double satRisk = 0;
    double mktRisk = 0;
    double calRisk = 0;
    String satLevel = 'medium';
    String mktTrend = 'stable';
    int calCount = 0;

    try {
      // 1. Saturation risk — latest saturation record
      final satData = await _client
          .from('saturation_records')
          .select('saturation_level, soil_moisture')
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (satData != null) {
        satLevel = satData['saturation_level'] ?? 'medium';
        final moisture =
            (satData['soil_moisture'] as num?)?.toDouble() ?? 50;

        switch (satLevel) {
          case 'high':
            satRisk = 70 + (moisture > 80 ? 20 : 10);
            break;
          case 'medium':
            satRisk = 35 + (moisture > 60 ? 15 : 0);
            break;
          case 'low':
            satRisk = 10;
            break;
        }
      }

      // 2. Market risk — price trend
      mktTrend = await getMarketTrend(cropType);
      switch (mktTrend) {
        case 'falling':
          mktRisk = 70;
          break;
        case 'stable':
          mktRisk = 25;
          break;
        case 'rising':
          mktRisk = 10;
          break;
      }

      // 3. Calamity risk — recent calamity reports (last 6 months)
      final sixMonthsAgo =
          DateTime.now().subtract(const Duration(days: 180));
      final calData = await _client
          .from('calamity_reports')
          .select('id, severity')
          .eq('farmer_id', farmerId)
          .gte('date_occurred',
              sixMonthsAgo.toIso8601String().split('T').first);

      calCount = (calData as List).length;
      if (calCount >= 3) {
        calRisk = 85;
      } else if (calCount == 2) {
        calRisk = 60;
      } else if (calCount == 1) {
        calRisk = 35;
      } else {
        calRisk = 5;
      }
    } catch (e) {
      print('Risk assessment error: $e');
    }

    return RiskAssessment(
      saturationRisk: satRisk,
      marketRisk: mktRisk,
      calamityRisk: calRisk,
      saturationLevel: satLevel,
      marketTrend: mktTrend,
      recentCalamities: calCount,
    );
  }

  // ── Forecast vs Actual ───────────────────────────────────────────

  /// Generate comparison rows for a project
  List<ForecastComparison> buildForecastComparison(FarmingProject project) {
    return [
      ForecastComparison(
        metric: 'Yield (kg)',
        expected: project.expectedYieldKg,
        actual: project.actualYieldKg,
      ),
      ForecastComparison(
        metric: 'Revenue (₱)',
        expected: project.computedExpectedRevenue,
        actual: project.actualRevenue,
      ),
      ForecastComparison(
        metric: 'Profit (₱)',
        expected: project.expectedProfit,
        actual: project.profit,
      ),
    ];
  }

  // ── Multi-Project Comparison ─────────────────────────────────────

  /// Build comparison data across all projects
  List<Map<String, dynamic>> buildMultiProjectComparison(
      List<FarmingProject> projects) {
    return projects.map((p) {
      return {
        'crop': p.cropType,
        'area': p.area,
        'revenue': p.actualRevenue,
        'expenses': p.totalExpenses,
        'profit': p.profit,
        'roi': p.roi,
        'costPerHa': p.costPerHectare,
        'status': p.status,
      };
    }).toList();
  }

  // ── Seasonal Cash Flow ───────────────────────────────────────────

  /// Returns monthly cash flow for a project
  /// Positive = income, Negative = expense
  Map<String, double> getSeasonalCashFlow(FarmingProject project) {
    return project.monthlyCashFlow;
  }

  // ── Update project with market price from DB ─────────────────────

  /// Enrich a project by looking up the latest market price
  Future<FarmingProject> enrichWithMarketPrice(
      FarmingProject project) async {
    if (project.marketPricePerKg > 0) return project;
    final price = await getMarketPrice(project.cropType);
    if (price > 0) {
      return project.copyWith(marketPricePerKg: price);
    }
    return project;
  }
}
