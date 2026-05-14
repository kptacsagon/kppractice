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
    await _supabase
        .from('agrisense_farmer_profiles')
        .upsert(profile.toJson());
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

  Future<void> saveFarm(AgrisenseFarm farm) async {
    await _supabase
        .from('agrisense_farms')
        .insert(farm.toJson());
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
