// ─────────────────────────────────────────────────────────────────────────────
// AgriFinancialInputService — Farmer → BAW → MAO Crop Cycle Journal pipeline
//
// Captures full 6-stage crop cycle data:
//   1. Pre-Planting   2. Planting    3. Maintenance
//   4. Harvest        5. Post-Harvest 6. Sales
//
// Status lifecycle: pending_baw → baw_verified / baw_returned → mao_approved
// Falls back to in-memory cache when the table doesn't exist yet.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:supabase_flutter/supabase_flutter.dart';

enum FinInputStatus { pendingBaw, bawVerified, bawReturned, maoApproved, maoRejected }

extension FinInputStatusExt on FinInputStatus {
  String get value {
    switch (this) {
      case FinInputStatus.pendingBaw:   return 'pending_baw';
      case FinInputStatus.bawVerified:  return 'baw_verified';
      case FinInputStatus.bawReturned:  return 'baw_returned';
      case FinInputStatus.maoApproved:  return 'mao_approved';
      case FinInputStatus.maoRejected:  return 'mao_rejected';
    }
  }

  String get label {
    switch (this) {
      case FinInputStatus.pendingBaw:   return 'Pending BAW Review';
      case FinInputStatus.bawVerified:  return 'BAW Verified';
      case FinInputStatus.bawReturned:  return 'Returned for Correction';
      case FinInputStatus.maoApproved:  return 'MAO Approved';
      case FinInputStatus.maoRejected:  return 'MAO Rejected';
    }
  }

  static FinInputStatus fromString(String? s) {
    switch (s) {
      case 'baw_verified':  return FinInputStatus.bawVerified;
      case 'baw_returned':  return FinInputStatus.bawReturned;
      case 'mao_approved':  return FinInputStatus.maoApproved;
      case 'mao_rejected':  return FinInputStatus.maoRejected;
      default:              return FinInputStatus.pendingBaw;
    }
  }
}

/// BAW 5-point verification checklist (PRD §3.3 — BAW Validator role)
class BawVerificationChecklist {
  final bool areaVerified;
  final bool cropVerified;
  final bool yieldReasonable;
  final bool lossesValidated;
  final bool marketConfirmed;
  const BawVerificationChecklist({
    this.areaVerified = false,
    this.cropVerified = false,
    this.yieldReasonable = false,
    this.lossesValidated = false,
    this.marketConfirmed = false,
  });

  bool get isComplete =>
      areaVerified && cropVerified && yieldReasonable && lossesValidated && marketConfirmed;

  int get checkedCount => [areaVerified, cropVerified, yieldReasonable, lossesValidated, marketConfirmed]
      .where((b) => b).length;

  Map<String, dynamic> toJson() => {
    'area_verified': areaVerified,
    'crop_verified': cropVerified,
    'yield_reasonable': yieldReasonable,
    'losses_validated': lossesValidated,
    'market_confirmed': marketConfirmed,
  };

  factory BawVerificationChecklist.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const BawVerificationChecklist();
    return BawVerificationChecklist(
      areaVerified:     j['area_verified'] as bool? ?? false,
      cropVerified:     j['crop_verified'] as bool? ?? false,
      yieldReasonable:  j['yield_reasonable'] as bool? ?? false,
      lossesValidated:  j['losses_validated'] as bool? ?? false,
      marketConfirmed:  j['market_confirmed'] as bool? ?? false,
    );
  }
}

class FinancialInputRecord {
  final String id;
  final String farmerId;
  final String farmerName;
  final String barangay;
  final FinInputStatus status;
  final DateTime submittedAt;

  // ── Stage 0: Crop metadata ────────────────────────────────────────────────
  final String cropType;
  final String cropVariety;
  final double areaPlantedHa;
  final DateTime plantingDate;
  final DateTime expectedHarvestDate;

  // ── Stage 1: Pre-Planting ─────────────────────────────────────────────────
  final double landPrepCost;      // PHP
  final double soilPrepCost;      // PHP
  final String seedSource;        // certified | saved | cooperative | other
  final double seedQtyKg;
  final double seedCostPhp;

  // ── Stage 2: Planting ─────────────────────────────────────────────────────
  final double laborPlantingPhp;
  final double fertBasalPhp;
  final double irrigationPhp;
  final double pesticidePlantingPhp;

