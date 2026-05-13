import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../config/supabase_config.dart';
import 'login_screen.dart';

enum UserRole { farmer, admin, buyer }

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0; // 0 = Details, 1 = Password
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
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
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    if (_currentStep == 0) {
      // Validate details form
      if (_fullNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your full name')),
        );
        return;
      }
      if (_emailController.text.trim().isEmpty ||
          !_emailController.text.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email')),
        );
        return;
      }
      setState(() => _currentStep = 1);
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      _navigateToLogin();
    }
  }

  Future<void> _handleSignUp() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password')),
      );
      return;
    }
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to Terms & Conditions')),
      );
      return;
    }

    if (!supabaseConfigLooksValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supabase configuration is invalid.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': 'farmer',
        },
      );

      if (!mounted) return;

      if (response.user != null) {
        // Create profile
        try {
          await Supabase.instance.client.from('profiles').insert({
            'id': response.user!.id,
            'email': _emailController.text.trim(),
            'full_name': _fullNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'role': 'farmer',
          });
        } catch (e) {
          print('Profile creation note: $e');
        }

        setState(() => _isLoading = false);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Account created! Please sign in.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        _navigateToLogin();
      }
    } on AuthException catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign up failed: ${e.message}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, anim, secondaryAnimation, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
              height: size.height * 0.32,
              child: ClipPath(
                clipper: TopWaveClipper(),
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
            ),
            // Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        // Back Button and Progress
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _goToPreviousStep,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(90),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.arrow_back_ios_new,
                                        size: 16, color: Color(0xFF285437)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Sign in',
                                      style: TextStyle(
                                        color: Color(0xFF285437),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Progress Dots
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildProgressDot(0),
                                const SizedBox(width: 12),
                                _buildProgressDot(1),
                                const SizedBox(width: 12),
                                _buildProgressDot(2),
                              ],
                            ),
                            const SizedBox(width: 80),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // Step Content
                        _buildStepContent(),
                      ],
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

  Widget _buildProgressDot(int step) {
    final isCompleted = step < _currentStep;
    final isActive = step == _currentStep;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 36 : 28,
      height: 28,
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF5FB87B)
            : isActive
                ? const Color(0xFFC49A50)
                : const Color(0xFFD0D7CE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF8F9F94),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_currentStep == 0) {
      return _buildDetailsStep();
    } else {
      return _buildPasswordStep();
    }
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your details',
          style: TextStyle(
            color: Color(0xFF142B1B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tell us a bit about you',
          style: TextStyle(
            color: Color(0xFF5D846D),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        // Full Name
        TextFormField(
          controller: _fullNameController,
          style: const TextStyle(
            color: AppTheme.textDark,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: 'Full name',
            hintStyle: const TextStyle(color: Color(0xFF8F9F94)),
            fillColor: Colors.white,
            filled: true,
            prefixIcon:
                const Icon(Icons.person_outline, size: 22, color: Color(0xFF7E9786)),
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
        ),
        const SizedBox(height: 16),
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
            prefixIcon:
                const Icon(Icons.mail_outline, size: 22, color: Color(0xFF7E9786)),
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
        ),
        const SizedBox(height: 20),
        const Text(
          'Phone (optional)',
          style: TextStyle(
            color: Color(0xFF5D846D),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        // Phone Number
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            color: AppTheme.textDark,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: '+63 — Phone number',
            hintStyle: const TextStyle(color: Color(0xFF8F9F94)),
            fillColor: Colors.white,
            filled: true,
            prefixIcon:
                const Icon(Icons.phone_outlined, size: 22, color: Color(0xFF7E9786)),
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
        ),
        const SizedBox(height: 40),
        // Next Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF142B1B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: _goToNextStep,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next — Set password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Sign In Link
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(color: Color(0xFF8F9F94), fontSize: 14),
              ),
              TextButton(
                onPressed: _navigateToLogin,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Sign in',
                  style: TextStyle(
                    color: Color(0xFF336345),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Secure your account',
          style: TextStyle(
            color: Color(0xFF142B1B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Almost there — set a password',
          style: TextStyle(
            color: Color(0xFF5D846D),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
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
            prefixIcon:
                const Icon(Icons.lock_outline, size: 22, color: Color(0xFF7E9786)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF7E9786),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
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
        ),
        const SizedBox(height: 16),
        // Confirm Password
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: const TextStyle(
            color: AppTheme.textDark,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: 'Confirm password',
            hintStyle: const TextStyle(color: Color(0xFF8F9F94)),
            fillColor: Colors.white,
            filled: true,
            prefixIcon:
                const Icon(Icons.lock_outline, size: 22, color: Color(0xFF7E9786)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF7E9786),
              ),
              onPressed: () =>
                  setState(() =>
                      _obscureConfirmPassword = !_obscureConfirmPassword),
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
        ),
        const SizedBox(height: 24),
        // Terms Agreement
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (v) =>
                    setState(() => _agreedToTerms = v ?? false),
                activeColor: const Color(0xFF285437),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: const BorderSide(color: Color(0xFFC0CEC3), width: 1.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'I agree to the ',
                      style: TextStyle(
                        color: Color(0xFF5D846D),
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: const TextStyle(
                        color: Color(0xFF285437),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(
                      text: ' and ',
                      style: TextStyle(
                        color: Color(0xFF5D846D),
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: Color(0xFF285437),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(
                      text: ' of SmartSack Farm',
                      style: TextStyle(
                        color: Color(0xFF5D846D),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Create Account Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLoading ? const Color(0xFF7A8E7D) : const Color(0xFF142B1B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: _isLoading ? null : _handleSignUp,
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Sign In Link
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(color: Color(0xFF8F9F94), fontSize: 14),
              ),
              TextButton(
                onPressed: _navigateToLogin,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Sign in',
                  style: TextStyle(
                    color: Color(0xFF336345),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
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
    path.lineTo(0, size.height - 40);

    path.cubicTo(
      size.width * 0.35,
      size.height,
      size.width * 0.65,
      size.height - 60,
      size.width,
      size.height - 20,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
