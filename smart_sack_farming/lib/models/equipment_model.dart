class Equipment {
  final String id;
  final String name;
  final String description;
  final String category;
  final double dailyRentalPrice;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final DateTime dateAdded;
  final bool isAvailable;
  final String imageUrl;
  final int quantity;
  final String condition;

  Equipment({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.dailyRentalPrice,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.dateAdded,
    required this.isAvailable,
    required this.imageUrl,
    required this.quantity,
    this.condition = 'Good',
  });

  factory Equipment.empty() {
    return Equipment(
      id: '',
      name: '',
      description: '',
      category: 'Tractor',
      dailyRentalPrice: 0,
      ownerId: '',
      ownerName: '',
      ownerPhone: '',
      dateAdded: DateTime.now(),
      isAvailable: true,
      imageUrl: '',
      quantity: 1,
      condition: 'Good',
    );
  }

  Equipment copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? dailyRentalPrice,
    String? ownerId,
    String? ownerName,
    String? ownerPhone,
    DateTime? dateAdded,
    bool? isAvailable,
    String? imageUrl,
    int? quantity,
    String? condition,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      dailyRentalPrice: dailyRentalPrice ?? this.dailyRentalPrice,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      dateAdded: dateAdded ?? this.dateAdded,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      condition: condition ?? this.condition,
    );
  }

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Equipment',
      dailyRentalPrice: (json['daily_rental_price'] is int)
          ? (json['daily_rental_price'] as int).toDouble()
          : json['daily_rental_price'] ?? 0.0,
      ownerId: json['owner_id'] ?? '',
      ownerName: json['owner_name'] ?? '',
      ownerPhone: json['owner_phone'] ?? '',
      dateAdded: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : json['dateAdded'] ?? DateTime.now(),
      isAvailable: json['is_available'] ?? true,
      imageUrl: json['image_url'] ?? '',
      quantity: json['quantity'] ?? 1,
      condition: json['condition'] ?? 'Good',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'daily_rental_price': dailyRentalPrice,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'created_at': dateAdded.toIso8601String(),
      'is_available': isAvailable,
      'image_url': imageUrl,
      'quantity': quantity,
      'condition': condition,
    };
  }
}
