import 'crop.dart';

enum PlantingStatus { growing, harvesting, completed }

extension PlantingStatusExt on PlantingStatus {
  String get name {
    switch (this) {
      case PlantingStatus.growing:
        return 'Growing';
      case PlantingStatus.harvesting:
        return 'Harvesting';
      case PlantingStatus.completed:
        return 'Completed';
    }
  }

  static PlantingStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'growing':
        return PlantingStatus.growing;
      case 'harvesting':
        return PlantingStatus.harvesting;
      case 'completed':
        return PlantingStatus.completed;
      default:
        throw ArgumentError('Unknown planting status: $s');
    }
  }
}

class PlantingRecord {
  final String id;
  final String farmerId;
  final CropName cropName;
  final double areaPlantedHa;
  final double estimatedYieldMt;
  final DateTime plantingDate;
  final DateTime expectedHarvestDate;
  final PlantingStatus status;

  PlantingRecord({
    required this.id,
    required this.farmerId,
    required this.cropName,
    required this.areaPlantedHa,
    required this.estimatedYieldMt,
    required this.plantingDate,
    required this.expectedHarvestDate,
    required this.status,
  });

  factory PlantingRecord.fromJson(Map<String, dynamic> json) {
    return PlantingRecord(
      id: json['id'] as String,
      farmerId: json['farmer_id'] as String,
      cropName: CropNameExt.fromString(json['crop_name'] as String),
      areaPlantedHa: (json['area_planted_ha'] as num).toDouble(),
      estimatedYieldMt: (json['estimated_yield_mt'] as num).toDouble(),
      plantingDate: DateTime.parse(json['planting_date'] as String),
      expectedHarvestDate: DateTime.parse(json['expected_harvest_date'] as String),
      status: PlantingStatusExt.fromString(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'crop_name': cropName.toJson(),
      'area_planted_ha': areaPlantedHa,
      'estimated_yield_mt': estimatedYieldMt,
      'planting_date': plantingDate.toIso8601String(),
      'expected_harvest_date': expectedHarvestDate.toIso8601String(),
      'status': status.name,
    };
  }
}
