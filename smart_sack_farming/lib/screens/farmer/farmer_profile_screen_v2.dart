import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import '../../theme/app_theme.dart';

class FarmerProfileScreenV2 extends StatefulWidget {
  const FarmerProfileScreenV2({super.key});

  @override
  State<FarmerProfileScreenV2> createState() => _FarmerProfileScreenV2State();
}

class _FarmerProfileScreenV2State extends State<FarmerProfileScreenV2> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  // Form controllers
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _ageController;
  late TextEditingController _landSizeController;

  // Profile data
  Map<String, dynamic> _profileData = {};
  String? _selectedSex = 'Prefer not to say';
  DateTime? _dateOfBirth;

  // UI state
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfileData();
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _ageController = TextEditingController();
    _landSizeController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _landSizeController.dispose();
    super.dispose();
  }

  // ==================== DATA LOADING ====================
  Future<void> _loadProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not authenticated';
        });
        return;
      }

      try {
        final response = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        setState(() {
          _profileData = response;
          _populateControllers();
          _isLoading = false;
        });
      } on PostgrestException catch (e) {
        print('Profile query error: ${e.message}');
        setState(() {
          _profileData = {
            'id': user.id,
            'email': user.email ?? '',
            'full_name': user.userMetadata?['full_name'] ?? '',
            'role': user.userMetadata?['role'] ?? 'farmer',
            'address': user.userMetadata?['address'] ?? '',
            'phone': user.userMetadata?['phone'] ?? '',
            'age': user.userMetadata?['age'],
            'sex': user.userMetadata?['sex'],
            'date_of_birth': user.userMetadata?['date_of_birth'],
            'land_size_ha': user.userMetadata?['land_size_ha'],
            'profile_complete': user.userMetadata?['profile_complete'] ?? false,
            'profile_photo_url': user.userMetadata?['profile_photo_url'],
          };
          _populateControllers();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load profile: $e';
      });
    }
  }

  void _populateControllers() {
    _fullNameController.text = _profileData['full_name'] ?? '';
    _emailController.text = _profileData['email'] ?? '';
    _phoneController.text = _profileData['phone'] ?? '';
    _addressController.text = _profileData['address'] ?? '';
    _ageController.text = _profileData['age']?.toString() ?? '';
    _landSizeController.text = _profileData['land_size_ha']?.toString() ?? '';
    _profilePhotoUrl = _profileData['profile_photo_url'];

    // Normalize sex value
    final sexValue = _profileData['sex'] ?? 'Prefer not to say';
    if (sexValue.toString().toLowerCase() == 'male') {
      _selectedSex = 'Male';
    } else if (sexValue.toString().toLowerCase() == 'female') {
      _selectedSex = 'Female';
    } else {
      _selectedSex = 'Prefer not to say';
    }

    // Parse date of birth
    if (_profileData['date_of_birth'] != null && _profileData['date_of_birth'].toString().isNotEmpty) {
      try {
        _dateOfBirth = DateTime.parse(_profileData['date_of_birth'].toString());
      } catch (e) {
        _dateOfBirth = null;
      }
    }
  }

  // ==================== PHOTO UPLOAD ====================
  Future<void> _showPhotoMenu() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Color(0xFF285437)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF285437)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.gallery);
              },
            ),
            if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image == null) return;

      setState(() => _isUploadingPhoto = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'profile-photos/${user.id}/$fileName';

      // Delete old photo if exists
      if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
        try {
          final oldPath = _profilePhotoUrl!.split('/').sublist(4).join('/');
          await Supabase.instance.client.storage.from('profile-photos').remove([oldPath]);
        } catch (e) {
          print('Could not delete old photo: $e');
        }
      }

      // Upload new photo - read bytes from XFile
      final fileBytes = await image.readAsBytes();
      await Supabase.instance.client.storage.from('profile-photos').uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final publicUrl = Supabase.instance.client.storage
          .from('profile-photos')
          .getPublicUrl(filePath);

      // Update profile
      await Supabase.instance.client
          .from('profiles')
          .update({'profile_photo_url': publicUrl})
          .eq('id', user.id);

      setState(() {
        _profilePhotoUrl = publicUrl;
        _profileData['profile_photo_url'] = publicUrl;
        _isUploadingPhoto = false;
      });

      if (!mounted) return;
      _showSnackBar('Profile photo updated successfully', isError: false);
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (!mounted) return;
      _showSnackBar('Error uploading photo: $e', isError: true);
    }
  }

  Future<void> _removeProfilePhoto() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      setState(() => _isUploadingPhoto = true);

      // Delete from storage
      if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
        try {
          final path = _profilePhotoUrl!.split('/').sublist(4).join('/');
          await Supabase.instance.client.storage.from('profile-photos').remove([path]);
        } catch (e) {
          print('Error deleting photo: $e');
        }
      }

      // Clear from database
      await Supabase.instance.client
          .from('profiles')
          .update({'profile_photo_url': null})
          .eq('id', user.id);

      setState(() {
        _profilePhotoUrl = null;
        _profileData['profile_photo_url'] = null;
        _isUploadingPhoto = false;
      });

      if (!mounted) return;
      _showSnackBar('Profile photo removed', isError: false);
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (!mounted) return;
      _showSnackBar('Error removing photo: $e', isError: true);
    }
  }

  // ==================== PROFILE UPDATES ====================
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'sex': _selectedSex,
        'age': _ageController.text.trim().isNotEmpty ? int.parse(_ageController.text.trim()) : null,
        'date_of_birth': _dateOfBirth != null ? _dateOfBirth!.toIso8601String().split('T')[0] : null,
        'land_size_ha': _landSizeController.text.trim().isNotEmpty ? double.parse(_landSizeController.text.trim()) : null,
        'profile_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('profiles').update(updateData).eq('id', user.id);

      setState(() {
        _profileData.addAll(updateData);
        _isEditing = false;
        _isSaving = false;
      });

      if (!mounted) return;
      _showSnackBar('Profile updated successfully', isError: false);
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      _showSnackBar('Error updating profile: $e', isError: true);
    }
  }

  // ==================== HELPER METHODS ====================
  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final words = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';

    final initials = words.map((word) => word.trim()[0].toUpperCase()).join();
    return initials.isEmpty ? '?' : (initials.length > 2 ? initials.substring(0, 2) : initials);
  }

  String _formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  int _getProfileCompletion() {
    int completed = 0;
    if (_profileData['full_name']?.toString().isNotEmpty ?? false) completed++;
    if (_profileData['email']?.toString().isNotEmpty ?? false) completed++;
    if (_profileData['phone']?.toString().isNotEmpty ?? false) completed++;
    if (_profileData['address']?.toString().isNotEmpty ?? false) completed++;
    if (_profileData['land_size_ha'] != null) completed++;
    if (_profileData['sex']?.toString().isNotEmpty ?? false) completed++;
    if (_profileData['date_of_birth'] != null) completed++;
    return ((completed / 7) * 100).toInt();
  }

  String _getMemberSince() {
    try {
      final createdAt = _profileData['created_at'];
      if (createdAt == null) return DateTime.now().year.toString();
      final date = DateTime.parse(createdAt.toString());
      return date.year.toString();
    } catch (e) {
      return DateTime.now().year.toString();
    }
  }

  String _formatLandSize(dynamic value) {
    if (value == null) return 'Not set';
    final parsed = double.tryParse(value.toString());
    if (parsed == null) return value.toString();
    final decimals = parsed == parsed.roundToDouble() ? 0 : 2;
    return '${parsed.toStringAsFixed(decimals)} ha';
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  // ==================== BUILD METHODS ====================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7F0),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF285437)),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F0),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              // Stats Strip
              _buildStatsStrip(),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Profile Completion
                    _buildProgressBar(),
                    const SizedBox(height: 28),
                    // Form
                    if (_isEditing) _buildEditForm() else _buildViewMode(),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F2618), Color(0xFF081C10)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(90),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF285437)),
                      ),
                    ),
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_isEditing) {
                          _updateProfile();
                        } else {
                          setState(() => _isEditing = true);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(90),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isEditing ? 'Save' : 'Edit',
                          style: const TextStyle(
                            color: Color(0xFF285437),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Avatar
              _buildAvatar(),
              const SizedBox(height: 16),
              // Name
              Text(
                _profileData['full_name'] ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Email
              Text(
                _profileData['email'] ?? '',
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFC49A50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'FARMER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFF235332),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            image: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(_profilePhotoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _profilePhotoUrl == null || _profilePhotoUrl!.isEmpty
              ? Center(
                  child: Text(
                    _getInitials(_profileData['full_name'] as String?),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploadingPhoto ? null : _showPhotoMenu,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFC49A50),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: _isUploadingPhoto
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsStrip() {
    final age = _profileData['age'] ?? 'N/A';
    final landSize = _formatLandSize(_profileData['land_size_ha']);
    final memberYear = _getMemberSince();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(age.toString(), 'AGE'),
            _buildDivider(),
            _buildStatItem(landSize, 'LAND SIZE'),
            _buildDivider(),
            _buildStatItem(memberYear, 'MEMBER YEAR'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF142B1B),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8F9F94),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFFE5E9E0),
    );
  }

  Widget _buildProgressBar() {
    final completion = _getProfileCompletion();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Profile Completion',
              style: TextStyle(
                color: Color(0xFF5D846D),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$completion%',
              style: const TextStyle(
                color: Color(0xFF285437),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: completion / 100,
            minHeight: 7,
            backgroundColor: const Color(0xFFE5E9E0),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF5FB87B)),
          ),
        ),
      ],
    );
  }

  Widget _buildViewMode() {
    return Column(
      children: [
        _buildInfoCard('PERSONAL INFORMATION', [
          _buildInfoRow('FULL NAME', _profileData['full_name'] ?? 'Not set'),
          _buildInfoRow('SEX', _profileData['sex'] ?? 'Not set'),
          _buildInfoRow('DATE OF BIRTH', _dateOfBirth != null ? _formatDate(_dateOfBirth!) : 'Not set'),
          _buildInfoRow('BARANGAY / MUNICIPALITY', _profileData['address'] ?? 'Not set'),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('CONTACT', [
          _buildInfoRow('EMAIL', _profileData['email'] ?? 'Not set'),
          _buildInfoRow('PHONE', _profileData['phone'] ?? 'Not set'),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('FARM DETAILS', [
          _buildInfoRow('LAND SIZE', _formatLandSize(_profileData['land_size_ha'])),
          _buildInfoRow('MEMBER SINCE', _getMemberSince()),
          _buildInfoRow('AGE', _profileData['age']?.toString() ?? 'Not set'),
        ]),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildFormCard('PERSONAL INFORMATION', [
            _buildFormField('Full Name', _fullNameController, 'Enter your full name', icon: Icons.person_outline),
            const SizedBox(height: 12),
            _buildDropdownField('Sex', _selectedSex, ['Male', 'Female', 'Prefer not to say'], (value) {
              setState(() => _selectedSex = value);
            }, icon: Icons.wc_rounded),
            const SizedBox(height: 12),
            _buildDateField('Date of Birth', _dateOfBirth, icon: Icons.cake_outlined),
            const SizedBox(height: 12),
            _buildFormField(
              'Barangay / Municipality',
              _addressController,
              'Enter barangay and municipality',
              icon: Icons.location_on_outlined,
              textCapitalization: TextCapitalization.words,
            ),
          ]),
          const SizedBox(height: 16),
          _buildFormCard('CONTACT', [
            _buildFormField('Email', _emailController, '', readOnly: true, icon: Icons.email_outlined),
            const SizedBox(height: 12),
            _buildFormField(
              'Phone',
              _phoneController,
              'Enter mobile number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
            ),
          ]),
          const SizedBox(height: 16),
          _buildFormCard('FARM DETAILS', [
            _buildFormField(
              'Land Size (ha)',
              _landSizeController,
              'Enter total cultivated area',
              icon: Icons.landscape_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
            ),
            const SizedBox(height: 12),
            _buildFormField(
              'Age',
              _ageController,
              'Enter age in years',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF5D846D),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: children.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (_, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: children[index],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8F9F94),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF2A5239),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF5D846D),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    String hint, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    List<TextInputFormatter>? inputFormatters,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5D846D),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFC0CEC3)),
            prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF5D846D), size: 18) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E9E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E9E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF285437), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5D846D),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF5D846D), size: 18) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E9E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E9E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF285437), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? value, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5D846D),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDateOfBirth,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E9E0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value != null ? _formatDate(value) : 'Select date',
                  style: TextStyle(
                    color: value != null ? const Color(0xFF2A5239) : const Color(0xFFC0CEC3),
                    fontSize: 14,
                  ),
                ),
                Icon(icon ?? Icons.calendar_today, size: 18, color: const Color(0xFF285437)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
