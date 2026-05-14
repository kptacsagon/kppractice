class AgrisenseCropRecommendation {
  final String? id;
  final String farmerId;
  final String farmId;
  final String recommendedCrop;
  final double recommendationScore;
  final String category;
  final Map<String, dynamic>? factors;

  AgrisenseCropRecommendation({
    this.id,
    required this.farmerId,
    required this.farmId,
    required this.recommendedCrop,
    required this.recommendationScore,
    required this.category,
    this.factors,
  });

  factory AgrisenseCropRecommendation.fromJson(Map<String, dynamic> json) {
    return AgrisenseCropRecommendation(
      id: json['id'],
      farmerId: json['farmer_id'],
      farmId: json['farm_id'],
      recommendedCrop: json['recommended_crop'],
      recommendationScore: (json['recommendation_score'] as num).toDouble(),
      category: json['category'],
      factors: json['factors'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmer_id': farmerId,
      'farm_id': farmId,
      'recommended_crop': recommendedCrop,
      'recommendation_score': recommendationScore,
      'category': category,
      'factors': factors,
    };
  }
}
