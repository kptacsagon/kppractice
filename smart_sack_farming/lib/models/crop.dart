enum CropName { okra, eggplant, ampalaya, squash, stringbeans }

extension CropNameExt on CropName {
  String get name {
    switch (this) {
      case CropName.okra:
        return 'Okra';
      case CropName.eggplant:
        return 'Eggplant';
      case CropName.ampalaya:
        return 'Ampalaya';
      case CropName.squash:
        return 'Squash';
      case CropName.stringbeans:
        return 'Stringbeans';
    }
  }

  /// Typical maturity ranges (min..max days) for each crop.
  Map<String, int> get maturityRange {
    switch (this) {
      case CropName.okra:
        return {'min': 50, 'max': 65};
      case CropName.eggplant:
        return {'min': 70, 'max': 80};
      case CropName.ampalaya:
        return {'min': 60, 'max': 70};
      case CropName.squash:
        return {'min': 80, 'max': 100};
      case CropName.stringbeans:
        return {'min': 50, 'max': 60};
    }
  }

  /// Typical yield (kg per hectare) for each crop used to estimate yields.
  double get typicalYieldKgPerHa {
    switch (this) {
      case CropName.okra:
        return 8000.0;
      case CropName.eggplant:
        return 6000.0;
      case CropName.ampalaya:
        return 7000.0;
      case CropName.squash:
        return 9000.0;
      case CropName.stringbeans:
        return 5000.0;
    }
  }

  /// Returns a deterministic typical maturity in days (midpoint rounded).
  int get maturityDays {
    final r = maturityRange;
    final avg = ((r['min'] ?? 0) + (r['max'] ?? 0)) / 2.0;
    return avg.round();
  }

  static CropName fromString(String s) {
    switch (s.toLowerCase()) {
      case 'okra':
        return CropName.okra;
      case 'eggplant':
        return CropName.eggplant;
      case 'ampalaya':
        return CropName.ampalaya;
      case 'squash':
        return CropName.squash;
      case 'stringbeans':
      case 'string beans':
        return CropName.stringbeans;
      default:
        throw ArgumentError('Unknown crop: $s');
    }
  }

  /// Return the value expected by the database enum (lowercase, no spaces).
  String toJson() => name.toLowerCase().replaceAll(' ', '');
}
