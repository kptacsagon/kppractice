class AgrisenseFarm {
  final String? id;
  final String farmerId;
  final String? farmName;
  final String province;
  final String municipality;
  final String barangay;
  final String? sitio;
  final double totalAreaHectares;
  final String ownershipType;
  final String primaryCrop;
  final String? secondaryCrop;
  final String farmingMethod;
  final List<String> cropSeasonality;
  final double? expectedYieldKg;
  final int? harvestsPerYear;
  final String terrainType;
  final String? soilClassification;
  final String? soilNotes;
  final String irrigationType;
  final List<String> waterSources;
  final String? irrigationNotes;
  final double? distanceToMarketKm;
  final String? transportationAccess;
  final String? roadType;
  final int? travelTimeToMarketMin;
  final String floodProne;
  final String landslideRisk;
  final String droughtRisk;
  final String? vulnerabilityNotes;
  final double? centroidLat;
  final double? centroidLng;
  final String verificationStatus;
  final bool privacyConsentGiven;
  final DateTime? submittedAt;
  final String? rejectionReasonCode;
  final String? rejectionNote;

  AgrisenseFarm({
    this.id,
    required this.farmerId,
    this.farmName,
    this.province = 'Iloilo',
    this.municipality = 'Tubungan',
    required this.barangay,
    this.sitio,
    required this.totalAreaHectares,
    this.ownershipType = 'Owner',
    this.primaryCrop = '',
    this.secondaryCrop,
    this.farmingMethod = 'Conventional',
    this.cropSeasonality = const [],
    this.expectedYieldKg,
    this.harvestsPerYear,
    this.terrainType = 'Lowland',
    this.soilClassification,
    this.soilNotes,
    this.irrigationType = 'Rainfed',
    this.waterSources = const [],
    this.irrigationNotes,
    this.distanceToMarketKm,
    this.transportationAccess,
    this.roadType,
    this.travelTimeToMarketMin,
    this.floodProne = 'Unknown',
    this.landslideRisk = 'Unknown',
    this.droughtRisk = 'Unknown',
    this.vulnerabilityNotes,
    this.centroidLat,
    this.centroidLng,
    this.verificationStatus = 'Draft',
    this.privacyConsentGiven = false,
    this.submittedAt,
    this.rejectionReasonCode,
    this.rejectionNote,
  });

  factory AgrisenseFarm.fromJson(Map<String, dynamic> json) {
    return AgrisenseFarm(
      id: json['id'],
      farmerId: json['farmer_id'],
      farmName: json['farm_name'],
      province: json['province'] ?? 'Iloilo',
      municipality: json['municipality'] ?? 'Tubungan',
      barangay: json['barangay'] ?? '',
      sitio: json['sitio'],
      totalAreaHectares: (json['total_area_hectares'] as num?)?.toDouble() ?? 0,
      ownershipType: json['ownership_type'] ?? 'Owner',
      primaryCrop: json['primary_crop'] ?? '',
      secondaryCrop: json['secondary_crop'],
      farmingMethod: json['farming_method'] ?? 'Conventional',
      cropSeasonality: List<String>.from(json['crop_seasonality'] ?? []),
      expectedYieldKg: (json['expected_yield_kg'] as num?)?.toDouble(),
      harvestsPerYear: json['harvests_per_year'],
      terrainType: json['terrain_type'] ?? 'Lowland',
      soilClassification: json['soil_classification'],
      soilNotes: json['soil_notes'],
      irrigationType: json['irrigation_type'] ?? 'Rainfed',
      waterSources: List<String>.from(json['water_sources'] ?? []),
      irrigationNotes: json['irrigation_notes'],
      distanceToMarketKm: (json['distance_to_market_km'] as num?)?.toDouble(),
      transportationAccess: json['transportation_access'],
      roadType: json['road_type'],
      travelTimeToMarketMin: json['travel_time_to_market_min'],
      floodProne: json['flood_prone'] ?? 'Unknown',
      landslideRisk: json['landslide_risk'] ?? 'Unknown',
      droughtRisk: json['drought_risk'] ?? 'Unknown',
      vulnerabilityNotes: json['vulnerability_notes'],
      centroidLat: (json['centroid_lat'] as num?)?.toDouble(),
      centroidLng: (json['centroid_lng'] as num?)?.toDouble(),
      verificationStatus: json['verification_status'] ?? 'Draft',
      privacyConsentGiven: json['privacy_consent_given'] ?? false,
      submittedAt: json['submitted_at'] == null ? null : DateTime.parse(json['submitted_at']),
      rejectionReasonCode: json['rejection_reason_code'],
      rejectionNote: json['rejection_note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmer_id': farmerId,
      'farm_name': farmName,
      'province': province,
      'municipality': municipality,
      'barangay': barangay,
      'sitio': sitio,
      'total_area_hectares': totalAreaHectares,
      'ownership_type': ownershipType,
      'primary_crop': primaryCrop,
      'secondary_crop': secondaryCrop,
      'farming_method': farmingMethod,
      'crop_seasonality': cropSeasonality,
      'expected_yield_kg': expectedYieldKg,
      'harvests_per_year': harvestsPerYear,
      'terrain_type': terrainType,
      'soil_classification': soilClassification,
      'soil_notes': soilNotes,
      'irrigation_type': irrigationType,
      'water_sources': waterSources,
      'irrigation_notes': irrigationNotes,
      'distance_to_market_km': distanceToMarketKm,
      'transportation_access': transportationAccess,
      'road_type': roadType,
      'travel_time_to_market_min': travelTimeToMarketMin,
      'flood_prone': floodProne,
      'landslide_risk': landslideRisk,
      'drought_risk': droughtRisk,
      'vulnerability_notes': vulnerabilityNotes,
      'centroid_lat': centroidLat,
      'centroid_lng': centroidLng,
      'verification_status': verificationStatus,
      'privacy_consent_given': privacyConsentGiven,
      'submitted_at': submittedAt?.toIso8601String(),
    };
  }
}
