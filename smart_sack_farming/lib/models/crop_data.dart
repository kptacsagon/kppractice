/// Represents a crop with its saturation requirements and planting info.
class CropData {
  final String name;
  final String icon;
  final String category; // Vegetable, Fruit, Grain, Herb, Root Crop
  final double idealMoistureMin; // Ideal moisture % range (min)
  final double idealMoistureMax; // Ideal moisture % range (max)
  final List<String> bestPlantingMonths;
  final String growthDuration; // e.g. "60-90 days"
  final String description;

  // ── Crop Sensitivity Coefficients (0.0 – 1.0) ──
  // Used by the Predictive Risk Model for thesis-grade risk analysis.
  final double heatSensitivity;    // Vulnerability to heat stress
  final double floodSensitivity;   // Vulnerability to flooding / excess water
  final double droughtSensitivity; // Vulnerability to water deficit

  const CropData({
    required this.name,
    required this.icon,
    required this.category,
    required this.idealMoistureMin,
    required this.idealMoistureMax,
    required this.bestPlantingMonths,
    required this.growthDuration,
    required this.description,
    this.heatSensitivity = 0.5,
    this.floodSensitivity = 0.5,
    this.droughtSensitivity = 0.5,
  });

  /// Composite sensitivity coefficient (average of all three).
  double get sensitivityCoefficient =>
      (heatSensitivity + floodSensitivity + droughtSensitivity) / 3.0;

  /// Analyzes saturation level given a water availability percentage.
  SaturationLevel analyzeSaturation(double waterAvailability) {
    if (waterAvailability >= idealMoistureMin && waterAvailability <= idealMoistureMax) {
      return SaturationLevel.medium;
    } else if (waterAvailability > idealMoistureMax) {
      return SaturationLevel.high;
    } else {
      return SaturationLevel.low;
    }
  }

  /// Returns crops that complement this crop in a mix-and-match scenario for high saturation.
  static List<CropData> getCompanionCrops(CropData primaryCrop, double waterAvailability) {
    return allCrops.where((crop) {
      if (crop.name == primaryCrop.name) return false;
      final level = crop.analyzeSaturation(waterAvailability);
      return level == SaturationLevel.medium || level == SaturationLevel.low;
    }).toList();
  }

