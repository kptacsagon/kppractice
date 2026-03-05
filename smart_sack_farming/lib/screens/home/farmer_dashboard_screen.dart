import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../features/progressive_profit_loss_screen.dart';
import '../features/rentals_screen.dart';
import '../features/reports_screen.dart';
import '../features/weather_screen.dart';
import '../features/crop_recommendation_screen.dart';
import '../features/financial_forecast_screen.dart';
import '../features/agronomic_logbook_screen.dart';
import '../saturation/saturation_meter_screen.dart';

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
                  icon: Icons.opacity_rounded,
                  iconColor: const Color(0xFF00BCD4),
                  title: 'Saturation Meter',
                  description: 'Measure and monitor water availability saturation levels',
                  buttonText: 'Check Saturation',
                  onTap: () => _navigateToFeature(context, 'Saturation Meter'),
                ),
                _buildFeatureCard(
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFF2196F3),
                  title: 'Profit & Loss Calculator',
                  description: 'Calculate your farming profits and track financial performance',
                  buttonText: 'Calculate P&L',
                  onTap: () => _navigateToFeature(context, 'P&L Calculator'),
                ),
                _buildFeatureCard(
                  icon: Icons.two_wheeler_rounded,
                  iconColor: const Color(0xFF673AB7),
                  title: 'Rentals',
                  description: 'Browse and manage available farming equipment rentals',
                  buttonText: 'View Rentals',
                  onTap: () => _navigateToFeature(context, 'Rentals'),
                ),
                _buildFeatureCard(
                  icon: Icons.bar_chart_rounded,
                  iconColor: const Color(0xFF4CAF50),
                  title: 'Reports',
                  description: 'View your farm production reports',
                  buttonText: 'Generate Report',
                  onTap: () => _navigateToFeature(context, 'Reports'),
                ),
                _buildFeatureCard(
                  icon: Icons.cloud_outlined,
                  iconColor: const Color(0xFF2196F3),
                  title: 'Weather',
                  description: 'Check weather forecasts for your area',
                  buttonText: 'View Weather',
                  onTap: () => _navigateToFeature(context, 'Weather'),
                ),
                _buildFeatureCard(
                  icon: Icons.psychology_rounded,
                  iconColor: const Color(0xFF2E7D32),
                  title: 'Crop Recommendations',
                  description: 'AI-powered planting advice with suitability scores',
                  buttonText: 'Get Recommendations',
                  onTap: () => _navigateToFeature(context, 'Crop Recommendations'),
                ),
                _buildFeatureCard(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF7B1FA2),
                  title: 'Financial Forecast',
                  description: 'Simulate profit scenarios and compare crop returns',
                  buttonText: 'View Forecast',
                  onTap: () => _navigateToFeature(context, 'Financial Forecast'),
                ),
                _buildFeatureCard(
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFF5D4037),
                  title: 'Farm Logbook',
                  description: 'Record and track all agronomic events and activities',
                  buttonText: 'Open Logbook',
                  onTap: () => _navigateToFeature(context, 'Farm Logbook'),
                ),
                _buildFeatureCard(
                  icon: Icons.support_agent_rounded,
                  iconColor: const Color(0xFFFF9800),
                  title: 'Support',
                  description: 'Get help from our support team',
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
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
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
    if (featureName == 'Saturation Meter') {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => const SaturationMeterScreen()),
      );
    } else if (featureName == 'P&L Calculator') {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => const ProgressiveProfitLossCalculatorScreen()),
      );
    } else if (featureName == 'Rentals') {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => const RentalsScreen()),
      );
    } else if (featureName == 'Reports') {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => const ReportsScreen()),
      );
    } else if (featureName == 'Weather') {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => const WeatherScreen()),
      );
    } else if (featureName == 'Crop Recommendations') {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => const CropRecommendationScreen()),
      );
    } else if (featureName == 'Financial Forecast') {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => const FinancialForecastScreen()),
      );
    } else if (featureName == 'Farm Logbook') {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => const AgronomicLogbookScreen()),
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
      print('Logout error: $e');
      // Still navigate to login even if error
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }
}
