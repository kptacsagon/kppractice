import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

class AgrisenseMunicipalDashboardScreen extends StatefulWidget {
  const AgrisenseMunicipalDashboardScreen({super.key});

  @override
  State<AgrisenseMunicipalDashboardScreen> createState() => _AgrisenseMunicipalDashboardScreenState();
}

class _AgrisenseMunicipalDashboardScreenState extends State<AgrisenseMunicipalDashboardScreen> {
  late DateTime selectedDate;
  late MapController mapController;
  String selectedBarangay = '';

  // Mock data - replace with real Supabase queries
  final Map<String, dynamic> barangayData = {
    'Banilad': {'farmers': 245, 'saturation': 0.85, 'crops': ['Rice', 'Corn'], 'riskLevel': 'SAFE'},
    'Puso': {'farmers': 312, 'saturation': 1.45, 'crops': ['Rice', 'Tomato'], 'riskLevel': 'DANGER'},
    'Lahug': {'farmers': 189, 'saturation': 0.92, 'crops': ['Corn', 'Cabbage'], 'riskLevel': 'SAFE'},
    'Busay': {'farmers': 156, 'saturation': 1.25, 'crops': ['Rice', 'Okra'], 'riskLevel': 'CAUTION'},
  };

  final List<Map<String, dynamic>> cropBreakdown = [
    {'crop': 'Rice', 'farmers': 450, 'supply': 850000, 'demand': 700000, 'trend': 'up'},
    {'crop': 'Corn', 'farmers': 380, 'supply': 250000, 'demand': 320000, 'trend': 'down'},
    {'crop': 'Tomato', 'farmers': 220, 'supply': 180000, 'demand': 150000, 'trend': 'up'},
  ];

  final List<Map<String, dynamic>> riskTrends = [
    {'week': 'Week 1', 'risk': 65},
    {'week': 'Week 2', 'risk': 72},
    {'week': 'Week 3', 'risk': 68},
    {'week': 'Week 4', 'risk': 81},
  ];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    final isMobileLayout = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Municipal Agriculture Dashboard'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        backgroundColor: const Color(0xFF1B7737),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MAO Verification Header
            _buildMaoVerificationCard(),
            const SizedBox(height: 16),

            // Pending Verification Alert
            _buildPendingVerificationCard(),
            const SizedBox(height: 24),

