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
  final Map<String, dynamic>? financialProfile;
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
    this.financialProfile,
    this.verificationStatus = 'Pending',
  });

  factory AgrisenseFarmerProfile.fromJson(Map<String, dynamic> json) {
    return AgrisenseFarmerProfile(
      id: json['id'],
      userId: json['user_id'],
      rsbsaNumber: json['rsbsa_number'],
      fullName: json['full_name'],
      age: json['age'],
      sex: json['sex'],
      civilStatus: json['civil_status'],
      contactNumber: json['contact_number'],
      address: json['address'],
      barangay: json['barangay'],
      municipality: json['municipality'],
      province: json['province'],
      farmingExperienceYears: json['farming_experience_years'],
      irrigationAccess: json['irrigation_access'],
      farmingMethod: json['farming_method'],
      equipmentOwned: List<String>.from(json['equipment_owned'] ?? []),
      primaryCrops: List<String>.from(json['primary_crops'] ?? []),
      preferredCrops: List<String>.from(json['preferred_crops'] ?? []),
      farmOwnershipType: json['farm_ownership_type'],
      marketAccess: json['market_access'],
      languagePreference: json['language_preference'],
      literacyPreference: json['literacy_preference'],
      financialProfile: json['financial_profile'] as Map<String, dynamic>?,
      verificationStatus: json['verification_status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'rsbsa_number': rsbsaNumber,
      'full_name': fullName,
      'age': age,
      'sex': sex,
      'civil_status': civilStatus,
      'contact_number': contactNumber,
      'address': address,
      'barangay': barangay,
      'municipality': municipality,
      'province': province,
      'farming_experience_years': farmingExperienceYears,
      'irrigation_access': irrigationAccess,
      'farming_method': farmingMethod,
      'equipment_owned': equipmentOwned,
      'primary_crops': primaryCrops,
      'preferred_crops': preferredCrops,
      'farm_ownership_type': farmOwnershipType,
      'market_access': marketAccess,
      'language_preference': languagePreference,
      'literacy_preference': literacyPreference,
      'financial_profile': financialProfile,
      'verification_status': verificationStatus,
    };
  }
}