  /// Pre-defined crop database with agronomic sensitivity coefficients.
  static const List<CropData> allCrops = [
    CropData(
      name: 'Rice',
      icon: '🌾',
      category: 'Grain',
      idealMoistureMin: 70,
      idealMoistureMax: 90,
      bestPlantingMonths: ['May', 'Jun', 'Jul'],
      growthDuration: '90-120 days',
      description: 'Thrives in waterlogged, high-saturation soil.',
      heatSensitivity: 0.6,
      floodSensitivity: 0.2,  // tolerant to flooding
      droughtSensitivity: 0.8,
    ),
    CropData(
      name: 'Corn',
      icon: '🌽',
      category: 'Grain',
      idealMoistureMin: 50,
      idealMoistureMax: 70,
      bestPlantingMonths: ['Mar', 'Apr', 'May'],
      growthDuration: '60-100 days',
      description: 'Prefers well-drained, moderately moist soil.',
      heatSensitivity: 0.5,
      floodSensitivity: 0.7,
      droughtSensitivity: 0.6,
    ),
    CropData(
      name: 'Tomato',
      icon: '🍅',
      category: 'Vegetable',
      idealMoistureMin: 40,
      idealMoistureMax: 60,
      bestPlantingMonths: ['Feb', 'Mar', 'Apr'],
      growthDuration: '60-85 days',
      description: 'Needs consistent moisture but not waterlogged soil.',
      heatSensitivity: 0.7,
      floodSensitivity: 0.8,
      droughtSensitivity: 0.6,
    ),
    CropData(
      name: 'Lettuce',
      icon: '🥬',
      category: 'Vegetable',
      idealMoistureMin: 45,
      idealMoistureMax: 65,
      bestPlantingMonths: ['Oct', 'Nov', 'Dec', 'Jan'],
      growthDuration: '30-60 days',
      description: 'Cool-season crop, prefers moderate moisture.',
      heatSensitivity: 0.9,  // very heat-sensitive
      floodSensitivity: 0.6,
      droughtSensitivity: 0.7,
    ),
    CropData(
      name: 'Eggplant',
      icon: '🍆',
      category: 'Vegetable',
      idealMoistureMin: 50,
      idealMoistureMax: 70,
      bestPlantingMonths: ['Mar', 'Apr', 'May'],
      growthDuration: '60-80 days',
      description: 'Warm-season crop that likes moderately moist soil.',
      heatSensitivity: 0.3,  // heat-tolerant
      floodSensitivity: 0.7,
      droughtSensitivity: 0.5,
    ),
    CropData(
      name: 'Sweet Potato',
      icon: '🍠',
      category: 'Root Crop',
      idealMoistureMin: 40,
      idealMoistureMax: 60,
      bestPlantingMonths: ['Apr', 'May', 'Jun'],
      growthDuration: '90-120 days',
      description: 'Tolerates drier conditions, does not like waterlogging.',
      heatSensitivity: 0.3,
      floodSensitivity: 0.8,
      droughtSensitivity: 0.3,  // drought-tolerant
    ),
    CropData(
      name: 'Carrot',
      icon: '🥕',
      category: 'Root Crop',
      idealMoistureMin: 35,
      idealMoistureMax: 55,
      bestPlantingMonths: ['Oct', 'Nov', 'Feb', 'Mar'],
      growthDuration: '70-80 days',
      description: 'Prefers loose, well-drained soil with moderate moisture.',
      heatSensitivity: 0.7,
      floodSensitivity: 0.8,
      droughtSensitivity: 0.5,
    ),
    CropData(
      name: 'Cabbage',
      icon: '🥗',
      category: 'Vegetable',
      idealMoistureMin: 55,
      idealMoistureMax: 75,
      bestPlantingMonths: ['Oct', 'Nov', 'Dec'],
      growthDuration: '70-100 days',
      description: 'Heavy feeder that likes consistent moisture.',
      heatSensitivity: 0.8,
      floodSensitivity: 0.5,
      droughtSensitivity: 0.6,
    ),
    CropData(
      name: 'Watermelon',
      icon: '🍉',
      category: 'Fruit',
      idealMoistureMin: 45,
      idealMoistureMax: 65,
      bestPlantingMonths: ['Mar', 'Apr', 'May'],
      growthDuration: '80-100 days',
      description: 'Needs warm soil and moderate moisture to develop.',
      heatSensitivity: 0.3,
      floodSensitivity: 0.7,
      droughtSensitivity: 0.4,
    ),
    CropData(
      name: 'Basil',
      icon: '🌿',
      category: 'Herb',
      idealMoistureMin: 35,
      idealMoistureMax: 55,
      bestPlantingMonths: ['Mar', 'Apr', 'May', 'Jun'],
      growthDuration: '30-60 days',
      description: 'Aromatic herb, prefers well-drained moderate soil.',
      heatSensitivity: 0.4,
      floodSensitivity: 0.7,
      droughtSensitivity: 0.5,
    ),
    CropData(
      name: 'Pepper',
      icon: '🌶️',
      category: 'Vegetable',
      idealMoistureMin: 40,
      idealMoistureMax: 60,
      bestPlantingMonths: ['Mar', 'Apr', 'May'],
      growthDuration: '60-90 days',
      description: 'Warm-season crop, needs consistent but not excess moisture.',
      heatSensitivity: 0.4,
      floodSensitivity: 0.7,
      droughtSensitivity: 0.5,
    ),
    CropData(
      name: 'Spinach',
      icon: '🥬',
      category: 'Vegetable',
      idealMoistureMin: 50,
      idealMoistureMax: 70,
      bestPlantingMonths: ['Sep', 'Oct', 'Nov', 'Feb'],
      growthDuration: '30-45 days',
      description: 'Fast-growing leafy green, likes moist cool soil.',
      heatSensitivity: 0.9,
      floodSensitivity: 0.5,
      droughtSensitivity: 0.7,
    ),
    // ══════════════════════════════════════════════════════════
    // PSA OpenSTAT CROPS - Iloilo Region (2019-2026 price data)
    // ══════════════════════════════════════════════════════════
    CropData(
      name: 'Squash',
      icon: '🎃',
      category: 'Vegetable',
      idealMoistureMin: 45,
      idealMoistureMax: 70,
      bestPlantingMonths: ['Mar', 'Apr', 'May', 'Jun'],
      growthDuration: '85-100 days',
      description: 'Hardy vine crop, tolerates varied moisture. Stable price ₱51/kg (PSA 2025).',
      heatSensitivity: 0.3,
      floodSensitivity: 0.6,
      droughtSensitivity: 0.4,
    ),
    CropData(
      name: 'Radish',
      icon: '🥕',
      category: 'Root Crop',
      idealMoistureMin: 50,
      idealMoistureMax: 70,
      bestPlantingMonths: ['Oct', 'Nov', 'Dec', 'Jan', 'Feb'],
      growthDuration: '25-35 days',
      description: 'Fast-maturing root crop. High price volatility ₱61-₱161/kg (PSA 2019-2025).',
      heatSensitivity: 0.7,
      floodSensitivity: 0.6,
      droughtSensitivity: 0.5,
    ),
    CropData(
      name: 'Potato',
      icon: '🥔',
      category: 'Root Crop',
      idealMoistureMin: 45,
      idealMoistureMax: 65,
      bestPlantingMonths: ['Oct', 'Nov', 'Dec', 'Jan'],
      growthDuration: '90-120 days',
      description: 'Cool-season root crop. High value ₱103-₱133/kg (PSA 2019-2021).',
      heatSensitivity: 0.8,
      floodSensitivity: 0.7,
      droughtSensitivity: 0.6,
    ),
    CropData(
      name: 'Banana Saba',
      icon: '🍌',
      category: 'Fruit',
      idealMoistureMin: 60,
      idealMoistureMax: 80,
      bestPlantingMonths: ['Jun', 'Jul', 'Aug', 'Sep'],
      growthDuration: '10-12 months',
      description: 'Staple cooking banana. Very stable price ₱36-₱39/kg (PSA 2021-2023). Low oversaturation risk.',
      heatSensitivity: 0.3,
      floodSensitivity: 0.4,
      droughtSensitivity: 0.6,
    ),
    CropData(
      name: 'Banana Lakatan',
      icon: '🍌',
      category: 'Fruit',
      idealMoistureMin: 60,
      idealMoistureMax: 80,
      bestPlantingMonths: ['Jun', 'Jul', 'Aug', 'Sep'],
      growthDuration: '10-12 months',
      description: 'Premium dessert banana. Higher price ₱80-₱87/kg (PSA 2021-2023). Stable market.',
      heatSensitivity: 0.3,
      floodSensitivity: 0.4,
      droughtSensitivity: 0.6,
    ),
    CropData(
      name: 'Onion',
      icon: '🧅',
      category: 'Vegetable',
      idealMoistureMin: 35,
      idealMoistureMax: 55,
      bestPlantingMonths: ['Oct', 'Nov', 'Dec'],
      growthDuration: '100-120 days',
      description: 'High-value crop but volatile. Best for dry season planting.',
      heatSensitivity: 0.5,
      floodSensitivity: 0.8,
      droughtSensitivity: 0.4,
    ),
  ];
}

