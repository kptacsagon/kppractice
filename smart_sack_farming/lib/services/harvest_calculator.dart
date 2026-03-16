import '../models/crop.dart';

class HarvestCalculator {
  /// Returns the expected harvest date by adding the crop's maturity days
  /// to the planting date.
  static DateTime expectedHarvestDate(DateTime plantingDate, CropName crop) {
    return plantingDate.add(Duration(days: crop.maturityDays));
  }

  /// Returns number of days remaining until expected harvest (can be negative).
  static int daysUntilHarvest(DateTime expectedHarvestDate) {
    final now = DateTime.now();
    return expectedHarvestDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }
}
