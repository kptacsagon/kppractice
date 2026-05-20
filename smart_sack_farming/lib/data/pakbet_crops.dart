/// The 8 high-value pakbet crops used throughout the system.
/// All crop dropdowns and lists must reference this constant.
const List<String> kPakbetCrops = [
  'Ampalaya',
  'Talong',
  'Kamatis',
  'Okra',
  'Sitaw',
  'Kangkong',
  'Pechay',
  'Kalabasa',
];

/// Display-friendly map: local name → English name
const Map<String, String> kPakbetEnglishNames = {
  'Ampalaya': 'Bitter Gourd',
  'Talong': 'Eggplant',
  'Kamatis': 'Tomato',
  'Okra': 'Okra',
  'Sitaw': 'String Beans',
  'Kangkong': 'Water Spinach',
  'Pechay': 'Bok Choy',
  'Kalabasa': 'Squash',
};

/// Days to maturity per crop (min, max)
const Map<String, (int, int)> kPakbetMaturityDays = {
  'Ampalaya':  (60,  75),
  'Talong':    (70,  85),
  'Kamatis':   (70,  85),
  'Okra':      (50,  60),
  'Sitaw':     (50,  65),
  'Kangkong':  (25,  35),
  'Pechay':    (30,  40),
  'Kalabasa':  (90, 120),
};

/// Typical yield in kg/ha per crop
const Map<String, double> kPakbetYieldKgPerHa = {
  'Ampalaya': 7000,
  'Talong':   6000,
  'Kamatis':  8000,
  'Okra':     8000,
  'Sitaw':    5000,
  'Kangkong': 10000,
  'Pechay':   12000,
  'Kalabasa': 9000,
};

/// Typical farmgate price range in ₱/kg
const Map<String, (double, double)> kPakbetPriceRange = {
  'Ampalaya': (25, 45),
  'Talong':   (20, 40),
  'Kamatis':  (20, 50),
  'Okra':     (25, 45),
  'Sitaw':    (30, 60),
  'Kangkong': (15, 30),
  'Pechay':   (15, 35),
  'Kalabasa': (15, 30),
};
