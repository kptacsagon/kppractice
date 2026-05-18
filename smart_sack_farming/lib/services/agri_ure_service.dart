import 'package:supabase_flutter/supabase_flutter.dart';

class UreEvent {
  final String id;
  final String farmerId;
  final String cropType;
  final String eventType;
  final String description;
  final double? financialImpact;
  final String status;
  final DateTime createdAt;
  final String? verifiedBy;
  final String? verificationNotes;

  UreEvent({
    required this.id,
    required this.farmerId,
    required this.cropType,
    required this.eventType,
    required this.description,
    this.financialImpact,
    required this.status,
    required this.createdAt,
    this.verifiedBy,
    this.verificationNotes,
  });

  factory UreEvent.fromJson(Map<String, dynamic> j) => UreEvent(
        id: j['id'] as String,
        farmerId: j['farmer_id'] as String,
        cropType: j['crop_type'] as String? ?? '',
        eventType: j['event_type'] as String? ?? '',
        description: j['description'] as String? ?? '',
        financialImpact: (j['financial_impact'] as num?)?.toDouble(),
        status: j['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(j['created_at'] as String),
        verifiedBy: j['verified_by'] as String?,
        verificationNotes: j['verification_notes'] as String?,
      );
}

class AgriUreService {
  static final _client = Supabase.instance.client;
  static final List<UreEvent> _cache = [];

  Future<void> submitUreEvent({
    required String farmerId,
    required String cropType,
    required String eventType,
    required String description,
    double? financialImpact,
  }) async {
    final record = {
      'farmer_id': farmerId,
      'crop_type': cropType,
      'event_type': eventType,
      'description': description,
      if (financialImpact != null) 'financial_impact': financialImpact,
      'status': 'pending',
    };

    try {
      await _client.from('agri_ure_events').insert(record);
    } catch (e) {
      final err = e.toString();
      if (err.contains('PGRST205') || err.contains('does not exist') || err.contains('42P01')) {
        _cache.add(UreEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          farmerId: farmerId,
          cropType: cropType,
          eventType: eventType,
          description: description,
          financialImpact: financialImpact,
          status: 'pending',
          createdAt: DateTime.now(),
        ));
        return;
      }
      rethrow;
    }
  }

  Future<List<UreEvent>> getMyUreEvents(String farmerId) async {
    try {
      final res = await _client
          .from('agri_ure_events')
          .select()
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);
      return (res as List).map((e) => UreEvent.fromJson(e)).toList();
    } catch (e) {
      final err = e.toString();
      if (err.contains('PGRST205') || err.contains('does not exist') || err.contains('42P01')) {
        return _cache.where((ev) => ev.farmerId == farmerId).toList();
      }
      rethrow;
    }
  }

  Future<List<UreEvent>> getAllUreEvents() async {
    try {
      final res = await _client
          .from('agri_ure_events')
          .select()
          .order('created_at', ascending: false);
      return (res as List).map((e) => UreEvent.fromJson(e)).toList();
    } catch (e) {
      final err = e.toString();
      if (err.contains('PGRST205') || err.contains('does not exist') || err.contains('42P01')) {
        return List.from(_cache);
      }
      rethrow;
    }
  }

  Future<void> updateVerificationStatus({
    required String eventId,
    required String status,
    String? verifiedBy,
    String? notes,
  }) async {
    try {
      await _client.from('agri_ure_events').update({
        'status': status,
        if (verifiedBy != null) 'verified_by': verifiedBy,
        if (notes != null) 'verification_notes': notes,
      }).eq('id', eventId);
    } catch (e) {
      final idx = _cache.indexWhere((ev) => ev.id == eventId);
      if (idx != -1) {
        final old = _cache[idx];
        _cache[idx] = UreEvent(
          id: old.id,
          farmerId: old.farmerId,
          cropType: old.cropType,
          eventType: old.eventType,
          description: old.description,
          financialImpact: old.financialImpact,
          status: status,
          createdAt: old.createdAt,
          verifiedBy: verifiedBy,
          verificationNotes: notes,
        );
      }
    }
  }
}