  // ── Stage 3: Maintenance ──────────────────────────────────────────────────
  final double laborWeedingPhp;
  final double sprayingCostPhp;
  final double fertTopDressPhp;       // additional fertilizer (top-dress)
  final String pestIncidents;          // free text describing incidents

  // ── Stage 4: Harvest ──────────────────────────────────────────────────────
  final double laborHarvestingPhp;
  final double grossHarvestKg;
  final double marketableYieldKg;
  final double damagedYieldKg;
  final double rejectedYieldKg;

  // ── Stage 5: Post-Harvest ─────────────────────────────────────────────────
  final double storageLossKg;
  final double unsoldKg;
  final double transportPhp;
  final double packagingPhp;

  // ── Stage 6: Sales ────────────────────────────────────────────────────────
  final double sellingPricePhp;       // PHP/kg
  final String buyerType;              // trader | cooperative | institutional | direct | market
  final double quantitySoldKg;

  // ── Fixed costs (overhead) ────────────────────────────────────────────────
  final double landRentalPhp;
  final double equipmentDeprecPhp;

  // ── BAW verification ──────────────────────────────────────────────────────
  final String? bawVerifierId;
  final String? bawNotes;
  final DateTime? bawReviewedAt;
  final BawVerificationChecklist bawChecklist;

  // ── MAO ───────────────────────────────────────────────────────────────────
  final String? maoNotes;

  const FinancialInputRecord({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.barangay,
    required this.status,
    required this.submittedAt,
    // crop metadata
    required this.cropType,
    required this.cropVariety,
    required this.areaPlantedHa,
    required this.plantingDate,
    required this.expectedHarvestDate,
    // pre-planting
    this.landPrepCost = 0,
    this.soilPrepCost = 0,
    this.seedSource = 'certified',
    this.seedQtyKg = 0,
    this.seedCostPhp = 0,
    // planting
    this.laborPlantingPhp = 0,
    this.fertBasalPhp = 0,
    this.irrigationPhp = 0,
    this.pesticidePlantingPhp = 0,
    // maintenance
    this.laborWeedingPhp = 0,
    this.sprayingCostPhp = 0,
    this.fertTopDressPhp = 0,
    this.pestIncidents = '',
    // harvest
    this.laborHarvestingPhp = 0,
    this.grossHarvestKg = 0,
    this.marketableYieldKg = 0,
    this.damagedYieldKg = 0,
    this.rejectedYieldKg = 0,
    // post-harvest
    this.storageLossKg = 0,
    this.unsoldKg = 0,
    this.transportPhp = 0,
    this.packagingPhp = 0,
    // sales
    this.sellingPricePhp = 0,
    this.buyerType = 'trader',
    this.quantitySoldKg = 0,
    // overhead
    this.landRentalPhp = 0,
    this.equipmentDeprecPhp = 0,
    // BAW
    this.bawVerifierId,
    this.bawNotes,
    this.bawReviewedAt,
    this.bawChecklist = const BawVerificationChecklist(),
    this.maoNotes,
  });

  // ── Computed financials ────────────────────────────────────────────────────

  double get totalPesticidePhp => pesticidePlantingPhp + sprayingCostPhp;
  double get totalFertilizerPhp => fertBasalPhp + fertTopDressPhp;
  double get totalLaborPhp => laborPlantingPhp + laborWeedingPhp + laborHarvestingPhp;

  /// Realized revenue = quantity actually sold × selling price.
  double get grossRevenue => quantitySoldKg * sellingPricePhp;

  /// Loss value = unsold + damaged + rejected at selling price.
  double get totalLossValue => (unsoldKg + damagedYieldKg + rejectedYieldKg) * sellingPricePhp;

  double get totalVariableCost =>
      landPrepCost + soilPrepCost + seedCostPhp +
      totalFertilizerPhp + totalPesticidePhp + totalLaborPhp +
      irrigationPhp + transportPhp + packagingPhp;

