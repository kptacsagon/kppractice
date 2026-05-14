class AgrisenseMarketPrice {
  final String? id;
  final String municipality;
  final String cropType;
  final double pricePerKg;
  final DateTime recordedDate;

  AgrisenseMarketPrice({
    this.id,
    required this.municipality,
    required this.cropType,
    required this.pricePerKg,
    required this.recordedDate,
  });

  factory AgrisenseMarketPrice.fromJson(Map<String, dynamic> json) {
    return AgrisenseMarketPrice(
      id: json['id'],
      municipality: json['municipality'],
      cropType: json['crop_type'],
      pricePerKg: (json['price_per_kg'] as num).toDouble(),
      recordedDate: DateTime.parse(json['recorded_date']),
    );
  }
}