/// Saturation level classification
enum SaturationLevel { low, medium, high }

/// Planting season classification
enum PlantingSeason { 
  monsoon,    // June-September (heavy rain)
  summer,     // March-May (hot and dry)
  winter,     // December-February (cool)
  autumn      // October-November (transition)
}

/// Helper class for season utilities
class SeasonHelper {
  /// Determines the planting season based on month
  static PlantingSeason getSeasonFromMonth(int month) {
    switch (month) {
      case 3:
      case 4:
      case 5:
        return PlantingSeason.summer;
      case 6:
      case 7:
      case 8:
      case 9:
        return PlantingSeason.monsoon;
      case 10:
      case 11:
        return PlantingSeason.autumn;
      case 12:
      case 1:
      case 2:
        return PlantingSeason.winter;
      default:
        return PlantingSeason.monsoon;
    }
  }

  /// Get season name
  static String getSeasonName(PlantingSeason season) {
    switch (season) {
      case PlantingSeason.monsoon:
        return 'Monsoon Season';
      case PlantingSeason.summer:
        return 'Summer Season';
      case PlantingSeason.winter:
        return 'Winter Season';
      case PlantingSeason.autumn:
        return 'Autumn Season';
    }
  }

  /// Get season emoji
  static String getSeasonEmoji(PlantingSeason season) {
    switch (season) {
      case PlantingSeason.monsoon:
        return '🌧️';
      case PlantingSeason.summer:
        return '☀️';
      case PlantingSeason.winter:
        return '❄️';
      case PlantingSeason.autumn:
        return '🍂';
    }
  }

  /// Get season description
  static String getSeasonDescription(PlantingSeason season) {
    switch (season) {
      case PlantingSeason.monsoon:
        return 'Heavy rainfall, waterlogged soil';
      case PlantingSeason.summer:
        return 'Hot and dry conditions';
      case PlantingSeason.winter:
        return 'Cool, mild temperatures';
      case PlantingSeason.autumn:
        return 'Transitional weather patterns';
    }
  }

  /// Get expected water availability for a season (0-100%)
  static double getExpectedMoisture(PlantingSeason season) {
    switch (season) {
      case PlantingSeason.monsoon:
        return 75.0; // High moisture
      case PlantingSeason.summer:
        return 40.0; // Low moisture
      case PlantingSeason.winter:
        return 55.0; // Moderate moisture
      case PlantingSeason.autumn:
        return 50.0; // Moderate moisture
    }
  }

  /// Check if a crop is suitable for a season
  static bool isCropSuitableForSeason(CropData crop, PlantingSeason season) {
    final month = _getMonthFromSeason(season);
    const monthAbbr = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return crop.bestPlantingMonths.contains(monthAbbr[month - 1]);
  }

  static int _getMonthFromSeason(PlantingSeason season) {
    switch (season) {
      case PlantingSeason.monsoon:
        return 7; // July
      case PlantingSeason.summer:
        return 4; // April
      case PlantingSeason.winter:
        return 1; // January
      case PlantingSeason.autumn:
        return 10; // October
    }
  }
}
