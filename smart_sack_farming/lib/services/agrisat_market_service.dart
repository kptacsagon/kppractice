import 'package:supabase_flutter/supabase_flutter.dart';

// PRD §7 — Three core market saturation indicators
class HarvestReport {
  final String id;
  final String farmerId;
  final String farmerName;
  final String cropId;
  final String cropName;
  final String? barangay;
  final double actualYieldKg;
  final double quantitySoldKg;
  final double quantityUnsoldKg;
  final double priceReceivedPerKg;
  final String? disposalMethod;
  final DateTime reportedAt;

  HarvestReport({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.cropId,
    required this.cropName,
    this.barangay,
    required this.actualYieldKg,
    required this.quantitySoldKg,
    required this.quantityUnsoldKg,
    required this.priceReceivedPerKg,
    this.disposalMethod,
    required this.reportedAt,
  });

  // PRD §7.1.1 — MAR = Q_sold / Q_total
  double get mar => actualYieldKg > 0 ? quantitySoldKg / actualYieldKg : 0;

  // PRD §7.1.3 — IUR = I_unsold / Q_total
  double get iur => actualYieldKg > 0 ? quantityUnsoldKg / actualYieldKg : 0;

  factory HarvestReport.fromJson(Map<String, dynamic> j) => HarvestReport(
    id: j['id'] as String,
    farmerId: j['farmer_id'] as String,
    farmerName: j['farmer_name'] as String? ?? '',
    cropId: j['crop_id'] as String? ?? '',
    cropName: j['crop_name'] as String? ?? '',
    barangay: j['barangay'] as String?,
    actualYieldKg: (j['actual_yield_kg'] as num?)?.toDouble() ?? 0,
    quantitySoldKg: (j['quantity_sold_kg'] as num?)?.toDouble() ?? 0,
    quantityUnsoldKg: (j['quantity_unsold_kg'] as num?)?.toDouble() ?? 0,
    priceReceivedPerKg: (j['price_received_per_kg'] as num?)?.toDouble() ?? 0,
    disposalMethod: j['disposal_method'] as String?,
    reportedAt: DateTime.parse(j['reported_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmer_id': farmerId,
    'farmer_name': farmerName,
    'crop_id': cropId,
    'crop_name': cropName,
    if (barangay != null) 'barangay': barangay,
    'actual_yield_kg': actualYieldKg,
    'quantity_sold_kg': quantitySoldKg,
    'quantity_unsold_kg': quantityUnsoldKg,
    'price_received_per_kg': priceReceivedPerKg,
    if (disposalMethod != null) 'disposal_method': disposalMethod,
    'reported_at': reportedAt.toIso8601String(),
  };
}

// PRD §7.2 — Saturation status levels
enum SaturationLevel { safe, caution, danger }

class CropIndicators {
  final String cropName;
  final double mar;   // Market Absorption Rate
  final double ppi;   // Price Pressure Indicator (%)
  final double iur;   // Inventory Unsold Ratio

  CropIndicators({required this.cropName, required this.mar, required this.ppi, required this.iur});

  // PRD §7.2 thresholds
  SaturationLevel get marLevel => mar >= 0.85 ? SaturationLevel.safe : mar >= 0.70 ? SaturationLevel.caution : SaturationLevel.danger;
  SaturationLevel get ppiLevel => (ppi >= -5 && ppi <= 10) ? SaturationLevel.safe : (ppi >= -10 || ppi <= 20) ? SaturationLevel.caution : SaturationLevel.danger;
  SaturationLevel get iurLevel => iur < 0.15 ? SaturationLevel.safe : iur <= 0.30 ? SaturationLevel.caution : SaturationLevel.danger;

  SaturationLevel get overall {
    final levels = [marLevel, ppiLevel, iurLevel];
    if (levels.any((l) => l == SaturationLevel.danger)) return SaturationLevel.danger;
    if (levels.any((l) => l == SaturationLevel.caution)) return SaturationLevel.caution;
    return SaturationLevel.safe;
  }

  String get overallLabel {
    switch (overall) {
      case SaturationLevel.safe: return 'Good';
      case SaturationLevel.caution: return 'Caution';
      case SaturationLevel.danger: return 'Oversupply Risk';
    }
  }
}

class AgrisatMarketService {
  static final _client = Supabase.instance.client;
  static final List<HarvestReport> _cache = [];

  bool _isTableError(Object e) {
    final s = e.toString();
    return s.contains('PGRST205') || s.contains('does not exist') || s.contains('42P01');
  }

  Future<void> submitHarvestReport(HarvestReport r) async {
    try {
      await _client.from('harvest_reports').insert(r.toJson());
    } catch (e) {
      if (_isTableError(e)) { _cache.add(r); return; }
      rethrow;
    }
  }

  Future<List<HarvestReport>> getMyHarvestReports(String farmerId) async {
    try {
      final res = await _client.from('harvest_reports').select().eq('farmer_id', farmerId).order('reported_at', ascending: false);
      return (res as List).map((e) => HarvestReport.fromJson(e)).toList();
    } catch (e) {
      if (_isTableError(e)) return _cache.where((r) => r.farmerId == farmerId).toList();
      rethrow;
    }
  }

  Future<List<HarvestReport>> getAllHarvestReports({String? barangay}) async {
    try {
      var q = _client.from('harvest_reports').select();
      if (barangay != null) q = q.eq('barangay', barangay);
      final res = await q.order('reported_at', ascending: false);
      return (res as List).map((e) => HarvestReport.fromJson(e)).toList();
    } catch (e) {
      if (_isTableError(e)) {
        final list = List<HarvestReport>.from(_cache);
        if (barangay != null) return list.where((r) => r.barangay == barangay).toList();
        return list;
      }
      rethrow;
    }
  }

  // PRD §7.1 — Compute indicators per crop from harvest reports
  List<CropIndicators> computeIndicators(List<HarvestReport> reports) {
    final Map<String, List<HarvestReport>> byCrop = {};
    for (final r in reports) {
      byCrop.putIfAbsent(r.cropName, () => []).add(r);
    }

    return byCrop.entries.map((e) {
      final list = e.value;
      final totalYield = list.fold(0.0, (s, r) => s + r.actualYieldKg);
      final totalSold = list.fold(0.0, (s, r) => s + r.quantitySoldKg);
      final totalUnsold = list.fold(0.0, (s, r) => s + r.quantityUnsoldKg);
      final avgPrice = list.fold(0.0, (s, r) => s + r.priceReceivedPerKg) / list.length;

      final mar = totalYield > 0 ? totalSold / totalYield : 0.0;
      final iur = totalYield > 0 ? totalUnsold / totalYield : 0.0;
      // PPI mock baseline: ₱25/kg for pakbet crops
      const baseline = 25.0;
      final ppi = baseline > 0 ? ((avgPrice - baseline) / baseline) * 100 : 0.0;

      return CropIndicators(cropName: e.key, mar: mar, ppi: ppi, iur: iur);
    }).toList();
  }

  // Mock indicators for demo (when no harvest data yet)
  List<CropIndicators> getMockIndicators() => [
    CropIndicators(cropName: 'Ampalaya (Bitter Gourd)', mar: 0.82, ppi: -8.5, iur: 0.18),
    CropIndicators(cropName: 'Sitaw (String Beans)', mar: 0.91, ppi: 4.2, iur: 0.09),
    CropIndicators(cropName: 'Okra (Okra)', mar: 0.67, ppi: -18.3, iur: 0.33),
    CropIndicators(cropName: 'Talong (Eggplant)', mar: 0.88, ppi: 2.1, iur: 0.12),
    CropIndicators(cropName: 'Kalabasa (Squash)', mar: 0.55, ppi: -22.0, iur: 0.45),
  ];
}
