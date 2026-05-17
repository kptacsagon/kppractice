import 'package:supabase_flutter/supabase_flutter.dart';

class SaturationBroadcastService {
  final _supabase = Supabase.instance.client;

  /// Get all saturation broadcasts visible to the current user
  Future<List<Map<String, dynamic>>> getSaturationBroadcasts() async {
    try {
      final broadcasts = await _supabase
          .from('saturation_broadcasts')
          .select()
          .order('created_at', ascending: false);

      return broadcasts.cast<Map<String, dynamic>>();
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread saturation broadcasts for a farmer
  Future<List<Map<String, dynamic>>> getUnreadBroadcasts(String farmerId) async {
    try {
      final unreadBroadcasts = await _supabase
          .from('saturation_broadcast_recipients')
          .select('''
            broadcast_id,
            is_read,
            created_at,
            saturation_broadcasts(
              id,
              admin_name,
              municipality,
              title,
              description,
              high_saturation_crops,
              medium_saturation_crops,
              low_saturation_crops,
              recommendations,
              created_at
            )
          ''')
          .eq('farmer_id', farmerId)
          .eq('is_read', false)
          .order('created_at', ascending: false);

      return unreadBroadcasts.cast<Map<String, dynamic>>();
    } catch (e) {
      rethrow;
    }
  }

  /// Mark a broadcast as read by a farmer
  Future<void> markBroadcastAsRead(String broadcastId, String farmerId) async {
    try {
      await _supabase
          .from('saturation_broadcast_recipients')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('broadcast_id', broadcastId)
          .eq('farmer_id', farmerId);
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new saturation broadcast (Admin/MAO only)
  /// This calls the RPC function to create a broadcast and notify all farmers
  Future<String> broadcastSaturationAlert({
    required String adminName,
    required String municipality,
    required String title,
    required String description,
    required List<String> highSaturationCrops,
    required List<String> mediumSaturationCrops,
    required List<String> lowSaturationCrops,
    required String recommendations,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase.rpc(
        'broadcast_saturation_alert',
        params: {
          'p_admin_id': userId,
          'p_admin_name': adminName,
          'p_municipality': municipality,
          'p_title': title,
          'p_description': description,
          'p_high_saturation_crops': highSaturationCrops,
          'p_medium_saturation_crops': mediumSaturationCrops,
          'p_low_saturation_crops': lowSaturationCrops,
          'p_recommendations': recommendations,
        },
      );

      return response as String;
    } catch (e) {
      rethrow;
    }
  }

  /// Get saturation analysis data to include in broadcast
  Future<Map<String, dynamic>> getSaturationAnalysisForBroadcast() async {
    try {
      final records = await _supabase
          .from('saturation_records')
          .select('primary_crop, saturation_level');

      // Group and analyze by crop and saturation level
      final Map<String, Map<String, int>> cropAnalysis = {};

      for (final record in records as List) {
        final crop = record['primary_crop'] as String? ?? 'Unknown';
        final saturation = record['saturation_level'] as String? ?? 'medium';

        if (!cropAnalysis.containsKey(crop)) {
          cropAnalysis[crop] = {'low': 0, 'medium': 0, 'high': 0};
        }

        cropAnalysis[crop]![saturation] =
            (cropAnalysis[crop]![saturation] ?? 0) + 1;
      }

      // Categorize crops by saturation level
      final List<String> highSaturation = [];
      final List<String> mediumSaturation = [];
      final List<String> lowSaturation = [];

      cropAnalysis.forEach((crop, levels) {
        final total = levels['low']! + levels['medium']! + levels['high']!;
        if (total == 0) return;

        final saturationPercent =
            ((levels['medium']! + levels['high']!) / total * 100);

        if (saturationPercent >= 70) {
          highSaturation.add(crop);
        } else if (saturationPercent >= 40) {
          mediumSaturation.add(crop);
        } else {
          lowSaturation.add(crop);
        }
      });

      return {
        'high_saturation_crops': highSaturation,
        'medium_saturation_crops': mediumSaturation,
        'low_saturation_crops': lowSaturation,
        'total_records': records.length,
        'crop_analysis': cropAnalysis,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get broadcast details with recipient count
  Future<Map<String, dynamic>> getBroadcastDetails(String broadcastId) async {
    try {
      final broadcast = await _supabase
          .from('saturation_broadcasts')
          .select('''
            *,
            recipients:saturation_broadcast_recipients(
              count()
            )
          ''')
          .eq('id', broadcastId)
          .single();

      return broadcast as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
