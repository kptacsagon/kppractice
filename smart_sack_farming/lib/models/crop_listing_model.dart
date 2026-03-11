/// Model representing a crop listing available in the marketplace.
class CropListing {
  final String id;
  final String farmerId;
  final String? saturationRecordId;
  
  // Crop info
  final String cropName;
  final String? cropIcon;
  final double quantityKg;
  final double availableQuantityKg;
  final double pricePerKg;
  
  // Condition
  final String saturationLevel;
  final String qualityGrade;
  final DateTime? harvestDate;
  final DateTime? expiryDate;
  
  // Location & details
  final String? farmLocation;
  final String? description;
  final String? imageUrl;
  
  // Farmer info (denormalized)
  final String? farmerName;
  final String? farmerPhone;
  
  // Status
  final String status;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const CropListing({
    required this.id,
    required this.farmerId,
    this.saturationRecordId,
    required this.cropName,
    this.cropIcon,
    required this.quantityKg,
    required this.availableQuantityKg,
    required this.pricePerKg,
    required this.saturationLevel,
    this.qualityGrade = 'B',
    this.harvestDate,
    this.expiryDate,
    this.farmLocation,
    this.description,
    this.imageUrl,
    this.farmerName,
    this.farmerPhone,
    this.status = 'available',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Total value of the listing
  double get totalValue => quantityKg * pricePerKg;
  
  /// Available value remaining
  double get availableValue => availableQuantityKg * pricePerKg;
  
  /// Percentage of crop still available
  double get availabilityPercent => 
    quantityKg > 0 ? (availableQuantityKg / quantityKg) * 100 : 0;
  
  /// Check if listing is still available for purchase
  bool get isAvailable => status == 'available' && availableQuantityKg > 0;
  
  /// Get saturation level color
  String get saturationEmoji {
    switch (saturationLevel.toLowerCase()) {
      case 'high':
        return '🔴';
      case 'medium':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '⚪';
    }
  }

  /// Get quality grade description
  String get qualityDescription {
    switch (qualityGrade.toUpperCase()) {
      case 'A':
        return 'Premium Quality';
      case 'B':
        return 'Standard Quality';
      case 'C':
        return 'Economy Quality';
      default:
        return 'Ungraded';
    }
  }

  factory CropListing.fromJson(Map<String, dynamic> json) {
    return CropListing(
      id: json['id'] as String,
      farmerId: json['farmer_id'] as String,
      saturationRecordId: json['saturation_record_id'] as String?,
      cropName: json['crop_name'] as String,
      cropIcon: json['crop_icon'] as String?,
      quantityKg: (json['quantity_kg'] as num).toDouble(),
      availableQuantityKg: (json['available_quantity_kg'] as num).toDouble(),
      pricePerKg: (json['price_per_kg'] as num).toDouble(),
      saturationLevel: json['saturation_level'] as String? ?? 'high',
      qualityGrade: json['quality_grade'] as String? ?? 'B',
      harvestDate: json['harvest_date'] != null 
        ? DateTime.parse(json['harvest_date'] as String) 
        : null,
      expiryDate: json['expiry_date'] != null 
        ? DateTime.parse(json['expiry_date'] as String) 
        : null,
      farmLocation: json['farm_location'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      farmerName: json['farmer_name'] as String?,
      farmerPhone: json['farmer_phone'] as String?,
      status: json['status'] as String? ?? 'available',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'saturation_record_id': saturationRecordId,
      'crop_name': cropName,
      'crop_icon': cropIcon,
      'quantity_kg': quantityKg,
      'available_quantity_kg': availableQuantityKg,
      'price_per_kg': pricePerKg,
      'saturation_level': saturationLevel,
      'quality_grade': qualityGrade,
      'harvest_date': harvestDate?.toIso8601String().split('T')[0],
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'farm_location': farmLocation,
      'description': description,
      'image_url': imageUrl,
      'farmer_name': farmerName,
      'farmer_phone': farmerPhone,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to insert-ready JSON (without id and timestamps)
  Map<String, dynamic> toInsertJson() {
    return {
      'farmer_id': farmerId,
      'saturation_record_id': saturationRecordId,
      'crop_name': cropName,
      'crop_icon': cropIcon,
      'quantity_kg': quantityKg,
      'available_quantity_kg': availableQuantityKg,
      'price_per_kg': pricePerKg,
      'saturation_level': saturationLevel,
      'quality_grade': qualityGrade,
      'harvest_date': harvestDate?.toIso8601String().split('T')[0],
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'farm_location': farmLocation,
      'description': description,
      'image_url': imageUrl,
      'farmer_name': farmerName,
      'farmer_phone': farmerPhone,
      'status': status,
    };
  }

  CropListing copyWith({
    String? id,
    String? farmerId,
    String? saturationRecordId,
    String? cropName,
    String? cropIcon,
    double? quantityKg,
    double? availableQuantityKg,
    double? pricePerKg,
    String? saturationLevel,
    String? qualityGrade,
    DateTime? harvestDate,
    DateTime? expiryDate,
    String? farmLocation,
    String? description,
    String? imageUrl,
    String? farmerName,
    String? farmerPhone,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CropListing(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      saturationRecordId: saturationRecordId ?? this.saturationRecordId,
      cropName: cropName ?? this.cropName,
      cropIcon: cropIcon ?? this.cropIcon,
      quantityKg: quantityKg ?? this.quantityKg,
      availableQuantityKg: availableQuantityKg ?? this.availableQuantityKg,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      saturationLevel: saturationLevel ?? this.saturationLevel,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      harvestDate: harvestDate ?? this.harvestDate,
      expiryDate: expiryDate ?? this.expiryDate,
      farmLocation: farmLocation ?? this.farmLocation,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      farmerName: farmerName ?? this.farmerName,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
