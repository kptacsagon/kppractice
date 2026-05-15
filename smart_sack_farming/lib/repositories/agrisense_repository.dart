import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agrisense_alert.dart';
import '../models/agrisense_crop_history.dart';
import '../models/agrisense_farmer_profile.dart';
import '../models/agrisense_farm.dart';
import '../models/agrisense_pest_report.dart';
import '../models/agrisense_price_alert.dart';
import '../models/agrisense_program_enrollment.dart';
import '../models/agrisense_saturation_score.dart';
import '../models/agrisense_seasonal_crop.dart';

class AgrisenseRepository {
  final SupabaseClient _supabase;

  AgrisenseRepository(this._supabase);

  // --- Farmer Profiles ---

  Future<void> saveFarmerProfile(AgrisenseFarmerProfile profile) async {
    final payload = profile.toJson();
    debugPrint('[AgrisenseRepo] saveFarmerProfile payload keys: ${payload.keys.toList()}');

    // Check whether a row already exists for this user.
    final existing = await _supabase
        .from('agrisense_farmer_profiles')
        .select('id')
        .eq('user_id', profile.userId)
        .maybeSingle();

    if (existing != null) {
      // Row exists — update it using the primary key.
      await _supabase
          .from('agrisense_farmer_profiles')
          .update(payload)
          .eq('user_id', profile.userId);
    } else {
      // No row yet — insert a new one.
      await _supabase
          .from('agrisense_farmer_profiles')
          .insert(payload);
    }
  }

  Future<AgrisenseFarmerProfile?> getFarmerProfile(String userId) async {
    final response = await _supabase
        .from('agrisense_farmer_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      return AgrisenseFarmerProfile.fromJson(response);
    }
    return null;
  }

  // --- Farms ---

  /// Returns the agrisense_farmer_profiles.id (DB UUID) for the given auth user.
  /// Returns null if no profile exists — caller must handle this case.
  Future<String?> getFarmerProfileId(String authUserId) async {
    final response = await _supabase
        .from('agrisense_farmer_profiles')
        .select('id')
        .eq('user_id', authUserId)
        .maybeSingle();
    return response?['id'] as String?;
  }

