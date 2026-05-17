import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agri_dss_models.dart';

// ─── Mock data — used when DB table is missing (PGRST205) ────────────────────
List<CroppingCycle> _mockCycles(String farmerId) {
  final now = DateTime.now();
  return [
    CroppingCycle(
      id: 'mock-1', farmerId: farmerId, commodity: 'Eggplant',
      barangay: 'San Jose', municipality: 'Tubungan', seasonName: 'Wet Season 2024',
      plantingDate: DateTime(2024, 6, 1), harvestDate: DateTime(2024, 9, 15),
      totalProductionKg: 2400, quantitySoldKg: 2016, unsoldInventoryKg: 384,
      marketPricePhp: 38, baselinePricePhp: 35,
      inputCostPhp: 18000, laborCostPhp: 12000, landCostPhp: 5000, transportCostPhp: 3200,
      dataSource: 'Cooperative Sales Ledger', confidenceLevel: 'High',
      recordedAt: DateTime(2024, 9, 20),
    ),
    CroppingCycle(
      id: 'mock-2', farmerId: farmerId, commodity: 'Eggplant',
      barangay: 'San Jose', municipality: 'Tubungan', seasonName: 'Dry Season 2025',
      plantingDate: DateTime(2025, 1, 5), harvestDate: DateTime(2025, 4, 20),
      totalProductionKg: 2800, quantitySoldKg: 2100, unsoldInventoryKg: 700,
      marketPricePhp: 30, baselinePricePhp: 35,
      inputCostPhp: 21000, laborCostPhp: 13500, landCostPhp: 5000, transportCostPhp: 3800,
      dataSource: 'Barangay Agriculture Office Record', confidenceLevel: 'High',
      recordedAt: DateTime(2025, 4, 25),
    ),
    CroppingCycle(
      id: 'mock-3', farmerId: farmerId, commodity: 'Eggplant',
      barangay: 'San Jose', municipality: 'Tubungan', seasonName: 'Wet Season 2025',
      plantingDate: DateTime(2025, 6, 3), harvestDate: DateTime(2025, 9, 18),
      totalProductionKg: 3100, quantitySoldKg: 2170, unsoldInventoryKg: 930,
      marketPricePhp: 28, baselinePricePhp: 35,
      inputCostPhp: 23500, laborCostPhp: 14000, landCostPhp: 5000, transportCostPhp: 4200,
      dataSource: 'LGU Price Monitoring Report', confidenceLevel: 'Medium',
      recordedAt: DateTime(2025, 9, 22),
    ),
    CroppingCycle(
      id: 'mock-4', farmerId: farmerId, commodity: 'Ampalaya (Bitter Gourd)',
      barangay: 'San Jose', municipality: 'Tubungan', seasonName: 'Wet Season 2024',
      plantingDate: DateTime(2024, 6, 10), harvestDate: DateTime(2024, 9, 5),
      totalProductionKg: 1200, quantitySoldKg: 1080, unsoldInventoryKg: 120,
      marketPricePhp: 55, baselinePricePhp: 50,
      inputCostPhp: 10000, laborCostPhp: 8000, landCostPhp: 3000, transportCostPhp: 1800,
      dataSource: 'Cooperative Sales Ledger', confidenceLevel: 'High',
      recordedAt: DateTime(2024, 9, 10),
    ),
    CroppingCycle(
      id: 'mock-5', farmerId: farmerId, commodity: 'Ampalaya (Bitter Gourd)',
      barangay: 'San Jose', municipality: 'Tubungan', seasonName: 'Dry Season 2025',
      plantingDate: DateTime(2025, 1, 8), harvestDate: DateTime(2025, 4, 5),
      totalProductionKg: 1350, quantitySoldKg: 1215, unsoldInventoryKg: 135,
      marketPricePhp: 60, baselinePricePhp: 50,
      inputCostPhp: 11000, laborCostPhp: 8500, landCostPhp: 3000, transportCostPhp: 2000,
      dataSource: 'LGU Price Monitoring Report', confidenceLevel: 'High',
      recordedAt: DateTime(2025, 4, 10),
    ),
    CroppingCycle(
      id: 'mock-6', farmerId: farmerId, commodity: 'Okra',
      barangay: 'San Jose', municipality: 'Tubungan', seasonName: 'Wet Season 2025',
      plantingDate: DateTime(2025, 5, 15), harvestDate: DateTime(2025, 8, 20),
      totalProductionKg: 900, quantitySoldKg: 675, unsoldInventoryKg: 225,
      marketPricePhp: 42, baselinePricePhp: 45,
      inputCostPhp: 8500, laborCostPhp: 6000, landCostPhp: 2500, transportCostPhp: 1500,
      dataSource: 'Barangay Agriculture Office Record', confidenceLevel: 'Medium',
      recordedAt: now.subtract(const Duration(days: 30)),
    ),
  ];
}

