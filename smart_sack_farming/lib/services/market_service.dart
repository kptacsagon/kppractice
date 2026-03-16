import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/market_endorsement.dart';
import '../models/planting_record.dart';
import 'yield_prediction_service.dart';

final _supabase = Supabase.instance.client;

class MarketService {
  // Fetch endorsements for a farmer by joining planting_records
  static Future<List<MarketEndorsement>> fetchEndorsementsForFarmer(String farmerId) async {
    // First get planting record ids for the farmer, then query endorsements
    final plantResp =
        await _supabase.from('planting_records').select('id').eq('farmer_id', farmerId);
    if (plantResp is! List) {
      throw Exception('Failed to fetch planting records for farmer: $farmerId');
    }

    final plantData = plantResp.cast<Map<String, dynamic>>();
    final ids = plantData.map((e) => e['id'] as String).toList();
    if (ids.isEmpty) return [];

    final response = await _supabase
        .from('market_endorsements')
        .select()
        .in_('planting_record_id', ids)
        .order('endorsement_date');

    if (response is! List) {
      throw Exception('Failed to fetch endorsements for farmer: $farmerId');
    }

    final data = response.cast<Map<String, dynamic>>();
    return data.map((d) => MarketEndorsement.fromJson(d)).toList();
  }

  static Future<void> requestEndorsement({required String plantingRecordId, String? maoId, required double startingBid}) async {
    final existingOpen = await _supabase
        .from('market_endorsements')
        .select('id')
        .eq('planting_record_id', plantingRecordId)
        .eq('status', 'open')
        .maybeSingle();

    if (existingOpen != null) {
      return;
    }

    await _supabase.from('market_endorsements').insert({
      'planting_record_id': plantingRecordId,
      'mao_id': maoId,
      'starting_bid_price': startingBid,
      'status': 'open',
    });
  }

  static Future<List<MarketEndorsement>> fetchOpenEndorsements() async {
    final response = await _supabase
        .from('market_endorsements')
        .select('''
          id,
          planting_record_id,
          mao_id,
          endorsement_date,
          starting_bid_price,
          current_highest_bid,
          status,
          planting_records (
            id,
            farmer_id,
            crop_name,
            planting_date,
            expected_harvest_date,
            area_planted_ha,
            estimated_yield_mt
          )
        ''')
        .eq('status', 'open')
        .order('endorsement_date');

    if (response is! List) {
      throw Exception('Failed to fetch open endorsements.');
    }

    final rows = response.cast<Map<String, dynamic>>();

    final farmerIds = rows
        .map((row) {
          final planting = row['planting_records'];
          if (planting is! Map<String, dynamic>) return '';
          return (planting['farmer_id'] ?? '').toString();
        })
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final profilesById = <String, Map<String, dynamic>>{};
    if (farmerIds.isNotEmpty) {
      try {
        final profileRows = await _supabase
            .from('profiles')
            .select('id, full_name, email, address')
            .in_('id', farmerIds);

        if (profileRows is List) {
          for (final row in profileRows.cast<Map<String, dynamic>>()) {
            final id = row['id']?.toString();
            if (id == null || id.isEmpty) continue;
            profilesById[id] = row;
          }
        }
      } catch (_) {}
    }

    return rows.map((raw) {
      final row = Map<String, dynamic>.from(raw);
      final planting = row['planting_records'];
      if (planting is Map<String, dynamic>) {
        final farmerId = planting['farmer_id']?.toString();
        final profile = farmerId != null ? profilesById[farmerId] : null;
        row['farmer_name'] = profile?['full_name'] ?? profile?['email'];
        row['farmer_address'] = profile?['address'];
      }
      return MarketEndorsement.fromJson(row);
    }).toList();
  }

  static Future<void> placeBid({required String endorsementId, required String buyerId, required double amount}) async {
    if (amount <= 0) {
      throw Exception('Bid amount must be greater than zero.');
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('You need to sign in before placing bids.');
    }

    if (currentUser.id != buyerId) {
      throw Exception('Bids can only be submitted by the signed-in buyer account.');
    }

    final profile = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', buyerId)
        .maybeSingle();

    final role = profile?['role']?.toString().toLowerCase();
    if (role != 'buyer') {
      throw Exception('Only registered buyers can bid on endorsed products.');
    }

    await _supabase.from('buyer_bids').insert({
      'endorsement_id': endorsementId,
      'buyer_id': currentUser.id,
      'bid_amount': amount,
      'status': 'pending',
    });
  }

  static Future<List<PlantingRecord>> fetchUpcomingPlantings({int limit = 100}) async {
    final response = await _supabase
      .from('planting_records')
      .select()
      .order('expected_harvest_date')
      .limit(limit);

    if (response is! List) {
      throw Exception('Failed to fetch planting records.');
    }

    final data = response.cast<Map<String, dynamic>>();
    return data.map((d) => PlantingRecord.fromJson(d)).toList();
  }

  static Future<int> endorseProjectionToBuyers({
    required String cropType,
    required DateTime windowStart,
    required DateTime windowEnd,
    required double startingBid,
    String? maoId,
    String? farmerId,
  }) async {
    if (startingBid <= 0) {
      throw Exception('Starting bid must be greater than zero.');
    }

    final currentUser = _supabase.auth.currentUser;
    final resolvedMaoId = maoId ?? currentUser?.id;

    var plantingQuery = _supabase
        .from('planting_records')
        .select('id, crop_name, farmer_id, expected_harvest_date')
        .gte('expected_harvest_date', _dateOnly(windowStart))
        .lte('expected_harvest_date', _dateOnly(windowEnd));

    final normalizedFarmerId = farmerId?.trim();
    if (normalizedFarmerId != null && normalizedFarmerId.isNotEmpty) {
      plantingQuery = plantingQuery.eq('farmer_id', normalizedFarmerId);
    }

    final plantingRows = await plantingQuery;

    if (plantingRows is! List || plantingRows.isEmpty) {
      return 0;
    }

    final targetCrop = YieldPredictionService.normalizeCropName(cropType);
    final candidatePlantingIds = plantingRows
        .cast<Map<String, dynamic>>()
        .where((row) {
          final rowCrop = (row['crop_name'] ?? '').toString();
          return YieldPredictionService.normalizeCropName(rowCrop) == targetCrop;
        })
        .map((row) => (row['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (candidatePlantingIds.isEmpty) {
      return 0;
    }

    final existingRows = await _supabase
        .from('market_endorsements')
        .select('planting_record_id')
        .in_('planting_record_id', candidatePlantingIds)
        .eq('status', 'open');

    final existingIds = <String>{};
    if (existingRows is List) {
      for (final row in existingRows.cast<Map<String, dynamic>>()) {
        final id = row['planting_record_id']?.toString();
        if (id != null && id.isNotEmpty) {
          existingIds.add(id);
        }
      }
    }

    final forInsert = candidatePlantingIds
        .where((id) => !existingIds.contains(id))
        .toList();

    if (forInsert.isEmpty) {
      return 0;
    }

    final payload = forInsert
        .map((id) => {
              'planting_record_id': id,
              'mao_id': resolvedMaoId,
              'starting_bid_price': startingBid,
              'status': 'open',
            })
        .toList();

    await _supabase.from('market_endorsements').insert(payload);
    return forInsert.length;
  }

  static String _dateOnly(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
