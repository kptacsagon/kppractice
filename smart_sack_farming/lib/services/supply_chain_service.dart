import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recommendation_model.dart';

/// Supply chain analytics service providing forward-looking supply projections,
/// harvest synchronization logic, and oversupply detection for MAO/Associations.
class SupplyChainService {
  final SupabaseClient _client;

  SupplyChainService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Generate supply projections from all active saturation records.
  /// Aggregates planned harvests by crop and time window to detect
  /// potential oversupply and generate actionable recommendations.
  Future<List<SupplyProjection>> generateSupplyProjections() async {
    try {
      // Fetch all saturation records with expected harvest dates
      final records = await _client
          .from('saturation_records')
          .select()
          .not('expected_harvest', 'is', null)
          .order('expected_harvest', ascending: true);

      if (records.isEmpty) return [];

      // Group by crop + harvest month window
      final groups = <String, _HarvestGroup>{};

      for (final record in records) {
        final crop = record['primary_crop'] as String;
        final harvestStr = record['expected_harvest'] as String?;
        if (harvestStr == null) continue;
        final harvest = DateTime.parse(harvestStr);
        final areaHa = (record['field_size_ha'] is num)
            ? (record['field_size_ha'] as num).toDouble()
            : 0.0;
        final expectedYield = (record['expected_yield_kg'] is num)
            ? (record['expected_yield_kg'] as num).toDouble()
            : (areaHa * 5000); // fallback estimate
        final farmerId = record['farmer_id'] as String;

        // Group by crop + month
        final key = '${crop}_${harvest.year}_${harvest.month}';
        groups.putIfAbsent(
          key,
          () => _HarvestGroup(
            crop: crop,
            windowStart: DateTime(harvest.year, harvest.month, 1),
            windowEnd: DateTime(harvest.year, harvest.month + 1, 0),
          ),
        );
        groups[key]!.addRecord(
          farmerId: farmerId,
          yieldKg: expectedYield,
          areaHa: areaHa,
        );
      }

      // Convert to SupplyProjections with risk analysis
      final projections = <SupplyProjection>[];

      for (final group in groups.values) {
        final riskPct = _calculateOversupplyRisk(group);
        final action = _generateSuggestedAction(group, riskPct);

        projections.add(SupplyProjection(
          id: '',
          cropType: group.crop,
          projectedYieldKg: group.totalYieldKg,
          harvestWindowStart: group.windowStart,
          harvestWindowEnd: group.windowEnd,
          farmerCount: group.farmerIds.length,
          totalAreaHa: group.totalAreaHa,
          riskOfOversupply: riskPct,
          suggestedAction: action,
          region: 'local',
        ));
      }

      // Sort by risk descending
      projections.sort(
          (a, b) => b.riskOfOversupply.compareTo(a.riskOfOversupply));

      // Persist projections
      await _persistProjections(projections);

      return projections;
    } catch (e) {
      print('Error generating supply projections: $e');
      return [];
    }
  }

  /// Detect harvest collisions — multiple farmers harvesting the same crop
  /// in the same time window.
  Future<List<HarvestCollision>> detectHarvestCollisions() async {
    try {
      final records = await _client
          .from('saturation_records')
          .select()
          .not('expected_harvest', 'is', null);

      if (records.isEmpty) return [];

      // Group by crop + 2-week window
      final collisions = <HarvestCollision>[];
      final cropRecords = <String, List<Map<String, dynamic>>>{};

      for (final r in records) {
        final crop = r['primary_crop'] as String;
        cropRecords.putIfAbsent(crop, () => []).add(r);
      }

      for (final entry in cropRecords.entries) {
        final crop = entry.key;
        final recs = entry.value;
        if (recs.length < 2) continue;

        // Sort by harvest date
        recs.sort((a, b) {
          final da = DateTime.parse(a['expected_harvest']);
          final db = DateTime.parse(b['expected_harvest']);
          return da.compareTo(db);
        });

        // Find overlapping harvest windows (within 14 days)
        for (int i = 0; i < recs.length - 1; i++) {
          final dateA = DateTime.parse(recs[i]['expected_harvest']);
          final clusterFarmers = <String>[recs[i]['farmer_id']];
          double clusterYield = (recs[i]['expected_yield_kg'] is num)
              ? (recs[i]['expected_yield_kg'] as num).toDouble()
              : 0;

          for (int j = i + 1; j < recs.length; j++) {
            final dateB = DateTime.parse(recs[j]['expected_harvest']);
            if (dateB.difference(dateA).inDays <= 14) {
              clusterFarmers.add(recs[j]['farmer_id']);
              clusterYield += (recs[j]['expected_yield_kg'] is num)
                  ? (recs[j]['expected_yield_kg'] as num).toDouble()
                  : 0;
            }
          }

          if (clusterFarmers.length >= 2) {
            collisions.add(HarvestCollision(
              cropType: crop,
              harvestDate: dateA,
              farmerCount: clusterFarmers.length,
              totalYieldKg: clusterYield,
              severity: clusterFarmers.length >= 5
                  ? 'critical'
                  : clusterFarmers.length >= 3
                      ? 'high'
                      : 'moderate',
              recommendation: _getCollisionRecommendation(
                  crop, clusterFarmers.length, clusterYield),
            ));
          }
        }
      }

      return collisions;
    } catch (e) {
      print('Error detecting harvest collisions: $e');
      return [];
    }
  }

