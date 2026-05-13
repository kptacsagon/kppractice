import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart'; // for UserRole import
import '../home/farmer_dashboard_screen.dart';
import '../home/mao_admin_dashboard.dart';
import '../buyer/buyer_marketplace_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final UserRole role;

  const CompleteProfileScreen({super.key, required this.role});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Farmer fields
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _landSizeController = TextEditingController();
  String? _selectedSex = 'Prefer not to say';
  DateTime? _dateOfBirth;

  // Buyer fields
  final _contactController = TextEditingController();
  final _organizationController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _ageController.dispose();
    _addressController.dispose();
    _landSizeController.dispose();
    _contactController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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

  Future<void> _skipOrComplete() async {
    _navigateToDashboard();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      if (widget.role == UserRole.farmer) {
        // Call the complete_profile RPC function for farmers
        final response = await Supabase.instance.client.rpc(
          'complete_profile',
          params: {
            'p_user_id': user.id,
            'p_address': _addressController.text.trim(),
            'p_age': _ageController.text.trim().isNotEmpty ? int.parse(_ageController.text.trim()) : null,
            'p_sex': _selectedSex,
            'p_date_of_birth': _dateOfBirth != null ? _formatDate(_dateOfBirth!) : null,
            'p_land_size_ha': _landSizeController.text.trim().isNotEmpty ? double.parse(_landSizeController.text.trim()) : null,
          },
        );

        if (response == null) throw Exception('Failed to complete profile');

        final result = response is String ? response : response;
        print('Profile completion response: $result');
      } else if (widget.role == UserRole.buyer) {
        // For buyers, use direct update (can be enhanced with RPC later)
        final updateData = <String, dynamic>{
          if (_contactController.text.trim().isNotEmpty) 'phone': _contactController.text.trim(),
          if (_organizationController.text.trim().isNotEmpty) 'organization': _organizationController.text.trim(),
          if (_addressController.text.trim().isNotEmpty) 'address': _addressController.text.trim(),
          'profile_complete': true,
        };

        if (updateData.isNotEmpty) {
          await Supabase.instance.client.from('profiles').update(updateData).eq('id', user.id);
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      _navigateToDashboard();

    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _navigateToDashboard() {
    Widget destination;
    switch (widget.role) {
      case UserRole.farmer:
        destination = const FarmerDashboardScreen();
        break;
      case UserRole.admin:
        destination = const MaoAdminDashboard();
        break;
      case UserRole.buyer:
        destination = const BuyerMarketplaceScreen();
        break;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, anim, secondaryAnimation, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.role == UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToDashboard());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _skipOrComplete,
            child: Text('Skip for now', style: TextStyle(color: AppTheme.textMedium)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.account_circle_outlined, size: 64, color: AppTheme.primary),
              const SizedBox(height: 16),
              const Text(
                'Complete Your Profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help us customize your ${widget.role.name} experience by providing a few more details.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textMedium,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),
              
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (widget.role == UserRole.farmer) ...[
                      TextFormField(
                        controller: _addressController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Barangay / Municipality',
                          hintText: 'e.g. San Isidro, City of Naga',
                          prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Barangay / Municipality is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          hintText: 'e.g. 35',
                          prefixIcon: Icon(Icons.cake_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed <= 0 || parsed > 120) {
                            return 'Enter a valid age';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedSex,
                        decoration: const InputDecoration(
                          labelText: 'Sex',
                          prefixIcon: Icon(Icons.wc_rounded, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                        ],
                        onChanged: (value) => setState(() => _selectedSex = value),
                      ),
                      const SizedBox(height: 16),
                      FormField<String>(
                        builder: (state) {
                          final dateText = _dateOfBirth == null ? '' : _formatDate(_dateOfBirth!);
                          return InkWell(
                            onTap: () async {
                              await _pickDateOfBirth();
                              state.didChange(dateText);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date of Birth',
                                prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                dateText.isEmpty ? 'Select date' : dateText,
                                style: TextStyle(
                                  color: dateText.isEmpty ? AppTheme.textLight : AppTheme.textDark,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _landSizeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Land Size (hectares)',
                          hintText: 'e.g. 1.5',
                          prefixIcon: Icon(Icons.landscape_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid land size';
                          }
                          return null;
                        },
                      ),
                    ],

                    if (widget.role == UserRole.buyer) ...[
                      TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact Number',
                          hintText: 'e.g. 09XXXXXXXXX',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _organizationController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Organization',
                          hintText: 'Company / Cooperative / Group',
                          prefixIcon: Icon(Icons.business_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          hintText: 'Barangay / Municipality',
                          prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save and Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
