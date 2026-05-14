class AgrisenseFarm {
  final String? id;
  final String farmerId;
  final String? farmName;
  final String barangay;
  final String municipality;
  final double totalAreaHectares;
  final String? soilClassification;
  final String? irrigationClassification;

  AgrisenseFarm({
    this.id,
    required this.farmerId,
    this.farmName,
    required this.barangay,
    required this.municipality,
    required this.totalAreaHectares,
    this.soilClassification,
    this.irrigationClassification,
  });

  factory AgrisenseFarm.fromJson(Map<String, dynamic> json) {
    return AgrisenseFarm(
      id: json['id'],
      farmerId: json['farmer_id'],
      farmName: json['farm_name'],
      barangay: json['barangay'],
      municipality: json['municipality'],
      totalAreaHectares: (json['total_area_hectares'] as num).toDouble(),
      soilClassification: json['soil_classification'],
      irrigationClassification: json['irrigation_classification'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmer_id': farmerId,
      'farm_name': farmName,
      'barangay': barangay,
      'municipality': municipality,
      'total_area_hectares': totalAreaHectares,
      'soil_classification': soilClassification,
      'irrigation_classification': irrigationClassification,
    };
  }
}