  /// Get alternative market channels for a crop.
  List<MarketChannel> getAlternativeChannels(
      String cropType, double surplusKg) {
    final channels = <MarketChannel>[];

    // Association buy-back program
    channels.add(MarketChannel(
      name: 'Association Buy-Back Program',
      type: 'buyback',
      description:
          'Local farming association purchases surplus at guaranteed floor price.',
      estimatedPrice: _getFloorPrice(cropType),
      capacityKg: surplusKg * 0.4,
      contactInfo: 'Contact your local farming association',
      priority: 1,
    ));

    // Cold storage
    channels.add(MarketChannel(
      name: 'Cold Storage / Deferred Sale',
      type: 'storage',
      description:
          'Store produce in cold storage to sell when prices improve (1-3 months).',
      estimatedPrice: 0,
      capacityKg: surplusKg * 0.6,
      contactInfo: 'Municipal cold storage facility',
      priority: 2,
    ));

    // Processing / value-add
    channels.add(MarketChannel(
      name: 'Food Processing Units',
      type: 'processing',
      description:
          'Sell to local processing plants for dried, canned, or frozen products.',
      estimatedPrice: _getFloorPrice(cropType) * 0.85,
      capacityKg: surplusKg * 0.5,
      contactInfo: 'Regional food processing directory',
      priority: 3,
    ));

    // Export / distant markets
    channels.add(MarketChannel(
      name: 'Inter-District Market Channel',
      type: 'export',
      description:
          'Transport surplus to districts with lower supply for better prices.',
      estimatedPrice: _getFloorPrice(cropType) * 1.1,
      capacityKg: surplusKg * 0.3,
      contactInfo: 'MAO inter-district coordination desk',
      priority: 4,
    ));

    // Direct consumer / farmer markets
    channels.add(MarketChannel(
      name: 'Direct-to-Consumer Farmer Market',
      type: 'direct',
      description:
          'Weekly farmer markets in urban areas for premium direct sales.',
      estimatedPrice: _getFloorPrice(cropType) * 1.3,
      capacityKg: surplusKg * 0.15,
      contactInfo: 'Local farmers market coordinator',
      priority: 5,
    ));

    return channels;
  }

  /// Get dashboard summary data for MAO.
  Future<SupplyChainSummary> getDashboardSummary() async {
    try {
      final projections = await generateSupplyProjections();
      final collisions = await detectHarvestCollisions();

      // Total upcoming harvests in next 90 days
      final now = DateTime.now();
      final upcoming = projections.where((p) =>
          p.harvestWindowStart
              .isBefore(now.add(const Duration(days: 90))) &&
          p.harvestWindowEnd.isAfter(now));

      final totalUpcomingYield =
          upcoming.fold<double>(0, (s, p) => s + p.projectedYieldKg);
      final totalFarmers = upcoming.fold<int>(0, (s, p) => s + p.farmerCount);
      final criticalCrops = projections
          .where((p) => p.riskOfOversupply >= 50)
          .map((p) => p.cropType)
          .toSet()
          .toList();

      return SupplyChainSummary(
        projections: projections,
        collisions: collisions,
        totalUpcomingYieldKg: totalUpcomingYield,
        totalFarmersHarvesting: totalFarmers,
        criticalOversupplyCrops: criticalCrops,
        highRiskProjections:
            projections.where((p) => p.riskOfOversupply >= 50).toList(),
      );
    } catch (e) {
      return SupplyChainSummary(
        projections: [],
        collisions: [],
        totalUpcomingYieldKg: 0,
        totalFarmersHarvesting: 0,
        criticalOversupplyCrops: [],
        highRiskProjections: [],
      );
    }
  }

  // ================================================================
  // PRIVATE HELPERS
  // ================================================================

  double _calculateOversupplyRisk(_HarvestGroup group) {
    // Based on farmer density, total yield, and typical demand
    final typicalMonthlyDemandKg = _getTypicalDemand(group.crop);
    if (typicalMonthlyDemandKg <= 0) return 50;

    final supplyRatio = group.totalYieldKg / typicalMonthlyDemandKg;

    // Supply > 150% of demand = high risk
    if (supplyRatio >= 2.0) return 95;
    if (supplyRatio >= 1.5) return 75;
    if (supplyRatio >= 1.2) return 55;
    if (supplyRatio >= 1.0) return 35;
    return 15;
  }

