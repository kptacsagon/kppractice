import 'package:supabase_flutter/supabase_flutter.dart';

class FarmerRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchCropsForFarmer(String farmerId) async {
    try {
      final response = await _client
          .from('planting_records')
          .select('crop_name, area_planted_ha, planting_date, expected_harvest_date')
          .eq('farmer_id', farmerId)
          .order('planting_date', ascending: false);
      
      if (response is List) {
        return response.map((e) => {
          'cropName': e['crop_name'] ?? 'Unknown',
          'landArea': e['area_planted_ha'],
          'plantingDate': e['planting_date'],
          'expectedHarvestDate': e['expected_harvest_date'],
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching crops for farmer $farmerId: $e');
      return [];
    }
  }
}
