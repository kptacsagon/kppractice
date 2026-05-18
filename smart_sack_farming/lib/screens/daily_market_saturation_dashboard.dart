import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/daily_market_saturation_service.dart';

/// Example Widget: Daily Market Saturation Dashboard
/// Shows real-time market saturation based on daily purchases vs supply
class DailyMarketSaturationDashboard extends StatefulWidget {
  final String? municipality;

  const DailyMarketSaturationDashboard({
    Key? key,
    this.municipality,
  }) : super(key: key);

  @override
  State<DailyMarketSaturationDashboard> createState() =>
      _DailyMarketSaturationDashboardState();
}

class _DailyMarketSaturationDashboardState
    extends State<DailyMarketSaturationDashboard> {
  final DailyMarketSaturationService _service = DailyMarketSaturationService();
  late Future<List<DailySaturationStatus>> _saturationData;
  late Future<List<DailySaturationStatus>> _criticalAlerts;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _saturationData = _service.getTodaySaturationStatus();
      _criticalAlerts = _service.getCriticalSaturationAlerts();
    });
  }

  Color _getColorForLevel(String level) {
    switch (level) {
      case 'CRITICALLY_SATURATED':
        return Colors.red[900]!;
      case 'SATURATED':
        return Colors.red[600]!;
      case 'BALANCED':
        return Colors.amber[600]!;
      case 'UNDERSUPPLIED':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getIconForLevel(String level) {
    switch (level) {
      case 'CRITICALLY_SATURATED':
        return Icons.warning;
      case 'SATURATED':
        return Icons.trending_down;
      case 'BALANCED':
        return Icons.trending_flat;
      case 'UNDERSUPPLIED':
        return Icons.trending_up;
      default:
        return Icons.info;
    }
  }

  String _getRecommendation(String level) {
    switch (level) {
      case 'CRITICALLY_SATURATED':
        return '❌ DO NOT PLANT - Severe oversupply expected';
      case 'SATURATED':
        return '⚠️ AVOID - Market is oversupplied';
      case 'BALANCED':
        return '✅ SAFE - Market is balanced';
      case 'UNDERSUPPLIED':
        return '🚀 RECOMMENDED - High demand expected';
      default:
        return 'No recommendation';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Saturation Status'),
        subtitle: Text(
          'Based on daily purchases: ${DateFormat('MMM dd, yyyy').format(DateTime.now().subtract(Duration(days: 1)))}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: (_) => Future.wait([
          _saturationData,
          _criticalAlerts,
        ]),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Critical Alerts Section
            _buildCriticalAlertsSection(),
            const SizedBox(height: 24),

            // Saturation Status Section
            _buildSaturationStatusSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalAlertsSection() {
    return FutureBuilder<List<DailySaturationStatus>>(
      future: _criticalAlerts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Error loading alerts: ${snapshot.error}',
              style: TextStyle(color: Colors.red[900]),
            ),
          );
        }

        final alerts = snapshot.data ?? [];

        if (alerts.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'No Critical Alerts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'No crops with critical oversupply detected',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔴 CRITICAL ALERTS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            ...alerts.map((alert) => _buildAlertCard(alert)),
          ],
        );
      },
    );
  }

  Widget _buildAlertCard(DailySaturationStatus alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${alert.cropType} in ${alert.municipality}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Supply is ${alert.saturationRatio.toStringAsFixed(0)}% of demand',
            style: const TextStyle(fontSize: 12, color: Colors.red),
          ),
          const SizedBox(height: 4),
          Text(
            '${alert.getSaturationMessage()}',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSaturationStatusSection() {
    return FutureBuilder<List<DailySaturationStatus>>(
      future: _saturationData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Error loading saturation data: ${snapshot.error}',
              style: TextStyle(color: Colors.red[900]),
            ),
          );
        }

        final statuses = snapshot.data ?? [];
        final filtered = widget.municipality != null
            ? statuses
                .where((s) => s.municipality == widget.municipality)
                .toList()
            : statuses;

        if (filtered.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No saturation data available for the selected municipality.',
              ),
            ),
          );
        }

        // Group by crop type
        final Map<String, List<DailySaturationStatus>> groupedByCrop = {};
        for (final status in filtered) {
          groupedByCrop.putIfAbsent(status.cropType, () => []).add(status);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crop Saturation Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...groupedByCrop.entries.map((entry) {
              final cropType = entry.key;
              final statuses = entry.value;

              // Use the first status for display (or aggregate if needed)
              final primaryStatus = statuses.first;

              return _buildCropCard(cropType, primaryStatus, statuses);
            }),
          ],
        );
      },
    );
  }

  Widget _buildCropCard(
    String cropType,
    DailySaturationStatus primaryStatus,
    List<DailySaturationStatus> allStatuses,
  ) {
    final color = _getColorForLevel(primaryStatus.saturationLevel);
    final icon = _getIconForLevel(primaryStatus.saturationLevel);
    final recommendation = _getRecommendation(primaryStatus.saturationLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          cropType,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          primaryStatus.saturationLevel.replaceAll('_', ' '),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDataRow(
                  'Daily Demand',
                  '${primaryStatus.dailyDemandKg.toStringAsFixed(2)} kg',
                  subtitle: 'Actual market purchases',
                ),
                const SizedBox(height: 8),
                _buildDataRow(
                  'Daily Supply',
                  '${primaryStatus.dailySupplyKg.toStringAsFixed(2)} kg',
                  subtitle: 'Available from farms',
                ),
                const SizedBox(height: 8),
                _buildDataRow(
                  'Supply/Demand Ratio',
                  '${primaryStatus.saturationRatio.toStringAsFixed(1)}%',
                  subtitle: '> 100% means oversupply',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recommendation:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              recommendation,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (allStatuses.length > 1) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'By Municipality:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...allStatuses.map((status) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            status.municipality,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getColorForLevel(status.saturationLevel)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${status.saturationRatio.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color:
                                  _getColorForLevel(status.saturationLevel),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(
    String label,
    String value, {
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }
}
