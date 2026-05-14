class AgrisensePestReport {
  final String? id;
  final String farmerId;
  final String? farmId;
  final String municipality;
  final String cropType;
  final String pestType;
  final String severity;
  final String? photoUrl;
  final String status;
  final DateTime reportedAt;

  AgrisensePestReport({
    this.id,
    required this.farmerId,
    this.farmId,
    required this.municipality,
    required this.cropType,
    required this.pestType,
    required this.severity,
    this.photoUrl,
    this.status = 'Pending',
    required this.reportedAt,
  });

  factory AgrisensePestReport.fromJson(Map<String, dynamic> json) {
    return AgrisensePestReport(
      id: json['id'],
      farmerId: json['farmer_id'],
      farmId: json['farm_id'],
      municipality: json['municipality'],
      cropType: json['crop_type'],
      pestType: json['pest_type'],
      severity: json['severity'],
      photoUrl: json['photo_url'],
      status: json['status'] ?? 'Pending',
      reportedAt: DateTime.parse(json['reported_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmer_id': farmerId,
      'farm_id': farmId,
      'municipality': municipality,
      'crop_type': cropType,
      'pest_type': pestType,
      'severity': severity,
      'photo_url': photoUrl,
      'status': status,
      'reported_at': reportedAt.toIso8601String(),
    };
  }
}