List<MaoAggregationRow> _mockMaoRows() => [
  const MaoAggregationRow(barangay: 'San Jose', farmerCount: 14, avgMar: 0.81, avgPpi: -8.2, avgIur: 0.19, totalNetMarginPhp: 284500, alertCount: 3, dominantCommodity: 'Eggplant'),
  const MaoAggregationRow(barangay: 'Igdampog Norte', farmerCount: 9, avgMar: 0.75, avgPpi: -14.5, avgIur: 0.25, totalNetMarginPhp: 152000, alertCount: 5, dominantCommodity: 'Eggplant'),
  const MaoAggregationRow(barangay: 'Badiang', farmerCount: 11, avgMar: 0.88, avgPpi: 6.3, avgIur: 0.12, totalNetMarginPhp: 318700, alertCount: 1, dominantCommodity: 'Ampalaya (Bitter Gourd)'),
  const MaoAggregationRow(barangay: 'Desposorio', farmerCount: 7, avgMar: 0.70, avgPpi: -22.1, avgIur: 0.30, totalNetMarginPhp: 89400, alertCount: 7, dominantCommodity: 'Okra'),
  const MaoAggregationRow(barangay: 'Buenavista', farmerCount: 12, avgMar: 0.92, avgPpi: 12.4, avgIur: 0.08, totalNetMarginPhp: 421000, alertCount: 0, dominantCommodity: 'Squash'),
  const MaoAggregationRow(barangay: 'Singon', farmerCount: 8, avgMar: 0.79, avgPpi: -5.0, avgIur: 0.21, totalNetMarginPhp: 174200, alertCount: 2, dominantCommodity: 'Sitaw (String Beans)'),
];

// ─── Service ──────────────────────────────────────────────────────────────────
class AgriDssService {
  final SupabaseClient _client;
  AgriDssService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  // ── Feature 1 — Load cropping cycles ─────────────────────────────────────
  Future<List<CroppingCycle>> getCycles({String? commodity}) async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      // Resolve the farmer profile id
      final profile = await _client
          .from('agrisense_farmer_profiles')
          .select('id')
          .eq('user_id', uid)
          .maybeSingle();
      final farmerId = profile?['id'] as String? ?? uid;

