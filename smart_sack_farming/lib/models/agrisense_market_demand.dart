class AgrisenseMarketDemand {
  final String? id;
  final String municipality;
  final String cropType;
  final String seasonName;
  final double projectedDemandKg;
  final String confidenceScore;
  final String? dataSource;
  final DateTime recordedDate;

  AgrisenseMarketDemand({
    this.id,
    required this.municipality,
    required this.cropType,
    required this.seasonName,
    required this.projectedDemandKg,
    this.confidenceScore = 'Medium',
    this.dataSource,
    required this.recordedDate,
  });

  factory AgrisenseMarketDemand.fromJson(Map<String, dynamic> json) {
    return AgrisenseMarketDemand(
      id: json['id'],
      municipality: json['municipality'],
      cropType: json['crop_type'],
      seasonName: json['season_name'],
      projectedDemandKg: (json['projected_demand_kg'] as num).toDouble(),
      confidenceScore: json['confidence_score'] ?? 'Medium',
      dataSource: json['data_source'],
      recordedDate: DateTime.parse(json['recorded_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'municipality': municipality,
      'crop_type': cropType,
      'season_name': seasonName,
      'projected_demand_kg': projectedDemandKg,
      'confidence_score': confidenceScore,
      'data_source': dataSource,
      'recorded_date': recordedDate.toIso8601String().split('T')[0],
    };
  }
}
