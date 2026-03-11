import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crop_listing_model.dart';
import '../models/crop_reservation_model.dart';

/// Service for managing crop listings and reservations in the marketplace.
class MarketplaceService {
  static final MarketplaceService _instance = MarketplaceService._internal();
  factory MarketplaceService() => _instance;
  MarketplaceService._internal();

  SupabaseClient get _client => Supabase.instance.client;
  
  String? get currentUserId => _client.auth.currentUser?.id;

  // ============================================================
  // CROP LISTINGS
  // ============================================================

  /// Fetch all available crop listings (for buyers)
  Future<List<CropListing>> getAvailableListings({
    String? cropName,
    String? saturationLevel,
    double? maxPrice,
  }) async {
    // Build query with filters first, then order last
    var query = _client
        .from('crop_listings')
        .select()
        .eq('status', 'available')
        .gt('available_quantity_kg', 0);

    if (cropName != null && cropName.isNotEmpty) {
      query = query.ilike('crop_name', '%$cropName%');
    }

    if (saturationLevel != null) {
      query = query.eq('saturation_level', saturationLevel);
    }

    if (maxPrice != null) {
      query = query.lte('price_per_kg', maxPrice);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => CropListing.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch oversaturated crop listings specifically
  Future<List<CropListing>> getOversaturatedListings() async {
    final response = await _client
        .from('crop_listings')
        .select()
        .eq('status', 'available')
        .eq('saturation_level', 'high')
        .gt('available_quantity_kg', 0)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => CropListing.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single listing by ID
  Future<CropListing?> getListingById(String listingId) async {
    final response = await _client
        .from('crop_listings')
        .select()
        .eq('id', listingId)
        .maybeSingle();

    if (response == null) return null;
    return CropListing.fromJson(response as Map<String, dynamic>);
  }

  /// Fetch listings by farmer (for farmer's own listing management)
  Future<List<CropListing>> getFarmerListings(String farmerId) async {
    final response = await _client
        .from('crop_listings')
        .select()
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => CropListing.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new crop listing (for farmers)
  Future<CropListing> createListing({
    required String cropName,
    String? cropIcon,
    required double quantityKg,
    required double pricePerKg,
    required String saturationLevel,
    String qualityGrade = 'B',
    DateTime? harvestDate,
    DateTime? expiryDate,
    String? farmLocation,
    String? description,
    String? saturationRecordId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Get farmer name from profile
    final profile = await _client
        .from('profiles')
        .select('full_name, phone')
        .eq('id', userId)
        .maybeSingle();

    final data = {
      'farmer_id': userId,
      'saturation_record_id': saturationRecordId,
      'crop_name': cropName,
      'crop_icon': cropIcon,
      'quantity_kg': quantityKg,
      'available_quantity_kg': quantityKg,
      'price_per_kg': pricePerKg,
      'saturation_level': saturationLevel,
      'quality_grade': qualityGrade,
      'harvest_date': harvestDate?.toIso8601String().split('T')[0],
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'farm_location': farmLocation,
      'description': description,
      'farmer_name': profile?['full_name'],
      'farmer_phone': profile?['phone'],
      'status': 'available',
    };

    final response = await _client
        .from('crop_listings')
        .insert(data)
        .select()
        .single();

    return CropListing.fromJson(response as Map<String, dynamic>);
  }

  /// Update a listing
  Future<void> updateListing(String listingId, Map<String, dynamic> updates) async {
    await _client
        .from('crop_listings')
        .update(updates)
        .eq('id', listingId);
  }

  /// Cancel a listing
  Future<void> cancelListing(String listingId) async {
    await _client
        .from('crop_listings')
        .update({'status': 'cancelled'})
        .eq('id', listingId);
  }

  // ============================================================
  // CROP RESERVATIONS
  // ============================================================

  /// Create a new reservation (for buyers)
  Future<CropReservation> createReservation({
    required String listingId,
    required double quantityKg,
    DateTime? pickupDate,
    String? notes,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Get listing details
    final listing = await getListingById(listingId);
    if (listing == null) throw Exception('Listing not found');
    if (!listing.isAvailable) throw Exception('Listing is no longer available');
    if (quantityKg > listing.availableQuantityKg) {
      throw Exception('Requested quantity exceeds available amount');
    }

    // Get buyer profile
    final profile = await _client
        .from('profiles')
        .select('full_name, phone, address')
        .eq('id', userId)
        .maybeSingle();

    final data = {
      'listing_id': listingId,
      'buyer_id': userId,
      'farmer_id': listing.farmerId,
      'quantity_kg': quantityKg,
      'price_per_kg': listing.pricePerKg,
      'total_amount': quantityKg * listing.pricePerKg,
      'status': 'pending',
      'pickup_date': pickupDate?.toIso8601String().split('T')[0],
      'buyer_notes': notes,
      'buyer_name': profile?['full_name'],
      'buyer_phone': profile?['phone'],
      'delivery_address': profile?['address'],
    };

    final response = await _client
        .from('crop_reservations')
        .insert(data)
        .select()
        .single();

    // Update listing available quantity
    await _client
        .from('crop_listings')
        .update({
          'available_quantity_kg': listing.availableQuantityKg - quantityKg,
        })
        .eq('id', listingId);

    return CropReservation.fromJson(response as Map<String, dynamic>);
  }

  /// Get buyer's reservations
  Future<List<CropReservation>> getBuyerReservations() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('crop_reservations')
        .select()
        .eq('buyer_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => CropReservation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get buyer's reservations with listing data
  Future<List<Map<String, dynamic>>> getBuyerReservationsWithListings() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('crop_reservations')
        .select('''
          *,
          crop_listings (
            crop_name,
            crop_icon,
            farmer_name,
            saturation_level,
            farm_location
          )
        ''')
        .eq('buyer_id', userId)
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get farmer's received reservations
  Future<List<CropReservation>> getFarmerReservations() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('crop_reservations')
        .select()
        .eq('farmer_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => CropReservation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Cancel a reservation (by buyer, only if pending)
  Future<void> cancelReservation(String reservationId, {String? reason}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Get the reservation first
    final reservationResponse = await _client
        .from('crop_reservations')
        .select()
        .eq('id', reservationId)
        .eq('buyer_id', userId)
        .single();

    final reservation = CropReservation.fromJson(
        reservationResponse as Map<String, dynamic>);

    if (!reservation.canCancel) {
      throw Exception('This reservation cannot be cancelled');
    }

    // Update reservation status
    await _client
        .from('crop_reservations')
        .update({
          'status': 'cancelled',
          'cancellation_reason': reason,
        })
        .eq('id', reservationId);

    // Restore listing quantity
    final listing = await getListingById(reservation.listingId);
    if (listing != null) {
      await _client
          .from('crop_listings')
          .update({
            'available_quantity_kg': 
                listing.availableQuantityKg + reservation.quantityKg,
            'status': 'available',
          })
          .eq('id', reservation.listingId);
    }
  }

  /// Update reservation status (by farmer)
  Future<void> updateReservationStatus(
    String reservationId, 
    String newStatus, {
    String? notes,
  }) async {
    final updates = <String, dynamic>{
      'status': newStatus,
    };

    if (notes != null) {
      updates['farmer_notes'] = notes;
    }

    if (newStatus == 'completed') {
      updates['completed_date'] = DateTime.now().toIso8601String();
    }

    await _client
        .from('crop_reservations')
        .update(updates)
        .eq('id', reservationId);
  }

  /// Confirm a reservation (by farmer)
  Future<void> confirmReservation(String reservationId) async {
    await updateReservationStatus(reservationId, 'confirmed');
  }

  /// Mark reservation as ready for pickup (by farmer)
  Future<void> markReadyForPickup(String reservationId) async {
    await updateReservationStatus(reservationId, 'ready_for_pickup');
  }

  /// Complete a reservation (by farmer)
  Future<void> completeReservation(String reservationId) async {
    await updateReservationStatus(reservationId, 'completed');
  }

  /// Reject a reservation (by farmer)
  Future<void> rejectReservation(String reservationId, {String? reason}) async {
    // Get the reservation first
    final reservationResponse = await _client
        .from('crop_reservations')
        .select()
        .eq('id', reservationId)
        .single();

    final reservation = CropReservation.fromJson(
        reservationResponse as Map<String, dynamic>);

    // Update reservation status
    await _client
        .from('crop_reservations')
        .update({
          'status': 'rejected',
          'cancellation_reason': reason,
        })
        .eq('id', reservationId);

    // Restore listing quantity
    final listing = await getListingById(reservation.listingId);
    if (listing != null) {
      await _client
          .from('crop_listings')
          .update({
            'available_quantity_kg': 
                listing.availableQuantityKg + reservation.quantityKg,
            'status': 'available',
          })
          .eq('id', reservation.listingId);
    }
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// Get marketplace statistics for dashboard
  Future<Map<String, dynamic>> getMarketplaceStats() async {
    final listings = await _client
        .from('crop_listings')
        .select('status, saturation_level')
        .eq('status', 'available');

    final totalListings = (listings as List).length;
    final highSaturation = listings.where(
        (l) => l['saturation_level'] == 'high').length;

    return {
      'total_listings': totalListings,
      'high_saturation_count': highSaturation,
    };
  }
}