  double get totalFixedCost => landRentalPhp + equipmentDeprecPhp;
  double get totalCost => totalVariableCost + totalFixedCost;
  double get netFarmIncome => grossRevenue - totalCost;
  double get contributionMargin => grossRevenue - totalVariableCost;
  double get cmr => grossRevenue == 0 ? 0 : (contributionMargin / grossRevenue) * 100;
  double get breakEvenPrice => marketableYieldKg == 0 ? 0 : totalCost / marketableYieldKg;
  double get yieldPerHa => areaPlantedHa == 0 ? 0 : grossHarvestKg / areaPlantedHa;
  double get marketableYieldPerHa => areaPlantedHa == 0 ? 0 : marketableYieldKg / areaPlantedHa;
  double get revenuePerHa => areaPlantedHa == 0 ? 0 : grossRevenue / areaPlantedHa;
  double get lossRatePct =>
      grossHarvestKg == 0 ? 0 : ((damagedYieldKg + rejectedYieldKg + storageLossKg) / grossHarvestKg) * 100;
  double get unsoldRatePct =>
      marketableYieldKg == 0 ? 0 : (unsoldKg / marketableYieldKg) * 100;
  double get safetyMarginPct {
    final beRev = cmr == 0 ? 0 : (totalFixedCost / cmr) * 100;
    return grossRevenue == 0 ? 0 : ((grossRevenue - beRev) / grossRevenue) * 100;
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmer_id': farmerId,
    'farmer_name': farmerName,
    'barangay': barangay,
    'status': status.value,
    'submitted_at': submittedAt.toIso8601String(),
    // crop
    'crop_type': cropType,
    'crop_variety': cropVariety,
    'area_planted_ha': areaPlantedHa,
    'planting_date': plantingDate.toIso8601String().split('T').first,
    'expected_harvest_date': expectedHarvestDate.toIso8601String().split('T').first,
    // pre-planting
    'land_prep_cost': landPrepCost,
    'soil_prep_cost': soilPrepCost,
    'seed_source': seedSource,
    'seed_qty_kg': seedQtyKg,
    'seed_cost_php': seedCostPhp,
    // planting
    'labor_planting_php': laborPlantingPhp,
    'fert_basal_php': fertBasalPhp,
    'irrigation_php': irrigationPhp,
    'pesticide_planting_php': pesticidePlantingPhp,
    // maintenance
    'labor_weeding_php': laborWeedingPhp,
    'spraying_cost_php': sprayingCostPhp,
    'fert_top_dress_php': fertTopDressPhp,
    'pest_incidents': pestIncidents,
    // harvest
    'labor_harvesting_php': laborHarvestingPhp,
    'gross_harvest_kg': grossHarvestKg,
    'marketable_yield_kg': marketableYieldKg,
    'damaged_yield_kg': damagedYieldKg,
    'rejected_yield_kg': rejectedYieldKg,
    // post-harvest
    'storage_loss_kg': storageLossKg,
    'unsold_kg': unsoldKg,
    'transport_php': transportPhp,
    'packaging_php': packagingPhp,
    // sales
    'selling_price_php': sellingPricePhp,
    'buyer_type': buyerType,
    'quantity_sold_kg': quantitySoldKg,
    // overhead
    'land_rental_php': landRentalPhp,
    'equipment_deprec_php': equipmentDeprecPhp,
    // BAW
    if (bawVerifierId != null) 'baw_verifier_id': bawVerifierId,
    if (bawNotes != null) 'baw_notes': bawNotes,
    if (bawReviewedAt != null) 'baw_reviewed_at': bawReviewedAt!.toIso8601String(),
    'baw_checklist': bawChecklist.toJson(),
    if (maoNotes != null) 'mao_notes': maoNotes,
  };

