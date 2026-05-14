class AgrisenseProgramEnrollment {
  final String? id;
  final String farmerId;
  final String programName;
  final String status;
  final DateTime? enrolledDate;
  final DateTime? expiryDate;
  final String? referenceNumber;

  AgrisenseProgramEnrollment({
    this.id,
    required this.farmerId,
    required this.programName,
    required this.status,
    this.enrolledDate,
    this.expiryDate,
    this.referenceNumber,
  });

  factory AgrisenseProgramEnrollment.fromJson(Map<String, dynamic> json) {
    return AgrisenseProgramEnrollment(
      id: json['id'],
      farmerId: json['farmer_id'],
      programName: json['program_name'],
      status: json['status'],
      enrolledDate: json['enrolled_date'] == null
          ? null
          : DateTime.parse(json['enrolled_date']),
      expiryDate: json['expiry_date'] == null
          ? null
          : DateTime.parse(json['expiry_date']),
      referenceNumber: json['reference_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmer_id': farmerId,
      'program_name': programName,
      'status': status,
      'enrolled_date': enrolledDate?.toIso8601String().split('T')[0],
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'reference_number': referenceNumber,
    };
  }
}
