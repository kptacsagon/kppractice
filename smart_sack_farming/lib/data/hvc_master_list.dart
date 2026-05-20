class HvcCrop {
  final String id;
  final String nameLocal;
  final String nameEnglish;
  final String category;
  final int avgDaysToMaturity;

  const HvcCrop({
    required this.id,
    required this.nameLocal,
    required this.nameEnglish,
    required this.category,
    required this.avgDaysToMaturity,
  });

  String get displayName => '$nameLocal ($nameEnglish)';
}

// Pakbet HVC Master List — only the 8 pakbet high-value crops
const kHvcMasterList = <HvcCrop>[
  HvcCrop(id: 'ampalaya', nameLocal: 'Ampalaya', nameEnglish: 'Bitter Gourd',  category: 'Vegetable', avgDaysToMaturity: 75),
  HvcCrop(id: 'talong',   nameLocal: 'Talong',   nameEnglish: 'Eggplant',      category: 'Vegetable', avgDaysToMaturity: 80),
  HvcCrop(id: 'kamatis',  nameLocal: 'Kamatis',  nameEnglish: 'Tomato',        category: 'Vegetable', avgDaysToMaturity: 80),
  HvcCrop(id: 'okra',     nameLocal: 'Okra',     nameEnglish: 'Okra',          category: 'Vegetable', avgDaysToMaturity: 55),
  HvcCrop(id: 'sitaw',    nameLocal: 'Sitaw',    nameEnglish: 'String Beans',  category: 'Vegetable', avgDaysToMaturity: 60),
  HvcCrop(id: 'kangkong', nameLocal: 'Kangkong', nameEnglish: 'Water Spinach', category: 'Vegetable', avgDaysToMaturity: 30),
  HvcCrop(id: 'pechay',   nameLocal: 'Pechay',   nameEnglish: 'Bok Choy',      category: 'Vegetable', avgDaysToMaturity: 35),
  HvcCrop(id: 'kalabasa', nameLocal: 'Kalabasa', nameEnglish: 'Squash',        category: 'Vegetable', avgDaysToMaturity: 120),
];

HvcCrop? findHvcById(String id) {
  for (final c in kHvcMasterList) {
    if (c.id == id) return c;
  }
  return null;
}
