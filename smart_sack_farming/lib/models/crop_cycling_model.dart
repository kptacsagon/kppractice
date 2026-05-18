import 'package:intl/intl.dart';

/// Represents a farmer's field or plot for crop cycling monitoring
class FarmerField {
  final String id;
  final String farmerId;
  final String fieldName;
  final String locationMunicipality;
  final String? locationBarangay;
  final double areaHectares;
  final String soilType;
  final double? soilPh;
  final String? irrigationType;
  final int? elevationMeters;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  FarmerField({
    required this.id,
    required this.farmerId,
    required this.fieldName,
    required this.locationMunicipality,
    this.locationBarangay,
    required this.areaHectares,
    required this.soilType,
    this.soilPh,
    this.irrigationType,
    this.elevationMeters,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FarmerField.fromJson(Map<String, dynamic> json) {
    return FarmerField(
      id: json['id'] as String,
      farmerId: json['farmer_id'] as String,
      fieldName: json['field_name'] as String,
      locationMunicipality: json['location_municipality'] as String,
      locationBarangay: json['location_barangay'] as String?,
      areaHectares: (json['area_hectares'] as num).toDouble(),
      soilType: json['soil_type'] as String,
      soilPh: json['soil_ph'] != null ? (json['soil_ph'] as num).toDouble() : null,
      irrigationType: json['irrigation_type'] as String?,
      elevationMeters: json['elevation_meters'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'field_name': fieldName,
      'location_municipality': locationMunicipality,
      'location_barangay': locationBarangay,
      'area_hectares': areaHectares,
      'soil_type': soilType,
      'soil_ph': soilPh,
      'irrigation_type': irrigationType,
      'elevation_meters': elevationMeters,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'FarmerField($fieldName, $areaHectares ha, $soilType soil, $locationMunicipality)';
}

/// Represents a single crop planting in rotation history
class CropRotationHistory {
  final String id;
  final String fieldId;
  final String farmerId;
  final String cropType;
  final DateTime plantingDate;
  final DateTime? harvestDate;
  final double? areaPlantedHectares;
  final double? yieldKg;
  final String status; // 'active', 'harvested', 'abandoned'
  final bool diseaseObserved;
  final String? diseaseNotes;
  final bool pestObserved;
  final String? pestNotes;
  final String? soilObservations;
  final String? inputNotes;
  final bool recordedByFarmer;
  final DateTime createdAt;
  final DateTime updatedAt;

  CropRotationHistory({
    required this.id,
    required this.fieldId,
    required this.farmerId,
    required this.cropType,
    required this.plantingDate,
    this.harvestDate,
    this.areaPlantedHectares,
    this.yieldKg,
    this.status = 'active',
    this.diseaseObserved = false,
    this.diseaseNotes,
    this.pestObserved = false,
    this.pestNotes,
    this.soilObservations,
    this.inputNotes,
    this.recordedByFarmer = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CropRotationHistory.fromJson(Map<String, dynamic> json) {
    return CropRotationHistory(
      id: json['id'] as String,
      fieldId: json['field_id'] as String,
      farmerId: json['farmer_id'] as String,
      cropType: json['crop_type'] as String,
      plantingDate: DateTime.parse(json['planting_date'] as String),
      harvestDate: json['harvest_date'] != null ? DateTime.parse(json['harvest_date'] as String) : null,
      areaPlantedHectares:
          json['area_planted_hectares'] != null ? (json['area_planted_hectares'] as num).toDouble() : null,
      yieldKg: json['yield_kg'] != null ? (json['yield_kg'] as num).toDouble() : null,
      status: json['status'] as String? ?? 'active',
      diseaseObserved: json['disease_observed'] as bool? ?? false,
      diseaseNotes: json['disease_notes'] as String?,
      pestObserved: json['pest_observed'] as bool? ?? false,
      pestNotes: json['pest_notes'] as String?,
      soilObservations: json['soil_observations'] as String?,
      inputNotes: json['input_notes'] as String?,
      recordedByFarmer: json['recorded_by_farmer'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field_id': fieldId,
      'farmer_id': farmerId,
      'crop_type': cropType,
      'planting_date': plantingDate.toIso8601String(),
      'harvest_date': harvestDate?.toIso8601String(),
      'area_planted_hectares': areaPlantedHectares,
      'yield_kg': yieldKg,
      'status': status,
      'disease_observed': diseaseObserved,
      'disease_notes': diseaseNotes,
      'pest_observed': pestObserved,
      'pest_notes': pestNotes,
      'soil_observations': soilObservations,
      'input_notes': inputNotes,
      'recorded_by_farmer': recordedByFarmer,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int get daysInField {
    final endDate = harvestDate ?? DateTime.now();
    return endDate.difference(plantingDate).inDays;
  }

  bool get isActive => status == 'active';

  @override
  String toString() =>
      'CropRotationHistory($cropType from ${DateFormat('MMM d, y').format(plantingDate)}, $fieldId)';
}

/// Represents a recommended crop rotation cycle
class RecommendedCropCycle {
  final String id;
  final String soilType;
  final String cycleName;
  final String? cycleDescription;
  final List<String> cropsInCycle;
  final int cycleDurationMonths;
  final String? soilHealthBenefit;
  final String? pestDiseaseMitigation;
  final bool nitrogenFixation;
  final int recommendedOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecommendedCropCycle({
    required this.id,
    required this.soilType,
    required this.cycleName,
    this.cycleDescription,
    required this.cropsInCycle,
    required this.cycleDurationMonths,
    this.soilHealthBenefit,
    this.pestDiseaseMitigation,
    this.nitrogenFixation = false,
    this.recommendedOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecommendedCropCycle.fromJson(Map<String, dynamic> json) {
    return RecommendedCropCycle(
      id: json['id'] as String,
      soilType: json['soil_type'] as String,
      cycleName: json['cycle_name'] as String,
      cycleDescription: json['cycle_description'] as String?,
      cropsInCycle: List<String>.from(json['crops_in_cycle'] as List),
      cycleDurationMonths: json['cycle_duration_months'] as int,
      soilHealthBenefit: json['soil_health_benefit'] as String?,
      pestDiseaseMitigation: json['pest_disease_mitigation'] as String?,
      nitrogenFixation: json['nitrogen_fixation'] as bool? ?? false,
      recommendedOrder: json['recommended_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'soil_type': soilType,
      'cycle_name': cycleName,
      'cycle_description': cycleDescription,
      'crops_in_cycle': cropsInCycle,
      'cycle_duration_months': cycleDurationMonths,
      'soil_health_benefit': soilHealthBenefit,
      'pest_disease_mitigation': pestDiseaseMitigation,
      'nitrogen_fixation': nitrogenFixation,
      'recommended_order': recommendedOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'RecommendedCropCycle($cycleName - ${cropsInCycle.join(" → ")}, $cycleDurationMonths months)';
}

/// Represents crop cycling monitoring analysis for a field
class CropCyclingMonitoring {
  final String id;
  final String fieldId;
  final String farmerId;
  final DateTime monitoringDate;
  final bool? isFollowingRecommendedCycle;
  final String? recommendedCycleId;
  final String? recommendedNextCrop;
  final int? daysUntilNextPlanting;
  final String soilFatigueRisk; // 'low', 'medium', 'high'
  final int consecutiveSameCrop;
  final double yearsSinceLegumeCrop;
  final String diseasePressureLevel; // 'low', 'medium', 'high'
  final String pestPressureLevel; // 'low', 'medium', 'high'
  final double monocultureRiskScore; // 0-100
  final String? recommendedAction;
  final String urgencyLevel; // 'low', 'medium', 'high', 'critical'
  final DateTime createdAt;
  final DateTime updatedAt;

  CropCyclingMonitoring({
    required this.id,
    required this.fieldId,
    required this.farmerId,
    required this.monitoringDate,
    this.isFollowingRecommendedCycle,
    this.recommendedCycleId,
    this.recommendedNextCrop,
    this.daysUntilNextPlanting,
    required this.soilFatigueRisk,
    this.consecutiveSameCrop = 0,
    this.yearsSinceLegumeCrop = 0.0,
    required this.diseasePressureLevel,
    required this.pestPressureLevel,
    this.monocultureRiskScore = 0.0,
    this.recommendedAction,
    required this.urgencyLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CropCyclingMonitoring.fromJson(Map<String, dynamic> json) {
    return CropCyclingMonitoring(
      id: json['id'] as String,
      fieldId: json['field_id'] as String,
      farmerId: json['farmer_id'] as String,
      monitoringDate: DateTime.parse(json['monitoring_date'] as String),
      isFollowingRecommendedCycle: json['is_following_recommended_cycle'] as bool?,
      recommendedCycleId: json['recommended_cycle_id'] as String?,
      recommendedNextCrop: json['recommended_next_crop'] as String?,
      daysUntilNextPlanting: json['days_until_next_planting'] as int?,
      soilFatigueRisk: json['soil_fatigue_risk'] as String,
      consecutiveSameCrop: json['consecutive_same_crop'] as int? ?? 0,
      yearsSinceLegumeCrop: (json['years_since_legume_crop'] as num?)?.toDouble() ?? 0.0,
      diseasePressureLevel: json['disease_pressure_level'] as String,
      pestPressureLevel: json['pest_pressure_level'] as String,
      monocultureRiskScore: (json['monoculture_risk_score'] as num?)?.toDouble() ?? 0.0,
      recommendedAction: json['recommended_action'] as String?,
      urgencyLevel: json['urgency_level'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field_id': fieldId,
      'farmer_id': farmerId,
      'monitoring_date': monitoringDate.toIso8601String(),
      'is_following_recommended_cycle': isFollowingRecommendedCycle,
      'recommended_cycle_id': recommendedCycleId,
      'recommended_next_crop': recommendedNextCrop,
      'days_until_next_planting': daysUntilNextPlanting,
      'soil_fatigue_risk': soilFatigueRisk,
      'consecutive_same_crop': consecutiveSameCrop,
      'years_since_legume_crop': yearsSinceLegumeCrop,
      'disease_pressure_level': diseasePressureLevel,
      'pest_pressure_level': pestPressureLevel,
      'monoculture_risk_score': monocultureRiskScore,
      'recommended_action': recommendedAction,
      'urgency_level': urgencyLevel,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isRiskHigh => soilFatigueRisk == 'high' || diseasePressureLevel == 'high';

  String get statusEmoji {
    if (urgencyLevel == 'critical') return '🔴';
    if (urgencyLevel == 'high') return '🟠';
    if (urgencyLevel == 'medium') return '🟡';
    return '🟢';
  }

  @override
  String toString() =>
      'CropCyclingMonitoring(Risk: $soilFatigueRisk, Urgency: $urgencyLevel, Score: $monocultureRiskScore)';
}

/// Represents a crop cycling alert for a farmer
class CropCyclingAlert {
  final String id;
  final String farmerId;
  final String fieldId;
  final String alertType; // 'monoculture_risk', 'disease_pressure', 'soil_fatigue', 'legume_overdue'
  final String alertTitle;
  final String alertMessage;
  final String? recommendedAction;
  final String severity; // 'low', 'medium', 'high', 'critical'
  final bool isRead;
  final bool actionTaken;
  final String? actionNotes;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  CropCyclingAlert({
    required this.id,
    required this.farmerId,
    required this.fieldId,
    required this.alertType,
    required this.alertTitle,
    required this.alertMessage,
    this.recommendedAction,
    required this.severity,
    this.isRead = false,
    this.actionTaken = false,
    this.actionNotes,
    required this.createdAt,
    this.resolvedAt,
  });

  factory CropCyclingAlert.fromJson(Map<String, dynamic> json) {
    return CropCyclingAlert(
      id: json['id'] as String,
      farmerId: json['farmer_id'] as String,
      fieldId: json['field_id'] as String,
      alertType: json['alert_type'] as String,
      alertTitle: json['alert_title'] as String,
      alertMessage: json['alert_message'] as String,
      recommendedAction: json['recommended_action'] as String?,
      severity: json['severity'] as String,
      isRead: json['is_read'] as bool? ?? false,
      actionTaken: json['action_taken'] as bool? ?? false,
      actionNotes: json['action_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'field_id': fieldId,
      'alert_type': alertType,
      'alert_title': alertTitle,
      'alert_message': alertMessage,
      'recommended_action': recommendedAction,
      'severity': severity,
      'is_read': isRead,
      'action_taken': actionTaken,
      'action_notes': actionNotes,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  String get severityEmoji {
    if (severity == 'critical') return '🔴';
    if (severity == 'high') return '🟠';
    if (severity == 'medium') return '🟡';
    return '🟢';
  }

  @override
  String toString() => 'CropCyclingAlert($alertTitle - $severity)';
}

/// Represents crop compatibility for rotation planning
class CropCompatibility {
  final String id;
  final String cropA;
  final String cropB;
  final double? compatibilityScore; // 0-1 (1 = excellent)
  final String? reason;
  final bool canFollow;
  final String? notes;

  CropCompatibility({
    required this.id,
    required this.cropA,
    required this.cropB,
    this.compatibilityScore,
    this.reason,
    this.canFollow = true,
    this.notes,
  });

  factory CropCompatibility.fromJson(Map<String, dynamic> json) {
    return CropCompatibility(
      id: json['id'] as String,
      cropA: json['crop_a'] as String,
      cropB: json['crop_b'] as String,
      compatibilityScore: json['compatibility_score'] != null ? (json['compatibility_score'] as num).toDouble() : null,
      reason: json['reason'] as String?,
      canFollow: json['can_follow'] as bool? ?? true,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crop_a': cropA,
      'crop_b': cropB,
      'compatibility_score': compatibilityScore,
      'reason': reason,
      'can_follow': canFollow,
      'notes': notes,
    };
  }

  String get qualityLabel {
    if (compatibilityScore == null) return 'Unknown';
    if (compatibilityScore! >= 0.9) return 'Excellent';
    if (compatibilityScore! >= 0.7) return 'Good';
    if (compatibilityScore! >= 0.5) return 'Fair';
    return 'Poor';
  }

  @override
  String toString() => 'CropCompatibility($cropA → $cropB: ${qualityLabel} (${(compatibilityScore ?? 0 * 100).toStringAsFixed(0)}%))';
}
