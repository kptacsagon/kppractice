import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class SaturationHeatmapScreen extends StatefulWidget {
  const SaturationHeatmapScreen({super.key});

  @override
  State<SaturationHeatmapScreen> createState() => _SaturationHeatmapScreenState();
}

class _SaturationHeatmapScreenState extends State<SaturationHeatmapScreen> {
  late Future<Map<String, Map<String, dynamic>>> _heatmapData;
  String _selectedMetric = 'saturation'; // 'saturation' or 'moisture'
  String _selectedCrop = 'All';
  List<String> _availableCrops = ['All'];

  @override
  void initState() {
    super.initState();
    _heatmapData = _fetchHeatmapData();
  }

  Future<Map<String, Map<String, dynamic>>> _fetchHeatmapData() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Fetch saturation records
      final response = await supabase
          .from('saturation_records')
          .select('primary_crop, saturation_level, soil_moisture, field_size_ha')
          .order('created_at', ascending: false);

      // Group data by crop and saturation level
      final Map<String, Map<String, dynamic>> heatmap = {};
      final Set<String> crops = {};

      for (final record in response) {
        final crop = record['primary_crop'] as String? ?? 'Unknown';
        final saturation = record['saturation_level'] as String? ?? 'medium';
        final moisture = (record['soil_moisture'] as num?)?.toDouble() ?? 0.0;
        final fieldSize = (record['field_size_ha'] as num?)?.toDouble() ?? 0.0;

        crops.add(crop);

        if (!heatmap.containsKey(crop)) {
          heatmap[crop] = {
            'low_count': 0,
            'medium_count': 0,
            'high_count': 0,
            'avg_moisture': 0.0,
            'total_field_size': 0.0,
            'total_records': 0,
          };
        }

        // Count saturation levels
        if (saturation == 'low') {
          heatmap[crop]!['low_count']++;
        } else if (saturation == 'medium') {
          heatmap[crop]!['medium_count']++;
        } else if (saturation == 'high') {
          heatmap[crop]!['high_count']++;
        }

        // Calculate averages
        heatmap[crop]!['avg_moisture'] =
            ((heatmap[crop]!['avg_moisture'] as double) * heatmap[crop]!['total_records'] +
                moisture) /
            (heatmap[crop]!['total_records'] + 1);
        heatmap[crop]!['total_field_size'] += fieldSize;
        heatmap[crop]!['total_records']++;

        // Calculate saturation percentage
        final total = heatmap[crop]!['low_count'] +
            heatmap[crop]!['medium_count'] +
            heatmap[crop]!['high_count'];
        final saturationPercentage =
            ((heatmap[crop]!['medium_count'] + heatmap[crop]!['high_count']) /
                total *
                100);
        heatmap[crop]!['saturation_percentage'] = saturationPercentage;
      }

      setState(() {
        _availableCrops = ['All', ...crops.toList()..sort()];
      });

