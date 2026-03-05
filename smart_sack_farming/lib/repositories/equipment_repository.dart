import '../models/equipment_model.dart';
import '../services/supabase_service.dart';

class EquipmentRepository {
  final SupabaseService _supabaseService = SupabaseService();

  static const String _tableName = 'equipment';

  /// Get all available equipment
  Future<List<Equipment>> getAllEquipment() async {
    try {
      final response =
          await _supabaseService.client.from(_tableName).select();

      return List<Equipment>.from((response as List)
          .map((e) => Equipment.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      throw Exception('Failed to fetch equipment: $e');
    }
  }

  /// Get equipment owned by a user
  Future<List<Equipment>> getUserEquipment(String userId) async {
    try {
      final response = await _supabaseService.client
          .from(_tableName)
          .select()
          .eq('owner_id', userId);

      return List<Equipment>.from((response as List)
          .map((e) => Equipment.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      throw Exception('Failed to fetch user equipment: $e');
    }
  }

  /// Add new equipment
  Future<Equipment> addEquipment(Equipment equipment, String userId) async {
    try {
      final data = {
        'owner_id': userId,
        'name': equipment.name,
        'description': equipment.description,
        'category': equipment.category,
        'daily_rental_price': equipment.dailyRentalPrice,
        'quantity': equipment.quantity,
        'condition': equipment.condition,
      };

      final response = await _supabaseService.client
          .from(_tableName)
          .insert(data)
          .select()
          .single();

      return Equipment.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add equipment: $e');
    }
  }

  /// Update equipment
  Future<void> updateEquipment(Equipment equipment, String userId) async {
    try {
      final data = {
        'name': equipment.name,
        'description': equipment.description,
        'category': equipment.category,
        'daily_rental_price': equipment.dailyRentalPrice,
        'quantity': equipment.quantity,
        'condition': equipment.condition,
      };

      await _supabaseService.client
          .from(_tableName)
          .update(data)
          .eq('id', equipment.id)
          .eq('owner_id', userId);
    } catch (e) {
      throw Exception('Failed to update equipment: $e');
    }
  }

  /// Delete equipment
  Future<void> deleteEquipment(String equipmentId, String userId) async {
    try {
      await _supabaseService.client
          .from(_tableName)
          .delete()
          .eq('id', equipmentId)
          .eq('owner_id', userId);
    } catch (e) {
      throw Exception('Failed to delete equipment: $e');
    }
  }

  /// Search equipment by category
  Future<List<Equipment>> searchByCategory(String category) async {
    try {
      final response = await _supabaseService.client
          .from(_tableName)
          .select()
          .eq('category', category);

      return List<Equipment>.from((response as List)
          .map((e) => Equipment.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      throw Exception('Failed to search equipment: $e');
    }
  }

  /// Search equipment by name
  Future<List<Equipment>> searchByName(String query) async {
    try {
      final response = await _supabaseService.client
          .from(_tableName)
          .select()
          .ilike('name', '%$query%');

      return List<Equipment>.from((response as List)
          .map((e) => Equipment.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      throw Exception('Failed to search equipment: $e');
    }
  }
}