  /// Creates a minimal farmer profile for the given auth user if one doesn't exist,
  /// then returns the agrisense_farmer_profiles.id. This ensures the FK reference
  /// in agrisense_farms.farmer_id is always valid before any farm insert.
  Future<String> ensureFarmerProfileAndGetId(String authUserId) async {
    // First try to find existing profile
    final existingId = await getFarmerProfileId(authUserId);
    if (existingId != null) return existingId;

    // No profile — create a minimal stub so farm FK is satisfied.
    // The farmer completes their profile separately via the registration screen.
    final inserted = await _supabase
        .from('agrisense_farmer_profiles')
        .insert({
          'user_id': authUserId,
          'full_name': 'Pending Registration',
          'barangay': 'Tubungan',
          'municipality': 'Tubungan',
          'province': 'Iloilo',
          'verification_status': 'Pending',
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }

  Future<void> saveFarm(AgrisenseFarm farm) async {
    // Validate that we have a real profile UUID before touching the DB.
    // Passing auth.uid() here would violate the FK constraint.
    if (farm.farmerId.isEmpty || farm.farmerId == 'unknown') {
      throw Exception('Cannot save farm: farmer profile ID is missing. '
          'Complete AgriSense Registration first.');
    }

    // Try the full extended schema first.
    try {
      await _supabase.from('agrisense_farms').insert(farm.toJson());
      return;
    } on PostgrestException catch (e) {
      // If it's a FK violation, re-throw immediately — retrying won't help.
      if (e.code == '23503') rethrow;
      // If it's a column-not-found error (42703), fall through to base-column save.
      if (e.code != '42703') rethrow;
    }

    // Fallback: DB hasn't had the schema migration applied yet.
    // Only send the original columns that are guaranteed to exist.
    await _supabase.from('agrisense_farms').insert({
      'farmer_id': farm.farmerId,
      'farm_name': farm.farmName,
      'barangay': farm.barangay,
      'municipality': farm.municipality,
      'total_area_hectares': farm.totalAreaHectares,
      'soil_classification': farm.soilClassification,
      'irrigation_classification': farm.irrigationType,
    });
  }

  Future<List<AgrisenseFarm>> getFarmsByFarmer(String farmerId) async {
    final response = await _supabase
        .from('agrisense_farms')
        .select()
        .eq('farmer_id', farmerId);

    return (response as List).map((json) => AgrisenseFarm.fromJson(json)).toList();
  }

  // --- Seasonal Crops ---

  Future<void> submitSeasonalCrop(AgrisenseSeasonalCrop crop) async {
    await _supabase
        .from('agrisense_seasonal_crops')
        .insert(crop.toJson());
  }

  Future<List<AgrisenseSeasonalCrop>> getSeasonalCrops(String farmId) async {
    final response = await _supabase
        .from('agrisense_seasonal_crops')
        .select()
        .eq('farm_id', farmId);

    return (response as List).map((json) => AgrisenseSeasonalCrop.fromJson(json)).toList();
  }

  // --- Crop History ---

  Future<void> saveCropHistory(AgrisenseCropHistory history) async {
    await _supabase
        .from('agrisense_crop_histories')
        .insert(history.toJson());
  }

  Future<List<AgrisenseCropHistory>> getCropHistory(String farmerId) async {
    final response = await _supabase
        .from('agrisense_crop_histories')
        .select()
        .eq('farmer_id', farmerId)
        .order('harvest_date', ascending: false);

    return (response as List)
        .map((json) => AgrisenseCropHistory.fromJson(json))
        .toList();
  }

  // --- Program Enrollments ---

  Future<void> saveProgramEnrollment(AgrisenseProgramEnrollment enrollment) async {
    await _supabase
        .from('agrisense_program_enrollments')
        .insert(enrollment.toJson());
  }

  Future<List<AgrisenseProgramEnrollment>> getProgramEnrollments(String farmerId) async {
    final response = await _supabase
        .from('agrisense_program_enrollments')
        .select()
        .eq('farmer_id', farmerId)
        .order('enrolled_date', ascending: false);

    return (response as List)
        .map((json) => AgrisenseProgramEnrollment.fromJson(json))
        .toList();
  }

  // --- Alerts ---

  Future<void> saveAlert(AgrisenseAlert alert) async {
    await _supabase
        .from('agrisense_alerts')
        .insert(alert.toJson());
  }

  Future<List<AgrisenseAlert>> getAlerts(String farmerId) async {
    final response = await _supabase
        .from('agrisense_alerts')
        .select()
        .eq('farmer_id', farmerId)
        .order('triggered_at', ascending: false);

    return (response as List)
        .map((json) => AgrisenseAlert.fromJson(json))
        .toList();
  }

  Future<void> markAlertRead(String alertId) async {
    await _supabase
        .from('agrisense_alerts')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', alertId);
  }

  // --- Saturation Scores ---

  Future<List<AgrisenseSaturationScore>> getSaturationScores(
    String municipality,
    String seasonName,
  ) async {
    final response = await _supabase
        .from('agrisense_saturation_scores')
        .select()
        .eq('municipality', municipality)
        .eq('season_name', seasonName);

    return (response as List)
        .map((json) => AgrisenseSaturationScore.fromJson(json))
        .toList();
  }

  // --- Pest Reports ---

  Future<void> submitPestReport(AgrisensePestReport report) async {
    await _supabase
        .from('agrisense_pest_reports')
        .insert(report.toJson());
  }

  Future<List<AgrisensePestReport>> getPestReports(String municipality) async {
    final response = await _supabase
        .from('agrisense_pest_reports')
        .select()
        .eq('municipality', municipality)
        .order('reported_at', ascending: false);

    return (response as List)
        .map((json) => AgrisensePestReport.fromJson(json))
        .toList();
  }

  // --- Price Alerts ---

  Future<void> savePriceAlert(AgrisensePriceAlert alert) async {
    await _supabase
        .from('agrisense_price_alerts')
        .insert(alert.toJson());
  }

  Future<List<AgrisensePriceAlert>> getPriceAlerts(String farmerId) async {
    final response = await _supabase
        .from('agrisense_price_alerts')
        .select()
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => AgrisensePriceAlert.fromJson(json))
        .toList();
  }

  // --- Saturation Intelligence (Basic) ---
  
  Future<double> calculateMunicipalSaturation(String municipality, String cropType, String seasonName) async {
    final response = await _supabase
        .from('agrisense_seasonal_crops')
        .select('estimated_yield_kg, agrisense_farms!inner(municipality)')
        .eq('status', 'Active Planting')
        .eq('crop_type', cropType)
        .eq('season_name', seasonName)
        .eq('agrisense_farms.municipality', municipality);

    double totalProjectedYield = 0;
    for (var item in response) {
      totalProjectedYield += (item['estimated_yield_kg'] as num).toDouble();
    }
    
    // In a real scenario, compare with market demand. 
    // This assumes a dummy demand of 100,000 for demonstration.
    double projectedDemand = 100000;
    if (projectedDemand == 0) return 0;
    
    double saturation = ((totalProjectedYield - projectedDemand) / projectedDemand) * 100;
    return saturation;
  }
}
