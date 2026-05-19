import 'package:supabase_flutter/supabase_flutter.dart';

// PRD FR-M05 / FR-F06 — Buyer Demand Board
class BuyerDemand {
  final String id;
  final String cropName;
  final double volumeNeededKg;
  final double priceOfferedPerKg;
  final String terms;
  final DateTime deadline;
  final String postedBy;
  final String status; // active | closed | filled
  final DateTime createdAt;

  BuyerDemand({
    required this.id,
    required this.cropName,
    required this.volumeNeededKg,
    required this.priceOfferedPerKg,
    required this.terms,
    required this.deadline,
    required this.postedBy,
    required this.status,
    required this.createdAt,
  });

  int get daysLeft => deadline.difference(DateTime.now()).inDays;

  factory BuyerDemand.fromJson(Map<String, dynamic> j) => BuyerDemand(
    id: j['id'] as String,
    cropName: j['crop_name'] as String? ?? '',
    volumeNeededKg: (j['volume_needed_kg'] as num?)?.toDouble() ?? 0,
    priceOfferedPerKg: (j['price_offered_per_kg'] as num?)?.toDouble() ?? 0,
    terms: j['terms'] as String? ?? '',
    deadline: DateTime.parse(j['deadline'] as String),
    postedBy: j['posted_by'] as String? ?? 'MAO',
    status: j['status'] as String? ?? 'active',
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'crop_name': cropName,
    'volume_needed_kg': volumeNeededKg,
    'price_offered_per_kg': priceOfferedPerKg,
    'terms': terms,
    'deadline': deadline.toIso8601String(),
    'posted_by': postedBy,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };
}

class BuyerDemandService {
  static final _client = Supabase.instance.client;
  static final List<BuyerDemand> _cache = [
    // Default demo demands so the board is never empty
    BuyerDemand(id: 'demo-1', cropName: 'Ampalaya (Bitter Gourd)', volumeNeededKg: 500,
      priceOfferedPerKg: 28, terms: 'Pickup at MAO warehouse · Cash on delivery',
      deadline: DateTime.now().add(const Duration(days: 7)), postedBy: 'MAO Tubungan',
      status: 'active', createdAt: DateTime.now()),
    BuyerDemand(id: 'demo-2', cropName: 'Sitaw (String Beans)', volumeNeededKg: 300,
      priceOfferedPerKg: 32, terms: 'Delivered to LGU canteen · Weekly supply',
      deadline: DateTime.now().add(const Duration(days: 14)), postedBy: 'LGU Canteen',
      status: 'active', createdAt: DateTime.now()),
    BuyerDemand(id: 'demo-3', cropName: 'Okra (Okra)', volumeNeededKg: 200,
      priceOfferedPerKg: 22, terms: 'Cooperative volume deal · Min 50 kg per farmer',
      deadline: DateTime.now().add(const Duration(days: 5)), postedBy: 'Tubungan Coop',
      status: 'active', createdAt: DateTime.now()),
  ];

  bool _isTableError(Object e) {
    final s = e.toString();
    return s.contains('PGRST205') || s.contains('does not exist') || s.contains('42P01');
  }

  Future<void> postDemand(BuyerDemand d) async {
    try {
      await _client.from('buyer_demands').insert(d.toJson());
    } catch (e) {
      if (_isTableError(e)) { _cache.add(d); return; }
      rethrow;
    }
  }

  Future<List<BuyerDemand>> getActiveDemands() async {
    try {
      final res = await _client.from('buyer_demands').select().eq('status', 'active').order('deadline', ascending: true);
      final list = (res as List).map((e) => BuyerDemand.fromJson(e)).toList();
      return list.isEmpty ? _cache : list;
    } catch (e) {
      if (_isTableError(e)) return List.from(_cache);
      rethrow;
    }
  }

  Future<void> closeDemand(String id) async {
    try {
      await _client.from('buyer_demands').update({'status': 'closed'}).eq('id', id);
    } catch (_) {
      final idx = _cache.indexWhere((d) => d.id == id);
      if (idx != -1) _cache.removeAt(idx);
    }
  }
}
