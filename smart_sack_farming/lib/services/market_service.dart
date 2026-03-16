import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/market_endorsement.dart';
import '../models/buyer_bid.dart';
import '../models/planting_record.dart';
import '../services/harvest_calculator.dart';

final _supabase = Supabase.instance.client;

class MarketService {
  // Fetch endorsements for a farmer by joining planting_records
  static Future<List<MarketEndorsement>> fetchEndorsementsForFarmer(String farmerId) async {
    // First get planting record ids for the farmer, then query endorsements
    final plantResp = await _supabase.from('planting_records').select('id').eq('farmer_id', farmerId).execute();
    if (plantResp.data == null) throw Exception('Failed to fetch planting records for farmer: $farmerId');
    final plantData = (plantResp.data as List).cast<Map<String, dynamic>>();
    final ids = plantData.map((e) => e['id'] as String).toList();
    if (ids.isEmpty) return [];

    final resp = await _supabase
        .from('market_endorsements')
        .select()
        .in_('planting_record_id', ids)
        .order('endorsement_date')
        .execute();

    if (resp.data == null) throw Exception('Failed to fetch endorsements for farmer: $farmerId');
    final data = (resp.data as List).cast<Map<String, dynamic>>();
    return data.map((d) => MarketEndorsement.fromJson(d)).toList();
  }

  static Future<void> requestEndorsement({required String plantingRecordId, String? maoId, required double startingBid}) async {
    final resp = await _supabase.from('market_endorsements').insert({
      'planting_record_id': plantingRecordId,
      'mao_id': maoId,
      'starting_bid_price': startingBid,
      'status': 'open',
    }).execute();
    if (resp.data == null) throw Exception('Failed to create endorsement: $resp');
  }

  static Future<List<MarketEndorsement>> fetchOpenEndorsements() async {
    final resp = await _supabase.from('market_endorsements').select('*, planting_records(*)').eq('status', 'open').order('endorsement_date').execute();
    if (resp.data == null) throw Exception('Failed to fetch open endorsements: $resp');
    final data = (resp.data as List).cast<Map<String, dynamic>>();
    return data.map((d) => MarketEndorsement.fromJson(d)).toList();
  }

  static Future<void> placeBid({required String endorsementId, required String buyerId, required double amount}) async {
    final resp = await _supabase.from('buyer_bids').insert({
      'endorsement_id': endorsementId,
      'buyer_id': buyerId,
      'bid_amount': amount,
      'status': 'pending',
    }).execute();
    if (resp.data == null) throw Exception('Failed to place bid: $resp');
  }

  static Future<List<PlantingRecord>> fetchUpcomingPlantings({int limit = 100}) async {
    final resp = await _supabase
      .from('planting_records')
      .select()
      .order('expected_harvest_date')
      .limit(limit)
      .execute();

    if (resp.data == null) throw Exception('Failed to fetch plantings: $resp');
    final data = (resp.data as List).cast<Map<String, dynamic>>();
    return data.map((d) => PlantingRecord.fromJson(d)).toList();
  }
}
