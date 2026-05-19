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

// PRD §3.1.1 — HVC Master List
const kHvcMasterList = <HvcCrop>[
  // Vegetables
  HvcCrop(id: 'ampalaya', nameLocal: 'Ampalaya', nameEnglish: 'Bitter Gourd', category: 'Vegetable', avgDaysToMaturity: 75),
  HvcCrop(id: 'sitaw', nameLocal: 'Sitaw', nameEnglish: 'String Beans', category: 'Vegetable', avgDaysToMaturity: 60),
  HvcCrop(id: 'pechay', nameLocal: 'Pechay', nameEnglish: 'Bok Choy', category: 'Vegetable', avgDaysToMaturity: 35),
  HvcCrop(id: 'repolyo', nameLocal: 'Repolyo', nameEnglish: 'Cabbage', category: 'Vegetable', avgDaysToMaturity: 75),
  HvcCrop(id: 'kamatis', nameLocal: 'Kamatis', nameEnglish: 'Tomato', category: 'Vegetable', avgDaysToMaturity: 80),
  HvcCrop(id: 'talong', nameLocal: 'Talong', nameEnglish: 'Eggplant', category: 'Vegetable', avgDaysToMaturity: 80),
  HvcCrop(id: 'okra', nameLocal: 'Okra', nameEnglish: 'Okra', category: 'Vegetable', avgDaysToMaturity: 55),
  HvcCrop(id: 'kalabasa', nameLocal: 'Kalabasa', nameEnglish: 'Squash', category: 'Vegetable', avgDaysToMaturity: 120),
  // Root Crops
  HvcCrop(id: 'kamote', nameLocal: 'Kamote', nameEnglish: 'Sweet Potato', category: 'Root Crop', avgDaysToMaturity: 120),
  HvcCrop(id: 'gabi', nameLocal: 'Gabi', nameEnglish: 'Taro', category: 'Root Crop', avgDaysToMaturity: 240),
  HvcCrop(id: 'ube', nameLocal: 'Ube', nameEnglish: 'Purple Yam', category: 'Root Crop', avgDaysToMaturity: 270),
  HvcCrop(id: 'singkamas', nameLocal: 'Singkamas', nameEnglish: 'Jicama', category: 'Root Crop', avgDaysToMaturity: 150),
  // Fruits
  HvcCrop(id: 'saging', nameLocal: 'Saging', nameEnglish: 'Banana', category: 'Fruit', avgDaysToMaturity: 365),
  HvcCrop(id: 'papaya', nameLocal: 'Papaya', nameEnglish: 'Papaya', category: 'Fruit', avgDaysToMaturity: 300),
  HvcCrop(id: 'mangga', nameLocal: 'Mangga', nameEnglish: 'Mango', category: 'Fruit', avgDaysToMaturity: 1825),
  HvcCrop(id: 'lansones', nameLocal: 'Lansones', nameEnglish: 'Lanzones', category: 'Fruit', avgDaysToMaturity: 3650),
  HvcCrop(id: 'rambutan', nameLocal: 'Rambutan', nameEnglish: 'Rambutan', category: 'Fruit', avgDaysToMaturity: 1825),
  // Spices & Condiments
  HvcCrop(id: 'luya', nameLocal: 'Luya', nameEnglish: 'Ginger', category: 'Spice', avgDaysToMaturity: 240),
  HvcCrop(id: 'sibuyas', nameLocal: 'Sibuyas', nameEnglish: 'Onion', category: 'Spice', avgDaysToMaturity: 90),
  HvcCrop(id: 'bawang', nameLocal: 'Bawang', nameEnglish: 'Garlic', category: 'Spice', avgDaysToMaturity: 150),
  HvcCrop(id: 'sili', nameLocal: 'Sili', nameEnglish: 'Chili', category: 'Spice', avgDaysToMaturity: 90),
  // Legumes
  HvcCrop(id: 'munggo', nameLocal: 'Munggo', nameEnglish: 'Mung Bean', category: 'Legume', avgDaysToMaturity: 65),
  HvcCrop(id: 'bataw', nameLocal: 'Bataw', nameEnglish: 'Hyacinth Bean', category: 'Legume', avgDaysToMaturity: 90),
  HvcCrop(id: 'kadyos', nameLocal: 'Kadyos', nameEnglish: 'Pigeon Pea', category: 'Legume', avgDaysToMaturity: 180),
];

HvcCrop? findHvcById(String id) {
  for (final c in kHvcMasterList) {
    if (c.id == id) return c;
  }
  return null;
}
