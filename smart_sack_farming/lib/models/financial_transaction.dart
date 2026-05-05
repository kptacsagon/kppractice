class FinancialTransaction {
  final String id;
  final String userId;
  final String type; // income | expense
  final double amount;
  final String currency;
  final DateTime transactionDate;
  final String category;
  final String? cropId;
  final String? seasonId;
  final String? farmItemId;
  final String? description;
  final String? counterparty;
  final String? notes;
  final String? receiptUrl;
  final String? enteredBy;
  final bool isDeleted;
  final String? localId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? runningBalance;

  FinancialTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.transactionDate,
    required this.category,
    this.cropId,
    this.seasonId,
    this.farmItemId,
    this.description,
    this.counterparty,
    this.notes,
    this.receiptUrl,
    this.enteredBy,
    this.isDeleted = false,
    this.localId,
    this.createdAt,
    this.updatedAt,
    this.runningBalance,
  });

  factory FinancialTransaction.empty({String currency = 'PHP'}) {
    return FinancialTransaction(
      id: '',
      userId: '',
      type: 'income',
      amount: 0,
      currency: currency,
      transactionDate: DateTime.now(),
      category: 'crop_sale',
    );
  }

  FinancialTransaction copyWith({
    String? id,
    String? userId,
    String? type,
    double? amount,
    String? currency,
    DateTime? transactionDate,
    String? category,
    String? cropId,
    String? seasonId,
    String? farmItemId,
    String? description,
    String? counterparty,
    String? notes,
    String? receiptUrl,
    String? enteredBy,
    bool? isDeleted,
    String? localId,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? runningBalance,
  }) {
    return FinancialTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      transactionDate: transactionDate ?? this.transactionDate,
      category: category ?? this.category,
      cropId: cropId ?? this.cropId,
      seasonId: seasonId ?? this.seasonId,
      farmItemId: farmItemId ?? this.farmItemId,
      description: description ?? this.description,
      counterparty: counterparty ?? this.counterparty,
      notes: notes ?? this.notes,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      enteredBy: enteredBy ?? this.enteredBy,
      isDeleted: isDeleted ?? this.isDeleted,
      localId: localId ?? this.localId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      runningBalance: runningBalance ?? this.runningBalance,
    );
  }

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: (json['id'] ?? json['transaction_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      type: (json['type'] ?? 'income').toString(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      currency: (json['currency'] ?? 'PHP').toString(),
      transactionDate: json['transaction_date'] is String
          ? DateTime.parse(json['transaction_date'])
          : json['date'] is String
              ? DateTime.parse(json['date'])
              : DateTime.now(),
      category: (json['category'] ?? '').toString(),
        cropId: json['crop_id']?.toString() ??
          json['cropId']?.toString() ??
          json['farm_item_id']?.toString(),
      seasonId: json['season_id']?.toString() ?? json['seasonId']?.toString(),
      farmItemId: json['farm_item_id']?.toString(),
      description: json['description']?.toString(),
      counterparty: json['counterparty']?.toString(),
      notes: json['notes']?.toString(),
      receiptUrl: json['receipt_url']?.toString(),
      enteredBy: json['entered_by']?.toString(),
      isDeleted: json['is_deleted'] == true,
      localId: json['local_id']?.toString(),
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] is String
          ? DateTime.tryParse(json['updated_at'])
          : null,
      runningBalance: json['running_balance'] is num
          ? (json['running_balance'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'type': type,
      'amount': amount,
      'currency': currency,
      'transaction_date': transactionDate.toIso8601String().split('T').first,
      'category': category,
      'farm_item_id': farmItemId,
      'description': description,
      'counterparty': counterparty,
      'notes': notes,
      'receipt_url': receiptUrl,
      'entered_by': enteredBy,
      'local_id': localId,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'type': type,
      'amount': amount,
      'currency': currency,
      'transaction_date': transactionDate.toIso8601String().split('T').first,
      'category': category,
      'farm_item_id': farmItemId,
      'description': description,
      'counterparty': counterparty,
      'notes': notes,
      'receipt_url': receiptUrl,
    };
  }
}
