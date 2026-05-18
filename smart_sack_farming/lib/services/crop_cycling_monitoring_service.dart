import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crop_cycling_model.dart';

/// CropCyclingMonitoringService - Manages crop rotation tracking, soil health analysis,
/// and rotation recommendations for farmers
class CropCyclingMonitoringService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================================
  // FARMER FIELDS MANAGEMENT
  // ============================================================================

  /// Get all fields for a farmer
  Future<List<FarmerField>> getFarmerFields(String farmerId) async {
    try {
      final response = await _supabase
          .from('farmer_fields')
          .select()
          .eq('farmer_id', farmerId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List).map((field) => FarmerField.fromJson(field)).toList();
    } catch (e) {
      throw Exception('Failed to fetch farmer fields: $e');
    }
  }

  /// Get a specific field by ID
  Future<FarmerField> getFieldById(String fieldId) async {
    try {
      final response = await _supabase
          .from('farmer_fields')
          .select()
          .eq('id', fieldId)
          .single();

      return FarmerField.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch field: $e');
    }
  }

  /// Create a new farmer field
  Future<FarmerField> createField({
    required String farmerId,
    required String fieldName,
    required String locationMunicipality,
    String? locationBarangay,
    required double areaHectares,
    required String soilType,
    double? soilPh,
    String? irrigationType,
    int? elevationMeters,
  }) async {
    try {
      final now = DateTime.now();
      final response = await _supabase.from('farmer_fields').insert({
        'farmer_id': farmerId,
        'field_name': fieldName,
        'location_municipality': locationMunicipality,
        'location_barangay': locationBarangay,
        'area_hectares': areaHectares,
        'soil_type': soilType,
        'soil_ph': soilPh,
        'irrigation_type': irrigationType,
        'elevation_meters': elevationMeters,
        'is_active': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).select().single();

      return FarmerField.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create field: $e');
    }
  }

  /// Update an existing field
  Future<FarmerField> updateField(String fieldId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('farmer_fields')
          .update(updates)
          .eq('id', fieldId)
          .select()
          .single();

      return FarmerField.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update field: $e');
    }
  }

  // ============================================================================
  // CROP ROTATION HISTORY MANAGEMENT
  // ============================================================================

  /// Record a new crop planting
  Future<CropRotationHistory> recordCropPlanting({
    required String fieldId,
    required String farmerId,
    required String cropType,
    required DateTime plantingDate,
    double? areaPlantedHectares,
    String? status,
    bool diseaseObserved = false,
    String? diseaseNotes,
    bool pestObserved = false,
    String? pestNotes,
    String? soilObservations,
    String? inputNotes,
  }) async {
    try {
      final now = DateTime.now();
      final response = await _supabase.from('crop_rotation_history').insert({
        'field_id': fieldId,
        'farmer_id': farmerId,
        'crop_type': cropType,
        'planting_date': plantingDate.toIso8601String(),
        'area_planted_hectares': areaPlantedHectares,
        'status': status ?? 'active',
        'disease_observed': diseaseObserved,
        'disease_notes': diseaseNotes,
        'pest_observed': pestObserved,
        'pest_notes': pestNotes,
        'soil_observations': soilObservations,
        'input_notes': inputNotes,
        'recorded_by_farmer': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).select().single();

      return CropRotationHistory.fromJson(response);
    } catch (e) {
      throw Exception('Failed to record crop planting: $e');
    }
  }

  /// Get rotation history for a specific field
  Future<List<CropRotationHistory>> getFieldRotationHistory(String fieldId) async {
    try {
      final response = await _supabase
          .from('crop_rotation_history')
          .select()
          .eq('field_id', fieldId)
          .order('planting_date', ascending: false);

      return (response as List)
          .map((record) => CropRotationHistory.fromJson(record))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch rotation history: $e');
    }
  }

  /// Update harvest information for an active planting
  Future<CropRotationHistory> recordHarvest(
    String plantingId, {
    required DateTime harvestDate,
    double? yieldKg,
    String? soilObservations,
  }) async {
    try {
      final response = await _supabase
          .from('crop_rotation_history')
          .update({
            'harvest_date': harvestDate.toIso8601String(),
            'yield_kg': yieldKg,
            'soil_observations': soilObservations,
            'status': 'harvested',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', plantingId)
          .select()
          .single();

      return CropRotationHistory.fromJson(response);
    } catch (e) {
      throw Exception('Failed to record harvest: $e');
    }
  }

  /// Get active crops for a farmer (across all fields)
  Future<List<CropRotationHistory>> getActiveCrops(String farmerId) async {
    try {
      final response = await _supabase
          .from('crop_rotation_history')
          .select()
          .eq('farmer_id', farmerId)
          .eq('status', 'active')
          .order('planting_date', ascending: false);

      return (response as List)
          .map((record) => CropRotationHistory.fromJson(record))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active crops: $e');
    }
  }

  // ============================================================================
  // CROP CYCLING MONITORING & ANALYSIS
  // ============================================================================

  /// Get monitoring data for a specific field
  Future<CropCyclingMonitoring?> getFieldMonitoring(String fieldId) async {
    try {
      final response = await _supabase
          .from('crop_cycling_monitoring')
          .select()
          .eq('field_id', fieldId)
          .order('monitoring_date', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;
      return CropCyclingMonitoring.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to fetch monitoring data: $e');
    }
  }

  /// Get monitoring data for all farmer's fields
  Future<List<CropCyclingMonitoring>> getFarmerMonitoring(String farmerId) async {
    try {
      final response = await _supabase
          .from('crop_cycling_monitoring')
          .select()
          .eq('farmer_id', farmerId)
          .order('monitoring_date', ascending: false);

      return (response as List)
          .map((record) => CropCyclingMonitoring.fromJson(record))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch farmer monitoring: $e');
    }
  }

  /// Get critical risk fields (high urgency)
  Future<List<CropCyclingMonitoring>> getCriticalRiskFields(String farmerId) async {
    try {
      final response = await _supabase
          .from('crop_cycling_monitoring')
          .select()
          .eq('farmer_id', farmerId)
          .in_('urgency_level', ['high', 'critical'])
          .order('monitoring_date', ascending: false);

      return (response as List)
          .map((record) => CropCyclingMonitoring.fromJson(record))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch critical risk fields: $e');
    }
  }

  // ============================================================================
  // CROP COMPATIBILITY & RECOMMENDATIONS
  // ============================================================================

  /// Get recommended crop cycles for a soil type
  Future<List<RecommendedCropCycle>> getRecommendedCycles(String soilType) async {
    try {
      final response = await _supabase
          .from('recommended_crop_cycles')
          .select()
          .eq('soil_type', soilType)
          .order('recommended_order', ascending: true);

      return (response as List)
          .map((cycle) => RecommendedCropCycle.fromJson(cycle))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recommended cycles: $e');
    }
  }

  /// Get crop compatibility for rotation planning
  Future<CropCompatibility?> getCropCompatibility(
    String cropA,
    String cropB,
  ) async {
    try {
      final response = await _supabase
          .from('crop_compatibility')
          .select()
          .eq('crop_a', cropA)
          .eq('crop_b', cropB);

      if (response.isEmpty) return null;
      return CropCompatibility.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to fetch compatibility: $e');
    }
  }

  /// Get all compatible next crops for a given crop
  Future<List<CropCompatibility>> getCompatibleNextCrops(String currentCrop) async {
    try {
      final response = await _supabase
          .from('crop_compatibility')
          .select()
          .eq('crop_a', currentCrop)
          .eq('can_follow', true)
          .order('compatibility_score', ascending: false);

      return (response as List)
          .map((compat) => CropCompatibility.fromJson(compat))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch compatible crops: $e');
    }
  }

  /// Get crops that should NOT follow a given crop (incompatible)
  Future<List<String>> getIncompatibleCrops(String currentCrop) async {
    try {
      final response = await _supabase
          .from('crop_compatibility')
          .select('crop_b')
          .eq('crop_a', currentCrop)
          .eq('can_follow', false);

      return (response as List).map((record) => record['crop_b'] as String).toList();
    } catch (e) {
      throw Exception('Failed to fetch incompatible crops: $e');
    }
  }

  // ============================================================================
  // CROP CYCLING ALERTS
  // ============================================================================

  /// Get unread alerts for a farmer
  Future<List<CropCyclingAlert>> getUnreadAlerts(String farmerId) async {
    try {
      final response = await _supabase
          .from('crop_cycling_alerts')
          .select()
          .eq('farmer_id', farmerId)
          .eq('is_read', false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((alert) => CropCyclingAlert.fromJson(alert))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch alerts: $e');
    }
  }

  /// Get all alerts for a farmer (with optional filtering)
  Future<List<CropCyclingAlert>> getFarmerAlerts(
    String farmerId, {
    String? alertType,
    String? severity,
    bool? unreadOnly = false,
  }) async {
    try {
      var query = _supabase
          .from('crop_cycling_alerts')
          .select()
          .eq('farmer_id', farmerId);

      if (unreadOnly == true) {
        query = query.eq('is_read', false);
      }
      if (alertType != null) {
        query = query.eq('alert_type', alertType);
      }
      if (severity != null) {
        query = query.eq('severity', severity);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((alert) => CropCyclingAlert.fromJson(alert))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch farmer alerts: $e');
    }
  }

  /// Get alerts for a specific field
  Future<List<CropCyclingAlert>> getFieldAlerts(String fieldId) async {
    try {
      final response = await _supabase
          .from('crop_cycling_alerts')
          .select()
          .eq('field_id', fieldId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((alert) => CropCyclingAlert.fromJson(alert))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch field alerts: $e');
    }
  }

  /// Mark an alert as read
  Future<void> markAlertAsRead(String alertId) async {
    try {
      await _supabase
          .from('crop_cycling_alerts')
          .update({'is_read': true})
          .eq('id', alertId);
    } catch (e) {
      throw Exception('Failed to mark alert as read: $e');
    }
  }

  /// Record action taken on an alert
  Future<void> recordAlertAction(
    String alertId, {
    required String actionNotes,
  }) async {
    try {
      await _supabase.from('crop_cycling_alerts').update({
        'action_taken': true,
        'action_notes': actionNotes,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', alertId);
    } catch (e) {
      throw Exception('Failed to record alert action: $e');
    }
  }

  // ============================================================================
  // ANALYSIS & INSIGHTS
  // ============================================================================

  /// Get crop rotation history summary for a field
  Future<Map<String, dynamic>> getFieldRotationSummary(String fieldId) async {
    try {
      final history = await getFieldRotationHistory(fieldId);

      if (history.isEmpty) {
        return {
          'field_id': fieldId,
          'total_plantings': 0,
          'crops_planted': [],
          'current_crop': null,
          'last_harvest_date': null,
          'average_daysInField': 0,
        };
      }

      final cropsCount = <String, int>{};
      for (final record in history) {
        cropsCount[record.cropType] = (cropsCount[record.cropType] ?? 0) + 1;
      }

      final completedCrops =
          history.where((h) => h.harvestDate != null).toList();
      final avgDays = completedCrops.isEmpty
          ? 0
          : completedCrops
                  .map((h) => h.daysInField)
                  .reduce((a, b) => a + b) ~/
              completedCrops.length;

      return {
        'field_id': fieldId,
        'total_plantings': history.length,
        'crops_planted': cropsCount.keys.toList(),
        'crop_frequency': cropsCount,
        'current_crop': history.first.cropType,
        'current_crop_status': history.first.status,
        'last_harvest_date': history.firstWhere((h) => h.harvestDate != null, orElse: () => history.first).harvestDate,
        'average_daysInField': avgDays,
        'diseases_observed': history.where((h) => h.diseaseObserved).length,
        'pests_observed': history.where((h) => h.pestObserved).length,
      };
    } catch (e) {
      throw Exception('Failed to get rotation summary: $e');
    }
  }

  /// Get monoculture risk assessment for a field
  Future<Map<String, dynamic>> assessMonocultureRisk(String fieldId) async {
    try {
      final history = await getFieldRotationHistory(fieldId);
      if (history.isEmpty) {
        return {'risk_level': 'low', 'consecutive_same_crop': 0};
      }

      final currentCrop = history.first.cropType;
      int consecutiveCount = 0;

      for (final record in history) {
        if (record.cropType == currentCrop) {
          consecutiveCount++;
        } else {
          break;
        }
      }

      String riskLevel;
      if (consecutiveCount > 2) {
        riskLevel = 'critical';
      } else if (consecutiveCount > 1) {
        riskLevel = 'high';
      } else if (consecutiveCount == 1) {
        riskLevel = 'medium';
      } else {
        riskLevel = 'low';
      }

      return {
        'field_id': fieldId,
        'current_crop': currentCrop,
        'consecutive_same_crop': consecutiveCount,
        'risk_level': riskLevel,
        'recommendation': _getMonocultureRecommendation(consecutiveCount, currentCrop),
      };
    } catch (e) {
      throw Exception('Failed to assess monoculture risk: $e');
    }
  }

  /// Get legume planting history
  Future<Map<String, dynamic>> getLegumePlantingStatus(String fieldId) async {
    try {
      final history = await getFieldRotationHistory(fieldId);
      final legumeCrops = ['Mungbean', 'Peanut', 'Cowpea', 'Soybean'];

      final lastLegume = history.firstWhere(
        (h) => legumeCrops.contains(h.cropType),
        orElse: () => history.first,
      );

      final yearsSinceLegume = lastLegume.cropType == 'Tomato'
          ? 999.0
          : DateTime.now().difference(lastLegume.plantingDate).inDays / 365.25;

      return {
        'field_id': fieldId,
        'last_legume_crop': lastLegume.cropType,
        'last_legume_date': lastLegume.plantingDate,
        'years_since_legume': yearsSinceLegume,
        'is_overdue': yearsSinceLegume > 2,
        'recommendation':
            yearsSinceLegume > 2
                ? 'Plant a legume crop soon to restore nitrogen'
                : 'Legume crop timing is good',
      };
    } catch (e) {
      throw Exception('Failed to get legume planting status: $e');
    }
  }

  String _getMonocultureRecommendation(int consecutiveCount, String crop) {
    if (consecutiveCount > 2) {
      return 'CRITICAL: Rotate crops immediately. $crop monoculture causes soil depletion and pest buildup.';
    } else if (consecutiveCount > 1) {
      return 'HIGH RISK: Plan to rotate $crop to a different crop next season to avoid soil fatigue.';
    } else {
      return 'Monitor crop health. Consider diversifying in future plantings.';
    }
  }

  /// Get soil health trend for a field (disease/pest observations)
  Future<Map<String, dynamic>> getSoilHealthTrend(String fieldId) async {
    try {
      final history = await getFieldRotationHistory(fieldId);

      final diseaseRecords = history.where((h) => h.diseaseObserved).toList();
      final pestRecords = history.where((h) => h.pestObserved).toList();

      return {
        'field_id': fieldId,
        'total_records': history.length,
        'disease_observations': diseaseRecords.length,
        'disease_rate': history.isEmpty ? 0.0 : (diseaseRecords.length / history.length),
        'pest_observations': pestRecords.length,
        'pest_rate': history.isEmpty ? 0.0 : (pestRecords.length / history.length),
        'health_status': _calculateHealthStatus(diseaseRecords.length, pestRecords.length, history.length),
      };
    } catch (e) {
      throw Exception('Failed to get soil health trend: $e');
    }
  }

  String _calculateHealthStatus(int diseases, int pests, int total) {
    if (total == 0) return 'no_data';
    final rate = ((diseases + pests) / total);
    if (rate > 0.5) return 'poor';
    if (rate > 0.25) return 'fair';
    return 'good';
  }
}
