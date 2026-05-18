import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../farmer/farmer_profile_screen_v2.dart';
import '../features/agrisense_dss_screen.dart';
import '../features/agri_financial_dss_screen.dart';
import '../features/agri_financial_model_screen.dart';
import '../farmer/agrisense_farmer_registration_screen.dart';
import '../features/rentals_screen.dart';
import '../features/reports_screen.dart';
import '../saturation/saturation_meter_screen.dart';
import '../saturation/saturation_heatmap_screen.dart';
import '../farmer/agrisense_farm_registry_screen.dart';
import '../farmer/agrisense_seasonal_crop_submission_screen.dart';
import '../farmer/my_market_screen.dart';

class FarmerDashboardScreen extends StatelessWidget {
  const FarmerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Here\'s your farm management dashboard',
          style: TextStyle(
            color: AppTheme.textMedium,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle_rounded,
              color: AppTheme.textMedium,
            ),
            tooltip: 'My Profile',
            onPressed: () => _navigateToFeature(context, 'My Profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textMedium),
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determine number of columns based on screen width
          int crossAxisCount;
          double horizontalPadding;
          double crossAxisSpacing;

          if (constraints.maxWidth < 600) {
            // Mobile: 1 column
            crossAxisCount = 1;
            horizontalPadding = 12;
            crossAxisSpacing = 8;
          } else if (constraints.maxWidth < 1000) {
            // Tablet: 2 columns
            crossAxisCount = 2;
            horizontalPadding = 16;
            crossAxisSpacing = 12;
          } else {
            // Web/Desktop: 3 columns
            crossAxisCount = 3;
            horizontalPadding = 20;
            crossAxisSpacing = 16;
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            child: Column(
              children: [
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                  children: [
                    _buildFeatureCard(
                      icon: Icons.insights_rounded,
                      iconColor: const Color(0xFF00897B),
                      title: 'AgriSense DSS',
                      description:
                          'Analyze oversupply risk with OSI and crop alternatives',
                      buttonText: 'Open AgriSense',
                      onTap: () => _navigateToFeature(context, 'AgriSense DSS'),
                    ),
                    _buildFeatureCard(
                      icon: Icons.storefront_rounded,
                      iconColor: const Color(0xFF00A86B),
                      title: 'My Market',
                      description:
                          'View market endorsements linked to your plantings',
                      buttonText: 'Open Market',
                      onTap: () => _navigateToFeature(context, 'My Market'),
                    ),
                    _buildFeatureCard(
                      icon: Icons.person_rounded,
                      iconColor: const Color(0xFF1B7737),
                      title: 'My Profile',
                      description:
                          'Complete your personal and AgriSense farmer profile to register farms and access DSS modules.',
                      buttonText: 'View Profile',
                      onTap: () => _navigateToFeature(context, 'My Profile'),
                    ),
                    _buildFeatureCard(
                      icon: Icons.landscape,
                      iconColor: const Color(0xFF388E3C),
                      title: 'AgriSense Farm Registry',
                      description: 'Register your farm parcels and map farm boundaries. Complete your profile first.',
                      buttonText: 'Open Farm Registry',
                      onTap: () => _navigateToFeature(context, 'AgriSense Farm Registry'),
                    ),
                    _buildFeatureCard(
                      icon: Icons.grass,
                      iconColor: const Color(0xFF4CAF50),
                      title: 'Predictive Planting',
                      description: 'Submit your crop schedule for saturation validation.',
                      buttonText: 'Crop Schedule',
                      onTap: () => _navigateToFeature(context, 'AgriSense Seasonal Crops'),
                    ),
                    _buildFeatureCard(
                      icon: Icons.map_rounded,
                      iconColor: const Color(0xFF16A34A),
                      title: 'SRS Heat Map',
                      description: 'View barangay-level crop saturation risk scores on a live map.',
                      buttonText: 'View Heat Map',
                      onTap: () => _navigateToFeature(context, 'SRS Heat Map'),
                    ),
                    _buildFeatureCard(
                      icon: Icons.support_agent_rounded,
                      iconColor: const Color(0xFFFF9800),
                      title: 'Support',
                      description: 'Get help from our support team.',
                      buttonText: 'Contact Support',
                      onTap: () => _navigateToFeature(context, 'Support'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF999999),
                    height: 1.3,
                  ),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B5FFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToFeature(BuildContext context, String featureName) {
    if (featureName == 'AgriSense Registration') {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AgrisenseFarmerRegistrationScreen()));
    } else if (featureName == 'Saturation Meter') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SaturationMeterScreen()));
    } else if (featureName == 'Rentals') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const RentalsScreen()));
    } else if (featureName == 'Reports') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
    } else if (featureName == 'AgriSense Farm Registry') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AgrisenseFarmRegistryScreen()));
    } else if (featureName == 'AgriSense Seasonal Crops') {
      // NOTE: Using 'farm-123' as dummy. Ideally passed dynamically after registry
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AgrisenseSeasonalCropSubmissionScreen(farmId: 'farm-123')));
    } else if (featureName == 'AgriSense DSS') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AgriSenseDssScreen()));
    } else if (featureName == 'AgriFinancial Model') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AgriFinancialModelScreen()),
      );
    } else if (featureName == 'My Profile') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const FarmerProfileScreenV2()));
    } else if (featureName == 'Financial DSS') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AgriFinancialDssScreen()),
      );
    } else if (featureName == 'SRS Heat Map') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SaturationHeatmapScreen()),
      );
    } else if (featureName == 'My Market') {
      final user = Supabase.instance.client.auth.currentUser;
      final farmerId = user?.id ?? 'farmer-unknown';
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MyMarketScreen(farmerId: farmerId)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$featureName feature coming soon!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _logout(BuildContext context) async {
    try {
      // Sign out from Supabase
      await Supabase.instance.client.auth.signOut();

      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      // Still navigate to login even if error
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }
}
