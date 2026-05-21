import 'package:supabase_flutter/supabase_flutter.dart';

// PRD §3.2.3 — Crop Declaration Status Lifecycle
// pending_review → validated (BAW) → mao_approved (MAO)
enum CropDeclarationStatus { pendingReview, validated, maoApproved, returned, harvested, cancelled }

String cropStatusToString(CropDeclarationStatus s) {
  switch (s) {
    case CropDeclarationStatus.pendingReview: return 'pending_review';
    case CropDeclarationStatus.validated:     return 'validated';
    case CropDeclarationStatus.maoApproved:   return 'mao_approved';
    case CropDeclarationStatus.returned:      return 'returned';
    case CropDeclarationStatus.harvested:     return 'harvested';
    case CropDeclarationStatus.cancelled:     return 'cancelled';
  }
}

CropDeclarationStatus cropStatusFromString(String? s) {
  switch (s) {
    case 'validated':    return CropDeclarationStatus.validated;
    case 'mao_approved': return CropDeclarationStatus.maoApproved;
    case 'returned':     return CropDeclarationStatus.returned;
    case 'harvested':    return CropDeclarationStatus.harvested;
    case 'cancelled':    return CropDeclarationStatus.cancelled;
    default:             return CropDeclarationStatus.pendingReview;
  }
}

class CropDeclaration {
  final String id;
  final String farmerId;
  final String farmerName;
  final String cropId;
  final String cropName;
  final String? barangay;
  final String? farmLot;
  final double areaPlantedHa;
  final DateTime plantingDate;
  final DateTime expectedHarvestDate;
  final DateTime? actualHarvestDate;
  final double estimatedVolumeKg;
  final double? actualVolumeKg;
  final String? farmingMethod;
  final String? remarks;
  final CropDeclarationStatus status;
  final String? technicianId;
  final String? atNotes;
  final DateTime submittedAt;
  final DateTime? validatedAt;

  CropDeclaration({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.cropId,
    required this.cropName,
    this.barangay,
    this.farmLot,
    required this.areaPlantedHa,
    required this.plantingDate,
    required this.expectedHarvestDate,
    this.actualHarvestDate,
    required this.estimatedVolumeKg,
    this.actualVolumeKg,
    this.farmingMethod,
    this.remarks,
    required this.status,
    this.technicianId,
    this.atNotes,
    required this.submittedAt,
    this.validatedAt,
  });

