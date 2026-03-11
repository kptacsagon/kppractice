/// Model representing a crop reservation made by a buyer.
class CropReservation {
  final String id;
  final String listingId;
  final String buyerId;
  final String farmerId;
  
  // Reservation details
  final double quantityKg;
  final double pricePerKg;
  final double totalAmount;
  
  // Status
  final String status;
  
  // Dates
  final DateTime reservationDate;
  final DateTime? pickupDate;
  final DateTime? completedDate;
  
  // Notes
  final String? buyerNotes;
  final String? farmerNotes;
  final String? cancellationReason;
  
  // Contact info snapshot
  final String? buyerName;
  final String? buyerPhone;
  final String? deliveryAddress;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const CropReservation({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.farmerId,
    required this.quantityKg,
    required this.pricePerKg,
    required this.totalAmount,
    this.status = 'pending',
    required this.reservationDate,
    this.pickupDate,
    this.completedDate,
    this.buyerNotes,
    this.farmerNotes,
    this.cancellationReason,
    this.buyerName,
    this.buyerPhone,
    this.deliveryAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if reservation can be cancelled
  bool get canCancel => status == 'pending';
  
  /// Check if reservation is active
  bool get isActive => 
    status == 'pending' || status == 'confirmed' || status == 'ready_for_pickup';
  
  /// Check if reservation is completed successfully
  bool get isCompleted => status == 'completed';
  
  /// Get status color name for UI
  String get statusColorName {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'confirmed':
        return 'blue';
      case 'ready_for_pickup':
        return 'green';
      case 'completed':
        return 'green';
      case 'cancelled':
        return 'red';
      case 'rejected':
        return 'red';
      default:
        return 'grey';
    }
  }

  /// Get human-readable status
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'ready_for_pickup':
        return 'Ready for Pickup';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  /// Get status icon
  String get statusIcon {
    switch (status) {
      case 'pending':
        return '⏳';
      case 'confirmed':
        return '✅';
      case 'ready_for_pickup':
        return '📦';
      case 'completed':
        return '🎉';
      case 'cancelled':
        return '❌';
      case 'rejected':
        return '🚫';
      default:
        return '❓';
    }
  }

  factory CropReservation.fromJson(Map<String, dynamic> json) {
    return CropReservation(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      buyerId: json['buyer_id'] as String,
      farmerId: json['farmer_id'] as String,
      quantityKg: (json['quantity_kg'] as num).toDouble(),
      pricePerKg: (json['price_per_kg'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      reservationDate: DateTime.parse(json['reservation_date'] as String),
      pickupDate: json['pickup_date'] != null 
        ? DateTime.parse(json['pickup_date'] as String) 
        : null,
      completedDate: json['completed_date'] != null 
        ? DateTime.parse(json['completed_date'] as String) 
        : null,
      buyerNotes: json['buyer_notes'] as String?,
      farmerNotes: json['farmer_notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      buyerName: json['buyer_name'] as String?,
      buyerPhone: json['buyer_phone'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_id': listingId,
      'buyer_id': buyerId,
      'farmer_id': farmerId,
      'quantity_kg': quantityKg,
      'price_per_kg': pricePerKg,
      'total_amount': totalAmount,
      'status': status,
      'reservation_date': reservationDate.toIso8601String(),
      'pickup_date': pickupDate?.toIso8601String().split('T')[0],
      'completed_date': completedDate?.toIso8601String(),
      'buyer_notes': buyerNotes,
      'farmer_notes': farmerNotes,
      'cancellation_reason': cancellationReason,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'delivery_address': deliveryAddress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to insert-ready JSON (without id and timestamps)
  Map<String, dynamic> toInsertJson() {
    return {
      'listing_id': listingId,
      'buyer_id': buyerId,
      'farmer_id': farmerId,
      'quantity_kg': quantityKg,
      'price_per_kg': pricePerKg,
      'total_amount': totalAmount,
      'status': status,
      'pickup_date': pickupDate?.toIso8601String().split('T')[0],
      'buyer_notes': buyerNotes,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'delivery_address': deliveryAddress,
    };
  }

  CropReservation copyWith({
    String? id,
    String? listingId,
    String? buyerId,
    String? farmerId,
    double? quantityKg,
    double? pricePerKg,
    double? totalAmount,
    String? status,
    DateTime? reservationDate,
    DateTime? pickupDate,
    DateTime? completedDate,
    String? buyerNotes,
    String? farmerNotes,
    String? cancellationReason,
    String? buyerName,
    String? buyerPhone,
    String? deliveryAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CropReservation(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      buyerId: buyerId ?? this.buyerId,
      farmerId: farmerId ?? this.farmerId,
      quantityKg: quantityKg ?? this.quantityKg,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      reservationDate: reservationDate ?? this.reservationDate,
      pickupDate: pickupDate ?? this.pickupDate,
      completedDate: completedDate ?? this.completedDate,
      buyerNotes: buyerNotes ?? this.buyerNotes,
      farmerNotes: farmerNotes ?? this.farmerNotes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Reservation with associated listing data for display
class ReservationWithListing {
  final CropReservation reservation;
  final String cropName;
  final String? cropIcon;
  final String? farmerName;
  final String saturationLevel;

  const ReservationWithListing({
    required this.reservation,
    required this.cropName,
    this.cropIcon,
    this.farmerName,
    required this.saturationLevel,
  });

  factory ReservationWithListing.fromJson(Map<String, dynamic> json) {
    // Handle joined data from Supabase
    final listingData = json['crop_listings'] as Map<String, dynamic>?;
    
    return ReservationWithListing(
      reservation: CropReservation.fromJson(json),
      cropName: listingData?['crop_name'] as String? ?? 'Unknown',
      cropIcon: listingData?['crop_icon'] as String?,
      farmerName: listingData?['farmer_name'] as String?,
      saturationLevel: listingData?['saturation_level'] as String? ?? 'high',
    );
  }
}
