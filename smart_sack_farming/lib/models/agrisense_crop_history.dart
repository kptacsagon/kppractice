class AgrisenseCropHistory {
  final String? id;
  final String farmerId;
  final String seasonName;
  final String cropType;
  final double areaHa;
  final double yieldKg;
  final DateTime? plantingDate;
  final DateTime? harvestDate;

  AgrisenseCropHistory({
    this.id,
    required this.farmerId,
    required this.seasonName,
    required this.cropType,
    required this.areaHa,
    required this.yieldKg,
    this.plantingDate,
    this.harvestDate,
  });

  factory AgrisenseCropHistory.fromJson(Map<String, dynamic> json) {
    return AgrisenseCropHistory(
      id: json['id'],
      farmerId: json['farmer_id'],
      seasonName: json['season_name'],
      cropType: json['crop_type'],
      areaHa: (json['area_ha'] as num).toDouble(),
      yieldKg: (json['yield_kg'] as num).toDouble(),
      plantingDate: json['planting_date'] == null
          ? null
          : DateTime.parse(json['planting_date']),
      harvestDate: json['harvest_date'] == null
          ? null
          : DateTime.parse(json['harvest_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmer_id': farmerId,
      'season_name': seasonName,
      'crop_type': cropType,
      'area_ha': areaHa,
      'yield_kg': yieldKg,
      'planting_date': plantingDate?.toIso8601String().split('T')[0],
      'harvest_date': harvestDate?.toIso8601String().split('T')[0],
    };
  }
}
