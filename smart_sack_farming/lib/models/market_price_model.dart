/// Market price data for crops used in financial forecasting.
class MarketPrice {
  final String id;
  final String cropType;
  final double pricePerKg;
  final DateTime priceDate;
  final String region;
  final String source;
  final String trend; // 'rising', 'stable', 'falling'

  MarketPrice({
    required this.id,
    required this.cropType,
    required this.pricePerKg,
    required this.priceDate,
    required this.region,
    required this.source,
    required this.trend,
  });

  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    return MarketPrice(
      id: json['id'] ?? '',
      cropType: json['crop_type'] ?? '',
      pricePerKg: (json['price_per_kg'] is num)
          ? (json['price_per_kg'] as num).toDouble()
          : 0.0,
      priceDate: json['price_date'] is String
          ? DateTime.parse(json['price_date'])
          : DateTime.now(),
      region: json['region'] ?? 'local',
      source: json['source'] ?? 'manual',
      trend: json['trend'] ?? 'stable',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crop_type': cropType,
      'price_per_kg': pricePerKg,
      'price_date': priceDate.toIso8601String().split('T').first,
      'region': region,
      'source': source,
      'trend': trend,
    };
  }

  /// Projects future price based on trend direction.
  double projectPrice(int daysAhead) {
    final dailyRate = trend == 'rising'
        ? 0.002
        : trend == 'falling'
            ? -0.0015
            : 0.0;
    return pricePerKg * (1 + dailyRate * daysAhead);
  }
}