  String _generateSuggestedAction(_HarvestGroup group, double riskPct) {
    if (riskPct >= 75) {
      return 'URGENT: ${group.farmerIds.length} farmers harvesting ${group.crop} '
          'simultaneously. Activate Association buy-back program and arrange '
          'cold storage. Consider staggering harvests by 2-week intervals.';
    }
    if (riskPct >= 50) {
      return 'CAUTION: Moderate oversupply risk for ${group.crop}. '
          'Coordinate with ${group.farmerIds.length} farmers to stagger delivery. '
          'Explore inter-district market channels.';
    }
    if (riskPct >= 25) {
      return 'MONITOR: ${group.crop} supply levels acceptable. '
          'Keep monitoring for additional plantings.';
    }
    return 'OK: ${group.crop} supply within normal range.';
  }

  String _getCollisionRecommendation(
      String crop, int farmerCount, double yieldKg) {
    final yieldTons = (yieldKg / 1000).toStringAsFixed(1);
    if (farmerCount >= 5) {
      return 'Critical: $farmerCount farmers dumping $yieldTons tons of $crop. '
          'Immediately activate emergency buy-back and cold storage programs.';
    }
    if (farmerCount >= 3) {
      return 'High: Coordinate staggered delivery schedule among $farmerCount '
          'farmers to prevent $yieldTons tons hitting market simultaneously.';
    }
    return 'Contact the $farmerCount farmers to space out harvest dates '
        'by at least 1-2 weeks.';
  }

  double _getFloorPrice(String cropType) {
    const floorPrices = {
      'Rice': 35.0,
      'Corn': 20.0,
      'Tomato': 25.0,
      'Lettuce': 45.0,
      'Eggplant': 22.0,
      'Sweet Potato': 20.0,
      'Carrot': 35.0,
      'Cabbage': 15.0,
      'Watermelon': 12.0,
      'Basil': 90.0,
      'Pepper': 40.0,
      'Spinach': 35.0,
    };
    return floorPrices[cropType] ?? 20.0;
  }

  double _getTypicalDemand(String crop) {
    // Approximate monthly local demand in kg
    const demand = {
      'Rice': 50000.0,
      'Corn': 30000.0,
      'Tomato': 40000.0,
      'Lettuce': 15000.0,
      'Eggplant': 25000.0,
      'Sweet Potato': 20000.0,
      'Carrot': 18000.0,
      'Cabbage': 22000.0,
      'Watermelon': 25000.0,
      'Basil': 5000.0,
      'Pepper': 12000.0,
      'Spinach': 10000.0,
    };
    return demand[crop] ?? 20000.0;
  }

  Future<void> _persistProjections(List<SupplyProjection> projections) async {
    try {
      // Clear old projections
      await _client.from('supply_projections').delete().neq('id', '');

      if (projections.isNotEmpty) {
        final rows = projections.map((p) => p.toJson()).toList();
        await _client.from('supply_projections').insert(rows);
      }
    } catch (e) {
      print('Warning: Could not persist supply projections: $e');
    }
  }
}

// ================================================================
// INTERNAL DATA CLASSES
// ================================================================

class _HarvestGroup {
  final String crop;
  final DateTime windowStart;
  final DateTime windowEnd;
  final Set<String> farmerIds = {};
  double totalYieldKg = 0;
  double totalAreaHa = 0;

  _HarvestGroup({
    required this.crop,
    required this.windowStart,
    required this.windowEnd,
  });

  void addRecord({
    required String farmerId,
    required double yieldKg,
    required double areaHa,
  }) {
    farmerIds.add(farmerId);
    totalYieldKg += yieldKg;
    totalAreaHa += areaHa;
  }
}

/// A detected harvest collision (multiple farmers harvesting at once).
class HarvestCollision {
  final String cropType;
  final DateTime harvestDate;
  final int farmerCount;
  final double totalYieldKg;
  final String severity; // 'moderate', 'high', 'critical'
  final String recommendation;

  HarvestCollision({
    required this.cropType,
    required this.harvestDate,
    required this.farmerCount,
    required this.totalYieldKg,
    required this.severity,
    required this.recommendation,
  });

  String get severityEmoji {
    switch (severity) {
      case 'critical':
        return '🔴';
      case 'high':
        return '🟠';
      default:
        return '🟡';
    }
  }
}

/// Alternative market channel for surplus produce.
class MarketChannel {
  final String name;
  final String type;
  final String description;
  final double estimatedPrice;
  final double capacityKg;
  final String contactInfo;
  final int priority;

  MarketChannel({
    required this.name,
    required this.type,
    required this.description,
    required this.estimatedPrice,
    required this.capacityKg,
    required this.contactInfo,
    required this.priority,
  });
}

/// Summary dashboard data for MAO.
class SupplyChainSummary {
  final List<SupplyProjection> projections;
  final List<HarvestCollision> collisions;
  final double totalUpcomingYieldKg;
  final int totalFarmersHarvesting;
  final List<String> criticalOversupplyCrops;
  final List<SupplyProjection> highRiskProjections;

  SupplyChainSummary({
    required this.projections,
    required this.collisions,
    required this.totalUpcomingYieldKg,
    required this.totalFarmersHarvesting,
    required this.criticalOversupplyCrops,
    required this.highRiskProjections,
  });
}