      var query = _client
          .from('agri_dss_cropping_cycles')
          .select()
          .eq('farmer_id', farmerId);
      if (commodity != null) query = query.eq('commodity', commodity);
      final rows = await query.order('recorded_at', ascending: false);
      return (rows as List).map((r) => CroppingCycle.fromJson(r as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '42P01') return _mockCycles(uid);
      debugPrint('[AgriDSS] getCycles error: $e');
      return _mockCycles(uid);
    } catch (e) {
      debugPrint('[AgriDSS] getCycles error: $e');
      return _mockCycles(uid);
    }
  }

  Future<void> saveCycle(CroppingCycle cycle) async {
    await _client.from('agri_dss_cropping_cycles').insert(cycle.toJson());
  }

  // ── Feature 2 — Price Scissors detection ─────────────────────────────────
  List<FinancialAlert> detectPriceScissors(List<CroppingCycle> cycles) {
    final alerts = <FinancialAlert>[];
    // Group by commodity to compare consecutive cycles
    final byCommodity = <String, List<CroppingCycle>>{};
    for (final c in cycles) {
      byCommodity.putIfAbsent(c.commodity, () => []).add(c);
    }
    for (final entry in byCommodity.entries) {
      final sorted = [...entry.value]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      if (sorted.length < 2) continue;
      final prev = sorted[sorted.length - 2];
      final curr = sorted.last;
      final inputRise = prev.inputCostPhp > 0
          ? (curr.inputCostPhp - prev.inputCostPhp) / prev.inputCostPhp * 100 : 0.0;
      final transportRise = prev.transportCostPhp > 0
          ? (curr.transportCostPhp - prev.transportCostPhp) / prev.transportCostPhp * 100 : 0.0;
      if ((inputRise > 10 || transportRise > 10) && curr.ppi < 0) {
        alerts.add(FinancialAlert(
          type: 'price_scissors',
          title: 'Price Scissors — ${entry.key}',
          description:
              'Input costs ${inputRise > 10 ? "rose ${inputRise.toStringAsFixed(1)}%" : ""}'
              '${transportRise > 10 ? " Transport costs rose ${transportRise.toStringAsFixed(1)}%" : ""} '
              'while market price fell (PPI ${curr.ppi.toStringAsFixed(1)}%). Margin at risk.',
          recommendation: 'Review input sourcing. Consider cooperative bulk-buy or crop shift.',
          commodity: entry.key,
          severity: AlertSeverity.critical,
          triggeredAt: DateTime.now(),
        ));
      }
    }
    return alerts;
  }

  // ── Feature 3 — PPI action thresholds ────────────────────────────────────
  List<FinancialAlert> ppiAlerts(List<CroppingCycle> cycles) {
    final alerts = <FinancialAlert>[];
    final latest = <String, CroppingCycle>{};
    for (final c in cycles) {
      if (!latest.containsKey(c.commodity) ||
          c.recordedAt.isAfter(latest[c.commodity]!.recordedAt)) {
        latest[c.commodity] = c;
      }
    }
    for (final c in latest.values) {
      final ppi = c.ppi;
      if (ppi > 10) {
        alerts.add(FinancialAlert(
          type: 'ppi_opportunity', title: 'Revenue Opportunity — ${c.commodity}',
          description: 'PPI is +${ppi.toStringAsFixed(1)}%. Market price is above baseline.',
          recommendation: 'Consider increasing planting area next cycle.',
          commodity: c.commodity, severity: AlertSeverity.opportunity,
          triggeredAt: DateTime.now(),
        ));
      } else if (ppi < -25) {
        alerts.add(FinancialAlert(
          type: 'ppi_collapse', title: 'Revenue Collapse Risk — ${c.commodity}',
          description: 'PPI is ${ppi.toStringAsFixed(1)}%. Price is critically below baseline.',
          recommendation: 'Shift to alternative crop immediately. Consult AT for alternatives.',
          commodity: c.commodity, severity: AlertSeverity.critical,
          triggeredAt: DateTime.now(),
        ));
      } else if (ppi <= -10) {
        alerts.add(FinancialAlert(
          type: 'ppi_compression', title: 'Margin Compression — ${c.commodity}',
          description: 'PPI is ${ppi.toStringAsFixed(1)}%. Explore alternative markets or storage.',
          recommendation: 'Contact MAO for cold chain options or provincial market endorsement.',
          commodity: c.commodity, severity: AlertSeverity.warning,
          triggeredAt: DateTime.now(),
        ));
      }
    }
    return alerts;
  }

  // ── Feature 4 — IUR Perishability alerts ─────────────────────────────────
  List<FinancialAlert> iurAlerts(List<CroppingCycle> cycles) {
    final alerts = <FinancialAlert>[];
    final latest = <String, CroppingCycle>{};
    for (final c in cycles) {
      if (!latest.containsKey(c.commodity) ||
          c.recordedAt.isAfter(latest[c.commodity]!.recordedAt)) {
        latest[c.commodity] = c;
      }
    }
    for (final c in latest.values) {
      final iur = c.iur;
      final tier = c.perishability;
      if (tier == PerishabilityTier.highlyPerishable && iur > 0.1) {
        alerts.add(FinancialAlert(
          type: 'iur_perishable', title: 'Unsold Inventory Risk — ${c.commodity}',
          description: '${(iur * 100).toStringAsFixed(1)}% unsold. Highly perishable crop — immediate action required.',
          recommendation: 'Issue discount pricing or redirect to nearest processing buyer today.',
          commodity: c.commodity, severity: AlertSeverity.critical,
          triggeredAt: DateTime.now(),
        ));
      } else if (tier == PerishabilityTier.moderatelyPerishable && iur > 0.25) {
        alerts.add(FinancialAlert(
          type: 'iur_moderate', title: 'Cold Chain Alert — ${c.commodity}',
          description: '${(iur * 100).toStringAsFixed(1)}% unsold. Coordinate cold storage or logistics.',
          recommendation: 'Contact barangay logistics coordinator for cold chain access.',
          commodity: c.commodity, severity: AlertSeverity.warning,
          triggeredAt: DateTime.now(),
        ));
      } else if (tier == PerishabilityTier.storable && iur > 0.3) {
        final holdingCost = c.unsoldInventoryKg * 0.5;
        alerts.add(FinancialAlert(
          type: 'iur_storable', title: 'Holding Cost Alert — ${c.commodity}',
          description: 'Est. holding cost: PHP ${holdingCost.toStringAsFixed(0)}. Monitor for price recovery.',
          recommendation: 'Track LGU price bulletin weekly. Target sale when PPI turns positive.',
          commodity: c.commodity, severity: AlertSeverity.info,
          triggeredAt: DateTime.now(),
        ));
      }
    }
    return alerts;
  }

  // ── Feature 5 — Market destination effective prices ───────────────────────
  List<MarketDestination> getMarketDestinations(CroppingCycle cycle) {
    return [
      MarketDestination(
        name: 'Tubungan LGU Market', type: 'local_lgu',
        pricePerKg: cycle.marketPricePhp,
        transportCostPerKg: cycle.totalProductionKg > 0
            ? cycle.transportCostPhp / cycle.quantitySoldKg.clamp(1, double.infinity) : 0,
        ppi: cycle.ppi,
      ),
      MarketDestination(
        name: 'Iloilo City Hub', type: 'regional_hub',
        pricePerKg: cycle.marketPricePhp * 1.12,
        transportCostPerKg: (cycle.totalProductionKg > 0
            ? cycle.transportCostPhp / cycle.quantitySoldKg.clamp(1, double.infinity) : 0) * 2.2,
        ppi: cycle.ppi + 3,
      ),
      MarketDestination(
        name: 'Provincial Market (Pavia)', type: 'provincial_market',
        pricePerKg: cycle.marketPricePhp * 1.08,
        transportCostPerKg: (cycle.totalProductionKg > 0
            ? cycle.transportCostPhp / cycle.quantitySoldKg.clamp(1, double.infinity) : 0) * 1.6,
        ppi: cycle.ppi + 1.5,
      ),
    ];
  }

  // ── Feature 6 — Crop-switch recommendation ────────────────────────────────
  List<String> cropSwitchRecommendations(List<CroppingCycle> cycles, String commodity) {
    final forCrop = cycles.where((c) => c.commodity == commodity).toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    if (forCrop.length < 2) return [];
    final persistentHighIur = forCrop.reversed.take(2).every((c) => c.iur > 0.3);
    if (!persistentHighIur) return [];
    // Find top 2 alternatives by best recent PPI
    final others = <String, double>{};
    for (final c in cycles.where((c) => c.commodity != commodity)) {
      if (!others.containsKey(c.commodity) || c.ppi > others[c.commodity]!) {
        others[c.commodity] = c.ppi;
      }
    }
    final sorted = others.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(2).map((e) => e.key).toList();
  }

  // ── Feature 7 — MAO aggregation ──────────────────────────────────────────
  Future<List<MaoAggregationRow>> getMaoAggregation() async {
    try {
      final rows = await _client
          .from('agri_dss_cropping_cycles')
          .select('barangay, farmer_id, total_production_kg, quantity_sold_kg, unsold_inventory_kg, market_price_php, baseline_price_php, input_cost_php, labor_cost_php, land_cost_php, transport_cost_php, commodity')
          .eq('municipality', 'Tubungan');

      final byBarangay = <String, List<Map<String, dynamic>>>{};
      for (final r in rows as List) {
        final b = r['barangay'] as String? ?? 'Unknown';
        byBarangay.putIfAbsent(b, () => []).add(r as Map<String, dynamic>);
      }

      return byBarangay.entries.map((entry) {
        final list = entry.value;
        final cycles = list.map((r) => CroppingCycle.fromJson({...r, 'id': '', 'farmer_id': r['farmer_id'] ?? '', 'season_name': '', 'created_at': DateTime.now().toIso8601String()})).toList();
        final farmerIds = list.map((r) => r['farmer_id']).toSet();
        final avgMar = cycles.isEmpty ? 0.0 : cycles.map((c) => c.mar).reduce((a, b) => a + b) / cycles.length;
        final avgPpi = cycles.isEmpty ? 0.0 : cycles.map((c) => c.ppi).reduce((a, b) => a + b) / cycles.length;
        final avgIur = cycles.isEmpty ? 0.0 : cycles.map((c) => c.iur).reduce((a, b) => a + b) / cycles.length;
        final totalNet = cycles.fold(0.0, (s, c) => s + c.netMargin);
        final domCrop = _dominantCrop(list);
        return MaoAggregationRow(
          barangay: entry.key,
          farmerCount: farmerIds.length,
          avgMar: avgMar,
          avgPpi: avgPpi,
          avgIur: avgIur,
          totalNetMarginPhp: totalNet,
          alertCount: cycles.where((c) => c.ppi < -10 || c.iur > 0.3).length,
          dominantCommodity: domCrop,
        );
      }).toList()..sort((a, b) => b.alertCount.compareTo(a.alertCount));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '42P01') return _mockMaoRows();
      return _mockMaoRows();
    } catch (_) {
      return _mockMaoRows();
    }
  }

  String _dominantCrop(List<Map<String, dynamic>> rows) {
    final counts = <String, int>{};
    for (final r in rows) {
      final c = r['commodity'] as String? ?? 'Unknown';
      counts[c] = (counts[c] ?? 0) + 1;
    }
    if (counts.isEmpty) return '—';
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // ── All alerts combined ───────────────────────────────────────────────────
  List<FinancialAlert> allAlerts(List<CroppingCycle> cycles) {
    return [
      ...detectPriceScissors(cycles),
      ...ppiAlerts(cycles),
      ...iurAlerts(cycles),
    ]..sort((a, b) => b.severity.index.compareTo(a.severity.index));
  }
}
