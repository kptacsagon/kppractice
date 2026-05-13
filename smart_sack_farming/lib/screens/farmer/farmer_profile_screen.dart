import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import '../../theme/app_theme.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
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
        // If RLS error, try to get basic profile from auth metadata
        print('Profile query error (may be RLS): ${e.message}');
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
    
    // Normalize sex value to match dropdown items (capitalize first letter)
    final sexValue = _profileData['sex'] ?? 'Prefer not to say';
    if (sexValue.toString().toLowerCase() == 'male') {
      _selectedSex = 'Male';
    } else if (sexValue.toString().toLowerCase() == 'female') {
      _selectedSex = 'Female';
    } else {
      _selectedSex = 'Prefer not to say';
    }
    
    // Parse date of birth safely
    if (_profileData['date_of_birth'] != null && _profileData['date_of_birth'].toString().isNotEmpty) {
      try {
        final dateStr = _profileData['date_of_birth'].toString();
        _dateOfBirth = DateTime.parse(dateStr);
      } catch (e) {
        print('Error parsing date: $e');
        _dateOfBirth = null;
      }
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final words = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    
    final initials = words
        .map((word) => word.trim().isNotEmpty ? word.trim()[0].toUpperCase() : '')
        .where((c) => c.isNotEmpty)
        .join();
    
    return initials.isEmpty ? '?' : (initials.length > 2 ? initials.substring(0, 2) : initials);
  }

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
        'age': _ageController.text.trim().isNotEmpty 
            ? int.parse(_ageController.text.trim()) 
            : null,
        'date_of_birth': _dateOfBirth != null 
            ? _dateOfBirth!.toIso8601String().split('T')[0]
            : null,
        'land_size_ha': _landSizeController.text.trim().isNotEmpty 
            ? double.parse(_landSizeController.text.trim())
            : null,
        'profile_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('profiles')
          .update(updateData)
          .eq('id', user.id);

      if (!mounted) return;

      setState(() {
        _profileData.addAll(updateData);
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Profile updated successfully',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to update profile: $e';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _uploadProfilePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
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

      // Delete old photo if it exists
      if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
        try {
          final oldPath = _profilePhotoUrl!.split('/').sublist(4).join('/');
          await Supabase.instance.client.storage.from('profile-photos').remove([oldPath]);
        } catch (e) {
          print('Could not delete old photo: $e');
        }
      }

      // Upload new photo
      await Supabase.instance.client.storage.from('profile-photos').upload(
            filePath,
            File(image.path),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final publicUrl = Supabase.instance.client.storage
          .from('profile-photos')
          .getPublicUrl(filePath);

      // Update profile with photo URL
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading photo: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  String _getProfileCompletionPercentage() {
    int completed = 0;
    int total = 6; // Total required fields

    if (_profileData['full_name'] != null && _profileData['full_name'].toString().isNotEmpty) completed++;
    if (_profileData['email'] != null && _profileData['email'].toString().isNotEmpty) completed++;
    if (_profileData['phone'] != null && _profileData['phone'].toString().isNotEmpty) completed++;
    if (_profileData['address'] != null && _profileData['address'].toString().isNotEmpty) completed++;
    if (_profileData['age'] != null) completed++;
    if (_profileData['date_of_birth'] != null) completed++;

    return '${((completed / total) * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const Color darkGreen = Color(0xFF0B2114);
    const Color offWhite = Color(0xFFF6F7F0);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: offWhite,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF285437)),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: offWhite,
        body: Stack(
          children: [
            // Header Background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.28,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0F2618), Color(0xFF081C10)],
                  ),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Top Bar with Back and Edit buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              child: const Icon(Icons.arrow_back_ios_new,
                                  size: 18, color: Color(0xFF285437)),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
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
                    const SizedBox(height: 16),
                    // Profile Header
                    Column(
                      children: [
                    // Avatar
                        Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
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
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            // Photo upload button
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _isUploadingPhoto ? null : _uploadProfilePhoto,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
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
                        ),
                        const SizedBox(height: 12),
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
                        const SizedBox(height: 12),
                        // Name
                        Text(
                          _profileData['full_name'] ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Email
                        Text(
                          _profileData['email'] ?? '',
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatItem(
                              label: 'AGE',
                              value: _profileData['age']?.toString() ?? '-',
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withAlpha(60),
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            _buildStatItem(
                              label: 'LAND',
                              value: '${_profileData['land_size_ha'] ?? '-'} ha',
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withAlpha(60),
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            _buildStatItem(
                              label: 'MEMBER',
                              value: _profileData['created_at'] != null
                                  ? DateFormat('yyyy').format(
                                      DateTime.parse(_profileData['created_at']))
                                  : '-',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Main Content Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Profile Completion
                            _buildProfileCompletion(),
                            const SizedBox(height: 24),
                            // Personal Information
                            _buildSectionHeader('PERSONAL INFORMATION'),
                            const SizedBox(height: 12),
                            _buildProfileField(
                              label: 'FULL NAME',
                              value: _fullNameController.text,
                              icon: Icons.person_outline,
                              controller: _fullNameController,
                              enabled: _isEditing,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Full name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildProfileField(
                              label: 'SEX',
                              value: _selectedSex ?? 'Not specified',
                              icon: Icons.wc_outlined,
                              isDropdown: true,
                              dropdownValue: _selectedSex,
                              onDropdownChanged: _isEditing ? (value) {
                                setState(() => _selectedSex = value);
                              } : null,
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 12),
                            _buildProfileField(
                              label: 'DATE OF BIRTH',
                              value: _dateOfBirth != null
                                  ? _formatDate(_dateOfBirth!)
                                  : 'Not specified',
                              icon: Icons.calendar_today_outlined,
                              onTap: _isEditing ? _pickDateOfBirth : null,
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 12),
                            _buildProfileField(
                              label: 'ADDRESS',
                              value: _addressController.text,
                              icon: Icons.location_on_outlined,
                              controller: _addressController,
                              enabled: _isEditing,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Address is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            // Contact
                            _buildSectionHeader('CONTACT'),
                            const SizedBox(height: 12),
                            _buildProfileField(
                              label: 'EMAIL',
                              value: _emailController.text,
                              icon: Icons.email_outlined,
                              controller: _emailController,
                              enabled: false, // Email typically not editable
                            ),
                            const SizedBox(height: 12),
                            _buildProfileField(
                              label: 'PHONE',
                              value: _phoneController.text,
                              icon: Icons.phone_outlined,
                              controller: _phoneController,
                              enabled: _isEditing,
                              validator: (value) {
                                if (_isEditing && (value == null || value.isEmpty)) {
                                  return 'Phone is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            // Farm Details
                            _buildSectionHeader('FARM DETAILS'),
                            const SizedBox(height: 12),
                            _buildProfileField(
                              label: 'LAND SIZE',
                              value: _landSizeController.text.isNotEmpty
                                  ? '${_landSizeController.text} hectares'
                                  : 'Not specified',
                              icon: Icons.landscape_outlined,
                              controller: _landSizeController,
                              enabled: _isEditing,
                              hint: 'e.g., 1.5',
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (double.tryParse(value) == null) {
                                    return 'Enter a valid number';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildProfileField(
                              label: 'ROLE',
                              value: 'Farmer',
                              icon: Icons.agriculture_outlined,
                              enabled: false,
                            ),
                            const SizedBox(height: 12),
                            _buildProfileField(
                              label: 'MEMBER SINCE',
                              value: _profileData['created_at'] != null
                                  ? DateFormat('MMMM yyyy').format(
                                      DateTime.parse(_profileData['created_at']))
                                  : 'Not available',
                              icon: Icons.calendar_month_outlined,
                              enabled: false,
                            ),
                            const SizedBox(height: 12),
                            _buildProfileField(
                              label: 'AGE',
                              value: _ageController.text.isNotEmpty
                                  ? _ageController.text
                                  : 'Not specified',
                              icon: Icons.cake_outlined,
                              controller: _ageController,
                              enabled: _isEditing,
                              hint: 'e.g., 25',
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final age = int.tryParse(value);
                                  if (age == null || age < 13 || age > 120) {
                                    return 'Enter valid age (13-120)';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(150),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF5D846D),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    required IconData icon,
    TextEditingController? controller,
    bool enabled = false,
    Function()? onTap,
    String? Function(String?)? validator,
    String? hint,
    bool isDropdown = false,
    String? dropdownValue,
    Function(String?)? onDropdownChanged,
  }) {
    if (isDropdown) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? const Color(0xFFE5E9E0) : const Color(0xFFE5E9E0),
            ),
          ),
          child: enabled
              ? DropdownButton<String>(
                  value: dropdownValue ?? 'Prefer not to say',
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(
                      value: 'Prefer not to say',
                      child: Text('Prefer not to say'),
                    ),
                  ],
                  onChanged: onDropdownChanged,
                )
              : Row(
                  children: [
                    Icon(icon, size: 20, color: const Color(0xFF7E9786)),
                    const SizedBox(width: 12),
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
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            value,
                            style: const TextStyle(
                              color: Color(0xFF2A5239),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 20, color: Color(0xFF8F9F94)),
                  ],
                ),
        ),
      );
    }

    if (controller != null) {
      return TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          fillColor: Colors.white,
          filled: true,
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF7E9786)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E9E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E9E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF285437), width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E9E0)),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          labelStyle: const TextStyle(
            color: Color(0xFF8F9F94),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: const TextStyle(color: Color(0xFF8F9F94)),
        ),
        style: const TextStyle(
          color: Color(0xFF2A5239),
          fontSize: 15,
        ),
        validator: validator,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E9E0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF7E9786)),
            const SizedBox(width: 12),
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF2A5239),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled)
              const Icon(Icons.chevron_right,
                  size: 20, color: Color(0xFF8F9F94)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCompletion() {
    final percentage = _getProfileCompletionPercentage();
    final progressValue = double.parse(percentage.replaceAll('%', '')) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PROFILE COMPLETION',
              style: TextStyle(
                color: Color(0xFF5D846D),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              percentage,
              style: const TextStyle(
                color: Color(0xFF285437),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E9E0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5FB87B)),
          ),
        ),
      ],
    );
  }
}
