import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crop.dart';
import '../models/planting_record.dart';
import '../services/harvest_calculator.dart';
import '../services/supabase_service.dart';

class PlantingFormState {
  final CropName crop;
  final DateTime plantingDate;
  final double areaPlantedHa;
  final bool isSubmitting;
  final String? error;

  PlantingFormState({
    required this.crop,
    required this.plantingDate,
    required this.areaPlantedHa,
    this.isSubmitting = false,
    this.error,
  });

  PlantingFormState copyWith({
    CropName? crop,
    DateTime? plantingDate,
    double? areaPlantedHa,
    bool? isSubmitting,
    String? error,
  }) {
    return PlantingFormState(
      crop: crop ?? this.crop,
      plantingDate: plantingDate ?? this.plantingDate,
      areaPlantedHa: areaPlantedHa ?? this.areaPlantedHa,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class PlantingFormNotifier extends StateNotifier<PlantingFormState> {
  PlantingFormNotifier()
      : super(PlantingFormState(
          crop: CropName.okra,
          plantingDate: DateTime.now(),
          areaPlantedHa: 0.0,
        ));

  void setCrop(CropName crop) => state = state.copyWith(crop: crop);
  void setPlantingDate(DateTime d) => state = state.copyWith(plantingDate: d);
  void setAreaPlantedHa(double v) => state = state.copyWith(areaPlantedHa: v);
  Future<String?> submitPlantingRecord({String? farmerId}) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final expected = HarvestCalculator.expectedHarvestDate(state.plantingDate, state.crop);

      // Build a PlantingRecord. ID is placeholder; backend should return real id.
      final record = PlantingRecord(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        farmerId: farmerId ?? '',
        cropName: state.crop,
        areaPlantedHa: state.areaPlantedHa,
        plantingDate: state.plantingDate,
        expectedHarvestDate: expected,
        status: PlantingStatus.growing,
      );

      final createdId = await _submitPlantingRecord(record);

      state = state.copyWith(isSubmitting: false);
      return createdId;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      rethrow;
    }
  }

  Future<String?> _submitPlantingRecord(PlantingRecord record) async {
    // Submit to Supabase via shared service
    try {
      final sup = SupabaseService();
      // Ensure farmerId is present; prefer current user if missing
      final farmerId = record.farmerId.isNotEmpty
          ? record.farmerId
          : (sup.currentUser?.id ?? '');

      if (farmerId.isEmpty) throw Exception('No farmer id provided or authenticated');

      final payload = record.toJson()..remove('id');
      payload['farmer_id'] = farmerId;

      final inserted = await sup.insertRecord('planting_records', payload);
      return inserted['id'] as String?;
    } catch (e) {
      rethrow;
    }
  }
}

final plantingFormProvider = StateNotifierProvider<PlantingFormNotifier, PlantingFormState>((ref) {
  return PlantingFormNotifier();
});
