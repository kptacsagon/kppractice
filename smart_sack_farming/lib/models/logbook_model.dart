/// Agronomic logbook entry for recording farming events.
class LogbookEntry {
  final String id;
  final String farmerId;
  final String? saturationId;
  final String? projectId;
  final String eventType;
  final DateTime eventDate;
  final String description;
  final double? quantity;
  final String? quantityUnit;
  final double cost;
  final String? cropAffected;
  final double? fieldAreaHa;
  final String? imageUrl;
  final DateTime createdAt;

  LogbookEntry({
    required this.id,
    required this.farmerId,
    this.saturationId,
    this.projectId,
    required this.eventType,
    required this.eventDate,
    required this.description,
    this.quantity,
    this.quantityUnit,
    this.cost = 0,
    this.cropAffected,
    this.fieldAreaHa,
    this.imageUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LogbookEntry.empty() {
    return LogbookEntry(
      id: '',
      farmerId: '',
      eventType: 'observation',
      eventDate: DateTime.now(),
      description: '',
    );
  }

  LogbookEntry copyWith({
    String? id,
    String? farmerId,
    String? saturationId,
    String? projectId,
    String? eventType,
    DateTime? eventDate,
    String? description,
    double? quantity,
    String? quantityUnit,
    double? cost,
    String? cropAffected,
    double? fieldAreaHa,
    String? imageUrl,
  }) {
    return LogbookEntry(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      saturationId: saturationId ?? this.saturationId,
      projectId: projectId ?? this.projectId,
      eventType: eventType ?? this.eventType,
      eventDate: eventDate ?? this.eventDate,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      cost: cost ?? this.cost,
      cropAffected: cropAffected ?? this.cropAffected,
      fieldAreaHa: fieldAreaHa ?? this.fieldAreaHa,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
    );
  }

  factory LogbookEntry.fromJson(Map<String, dynamic> json) {
    return LogbookEntry(
      id: json['id'] ?? '',
      farmerId: json['farmer_id'] ?? '',
      saturationId: json['saturation_id'],
      projectId: json['project_id'],
      eventType: json['event_type'] ?? 'observation',
      eventDate: json['event_date'] is String
          ? DateTime.parse(json['event_date'])
          : DateTime.now(),
      description: json['description'] ?? '',
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toDouble()
          : null,
      quantityUnit: json['quantity_unit'],
      cost: (json['cost'] is num)
          ? (json['cost'] as num).toDouble()
          : 0,
      cropAffected: json['crop_affected'],
      fieldAreaHa: (json['field_area_ha'] is num)
          ? (json['field_area_ha'] as num).toDouble()
          : null,
      imageUrl: json['image_url'],
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'farmer_id': farmerId,
      'event_type': eventType,
      'event_date': eventDate.toIso8601String().split('T').first,
      'description': description,
      'cost': cost,
    };
    if (saturationId != null) json['saturation_id'] = saturationId;
    if (projectId != null) json['project_id'] = projectId;
    if (quantity != null) json['quantity'] = quantity;
    if (quantityUnit != null) json['quantity_unit'] = quantityUnit;
    if (cropAffected != null) json['crop_affected'] = cropAffected;
    if (fieldAreaHa != null) json['field_area_ha'] = fieldAreaHa;
    if (imageUrl != null) json['image_url'] = imageUrl;
    return json;
  }

  /// Human-readable event type label.
  String get eventTypeLabel {
    const labels = {
      'fertilizer_application': 'Fertilizer Application',
      'pesticide_application': 'Pesticide Application',
      'irrigation': 'Irrigation',
      'weeding': 'Weeding',
      'pruning': 'Pruning',
      'soil_testing': 'Soil Testing',
      'seed_treatment': 'Seed Treatment',
      'transplanting': 'Transplanting',
      'harvesting': 'Harvesting',
      'observation': 'Observation',
      'weather_event': 'Weather Event',
      'other': 'Other',
    };
    return labels[eventType] ?? eventType;
  }

  /// Emoji for the event type.
  String get eventTypeEmoji {
    const emojis = {
      'fertilizer_application': '🌱',
      'pesticide_application': '🧪',
      'irrigation': '💧',
      'weeding': '🌿',
      'pruning': '✂️',
      'soil_testing': '🔬',
      'seed_treatment': '🌰',
      'transplanting': '🪴',
      'harvesting': '🌾',
      'observation': '👁️',
      'weather_event': '⛅',
      'other': '📝',
    };
    return emojis[eventType] ?? '📝';
  }

  static const List<String> eventTypes = [
    'fertilizer_application',
    'pesticide_application',
    'irrigation',
    'weeding',
    'pruning',
    'soil_testing',
    'seed_treatment',
    'transplanting',
    'harvesting',
    'observation',
    'weather_event',
    'other',
  ];
}