  factory FinancialInputRecord.fromJson(Map<String, dynamic> j) => FinancialInputRecord(
    id: j['id'] as String,
    farmerId: j['farmer_id'] as String,
    farmerName: j['farmer_name'] as String? ?? '',
    barangay: j['barangay'] as String? ?? '',
    status: FinInputStatusExt.fromString(j['status'] as String?),
    submittedAt: DateTime.parse(j['submitted_at'] as String),
    // crop
    cropType: j['crop_type'] as String? ?? '',
    cropVariety: j['crop_variety'] as String? ?? '',
    areaPlantedHa: _d(j['area_planted_ha']),
    plantingDate: DateTime.parse(j['planting_date'] as String),
    expectedHarvestDate: DateTime.parse(j['expected_harvest_date'] as String),
    // pre-planting
    landPrepCost: _d(j['land_prep_cost']),
    soilPrepCost: _d(j['soil_prep_cost']),
    seedSource: j['seed_source'] as String? ?? 'certified',
    seedQtyKg: _d(j['seed_qty_kg']),
    seedCostPhp: _d(j['seed_cost_php']),
    // planting
    laborPlantingPhp: _d(j['labor_planting_php']),
    fertBasalPhp: _d(j['fert_basal_php']),
    irrigationPhp: _d(j['irrigation_php']),
    pesticidePlantingPhp: _d(j['pesticide_planting_php']),
    // maintenance
    laborWeedingPhp: _d(j['labor_weeding_php']),
    sprayingCostPhp: _d(j['spraying_cost_php']),
    fertTopDressPhp: _d(j['fert_top_dress_php']),
    pestIncidents: j['pest_incidents'] as String? ?? '',
    // harvest
    laborHarvestingPhp: _d(j['labor_harvesting_php']),
    grossHarvestKg: _d(j['gross_harvest_kg']),
    marketableYieldKg: _d(j['marketable_yield_kg']),
    damagedYieldKg: _d(j['damaged_yield_kg']),
    rejectedYieldKg: _d(j['rejected_yield_kg']),
    // post-harvest
    storageLossKg: _d(j['storage_loss_kg']),
    unsoldKg: _d(j['unsold_kg']),
    transportPhp: _d(j['transport_php']),
    packagingPhp: _d(j['packaging_php']),
    // sales
    sellingPricePhp: _d(j['selling_price_php']),
    buyerType: j['buyer_type'] as String? ?? 'trader',
    quantitySoldKg: _d(j['quantity_sold_kg']),
    // overhead
    landRentalPhp: _d(j['land_rental_php']),
    equipmentDeprecPhp: _d(j['equipment_deprec_php']),
    // BAW
    bawVerifierId: j['baw_verifier_id'] as String?,
    bawNotes: j['baw_notes'] as String?,
    bawReviewedAt: j['baw_reviewed_at'] != null ? DateTime.parse(j['baw_reviewed_at'] as String) : null,
    bawChecklist: BawVerificationChecklist.fromJson(j['baw_checklist'] as Map<String, dynamic>?),
    maoNotes: j['mao_notes'] as String?,
  );

  static double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;

  FinancialInputRecord copyWith({
    FinInputStatus? status,
    String? bawVerifierId,
    String? bawNotes,
    DateTime? bawReviewedAt,
    BawVerificationChecklist? bawChecklist,
    String? maoNotes,
  }) => FinancialInputRecord(
    id: id, farmerId: farmerId, farmerName: farmerName, barangay: barangay,
    status: status ?? this.status, submittedAt: submittedAt,
    cropType: cropType, cropVariety: cropVariety, areaPlantedHa: areaPlantedHa,
    plantingDate: plantingDate, expectedHarvestDate: expectedHarvestDate,
    landPrepCost: landPrepCost, soilPrepCost: soilPrepCost,
    seedSource: seedSource, seedQtyKg: seedQtyKg, seedCostPhp: seedCostPhp,
    laborPlantingPhp: laborPlantingPhp, fertBasalPhp: fertBasalPhp,
    irrigationPhp: irrigationPhp, pesticidePlantingPhp: pesticidePlantingPhp,
    laborWeedingPhp: laborWeedingPhp, sprayingCostPhp: sprayingCostPhp,
    fertTopDressPhp: fertTopDressPhp, pestIncidents: pestIncidents,
    laborHarvestingPhp: laborHarvestingPhp, grossHarvestKg: grossHarvestKg,
    marketableYieldKg: marketableYieldKg, damagedYieldKg: damagedYieldKg,
    rejectedYieldKg: rejectedYieldKg,
    storageLossKg: storageLossKg, unsoldKg: unsoldKg,
    transportPhp: transportPhp, packagingPhp: packagingPhp,
    sellingPricePhp: sellingPricePhp, buyerType: buyerType, quantitySoldKg: quantitySoldKg,
    landRentalPhp: landRentalPhp, equipmentDeprecPhp: equipmentDeprecPhp,
    bawVerifierId: bawVerifierId ?? this.bawVerifierId,
    bawNotes: bawNotes ?? this.bawNotes,
    bawReviewedAt: bawReviewedAt ?? this.bawReviewedAt,
    bawChecklist: bawChecklist ?? this.bawChecklist,
    maoNotes: maoNotes ?? this.maoNotes,
  );
}

// ─── Service ──────────────────────────────────────────────────────────────────

class AgriFinancialInputService {
  static final _client = Supabase.instance.client;
  static final List<FinancialInputRecord> _cache = [];
  static const _table = 'agri_financial_inputs';

  bool _isMissing(Object e) {
    final s = e.toString();
    return s.contains('PGRST205') || s.contains('does not exist') || s.contains('42P01');
  }

