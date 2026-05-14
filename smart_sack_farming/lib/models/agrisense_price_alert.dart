class AgrisensePriceAlert {
  final String? id;
  final String farmerId;
  final String cropType;
  final double targetPrice;
  final bool isActive;
  final DateTime createdAt;

  AgrisensePriceAlert({
    this.id,
    required this.farmerId,
    required this.cropType,
    required this.targetPrice,
    this.isActive = true,
    required this.createdAt,
  });

  factory AgrisensePriceAlert.fromJson(Map<String, dynamic> json) {
    return AgrisensePriceAlert(
      id: json['id'],
      farmerId: json['farmer_id'],
      cropType: json['crop_type'],
      targetPrice: (json['target_price'] as num).toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmer_id': farmerId,
      'crop_type': cropType,
      'target_price': targetPrice,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
