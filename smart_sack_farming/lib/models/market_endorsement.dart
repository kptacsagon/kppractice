class MarketEndorsement {
  final String id;
  final String plantingRecordId;
  final String? maoId;
  final DateTime endorsementDate;
  final double startingBidPrice;
  final double? currentHighestBid;
  final String status; // 'Open' or 'Closed'
  final String? cropName;
  final DateTime? plantingDate;
  final DateTime? expectedHarvestDate;
  final double? areaPlantedHa;
  final double? estimatedYieldMt;
  final String? farmerId;
  final String? farmerName;
  final String? farmerAddress;

  MarketEndorsement({
    required this.id,
    required this.plantingRecordId,
    this.maoId,
    required this.endorsementDate,
    required this.startingBidPrice,
    this.currentHighestBid,
    required this.status,
    this.cropName,
    this.plantingDate,
    this.expectedHarvestDate,
    this.areaPlantedHa,
    this.estimatedYieldMt,
    this.farmerId,
    this.farmerName,
    this.farmerAddress,
  });

  factory MarketEndorsement.fromJson(Map<String, dynamic> json) {
    final planting = json['planting_records'] is Map<String, dynamic>
        ? json['planting_records'] as Map<String, dynamic>
        : null;

    return MarketEndorsement(
      id: json['id'] as String,
      plantingRecordId: json['planting_record_id'] as String,
      maoId: json['mao_id'] as String?,
      endorsementDate: DateTime.parse(json['endorsement_date'] as String),
      startingBidPrice: (json['starting_bid_price'] as num).toDouble(),
      currentHighestBid: json['current_highest_bid'] == null ? null : (json['current_highest_bid'] as num).toDouble(),
      status: json['status'] as String,
      cropName: (json['crop_name'] ?? planting?['crop_name'])?.toString(),
      plantingDate: _tryParseDate(json['planting_date'] ?? planting?['planting_date']),
      expectedHarvestDate:
          _tryParseDate(json['expected_harvest_date'] ?? planting?['expected_harvest_date']),
      areaPlantedHa: _toDouble(json['area_planted_ha'] ?? planting?['area_planted_ha']),
      estimatedYieldMt:
          _toDouble(json['estimated_yield_mt'] ?? planting?['estimated_yield_mt']),
      farmerId: (json['farmer_id'] ?? planting?['farmer_id'])?.toString(),
      farmerName: json['farmer_name']?.toString(),
      farmerAddress: json['farmer_address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planting_record_id': plantingRecordId,
      'mao_id': maoId,
      'endorsement_date': endorsementDate.toIso8601String(),
      'starting_bid_price': startingBidPrice,
      'current_highest_bid': currentHighestBid,
      'status': status,
      'crop_name': cropName,
      'planting_date': plantingDate?.toIso8601String(),
      'expected_harvest_date': expectedHarvestDate?.toIso8601String(),
      'area_planted_ha': areaPlantedHa,
      'estimated_yield_mt': estimatedYieldMt,
      'farmer_id': farmerId,
      'farmer_name': farmerName,
      'farmer_address': farmerAddress,
    };
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final text = value.toString();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
