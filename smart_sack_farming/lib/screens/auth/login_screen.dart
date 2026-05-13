import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../home/farmer_dashboard_screen.dart';
import '../home/mao_admin_dashboard.dart';
import '../buyer/buyer_marketplace_screen.dart';
import 'signup_screen.dart';
import 'complete_profile_screen.dart';

enum UserRole { farmer, admin, buyer }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.farmer;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _syncProfileFromMetadata(
    User user,
    String role,
    String emailFallback,
  ) async {
    final client = Supabase.instance.client;
    final metadata = user.userMetadata ?? <String, dynamic>{};

    final address = metadata['address']?.toString().trim();
    final phone = metadata['phone']?.toString().trim();
    final organization = metadata['organization']?.toString().trim();
    final age = int.tryParse('${metadata['age'] ?? ''}');
    final landSize = double.tryParse('${metadata['land_size_ha'] ?? ''}');
    final sex = metadata['sex']?.toString().toLowerCase().trim();
    final dateOfBirth = metadata['date_of_birth']?.toString().trim();

    final baseData = <String, dynamic>{
      'id': user.id,
      'email': user.email ?? emailFallback,
      'full_name': (metadata['full_name'] ?? emailFallback.split('@')[0]).toString(),
      'role': role,
    };

    final farmerFullData = <String, dynamic>{
      if (age != null) 'age': age,
      if (sex != null && sex.isNotEmpty) 'sex': sex,
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) 'date_of_birth': dateOfBirth,
      if (address != null && address.isNotEmpty) 'address': address,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (organization != null && organization.isNotEmpty)
        'organization': organization,
      if (landSize != null) 'land_size_ha': landSize,
    };

    final farmerAddressOnlyData = <String, dynamic>{
      if (address != null && address.isNotEmpty) 'address': address,
    };

    final farmerAddressAndLandSizeData = <String, dynamic>{
      if (address != null && address.isNotEmpty) 'address': address,
      if (landSize != null) 'land_size_ha': landSize,
    };

    final candidates = <Map<String, dynamic>>[
      {...baseData, ...farmerFullData},
      if (farmerAddressAndLandSizeData.isNotEmpty)
        {...baseData, ...farmerAddressAndLandSizeData},
      if (farmerAddressOnlyData.isNotEmpty) {...baseData, ...farmerAddressOnlyData},
      baseData,
    ];

    Object? lastError;
    for (final candidate in candidates) {
      try {
        await client.from('profiles').upsert(candidate, onConflict: 'id');
        return;
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      print('Profile sync note: $lastError');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Sign in with Supabase
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.user != null) {
        // ── Role verification ──────────────────────────────────────────
        // Determine the user's actual role from the profiles table first,
        // falling back to user_metadata if the profile doesn't exist yet.
        String actualRole = 'farmer'; // default

        try {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('id, role')
              .eq('id', response.user!.id)
              .maybeSingle();

          if (profile != null) {
            actualRole = (profile['role'] ?? 'farmer').toString().toLowerCase();
          } else {
            // Profile doesn't exist yet — use metadata and create profile
            actualRole = (response.user!.userMetadata?['role'] ?? 'farmer')
                .toString()
                .toLowerCase();
            await Supabase.instance.client.from('profiles').insert({
              'id': response.user!.id,
              'email': _emailController.text.trim(),
              'role': actualRole,
              'full_name': response.user!.userMetadata?['full_name'] ??
                  _emailController.text.trim().split('@')[0],
            });
          }
        } catch (e) {
          // If profile query fails, fall back to metadata
          actualRole = (response.user!.userMetadata?['role'] ?? 'farmer')
              .toString()
              .toLowerCase();
          print('Profile check note: $e');
        }

        // Map selected UI role to string
        String selectedRoleStr;
        switch (_selectedRole) {
          case UserRole.farmer:
            selectedRoleStr = 'farmer';
            break;
          case UserRole.admin:
            selectedRoleStr = 'admin';
            break;
          case UserRole.buyer:
            selectedRoleStr = 'buyer';
            break;
        }

        // Block login if role mismatch
        if (actualRole != selectedRoleStr) {
          // Sign the user out immediately — they shouldn't stay authenticated
          await Supabase.instance.client.auth.signOut();

          if (!mounted) return;
          setState(() => _isLoading = false);

          String roleLabel;
          switch (actualRole) {
            case 'admin':
              roleLabel = 'Admin';
              break;
            case 'buyer':
              roleLabel = 'Buyer';
              break;
            default:
              roleLabel = 'Farmer';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.block_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Access denied. This account is registered as $roleLabel. '
                      'Please select the "$roleLabel" role to sign in.',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          return;
        }
        // ── End role verification ──────────────────────────────────────

        await _syncProfileFromMetadata(
          response.user!,
          actualRole,
          _emailController.text.trim(),
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        // Check if profile needs completion
        bool needsCompletion = false;
        try {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('age, address, phone, organization')
              .eq('id', response.user!.id)
              .maybeSingle();

          if (profile != null) {
            if (_selectedRole == UserRole.farmer) {
              needsCompletion = profile['age'] == null || profile['address'] == null;
            } else if (_selectedRole == UserRole.buyer) {
              needsCompletion = profile['phone'] == null || profile['organization'] == null;
            }
          }
        } catch (e) {
          needsCompletion = true;
        }

        Widget destination;
        if (needsCompletion && _selectedRole != UserRole.admin) {
          destination = CompleteProfileScreen(role: _selectedRole);
        } else {
          switch (_selectedRole) {
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
    } on AuthException catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first to reset password.')),
      );
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent to your email.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to send reset link: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    const Color darkGreen = Color(0xFF0B2114);
    const Color offWhite = Color(0xFFF6F7F0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: offWhite,
        body: Stack(
          children: [
            // Top Wavy Background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.40,
              child: ClipPath(
                clipper: TopWaveClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    color: darkGreen,
                    // Optional subtle gradient matching the image
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0F2618), Color(0xFF081C10)],
                    ),
                  ),
                ),
              ),
            ),
            // Background pattern behind Logo
            Positioned(
              top: size.height * 0.1,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(5),
                  ),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(20),
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? size.width * 0.2 : 24,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Logo & Title
                          _buildHeader(),
                          const SizedBox(height: 48),
                          // Login Options and Form
                          _buildLoginSection(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF235332), // Darker green circle
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.eco_rounded, color: Color(0xFFC49A50), size: 36), // Using eco with brownish/gold color resembling the sack plant
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'SmartSack Farm',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'FARMING INTELLIGENCE PLATFORM',
          style: TextStyle(
            color: Colors.white.withAlpha(150),
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginSection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Role Selector
          const Text(
            'SIGN IN AS',
            style: TextStyle(
              color: Color(0xFF5D846D),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildRoleSelector(),
          const SizedBox(height: 24),
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'Email address',
              hintStyle: const TextStyle(color: Color(0xFF8F9F94)),
              fillColor: Colors.white,
              filled: true,
              prefixIcon: const Icon(Icons.mail_outline, size: 22, color: Color(0xFF7E9786)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E9E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E9E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF285437), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: const TextStyle(color: Color(0xFF8F9F94)),
              fillColor: Colors.white,
              filled: true,
              prefixIcon: const Icon(Icons.lock_outline, size: 22, color: Color(0xFF7E9786)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: const Color(0xFF7E9786),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E9E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E9E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF285437), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Remember me & Forgot Password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                      activeColor: const Color(0xFF285437),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      side: const BorderSide(color: Color(0xFFC0CEC3), width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Remember me',
                    style: TextStyle(
                      color: Color(0xFF5D846D),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _handleForgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: Color(0xFF235560), // Tealish dark tone
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Login Button
          _buildLoginButton(),
          const SizedBox(height: 32),
          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildRoleCard(
            role: UserRole.farmer,
            icon: Icons.pin_drop_outlined, // Closer to image mock
            label: 'Farmer',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRoleCard(
            role: UserRole.buyer,
            icon: Icons.shopping_bag_outlined,
            label: 'Buyer',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRoleCard(
            role: UserRole.admin,
            icon: Icons.person_outline,
            label: 'Admin',
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedRole == role;
    final activeBg = const Color(0xFF264C34);
    final activeFg = Colors.white;
    final inactiveBg = Colors.white;
    final inactiveBorder = const Color(0xFFE5E9E0);
    final inactiveFg = const Color(0xFF2A5239); // Dark green icon for inactive
    final inactiveLabel = const Color(0xFF5A7A66);

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: inactiveBorder),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withAlpha(20) : const Color(0xFFE9F0EC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? activeFg : inactiveFg,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? activeFg : inactiveLabel,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8DC099),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF142B1B), // Very dark green/black
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: () {
          if (_isLoading) return;
          _handleLogin();
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedRole == UserRole.farmer
                            ? 'Sign in as Farmer'
                            : _selectedRole == UserRole.buyer
                                ? 'Sign in as Buyer'
                                : 'Sign in as Admin',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, size: 16),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        const Text(
          "New here? ",
          style: TextStyle(color: Color(0xFF8F9F94), fontSize: 14),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const SignUpScreen(),
                transitionsBuilder:
                    (context, anim, secondaryAnimation, child) {
                  return FadeTransition(opacity: anim, child: child);
                },
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Create an account',
            style: TextStyle(
              color: Color(0xFF336345),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40); // Start from top left, go down
    
    // Wave down then up softly
    path.cubicTo(
      size.width * 0.35, size.height, // Control point 1
      size.width * 0.65, size.height - 60, // Control point 2
      size.width, size.height - 20 // End point
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
