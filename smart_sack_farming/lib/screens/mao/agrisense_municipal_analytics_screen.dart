import 'package:flutter/material.dart';
import '../../services/saturation_broadcast_service.dart';
import '../../theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgrisenseMunicipalAnalyticsScreen extends StatefulWidget {
  const AgrisenseMunicipalAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AgrisenseMunicipalAnalyticsScreen> createState() => _AgrisenseMunicipalAnalyticsScreenState();
}

class _AgrisenseMunicipalAnalyticsScreenState extends State<AgrisenseMunicipalAnalyticsScreen> {
  final _broadcastService = SaturationBroadcastService();
  late Future<Map<String, dynamic>> _saturationAnalysis;
  bool _isBroadcasting = false;

  @override
  void initState() {
    super.initState();
    _saturationAnalysis = _broadcastService.getSaturationAnalysisForBroadcast();
  }

  Future<void> _broadcastSaturationAlert(Map<String, dynamic> analysis) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Get admin profile for name
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();

      final adminName = profile['full_name'] as String? ?? 'Administrator';

      setState(() => _isBroadcasting = true);

      final highSaturation =
          (analysis['high_saturation_crops'] as List?)?.cast<String>() ?? [];
      final mediumSaturation =
          (analysis['medium_saturation_crops'] as List?)?.cast<String>() ?? [];
      final lowSaturation =
          (analysis['low_saturation_crops'] as List?)?.cast<String>() ?? [];

      // Build description based on analysis
      final description =
          'Based on current soil saturation records across the municipality, '
          'farmers should be aware of the following conditions:\n\n'
          '• High Saturation Crops: ${highSaturation.join(', ').isEmpty ? 'None' : highSaturation.join(', ')}\n'
          '• Moderate Saturation Crops: ${mediumSaturation.join(', ').isEmpty ? 'None' : mediumSaturation.join(', ')}\n'
          '• Good Planting Crops: ${lowSaturation.join(', ').isEmpty ? 'None' : lowSaturation.join(', ')}\n\n'
          'Total records analyzed: ${analysis['total_records']} farmer fields';

      final recommendations =
          'For oversaturated crops (high saturation), consider:\n'
          '• Delaying planting until soil moisture decreases\n'
          '• Switching to water-tolerant crop varieties\n'
          '• Implementing improved drainage systems\n\n'
          'For crops with good saturation conditions:\n'
          '• These are ideal for planting now\n'
          '• Monitor weather forecasts for significant changes\n'
          '• Apply standard agronomic practices';

      await _broadcastService.broadcastSaturationAlert(
        adminName: adminName,
        municipality: 'Municipal',
        title: 'Saturation Alert: Crop Planting Recommendations',
        description: description,
        highSaturationCrops: highSaturation,
        mediumSaturationCrops: mediumSaturation,
        lowSaturationCrops: lowSaturation,
        recommendations: recommendations,
      );

      if (mounted) {
        setState(() => _isBroadcasting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Saturation alert broadcasted to all farmers'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBroadcasting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Demand & Intelligence'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      backgroundColor: AppTheme.background,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _saturationAnalysis,
        builder: (context, snapshot) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Commodity Saturation Analysis',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSaturationCard('Rice (Oryza sativa)', 500000, 350000,
                    'Critical', Colors.red),
                const SizedBox(height: 8),
                _buildSaturationCard('Corn (Zea mays)', 120000, 200000, 'Safe',
                    Colors.green),
                const SizedBox(height: 8),
                _buildSaturationCard('Cassava', 80000, 75000, 'Moderate',
                    Colors.yellow.shade800),
                const SizedBox(height: 32),
                const Text(
                  'Weather & Climate Advisories',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  color: Colors.blue.shade50,
                  child: const ListTile(
                    leading: Icon(Icons.water_drop, color: Colors.blue, size: 40),
                    title: Text('El Niño Warning Active',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'Drought conditions expected starting November. Recommend drought-resistant crops (e.g., Cassava, Sorghum).'),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Actionable Interventions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (snapshot.hasData)
                  ElevatedButton.icon(
                    onPressed: _isBroadcasting
                        ? null
                        : () => _broadcastSaturationAlert(snapshot.data!),
                    icon: _isBroadcasting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.textOnPrimary),
                            ),
                          )
                        : const Icon(Icons.campaign),
                    label: Text(_isBroadcasting
                        ? 'Broadcasting...'
                        : 'Broadcast Saturation Alert to Farmers'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.textOnPrimary,
                    ),
                  )
                else if (snapshot.hasError)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.error.withAlpha(40)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Error loading saturation data',
                            style: TextStyle(color: AppTheme.error),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaturationCard(String crop, double projectedYield, double projectedDemand, String riskLevel, Color alertColor) {
    double saturationPercentage = ((projectedYield - projectedDemand) / projectedDemand) * 100;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(crop, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(riskLevel, style: const TextStyle(color: Colors.white)),
                  backgroundColor: alertColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Projected Production: ${projectedYield.toStringAsFixed(0)} kg'),
            Text('Estimated Demand: ${projectedDemand.toStringAsFixed(0)} kg'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: projectedDemand == 0 ? 0 : (projectedYield / projectedDemand).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              color: alertColor,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              'Saturation Risk: ${saturationPercentage.toStringAsFixed(1)}%',
              style: TextStyle(color: alertColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
