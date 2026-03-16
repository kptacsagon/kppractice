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

  int get maturityDays {
    switch (this) {
      case CropName.okra:
        return 60;
      case CropName.eggplant:
        return 75;
      case CropName.ampalaya:
        return 65;
      case CropName.squash:
        return 90;
      case CropName.stringbeans:
        return 55;
    }
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

  String toJson() => name;
}
