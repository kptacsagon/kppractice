class MarketEndorsement {
  final String id;
  final String plantingRecordId;
  final String maoId;
  final DateTime endorsementDate;
  final double startingBidPrice;
  final double? currentHighestBid;
  final String status; // 'Open' or 'Closed'

  MarketEndorsement({
    required this.id,
    required this.plantingRecordId,
    required this.maoId,
    required this.endorsementDate,
    required this.startingBidPrice,
    this.currentHighestBid,
    required this.status,
  });

  factory MarketEndorsement.fromJson(Map<String, dynamic> json) {
    return MarketEndorsement(
      id: json['id'] as String,
      plantingRecordId: json['planting_record_id'] as String,
      maoId: json['mao_id'] as String,
      endorsementDate: DateTime.parse(json['endorsement_date'] as String),
      startingBidPrice: (json['starting_bid_price'] as num).toDouble(),
      currentHighestBid: json['current_highest_bid'] == null ? null : (json['current_highest_bid'] as num).toDouble(),
      status: json['status'] as String,
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
    };
  }
}