  Future<void> submitInput(FinancialInputRecord record) async {
    try {
      await _client.from(_table).insert(record.toJson());
    } catch (e) {
      if (_isMissing(e)) { _cache.add(record); return; }
      rethrow;
    }
  }

  Future<List<FinancialInputRecord>> getMySubmissions(String farmerId) async {
    try {
      final res = await _client.from(_table).select()
          .eq('farmer_id', farmerId)
          .order('submitted_at', ascending: false);
      return (res as List).map((e) => FinancialInputRecord.fromJson(e)).toList();
    } catch (e) {
      if (_isMissing(e)) return _cache.where((r) => r.farmerId == farmerId).toList();
      rethrow;
    }
  }

  Future<List<FinancialInputRecord>> getPendingForBaw({String? barangay}) async {
    try {
      var q = _client.from(_table).select().eq('status', FinInputStatus.pendingBaw.value);
      if (barangay != null) q = q.eq('barangay', barangay);
      final res = await q.order('submitted_at', ascending: true);
      return (res as List).map((e) => FinancialInputRecord.fromJson(e)).toList();
    } catch (e) {
      if (_isMissing(e)) {
        return _cache.where((r) =>
          r.status == FinInputStatus.pendingBaw &&
          (barangay == null || r.barangay == barangay)).toList();
      }
      rethrow;
    }
  }

  Future<void> bawVerify(String id, String bawId, BawVerificationChecklist checklist, {String? notes}) async {
    final payload = {
      'status': FinInputStatus.bawVerified.value,
      'baw_verifier_id': bawId,
      'baw_checklist': checklist.toJson(),
      if (notes != null) 'baw_notes': notes,
      'baw_reviewed_at': DateTime.now().toIso8601String(),
    };
    try {
      await _client.from(_table).update(payload).eq('id', id);
    } catch (e) {
      _updateCache(id, FinInputStatus.bawVerified,
          bawNotes: notes, bawVerifierId: bawId, checklist: checklist);
    }
  }

  Future<void> bawReturn(String id, String bawId, String notes) async {
    final payload = {
      'status': FinInputStatus.bawReturned.value,
      'baw_verifier_id': bawId,
      'baw_notes': notes,
      'baw_reviewed_at': DateTime.now().toIso8601String(),
    };
    try {
      await _client.from(_table).update(payload).eq('id', id);
    } catch (e) {
      _updateCache(id, FinInputStatus.bawReturned, bawNotes: notes, bawVerifierId: bawId);
    }
  }

  Future<List<FinancialInputRecord>> getVerifiedForMao({String? barangay}) async {
    try {
      var q = _client.from(_table).select().eq('status', FinInputStatus.bawVerified.value);
      if (barangay != null) q = q.eq('barangay', barangay);
      final res = await q.order('submitted_at', ascending: false);
      return (res as List).map((e) => FinancialInputRecord.fromJson(e)).toList();
    } catch (e) {
      if (_isMissing(e)) {
        return _cache.where((r) =>
          r.status == FinInputStatus.bawVerified &&
          (barangay == null || r.barangay == barangay)).toList();
      }
      rethrow;
    }
  }

  Future<void> maoApprove(String id, {String? notes}) async {
    final payload = {
      'status': FinInputStatus.maoApproved.value,
      if (notes != null) 'mao_notes': notes,
    };
    try {
      await _client.from(_table).update(payload).eq('id', id);
    } catch (e) {
      _updateCache(id, FinInputStatus.maoApproved, maoNotes: notes);
    }
  }

  Future<List<FinancialInputRecord>> getAllApproved() async {
    try {
      final res = await _client.from(_table).select()
          .eq('status', FinInputStatus.maoApproved.value)
          .order('submitted_at', ascending: false);
      return (res as List).map((e) => FinancialInputRecord.fromJson(e)).toList();
    } catch (e) {
      if (_isMissing(e)) {
        return _cache.where((r) => r.status == FinInputStatus.maoApproved).toList();
      }
      rethrow;
    }
  }

  void _updateCache(String id, FinInputStatus status, {
    String? bawNotes, String? bawVerifierId,
    BawVerificationChecklist? checklist, String? maoNotes,
  }) {
    final idx = _cache.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _cache[idx] = _cache[idx].copyWith(
        status: status,
        bawNotes: bawNotes,
        bawVerifierId: bawVerifierId,
        bawReviewedAt: DateTime.now(),
        bawChecklist: checklist,
        maoNotes: maoNotes,
      );
    }
  }
}
