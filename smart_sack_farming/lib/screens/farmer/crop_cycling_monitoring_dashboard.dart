// This file is deprecated - use crop_cycling_monitoring_simple.dart instead
import 'package:flutter/material.dart';

class CropCyclingMonitoringDashboard extends StatelessWidget {
  final String? farmerId;
  
  const CropCyclingMonitoringDashboard({
    this.farmerId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Use CropCyclingMonitoringSimple instead'),
      ),
    );
  }
}

  @override
  State<CropCyclingMonitoringDashboard> createState() =>
      _CropCyclingMonitoringDashboardState();
}

class _CropCyclingMonitoringDashboardState
    extends State<CropCyclingMonitoringDashboard> {
  final _service = CropCyclingMonitoringService();
  
  late String _farmerId;
  late Future<List<FarmerField>> _fieldsFuture;
  FarmerField? _selectedField;
  late Future<List<CropRotationHistory>> _rotationHistoryFuture;
  late Future<List<CropCyclingAlert>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    // Get farmerId from parameter or from current user
    _farmerId = widget.farmerId ?? Supabase.instance.client.auth.currentUser?.id ?? 'unknown';
    _fieldsFuture = _service.getFarmerFields(_farmerId);
    _rotationHistoryFuture = Future.value([]);
    _alertsFuture = _service.getFarmerAlerts(_farmerId);
  }

  void _selectField(FarmerField field) {
    setState(() {
      _selectedField = field;
      _rotationHistoryFuture = _service.getFieldRotationHistory(field.id);
    });
  }

  void _refreshData() {
    setState(() {
      _fieldsFuture = _service.getFarmerFields(_farmerId);
      if (_selectedField != null) {
        _rotationHistoryFuture = _service.getFieldRotationHistory(_selectedField!.id);
      }
      _alertsFuture = _service.getFarmerAlerts(_farmerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Cycling Monitor'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Alert Banner Section
            FutureBuilder<List<CropCyclingAlert>>(
              future: _alertsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                final criticalAlerts = snapshot.data
                        ?.where((a) => a.severity == 'critical' && !a.isRead)
                        .toList() ??
                    [];

                if (criticalAlerts.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  color: Colors.red[900],
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            '${criticalAlerts.length} Critical Alert${criticalAlerts.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...criticalAlerts.take(2).map((alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${alert.alertTitle}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )),
                    ],
                  ),
                );
              },
            ),

            // Field Selection
            _buildFieldSelector(),

            if (_selectedField != null) ...[
              const SizedBox(height: 16),
              _buildFieldOverview(),
              const SizedBox(height: 16),
              _buildMonitoringData(),
              const SizedBox(height: 16),
              _buildRotationHistory(),
              const SizedBox(height: 16),
              _buildRecommendations(),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // FIELD SELECTOR
  // ============================================================================

  Widget _buildFieldSelector() {
    return FutureBuilder<List<FarmerField>>(
      future: _fieldsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        final fields = snapshot.data ?? [];
        if (fields.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('No fields found. Add a field to get started.'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to add field screen
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Field'),
                ),
              ],
            ),
          );
        }

        if (_selectedField == null) {
          _selectField(fields.first);
        }

        return Container(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fields
                .map((field) => FilterChip(
                      selected: _selectedField?.id == field.id,
                      label: Text(field.fieldName),
                      onSelected: (_) => _selectField(field),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  // ============================================================================
  // FIELD OVERVIEW
  // ============================================================================

  Widget _buildFieldOverview() {
    if (_selectedField == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedField!.fieldName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildFieldInfoRow('📍 Location', _selectedField!.locationMunicipality),
              _buildFieldInfoRow('🌾 Area', '${_selectedField!.areaHectares} hectares'),
              _buildFieldInfoRow('🧪 Soil Type', _selectedField!.soilType),
              if (_selectedField!.soilPh != null)
                _buildFieldInfoRow('📊 Soil pH', _selectedField!.soilPh!.toStringAsFixed(2)),
              if (_selectedField!.irrigationType != null)
                _buildFieldInfoRow('💧 Irrigation', _selectedField!.irrigationType!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MONITORING DATA
  // ============================================================================

  Widget _buildMonitoringData() {
    if (_selectedField == null) return const SizedBox.shrink();

    return FutureBuilder<CropCyclingMonitoring?>(
      future: _service.getFieldMonitoring(_selectedField!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        final monitoring = snapshot.data;
        if (monitoring == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No monitoring data available. Add crops to your rotation history.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Risk Assessment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildRiskCard(
                      'Soil Fatigue',
                      monitoring.soilFatigueRisk,
                      Icons.grain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRiskCard(
                      'Disease Pressure',
                      monitoring.diseasePressureLevel,
                      Icons.bug_report,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRiskCard(
                      'Pest Pressure',
                      monitoring.pestPressureLevel,
                      Icons.pest_control,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: _getMonocultureRiskColor(monitoring.monocultureRiskScore),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monoculture Risk',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${monitoring.monocultureRiskScore.toStringAsFixed(0)}/100',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            monitoring.urgencyLevel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: monitoring.monocultureRiskScore / 100,
                        color: Colors.white70,
                        backgroundColor: Colors.white.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (monitoring.recommendedAction != null)
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_outline, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Recommended Action',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(monitoring.recommendedAction!),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskCard(String label, String level, IconData icon) {
    final color = _getRiskColor(level);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              level.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return Colors.red[900]!;
      case 'high':
        return Colors.red[600]!;
      case 'medium':
        return Colors.amber[600]!;
      default:
        return Colors.green[600]!;
    }
  }

  Color _getMonocultureRiskColor(double score) {
    if (score >= 75) return Colors.red[900]!;
    if (score >= 50) return Colors.orange[700]!;
    if (score >= 25) return Colors.amber[700]!;
    return Colors.green[700]!;
  }

  // ============================================================================
  // ROTATION HISTORY
  // ============================================================================

  Widget _buildRotationHistory() {
    if (_selectedField == null) return const SizedBox.shrink();

    return FutureBuilder<List<CropRotationHistory>>(
      future: _rotationHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'No crop history. Record your first crop to get started.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to record crop screen
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Record Crop'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rotation History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...history.map((record) => _buildRotationCard(record)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRotationCard(CropRotationHistory record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record.cropType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: record.isActive ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    record.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: record.isActive ? Colors.green[700] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildHistoryInfoRow(
              '📅 Planted',
              DateFormat('MMM d, y').format(record.plantingDate),
            ),
            if (record.harvestDate != null)
              _buildHistoryInfoRow(
                '✂️ Harvested',
                DateFormat('MMM d, y').format(record.harvestDate!),
              ),
            if (record.yieldKg != null)
              _buildHistoryInfoRow(
                '📊 Yield',
                '${record.yieldKg!.toStringAsFixed(0)} kg',
              ),
            if (record.diseaseObserved)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[700], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Disease observed: ${record.diseaseNotes ?? 'Not specified'}',
                          style: TextStyle(color: Colors.red[700], fontSize: 12),
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

  Widget _buildHistoryInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ============================================================================
  // RECOMMENDATIONS
  // ============================================================================

  Widget _buildRecommendations() {
    if (_selectedField == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommendations',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<RecommendedCropCycle>>(
            future: _service.getRecommendedCycles(_selectedField!.soilType),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              final cycles = snapshot.data ?? [];
              if (cycles.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No crop cycles recommended for ${_selectedField!.soilType} soil.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              }

              return Column(
                children: cycles
                    .map((cycle) => _buildRecommendationCard(cycle))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(RecommendedCropCycle cycle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cycle.cycleName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cycle: ${cycle.cropsInCycle.join(" → ")}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '${cycle.cycleDurationMonths} months',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (cycle.cycleDescription != null)
              Text(
                cycle.cycleDescription!,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            const SizedBox(height: 12),
            if (cycle.nitrogenFixation)
              Chip(
                label: const Text('Has nitrogen fixation'),
                backgroundColor: Colors.green[100],
                labelStyle: TextStyle(color: Colors.green[700]),
              ),
          ],
        ),
      ),
    );
  }
}
