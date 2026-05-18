import 'package:supabase_flutter/supabase_flutter.dart';

/// Model to represent daily market purchase data
class DailyMarketPurchase {
  final String id;
  final String municipality;
  final String cropType;
  final DateTime purchaseDate;
  final double quantityPurchasedKg;
  final int numBuyers;
  final double? averagePricePerKg;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyMarketPurchase({
    required this.id,
    required this.municipality,
    required this.cropType,
    required this.purchaseDate,
    required this.quantityPurchasedKg,
    required this.numBuyers,
    this.averagePricePerKg,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyMarketPurchase.fromJson(Map<String, dynamic> json) {
    return DailyMarketPurchase(
      id: json['id'] as String,
      municipality: json['municipality'] as String,
      cropType: json['crop_type'] as String,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      quantityPurchasedKg: double.parse(json['quantity_purchased_kg'].toString()),
      numBuyers: json['num_buyers'] as int? ?? 1,
      averagePricePerKg: json['average_price_per_kg'] != null
          ? double.parse(json['average_price_per_kg'].toString())
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'municipality': municipality,
    'crop_type': cropType,
    'purchase_date': purchaseDate.toIso8601String().split('T')[0],
    'quantity_purchased_kg': quantityPurchasedKg,
    'num_buyers': numBuyers,
    'average_price_per_kg': averagePricePerKg,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

/// Model to represent daily saturation status
class DailySaturationStatus {
  final String id;
  final String municipality;
  final String cropType;
  final DateTime statusDate;
  final double dailyDemandKg; // Actual purchases
  final double dailySupplyKg; // Expected yield available
  final double saturationRatio; // Supply / Demand * 100
  final bool isSaturated; // Supply > Demand
  final String saturationLevel; // CRITICALLY_SATURATED, SATURATED, BALANCED, UNDERSUPPLIED
  final DateTime createdAt;
  final DateTime updatedAt;

  DailySaturationStatus({
    required this.id,
    required this.municipality,
    required this.cropType,
    required this.statusDate,
    required this.dailyDemandKg,
    required this.dailySupplyKg,
    required this.saturationRatio,
    required this.isSaturated,
    required this.saturationLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if crop is saturated (supply > demand)
  bool get saturated => isSaturated;

  /// Get user-friendly saturation message
  String getSaturationMessage() {
    switch (saturationLevel) {
      case 'CRITICALLY_SATURATED':
        return 'Market is CRITICALLY SATURATED - supply is more than 2x demand';
      case 'SATURATED':
        return 'Market is SATURATED - supply exceeds demand';
      case 'BALANCED':
        return 'Market is BALANCED - supply matches demand';
      case 'UNDERSUPPLIED':
        return 'Market is UNDERSUPPLIED - demand exceeds supply';
      default:
        return 'Market saturation level unknown';
    }
  }

  factory DailySaturationStatus.fromJson(Map<String, dynamic> json) {
    return DailySaturationStatus(
      id: json['id'] as String,
      municipality: json['municipality'] as String,
      cropType: json['crop_type'] as String,
      statusDate: DateTime.parse(json['status_date'] as String),
      dailyDemandKg: double.parse(json['daily_demand_kg'].toString()),
      dailySupplyKg: double.parse(json['daily_supply_kg'].toString()),
      saturationRatio: double.parse(json['saturation_ratio'].toString()),
      isSaturated: json['is_saturated'] as bool,
      saturationLevel: json['saturation_level'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'municipality': municipality,
    'crop_type': cropType,
    'status_date': statusDate.toIso8601String().split('T')[0],
    'daily_demand_kg': dailyDemandKg,
    'daily_supply_kg': dailySupplyKg,
    'saturation_ratio': saturationRatio,
    'is_saturated': isSaturated,
    'saturation_level': saturationLevel,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

/// Service to manage daily market saturation calculations
class DailyMarketSaturationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String dailyMarketPurchasesTable = 'daily_market_purchases';
  static const String dailySaturationStatusTable = 'daily_saturation_status';

  /// Record a market purchase
  Future<DailyMarketPurchase> recordMarketPurchase({
    required String municipality,
    required String cropType,
    required double quantityPurchasedKg,
    required int numBuyers,
    double? averagePricePerKg,
    DateTime? purchaseDate,
  }) async {
    final date = purchaseDate ?? DateTime.now();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final response = await _supabase
        .from(dailyMarketPurchasesTable)
        .insert({
          'municipality': municipality,
          'crop_type': cropType,
          'purchase_date': dateStr,
          'quantity_purchased_kg': quantityPurchasedKg,
          'num_buyers': numBuyers,
          'average_price_per_kg': averagePricePerKg,
        })
        .select()
        .single();

    return DailyMarketPurchase.fromJson(response);
  }

  /// Get daily saturation status for a specific date and crop
  Future<DailySaturationStatus?> getDailySaturationStatus({
    required String municipality,
    required String cropType,
    DateTime? statusDate,
  }) async {
    final date = statusDate ?? DateTime.now();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final response = await _supabase
        .from(dailySaturationStatusTable)
        .select()
        .eq('municipality', municipality)
        .eq('crop_type', cropType)
        .eq('status_date', dateStr)
        .maybeSingle();

    if (response == null) return null;
    return DailySaturationStatus.fromJson(response);
  }

  /// Get all saturated crops for a municipality on a specific date
  Future<List<DailySaturationStatus>> getSaturatedCropsForMunicipality({
    required String municipality,
    DateTime? statusDate,
  }) async {
    final date = statusDate ?? DateTime.now();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final response = await _supabase
        .from(dailySaturationStatusTable)
        .select()
        .eq('municipality', municipality)
        .eq('status_date', dateStr)
        .eq('is_saturated', true)
        .order('saturation_ratio', ascending: false);

    return (response as List<dynamic>)
        .map((item) => DailySaturationStatus.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Get market purchases for a specific crop in a municipality over a date range
  Future<List<DailyMarketPurchase>> getMarketPurchasesForCrop({
    required String municipality,
    required String cropType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    final response = await _supabase
        .from(dailyMarketPurchasesTable)
        .select()
        .eq('municipality', municipality)
        .eq('crop_type', cropType)
        .gte('purchase_date', startStr)
        .lte('purchase_date', endStr)
        .order('purchase_date', ascending: false);

    return (response as List<dynamic>)
        .map((item) => DailyMarketPurchase.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Get today's saturation status for all crops in all municipalities
  Future<List<DailySaturationStatus>> getTodaySaturationStatus() async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final response = await _supabase
        .from(dailySaturationStatusTable)
        .select()
        .eq('status_date', dateStr)
        .order('saturation_ratio', ascending: false);

    return (response as List<dynamic>)
        .map((item) => DailySaturationStatus.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Get critical saturation alerts (crops where supply > 2x demand)
  Future<List<DailySaturationStatus>> getCriticalSaturationAlerts({
    DateTime? statusDate,
  }) async {
    final date = statusDate ?? DateTime.now();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final response = await _supabase
        .from(dailySaturationStatusTable)
        .select()
        .eq('status_date', dateStr)
        .eq('saturation_level', 'CRITICALLY_SATURATED')
        .order('saturation_ratio', ascending: false);

    return (response as List<dynamic>)
        .map((item) => DailySaturationStatus.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Get saturation trend for a crop over the last N days
  Future<List<DailySaturationStatus>> getSaturationTrend({
    required String municipality,
    required String cropType,
    int days = 7,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    final response = await _supabase
        .from(dailySaturationStatusTable)
        .select()
        .eq('municipality', municipality)
        .eq('crop_type', cropType)
        .gte('status_date', startStr)
        .lte('status_date', endStr)
        .order('status_date', ascending: true);

    return (response as List<dynamic>)
        .map((item) => DailySaturationStatus.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Calculate average daily demand for a crop over a period
  Future<double> getAverageDailyDemand({
    required String cropType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    final response = await _supabase
        .from(dailySaturationStatusTable)
        .select('daily_demand_kg')
        .eq('crop_type', cropType)
        .gte('status_date', startStr)
        .lte('status_date', endStr);

    if (response.isEmpty) return 0;

    final total = (response as List<dynamic>)
        .fold<double>(0, (sum, item) => sum + (double.parse(item['daily_demand_kg'].toString())));

    return total / response.length;
  }

  /// Get supply-to-demand ratio for a crop (supply / demand)
  /// Returns null if no demand data available
  Future<double?> getSupplyToDemandRatio({
    required String municipality,
    required String cropType,
    DateTime? statusDate,
  }) async {
    final status = await getDailySaturationStatus(
      municipality: municipality,
      cropType: cropType,
      statusDate: statusDate,
    );

    if (status == null || status.dailyDemandKg <= 0) return null;

    return status.saturationRatio / 100; // Convert back from percentage
  }
}
