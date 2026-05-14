class AgrisenseSeasonalCrop {
  final String? id;
  final String farmId;
  final String? farmerId;
  final String seasonName;
  final String cropType;
  final String? seedVariety;
  final DateTime plantingDate;
  final DateTime expectedHarvestDate;
  final double plannedPlantingAreaHa;
  final double estimatedYieldKg;
  final String? targetMarket;
  final String status;

  AgrisenseSeasonalCrop({
    this.id,
    required this.farmId,
    this.farmerId,
    required this.seasonName,
    required this.cropType,
    this.seedVariety,
    required this.plantingDate,
    required this.expectedHarvestDate,
    required this.plannedPlantingAreaHa,
    required this.estimatedYieldKg,
    this.targetMarket,
    this.status = 'Draft',
  });

  factory AgrisenseSeasonalCrop.fromJson(Map<String, dynamic> json) {
    return AgrisenseSeasonalCrop(
      id: json['id'],
      farmId: json['farm_id'],
      farmerId: json['farmer_id'],
      seasonName: json['season_name'],
      cropType: json['crop_type'],
      seedVariety: json['seed_variety'],
      plantingDate: DateTime.parse(json['planting_date']),
      expectedHarvestDate: DateTime.parse(json['expected_harvest_date']),
      plannedPlantingAreaHa: (json['planned_planting_area_ha'] as num).toDouble(),
      estimatedYieldKg: (json['estimated_yield_kg'] as num).toDouble(),
      targetMarket: json['target_market'],
      status: json['status'] ?? 'Draft',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farm_id': farmId,
      'farmer_id': farmerId,
      'season_name': seasonName,
      'crop_type': cropType,
      'seed_variety': seedVariety,
      'planting_date': plantingDate.toIso8601String().split('T')[0],
      'expected_harvest_date': expectedHarvestDate.toIso8601String().split('T')[0],
      'planned_planting_area_ha': plannedPlantingAreaHa,
      'estimated_yield_kg': estimatedYieldKg,
      'target_market': targetMarket,
      'status': status,
    };
  }
}
