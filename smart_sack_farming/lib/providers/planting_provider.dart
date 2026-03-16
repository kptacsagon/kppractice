import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crop.dart';
import '../models/planting_record.dart';
import '../services/harvest_calculator.dart';

class PlantingFormState {
  final CropName crop;
  final DateTime plantingDate;
  final double areaPlantedHa;
  final double estimatedYieldMt;
  final bool isSubmitting;
  final String? error;

  PlantingFormState({
    required this.crop,
    required this.plantingDate,
    required this.areaPlantedHa,
    required this.estimatedYieldMt,
    this.isSubmitting = false,
    this.error,
  });

  PlantingFormState copyWith({
    CropName? crop,
    DateTime? plantingDate,
    double? areaPlantedHa,
    double? estimatedYieldMt,
    bool? isSubmitting,
    String? error,
  }) {
    return PlantingFormState(
      crop: crop ?? this.crop,
      plantingDate: plantingDate ?? this.plantingDate,
      areaPlantedHa: areaPlantedHa ?? this.areaPlantedHa,
      estimatedYieldMt: estimatedYieldMt ?? this.estimatedYieldMt,
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
          estimatedYieldMt: 0.0,
        ));

  void setCrop(CropName crop) => state = state.copyWith(crop: crop);
  void setPlantingDate(DateTime d) => state = state.copyWith(plantingDate: d);
  void setAreaPlantedHa(double v) => state = state.copyWith(areaPlantedHa: v);
  void setEstimatedYieldMt(double v) => state = state.copyWith(estimatedYieldMt: v);

  Future<void> submitPlantingRecord({required String farmerId}) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final expected = HarvestCalculator.expectedHarvestDate(state.plantingDate, state.crop);

      // Build a PlantingRecord. ID is placeholder; backend should return real id.
      final record = PlantingRecord(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        farmerId: farmerId,
        cropName: state.crop,
        areaPlantedHa: state.areaPlantedHa,
        estimatedYieldMt: state.estimatedYieldMt,
        plantingDate: state.plantingDate,
        expectedHarvestDate: expected,
        status: PlantingStatus.growing,
      );

      // Placeholder API call
      await _submitPlantingRecord(record);

      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> _submitPlantingRecord(PlantingRecord record) async {
    // TODO: replace with real API call to backend (Supabase/Postgres)
    await Future.delayed(const Duration(milliseconds: 600));
    // simulate success
  }
}

final plantingFormProvider = StateNotifierProvider<PlantingFormNotifier, PlantingFormState>((ref) {
  return PlantingFormNotifier();
});