            // Title & Date Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Forecasting Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                _buildDatePickerButton(),
              ],
            ),
            const SizedBox(height: 16),

            // Metric Cards (Interactive)
            Row(
              children: [
                Expanded(
                  child: _buildInteractiveMetricCard(
                    'Total Active Farms',
                    '1,245',
                    Icons.landscape,
                    const Color(0xFF2196F3),
                    () => _showCropBreakdownDialog(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInteractiveMetricCard(
                    'At-Risk Crops',
                    '3',
                    Icons.warning_amber_rounded,
                    Colors.orange,
                    () => _showRiskDetailsDialog(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Risk Trends
            _buildRiskTrendsSection(),
            const SizedBox(height: 24),

            // Barangay Heatmap with Interactive Features
            _buildEnhancedHeatmap(),
            const SizedBox(height: 24),

            // Selected Barangay Details
            if (selectedBarangay.isNotEmpty) _buildBarangayDetailsCard(),

            const SizedBox(height: 24),

            // Crop Risk Analysis
            _buildCropRiskAnalysis(),
          ],
        ),
      ),
    );
  }

  Widget _buildMaoVerificationCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B7737),
            const Color(0xFF2D9B4C),
            const Color(0xFF1B7737).withValues(alpha: 0.9)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B7737).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF2D9B4C).withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative background pattern
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -50,
              bottom: -50,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Icon with animation
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.security_rounded, color: Colors.white, size: 36),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Verified MAO Officer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade400,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cebu City Agriculture Office • Real-time Access',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '✓ 2 Farms Pending • ✓ Data Verified • ✓ Updates Today',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action arrow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingVerificationCard() {
    return GestureDetector(
      onTap: () {
        // Navigate to pending verification screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening pending farm verifications...')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade600,
              Colors.orange.shade500,
              Colors.amber.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Decorative background
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Icon badge
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.assignment_late_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '2 Farms Pending Verification',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Action Required',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Review and approve farm submissions to proceed',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Arrow indicator
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 18,
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

  Widget _buildDatePickerButton() {
    return TextButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 90)),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => selectedDate = picked);
        }
      },
      icon: const Icon(Icons.calendar_today),
      label: Text(DateFormat('MMM d').format(selectedDate)),
    );
  }

  Widget _buildInteractiveMetricCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B7737))),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              const SizedBox(height: 8),
              Text('Tap for details →', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskTrendsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Risk Trend (This Month)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(riskTrends.length, (i) {
                  final item = riskTrends[i];
                  final height = (item['risk'] as int).toDouble();
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: double.infinity,
                          height: height * 1.5,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_getRiskColor(height.toInt()).withValues(alpha: 0.7), _getRiskColor(height.toInt())],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(item['week'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                        Text('${item['risk']}%', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trend: ↑ +16% week-over-week', style: TextStyle(fontSize: 12, color: Colors.red[700], fontWeight: FontWeight.w600)),
                const Text('⚠️ High Alert', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeatmap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Barangay Saturation Heatmap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!, width: 1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(10.3157, 123.8854),
                    initialZoom: 12.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.smart_sack_farming',
                    ),
                    MarkerLayer(
                      markers: [
                        _buildBarangayMarker('Banilad', 10.3157, 123.8854),
                        _buildBarangayMarker('Puso', 10.3257, 123.8854),
                        _buildBarangayMarker('Lahug', 10.2957, 123.8654),
                        _buildBarangayMarker('Busay', 10.3057, 123.8754),
                      ],
                    ),
                  ],
                ),
                // Legend
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLegendItem(Colors.green, 'Safe (<0.8)'),
                        _buildLegendItem(Colors.orange, 'Caution (0.8-1.3)'),
                        _buildLegendItem(Colors.red, 'Danger (>1.3)'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('💡 Tap markers to view barangay details', style: TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Marker _buildBarangayMarker(String name, double lat, double lng) {
    final data = barangayData[name]!;
    final riskLevel = data['riskLevel'] as String;
    final saturation = data['saturation'] as double;
    final color = _getSaturationColor(saturation);

    return Marker(
      point: LatLng(lat, lng),
      width: 60,
      height: 60,
      child: GestureDetector(
        onTap: () => setState(() => selectedBarangay = name),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selectedBarangay == name ? Colors.white : Colors.white.withValues(alpha: 0.6),
              width: selectedBarangay == name ? 3 : 2,
            ),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text((data['farmers'] as int).toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                Text('farmers', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildBarangayDetailsCard() {
    final data = barangayData[selectedBarangay]!;
    final saturation = data['saturation'] as double;
    final riskLevel = data['riskLevel'] as String;

    return Card(
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getSaturationColor(saturation).withValues(alpha: 0.3), width: 2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$selectedBarangay Details', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(riskLevel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  backgroundColor: _getSaturationColor(saturation),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDetailStat('Farmers', '${data['farmers']}', Icons.people),
                _buildDetailStat('Saturation', '${(saturation * 100).toStringAsFixed(0)}%', Icons.trending_up),
                _buildDetailStat('Crops', '${(data['crops'] as List).length}', Icons.agriculture),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: List.generate(
                (data['crops'] as List).length,
                (i) => Chip(label: Text((data['crops'] as List)[i].toString())),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1B7737)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildCropRiskAnalysis() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Crop Risk Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...cropBreakdown.map((crop) => _buildCropRiskRow(crop)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCropRiskRow(Map<String, dynamic> crop) {
    final supply = crop['supply'] as int;
    final demand = crop['demand'] as int;
    final ratio = supply / demand;
    final trend = crop['trend'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(crop['crop'], style: const TextStyle(fontWeight: FontWeight.bold)),
              Chip(
                label: Text('${(ratio * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                backgroundColor: _getSaturationColor(ratio),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${crop['farmers']} farmers • Supply: ${crop['supply']} kg / Demand: ${crop['demand']} kg',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (ratio).clamp(0.0, 2.0) / 2.0,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getSaturationColor(ratio)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trend == 'up' ? '📈 Increasing saturation risk' : '📉 Decreasing saturation risk',
            style: TextStyle(fontSize: 11, color: trend == 'up' ? Colors.red : Colors.green, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showCropBreakdownDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crop Breakdown by Farmers'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: cropBreakdown.length,
            itemBuilder: (context, i) {
              final crop = cropBreakdown[i];
              return ListTile(
                title: Text(crop['crop']),
                subtitle: Text('${crop['farmers']} farmers planning'),
                trailing: Chip(label: Text('${crop['farmers']} 👨‍🌾')),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showRiskDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('At-Risk Crops Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            children: [
              _buildRiskDialogItem('Rice (Wet Season)', 'High Risk', Colors.red, '500k kg supply vs 350k demand'),
              _buildRiskDialogItem('Tomato (Summer)', 'Caution', Colors.orange, '180k kg supply vs 150k demand'),
              _buildRiskDialogItem('Okra (Dry Season)', 'Caution', Colors.orange, '95k kg supply vs 80k demand'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildRiskDialogItem(String crop, String risk, Color color, String details) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(crop, style: const TextStyle(fontWeight: FontWeight.bold)),
                Chip(label: Text(risk, style: const TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: color),
              ],
            ),
            const SizedBox(height: 4),
            Text(details, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Color _getSaturationColor(double saturation) {
    if (saturation < 0.8) return Colors.green;
    if (saturation <= 1.3) return Colors.orange;
    return Colors.red;
  }

  Color _getRiskColor(int riskScore) {
    if (riskScore < 40) return Colors.green;
    if (riskScore < 70) return Colors.orange;
    return Colors.red;
  }
}
