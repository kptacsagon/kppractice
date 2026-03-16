class YieldPredictionService {
  static const Map<String, Map<int, double>> _monthlyYieldMtHa = {
    'okra': {
      1: 1.25,
      2: 1.15,
      3: 5.25,
      4: 5.50,
      6: 2.00,
      7: 1.50,
      8: 2.33,
      9: 6.26,
      10: 6.26,
      11: 8.33,
      12: 2.50,
    },
    'eggplant': {
      1: 0.96,
      2: 0.90,
      3: 7.00,
      4: 7.00,
      5: 4.40,
      6: 6.00,
      7: 5.20,
      8: 15.00,
      9: 15.00,
      10: 15.00,
      11: 15.00,
      12: 15.00,
    },
    'ampalaya': {
      1: 10.00,
      2: 9.00,
      3: 8.00,
      4: 11.00,
      5: 5.00,
      6: 3.50,
      7: 4.00,
      8: 12.00,
      9: 12.00,
      10: 12.00,
      11: 12.00,
      12: 12.00,
    },
    'squash': {
      1: 12.00,
      2: 12.50,
      3: 9.41,
      4: 7.50,
      8: 14.00,
      9: 14.00,
      10: 14.00,
      11: 14.00,
      12: 14.00,
    },
    'stringbeans': {
      1: 5.00,
      2: 2.16,
      3: 1.50,
      4: 1.50,
      5: 2.50,
      6: 2.50,
      7: 2.50,
      8: 11.00,
      9: 11.00,
      10: 11.00,
      11: 11.00,
      12: 11.00,
    },
  };

  static String normalizeCropName(String cropName) {
    final cleaned = cropName.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (cleaned == 'stringbean' || cleaned == 'sitaw') return 'stringbeans';
    return cleaned;
  }

  static double? getMonthlyYieldMtHa(String cropName, DateTime? harvestDate) {
    if (harvestDate == null) return null;
    final normalized = normalizeCropName(cropName);
    final cropMonthMap = _monthlyYieldMtHa[normalized];
    if (cropMonthMap == null) return null;
    return cropMonthMap[harvestDate.month];
  }

  static double? predictYieldKg({
    required String cropName,
    required DateTime? harvestDate,
    required double areaHa,
  }) {
    if (areaHa <= 0 || harvestDate == null) return null;
    final yieldMtHa = getMonthlyYieldMtHa(cropName, harvestDate);
    if (yieldMtHa == null) return null;
    return areaHa * yieldMtHa * 1000;
  }
}