  factory CropDeclaration.fromJson(Map<String, dynamic> j) => CropDeclaration(
    id: j['id'] as String,
    farmerId: j['farmer_id'] as String,
    farmerName: j['farmer_name'] as String? ?? '',
    cropId: j['crop_id'] as String? ?? '',
    cropName: j['crop_name'] as String? ?? '',
    barangay: j['barangay'] as String?,
    farmLot: j['farm_lot'] as String?,
    areaPlantedHa: (j['area_planted_ha'] as num?)?.toDouble() ?? 0,
    plantingDate: DateTime.parse(j['planting_date'] as String),
    expectedHarvestDate: DateTime.parse(j['expected_harvest_date'] as String),
    actualHarvestDate: j['actual_harvest_date'] != null ? DateTime.parse(j['actual_harvest_date'] as String) : null,
    estimatedVolumeKg: (j['estimated_volume_kg'] as num?)?.toDouble() ?? 0,
    actualVolumeKg: (j['actual_volume_kg'] as num?)?.toDouble(),
    farmingMethod: j['farming_method'] as String?,
    remarks: j['remarks'] as String?,
    status: cropStatusFromString(j['status'] as String?),
    technicianId: j['technician_id'] as String?,
    atNotes: j['at_notes'] as String?,
    submittedAt: DateTime.parse(j['submitted_at'] as String),
    validatedAt: j['validated_at'] != null ? DateTime.parse(j['validated_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmer_id': farmerId,
    'farmer_name': farmerName,
    'crop_id': cropId,
    'crop_name': cropName,
    if (barangay != null) 'barangay': barangay,
    if (farmLot != null) 'farm_lot': farmLot,
    'area_planted_ha': areaPlantedHa,
    'planting_date': plantingDate.toIso8601String(),
    'expected_harvest_date': expectedHarvestDate.toIso8601String(),
    if (actualHarvestDate != null) 'actual_harvest_date': actualHarvestDate!.toIso8601String(),
    'estimated_volume_kg': estimatedVolumeKg,
    if (actualVolumeKg != null) 'actual_volume_kg': actualVolumeKg,
    if (farmingMethod != null) 'farming_method': farmingMethod,
    if (remarks != null) 'remarks': remarks,
    'status': cropStatusToString(status),
    if (technicianId != null) 'technician_id': technicianId,
    if (atNotes != null) 'at_notes': atNotes,
    'submitted_at': submittedAt.toIso8601String(),
    if (validatedAt != null) 'validated_at': validatedAt!.toIso8601String(),
  };

  CropDeclaration copyWith({
    CropDeclarationStatus? status,
    String? technicianId,
    String? atNotes,
    DateTime? validatedAt,
    DateTime? actualHarvestDate,
    double? actualVolumeKg,
  }) => CropDeclaration(
    id: id, farmerId: farmerId, farmerName: farmerName, cropId: cropId, cropName: cropName,
    barangay: barangay, farmLot: farmLot, areaPlantedHa: areaPlantedHa,
    plantingDate: plantingDate, expectedHarvestDate: expectedHarvestDate,
    actualHarvestDate: actualHarvestDate ?? this.actualHarvestDate,
    estimatedVolumeKg: estimatedVolumeKg,
    actualVolumeKg: actualVolumeKg ?? this.actualVolumeKg,
    farmingMethod: farmingMethod, remarks: remarks,
    status: status ?? this.status,
    technicianId: technicianId ?? this.technicianId,
    atNotes: atNotes ?? this.atNotes,
    submittedAt: submittedAt,
    validatedAt: validatedAt ?? this.validatedAt,
  );
}

class CropDeclarationService {
  static final _client = Supabase.instance.client;
  static final List<CropDeclaration> _cache = [];

  bool _isMissingTableError(Object e) {
    final s = e.toString();
    return s.contains('PGRST205') || s.contains('does not exist') || s.contains('42P01');
  }

  Future<void> submitDeclaration(CropDeclaration decl) async {
    try {
      await _client.from('crop_declarations').insert(decl.toJson());
    } catch (e) {
      if (_isMissingTableError(e)) { _cache.add(decl); return; }
      rethrow;
    }
  }

  Future<List<CropDeclaration>> getMyDeclarations(String farmerId) async {
    try {
      final res = await _client.from('crop_declarations').select().eq('farmer_id', farmerId).order('submitted_at', ascending: false);
      return (res as List).map((e) => CropDeclaration.fromJson(e)).toList();
    } catch (e) {
      if (_isMissingTableError(e)) return _cache.where((d) => d.farmerId == farmerId).toList();
      rethrow;
    }
  }

  Future<List<CropDeclaration>> getPendingDeclarations({String? barangay}) async {
    try {
      var q = _client.from('crop_declarations').select().eq('status', 'pending_review');
      if (barangay != null) q = q.eq('barangay', barangay);
      final res = await q.order('submitted_at', ascending: true);
      return (res as List).map((e) => CropDeclaration.fromJson(e)).toList();
    } catch (e) {
      if (_isMissingTableError(e)) {
        return _cache.where((d) => d.status == CropDeclarationStatus.pendingReview && (barangay == null || d.barangay == barangay)).toList();
      }
      rethrow;
    }
  }

  Future<List<CropDeclaration>> getValidatedDeclarations({String? barangay}) async {
    try {
      var q = _client.from('crop_declarations').select().neq('status', 'pending_review').neq('status', 'cancelled');
      if (barangay != null) q = q.eq('barangay', barangay);
      final res = await q.order('expected_harvest_date', ascending: true);
      return (res as List).map((e) => CropDeclaration.fromJson(e)).toList();
    } catch (e) {
      if (_isMissingTableError(e)) {
        return _cache.where((d) => d.status != CropDeclarationStatus.pendingReview && d.status != CropDeclarationStatus.cancelled && (barangay == null || d.barangay == barangay)).toList();
      }
      rethrow;
    }
  }

  Future<List<CropDeclaration>> getAllDeclarations() async {
    try {
      final res = await _client.from('crop_declarations').select().order('submitted_at', ascending: false);
      return (res as List).map((e) => CropDeclaration.fromJson(e)).toList();
    } catch (e) {
      if (_isMissingTableError(e)) return List.from(_cache);
      rethrow;
    }
  }

  Future<void> validateDeclaration(String id, String technicianId) async {
    try {
      await _client.from('crop_declarations').update({
        'status': 'validated',
        'technician_id': technicianId,
        'validated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (_) {
      final idx = _cache.indexWhere((d) => d.id == id);
      if (idx != -1) _cache[idx] = _cache[idx].copyWith(
        status: CropDeclarationStatus.validated,
        technicianId: technicianId,
        validatedAt: DateTime.now(),
      );
    }
  }

  Future<void> returnDeclaration(String id, String technicianId, String notes) async {
    try {
      await _client.from('crop_declarations').update({
        'status': 'returned',
        'technician_id': technicianId,
        'at_notes': notes,
      }).eq('id', id);
    } catch (_) {
      final idx = _cache.indexWhere((d) => d.id == id);
      if (idx != -1) _cache[idx] = _cache[idx].copyWith(
        status: CropDeclarationStatus.returned,
        technicianId: technicianId,
        atNotes: notes,
      );
    }
  }

  Future<void> maoApproveDeclaration(String id, {String? notes}) async {
    try {
      await _client.from('crop_declarations').update({
        'status': 'mao_approved',
        if (notes != null) 'at_notes': notes,
      }).eq('id', id);
    } catch (_) {
      final idx = _cache.indexWhere((d) => d.id == id);
      if (idx != -1) _cache[idx] = _cache[idx].copyWith(
        status: CropDeclarationStatus.maoApproved,
      );
    }
  }

  Future<List<CropDeclaration>> getValidatedForMao({String? barangay}) async {
    try {
      var q = _client.from('crop_declarations').select()
          .eq('status', 'validated');
      if (barangay != null) q = q.eq('barangay', barangay);
      final res = await q.order('submitted_at', ascending: false);
      return (res as List).map((e) => CropDeclaration.fromJson(e)).toList();
    } catch (e) {
      if (_isMissingTableError(e)) {
        return _cache.where((d) =>
          d.status == CropDeclarationStatus.validated &&
          (barangay == null || d.barangay == barangay)).toList();
      }
      rethrow;
    }
  }
}
