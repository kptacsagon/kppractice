import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isUploadingPhoto = false;
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
        .select('full_name, email, role, age, sex, date_of_birth, address, land_size_ha, avatar_url')
            .eq('id', userId)
            .maybeSingle();
      } catch (_) {
        profile = await Supabase.instance.client
            .from('profiles')
        .select('full_name, email, role, address, avatar_url')
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
        'avatar_url': profile?['avatar_url'] ?? metadata['avatar_url'],
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

  bool get _isOwnProfile {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return false;
    if (widget.farmerId == null) return true;
    return widget.farmerId == currentUser.id;
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    if (!_isOwnProfile) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) {
        if (mounted) setState(() => _isUploadingPhoto = false);
        return;
      }

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) throw Exception('Not authenticated');

      final bytes = await picked.readAsBytes();
      final fileName = 'avatar_${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';

      String uploadBucket = 'profile-images';
      try {
        await Supabase.instance.client.storage
            .from(uploadBucket)
            .uploadBinary(fileName, bytes);
      } catch (storageError) {
        final storageErrorText = storageError.toString().toLowerCase();
        if (storageErrorText.contains('bucket not found')) {
          uploadBucket = 'calamity-images';
          await Supabase.instance.client.storage
              .from(uploadBucket)
              .uploadBinary(fileName, bytes);
        } else {
          rethrow;
        }
      }

      final imageUrl = Supabase.instance.client.storage
          .from(uploadBucket)
          .getPublicUrl(fileName);

      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', currentUser.id);

      if (!mounted) return;
      setState(() {
        _profile = {
          ...?_profile,
          'avatar_url': imageUrl,
        };
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      final errorText = e.toString().toLowerCase();
      if (errorText.contains('bucket not found')) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Profile Photos Setup Required'),
            content: const Text(
              'The storage bucket "profile-images" is not created yet in Supabase.\n\n'
              'Run PROFILE_IMAGES_SETUP.sql in Supabase SQL Editor, then try uploading again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload profile photo: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
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
    final avatarUrl = (profile['avatar_url'] ?? '').toString();

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
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppTheme.primary.withAlpha(25),
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? const Icon(Icons.person_rounded, size: 46, color: AppTheme.primary)
                        : null,
                  ),
                  if (_isOwnProfile) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_isUploadingPhoto) return;
                          _pickAndUploadProfilePhoto();
                        },
                        icon: _isUploadingPhoto
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.photo_camera_outlined, size: 18),
                        label: Text(_isUploadingPhoto ? 'Uploading...' : 'Upload Photo'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
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
