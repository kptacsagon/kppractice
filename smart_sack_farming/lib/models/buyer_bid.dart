enum BuyerBidStatus { pending, accepted, rejected }

extension BuyerBidStatusExt on BuyerBidStatus {
  String get name {
    switch (this) {
      case BuyerBidStatus.pending:
        return 'Pending';
      case BuyerBidStatus.accepted:
        return 'Accepted';
      case BuyerBidStatus.rejected:
        return 'Rejected';
    }
  }

  static BuyerBidStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return BuyerBidStatus.pending;
      case 'accepted':
        return BuyerBidStatus.accepted;
      case 'rejected':
        return BuyerBidStatus.rejected;
      default:
        throw ArgumentError('Unknown bid status: $s');
    }
  }
}

class BuyerBid {
  final String id;
  final String endorsementId;
  final String buyerId;
  final double bidAmount;
  final DateTime bidDate;
  final BuyerBidStatus status;

  BuyerBid({
    required this.id,
    required this.endorsementId,
    required this.buyerId,
    required this.bidAmount,
    required this.bidDate,
    required this.status,
  });

  factory BuyerBid.fromJson(Map<String, dynamic> json) {
    return BuyerBid(
      id: json['id'] as String,
      endorsementId: json['endorsement_id'] as String,
      buyerId: json['buyer_id'] as String,
      bidAmount: (json['bid_amount'] as num).toDouble(),
      bidDate: DateTime.parse(json['bid_date'] as String),
      status: BuyerBidStatusExt.fromString(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'endorsement_id': endorsementId,
      'buyer_id': buyerId,
      'bid_amount': bidAmount,
      'bid_date': bidDate.toIso8601String(),
      'status': status.name,
    };
  }
}
