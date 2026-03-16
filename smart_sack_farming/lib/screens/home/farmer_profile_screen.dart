import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';

class FarmerProfileScreen extends StatefulWidget {
  final String? farmerId;
  const FarmerProfileScreen({super.key, this.farmerId});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  String? _error;
  int _activePlantingsCount = 0;
  List<Map<String, dynamic>> _plantings = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final userId = widget.farmerId ?? currentUser?.id;
      if (userId == null) throw Exception('No farmer id provided or authenticated.');

      Map<String, dynamic>? profile;
      try {
        profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name, email, role, age, sex, date_of_birth, address, land_size_ha')
            .eq('id', userId)
            .maybeSingle();
      } catch (_) {
        profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name, email, role, address')
            .eq('id', userId)
            .maybeSingle();
      }

      final metadata = (currentUser != null && currentUser.id == userId) ? currentUser.userMetadata ?? <String, dynamic>{} : <String, dynamic>{};
      final mergedProfile = <String, dynamic>{
        ...(profile ?? <String, dynamic>{}),
        'email': profile?['email'] ?? currentUser?.email,
        'age': profile?['age'] ?? metadata['age'],
        'sex': profile?['sex'] ?? metadata['sex'],
        'date_of_birth': profile?['date_of_birth'] ?? metadata['date_of_birth'],
        'address': profile?['address'] ?? metadata['address'],
        'land_size_ha': profile?['land_size_ha'] ?? metadata['land_size_ha'],
      };

      // Fetch planting records for this farmer
      final recs = await Supabase.instance.client
          .from('planting_records')
          .select('crop_name, planting_date, expected_harvest_date, status')
          .eq('farmer_id', userId);

      final plantings = List<Map<String, dynamic>>.from(recs as List<dynamic>? ?? []);
      final active = plantings.where((p) {
        final status = (p['status'] as String?) ?? '';
        return status == 'growing' || status == 'harvesting';
      }).toList();

      if (!mounted) return;
      setState(() {
        _profile = mergedProfile;
        _isLoading = false;
        _plantings = plantings;
        _activePlantingsCount = active.length;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatValue(dynamic value, {String fallback = 'Not set'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _formatDate(dynamic value) {
    final text = _formatValue(value);
    if (text == 'Not set') return text;
    if (text.length >= 10) return text.substring(0, 10);
    return text;
  }

  String _formatLandSize(dynamic value) {
    if (value == null) return 'Not set';
    final parsed = double.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return '${parsed.toStringAsFixed(parsed == parsed.roundToDouble() ? 0 : 2)} ha';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 44, color: AppTheme.error),
            const SizedBox(height: 12),
            const Text(
              'Unable to load profile',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMedium),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    final profile = _profile ?? <String, dynamic>{};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppTheme.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField('Name', _formatValue(profile['full_name'])),
            _buildField('Email', _formatValue(profile['email'])),
            _buildField('Role', _formatValue(profile['role'])),
            const Divider(height: 28),
            _buildField('Age', _formatValue(profile['age'])),
            _buildField('Sex', _formatValue(profile['sex'])),
            _buildField('Date of Birth', _formatDate(profile['date_of_birth'])),
            _buildField('Address', _formatValue(profile['address'])),
            _buildField('Land Size', _formatLandSize(profile['land_size_ha'])),
            const SizedBox(height: 18),
            // --- Planting dashboard ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active plantings: $_activePlantingsCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (_plantings.isEmpty)
                    const Text('No planting records found.')
                  else
                    Column(
                      children: _plantings.map((p) {
                        final crop = p['crop_name'] ?? '';
                        final planting = p['planting_date'] ?? '';
                        final harvest = p['expected_harvest_date'] ?? '';
                        return ListTile(
                          dense: true,
                          title: Text(crop.toString()),
                          subtitle: Text('Planted: ${planting.toString().substring(0,10)}  → Harvest: ${harvest.toString().substring(0,10)}'),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMedium,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
