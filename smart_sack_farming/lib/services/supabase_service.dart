import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  /// Always returns the Supabase client from the already-initialized instance.
  /// Supabase.initialize() must be called first (done in main.dart).
  SupabaseClient get client => Supabase.instance.client;

  /// Initialize is kept for backward compatibility but is no longer needed
  /// since main.dart already calls Supabase.initialize().
  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    // Supabase is already initialized in main.dart
    print('SupabaseService ready (using existing Supabase instance)');
  }

  // Auth Methods
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  // Generic database methods
  Future<List<Map<String, dynamic>>> getRecords(
    String table, {
    Map<String, dynamic>? filters,
  }) async {
    var query = _client.from(table).select();

    if (filters != null) {
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
    }

    return await query;
  }

  Future<Map<String, dynamic>> insertRecord(
    String table,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.from(table).insert(data).select().single();
    return response as Map<String, dynamic>;
  }

  Future<void> updateRecord(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _client.from(table).update(data).eq('id', id);
  }

  Future<void> deleteRecord(String table, String id) async {
    await _client.from(table).delete().eq('id', id);
  }
}
