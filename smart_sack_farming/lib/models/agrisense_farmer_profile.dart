class AgrisenseFarmerProfile {
  final String? id;
  final String userId;
  final String? rsbsaNumber;
  final String fullName;
  final int? age;
  final String? sex;
  final String? civilStatus;
  final String? contactNumber;
  final String? address;
  final String barangay;
  final String municipality;
  final String province;
  final int? farmingExperienceYears;
  final String? irrigationAccess;
  final String? farmingMethod;
  final List<String> equipmentOwned;
  final List<String> primaryCrops;
  final List<String> preferredCrops;
  final String? farmOwnershipType;
  final String? marketAccess;
  final String? languagePreference;
  final String? literacyPreference;
  final String verificationStatus;

  AgrisenseFarmerProfile({
    this.id,
    required this.userId,
    this.rsbsaNumber,
    required this.fullName,
    this.age,
    this.sex,
    this.civilStatus,
    this.contactNumber,
    this.address,
    required this.barangay,
    required this.municipality,
    required this.province,
    this.farmingExperienceYears,
    this.irrigationAccess,
    this.farmingMethod,
    this.equipmentOwned = const [],
    this.primaryCrops = const [],
    this.preferredCrops = const [],
    this.farmOwnershipType,
    this.marketAccess,
    this.languagePreference,
    this.literacyPreference,
    this.verificationStatus = 'Pending',
  });

  factory AgrisenseFarmerProfile.fromJson(Map<String, dynamic> json) {
    return AgrisenseFarmerProfile(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      rsbsaNumber: json['rsbsa_number'] as String?,
      fullName: (json['full_name'] as String?) ?? '',
      age: json['age'] as int?,
      sex: json['sex'] as String?,
      civilStatus: json['civil_status'] as String?,
      contactNumber: json['contact_number'] as String?,
      address: json['address'] as String?,
      barangay: (json['barangay'] as String?) ?? '',
      municipality: (json['municipality'] as String?) ?? 'Tubungan',
      province: (json['province'] as String?) ?? 'Iloilo',
      farmingExperienceYears: json['farming_experience_years'] as int?,
      irrigationAccess: json['irrigation_access'] as String?,
      farmingMethod: json['farming_method'] as String?,
      equipmentOwned: List<String>.from(json['equipment_owned'] ?? []),
      primaryCrops: List<String>.from(json['primary_crops'] ?? []),
      preferredCrops: List<String>.from(json['preferred_crops'] ?? []),
      farmOwnershipType: json['farm_ownership_type'] as String?,
      marketAccess: json['market_access'] as String?,
      languagePreference: json['language_preference'] as String?,
      literacyPreference: json['literacy_preference'] as String?,
      verificationStatus: (json['verification_status'] as String?) ?? 'Pending',
    );
  }

  /// Returns a payload safe to send to Supabase.
  /// - Includes [id] so upsert targets the correct existing row.
  /// - Skips null optional fields to avoid PGRST204 on columns
  ///   that have not yet been added via migration.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'user_id': userId,
      'full_name': fullName,
      'barangay': barangay,
      'municipality': municipality,
      'province': province,
      'verification_status': verificationStatus,
      'equipment_owned': equipmentOwned,
      'primary_crops': primaryCrops,
      'preferred_crops': preferredCrops,
    };

    // Include id for upsert to update the correct row instead of inserting a duplicate.
    if (id != null) map['id'] = id;

    // Optional fields — only included when non-null to prevent PGRST204
    // errors on databases that have not yet run the full schema migration.
    if (rsbsaNumber != null)          map['rsbsa_number']             = rsbsaNumber;
    if (age != null)                  map['age']                      = age;
    if (sex != null)                  map['sex']                      = sex;
    if (civilStatus != null)          map['civil_status']             = civilStatus;
    if (contactNumber != null)        map['contact_number']           = contactNumber;
    if (address != null)              map['address']                  = address;
    if (farmingExperienceYears != null) map['farming_experience_years'] = farmingExperienceYears;
    if (irrigationAccess != null)     map['irrigation_access']        = irrigationAccess;
    if (farmingMethod != null)        map['farming_method']           = farmingMethod;
    if (farmOwnershipType != null)    map['farm_ownership_type']      = farmOwnershipType;
    if (marketAccess != null)         map['market_access']            = marketAccess;
    if (languagePreference != null)   map['language_preference']      = languagePreference;
    if (literacyPreference != null)   map['literacy_preference']      = literacyPreference;

    return map;
  }
}