      return heatmap;
    } catch (e) {
      rethrow;
    }
  }

  Color _getSaturationColor(double percentage) {
    if (percentage <= 33) {
      return AppTheme.success; // Green for low saturation
    } else if (percentage <= 66) {
      return AppTheme.warning; // Yellow for medium saturation
    } else {
      return AppTheme.error; // Red for high saturation
    }
  }

  String _getSaturationLabel(double percentage) {
    if (percentage <= 33) {
      return 'Low';
    } else if (percentage <= 66) {
      return 'Medium';
    } else {
      return 'High';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saturation Heat Map',
          style: TextStyle(
            color: AppTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, Map<String, dynamic>>>(
        future: _heatmapData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading heat map',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              ),
            );
          }

          final heatmap = snapshot.data ?? {};

          if (heatmap.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: AppTheme.textLight),
                  const SizedBox(height: 16),
                  Text(
                    'No saturation data available',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          // Filter crops based on selection
          final filteredHeatmap = _selectedCrop == 'All'
              ? heatmap
              : {_selectedCrop: heatmap[_selectedCrop]!};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Legend
                _buildLegend(),
                const SizedBox(height: 20),

                // Metric selector
                _buildMetricSelector(),
                const SizedBox(height: 16),

                // Crop filter
                _buildCropFilter(heatmap.keys.toList()),
                const SizedBox(height: 20),

                // Heat map grid
                _buildHeatmapGrid(filteredHeatmap),
                const SizedBox(height: 20),

                // Statistics
                _buildStatistics(filteredHeatmap),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saturation Level',
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendItem('Low', AppTheme.success),
              const SizedBox(width: 24),
              _buildLegendItem('Medium', AppTheme.warning),
              const SizedBox(width: 24),
              _buildLegendItem('High', AppTheme.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMedium,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'View Metric',
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricButton('Saturation', 'saturation'),
              const SizedBox(width: 12),
              _buildMetricButton('Soil Moisture', 'moisture'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricButton(String label, String value) {
    final isSelected = _selectedMetric == value;
    return Expanded(
      child: Material(
        color: isSelected ? AppTheme.primary : AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _selectedMetric = value),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppTheme.textOnPrimary : AppTheme.textMedium,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCropFilter(List<String> crops) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Crop',
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _availableCrops.map((crop) {
                final isSelected = _selectedCrop == crop;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: isSelected ? AppTheme.primary : AppTheme.inputBackground,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCrop = crop),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          crop,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.textOnPrimary
                                : AppTheme.textMedium,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid(Map<String, Map<String, dynamic>> filteredHeatmap) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Crop Saturation Map',
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (filteredHeatmap.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No data available for selected crop',
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            Column(
              children: filteredHeatmap.entries.map((entry) {
                final cropName = entry.key;
                final data = entry.value;
                final saturationPercentage =
                    (data['saturation_percentage'] as double?) ?? 0.0;
                final color = _getSaturationColor(saturationPercentage);
                final label = _getSaturationLabel(saturationPercentage);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildHeatmapCell(
                    cropName,
                    saturationPercentage,
                    color,
                    label,
                    data,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeatmapCell(
    String cropName,
    double saturationPercentage,
    Color color,
    String label,
    Map<String, dynamic> data,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with crop name and level
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  cropName,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Saturation bar
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: saturationPercentage / 100,
                    minHeight: 8,
                    backgroundColor: AppTheme.inputBackground,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 8),

                // Details grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricTile(
                      'Saturation',
                      '${saturationPercentage.toStringAsFixed(1)}%',
                    ),
                    _buildMetricTile(
                      'Avg Moisture',
                      '${(data['avg_moisture'] as double?)?.toStringAsFixed(1) ?? '0'}%',
                    ),
                    _buildMetricTile(
                      'Records',
                      '${data['total_records']}',
                    ),
                    _buildMetricTile(
                      'Field Size',
                      '${(data['total_field_size'] as double?)?.toStringAsFixed(1) ?? '0'} ha',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(Map<String, Map<String, dynamic>> filteredHeatmap) {
    if (filteredHeatmap.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate overall statistics
    int totalRecords = 0;
    int lowCount = 0;
    int mediumCount = 0;
    int highCount = 0;
    double totalFieldSize = 0;
    double totalMoisture = 0;

    filteredHeatmap.forEach((crop, data) {
      totalRecords += (data['total_records'] as int? ?? 0);
      lowCount += (data['low_count'] as int? ?? 0);
      mediumCount += (data['medium_count'] as int? ?? 0);
      highCount += (data['high_count'] as int? ?? 0);
      totalFieldSize += (data['total_field_size'] as double? ?? 0);
      totalMoisture += (data['avg_moisture'] as double? ?? 0) *
          (data['total_records'] as int? ?? 0);
    });

    final avgMoisture = totalRecords > 0 ? totalMoisture / totalRecords : 0.0;
    final overallSaturation = totalRecords > 0
        ? (((mediumCount + highCount) / totalRecords * 100) as double)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Statistics',
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                'Total Records',
                '$totalRecords',
                Icons.library_books_rounded,
                AppTheme.primary,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Avg Saturation',
                '${overallSaturation.toStringAsFixed(1)}%',
                Icons.show_chart_rounded,
                _getSaturationColor(overallSaturation),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                'Total Field Area',
                '${totalFieldSize.toStringAsFixed(1)} ha',
                Icons.landscape_rounded,
                AppTheme.primary,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Avg Moisture',
                '${avgMoisture.toStringAsFixed(1)}%',
                Icons.water_drop_rounded,
                AppTheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
