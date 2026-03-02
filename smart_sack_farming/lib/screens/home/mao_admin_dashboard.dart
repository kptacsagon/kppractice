import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class MaoAdminDashboard extends StatefulWidget {
  const MaoAdminDashboard({super.key});

  @override
  State<MaoAdminDashboard> createState() => _MaoAdminDashboardState();
}

class _MaoAdminDashboardState extends State<MaoAdminDashboard> {
  bool _isLoading = true;

  // Summary counts
  int _totalCalamities = 0;
  double _totalYieldKg = 0;
  int _totalProjects = 0;
  int _totalEquipment = 0;
  int _totalFarmers = 0;

  // Chart data
  Map<String, int> _calamityByType = {};
  Map<String, double> _yieldByCrop = {};
  Map<String, int> _equipmentByCategory = {};
  List<_MonthlyData> _monthlyProduction = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;

      // Load all data in parallel
      final results = await Future.wait([
        client.from('calamity_reports').select(),
        client.from('production_reports').select(),
        client.from('farming_projects').select(),
        client.from('equipment').select(),
        client.from('profiles').select().eq('role', 'farmer'),
      ]);

      final calamities = results[0] as List;
      final productions = results[1] as List;
      final projects = results[2] as List;
      final equipment = results[3] as List;
      final farmers = results[4] as List;

      // Summary metrics
      _totalCalamities = calamities.length;
      _totalProjects = projects.length;
      _totalEquipment = equipment.length;
      _totalFarmers = farmers.length;

      // Total yield
      _totalYieldKg = 0;
      for (var p in productions) {
        _totalYieldKg += (p['yield_kg'] as num?)?.toDouble() ?? 0;
      }

      // Calamity by type
      _calamityByType = {};
      for (var c in calamities) {
        final type = c['calamity_type'] ?? 'Other';
        _calamityByType[type] = (_calamityByType[type] ?? 0) + 1;
      }

      // Yield by crop
      _yieldByCrop = {};
      for (var p in productions) {
        final crop = p['crop_type'] ?? 'Other';
        _yieldByCrop[crop] =
            (_yieldByCrop[crop] ?? 0) + ((p['yield_kg'] as num?)?.toDouble() ?? 0);
      }

      // Equipment by category
      _equipmentByCategory = {};
      for (var e in equipment) {
        final cat = e['category'] ?? 'Other';
        _equipmentByCategory[cat] = (_equipmentByCategory[cat] ?? 0) + 1;
      }

      // Monthly production (last 6 months)
      _monthlyProduction = _computeMonthlyProduction(productions);

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      setState(() => _isLoading = false);
    }
  }

  List<_MonthlyData> _computeMonthlyProduction(List productions) {
    final now = DateTime.now();
    final months = <_MonthlyData>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      double total = 0;
      for (var p in productions) {
        final dateStr = p['harvest_date'] ?? p['created_at'];
        if (dateStr == null) continue;
        final date = DateTime.tryParse(dateStr.toString());
        if (date != null && date.year == month.year && date.month == month.month) {
          total += (p['yield_kg'] as num?)?.toDouble() ?? 0;
        }
      }
      months.add(_MonthlyData(
        label: _monthAbbr(month.month),
        value: total,
      ));
    }
    return months;
  }

  String _monthAbbr(int m) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[(m - 1) % 12];
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00695C).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.agriculture_rounded,
                  color: Color(0xFF00695C), size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'MAO Dashboard',
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMedium),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textMedium),
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome banner
                        _buildWelcomeBanner(),
                        const SizedBox(height: 20),

                        // Summary cards
                        const Text('Overview',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark)),
                        const SizedBox(height: 12),
                        _buildSummaryCards(isWide),
                        const SizedBox(height: 24),

                        // Charts
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildCalamityBarChart()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildProductionLineChart()),
                            ],
                          )
                        else ...[
                          _buildCalamityBarChart(),
                          const SizedBox(height: 16),
                          _buildProductionLineChart(),
                        ],
                        const SizedBox(height: 16),

                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildYieldByCropChart()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildEquipmentPieChart()),
                            ],
                          )
                        else ...[
                          _buildYieldByCropChart(),
                          const SizedBox(height: 16),
                          _buildEquipmentPieChart(),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  // ─── Welcome Banner ────────────────────────────────────────────────────────

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00695C), Color(0xFF004D40)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Municipal Agriculture Office',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Monitor farmer activities, calamity reports, and production data across the municipality.',
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Summary Cards ─────────────────────────────────────────────────────────

  Widget _buildSummaryCards(bool isWide) {
    final cards = [
      _SummaryCardData('Calamities', _totalCalamities.toString(),
          Icons.warning_amber_rounded, const Color(0xFFE53935)),
      _SummaryCardData('Total Yield', '${(_totalYieldKg / 1000).toStringAsFixed(1)} t',
          Icons.grass_rounded, const Color(0xFF43A047)),
      _SummaryCardData('Projects', _totalProjects.toString(),
          Icons.folder_open_rounded, const Color(0xFF1E88E5)),
      _SummaryCardData('Equipment', _totalEquipment.toString(),
          Icons.handyman_rounded, const Color(0xFFF57C00)),
      _SummaryCardData('Farmers', _totalFarmers.toString(),
          Icons.people_rounded, const Color(0xFF7B1FA2)),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildSummaryCard(c),
                  ),
                ))
            .toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: cards.map(_buildSummaryCard).toList(),
    );
  }

  Widget _buildSummaryCard(_SummaryCardData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const Spacer(),
          Text(
            data.value,
            style: TextStyle(
              color: data.color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: const TextStyle(color: AppTheme.textMedium, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Calamity Bar Chart ────────────────────────────────────────────────────

  Widget _buildCalamityBarChart() {
    final entries = _calamityByType.entries.toList();
    if (entries.isEmpty) {
      return _buildChartCard(
        title: 'Calamity Reports by Type',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('No calamity data yet',
                style: TextStyle(color: AppTheme.textLight)),
          ),
        ),
      );
    }

    return _buildChartCard(
      title: 'Calamity Reports by Type',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (entries.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 2).toDouble(),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, gIdx, rod, rIdx) {
                  return BarTooltipItem(
                    '${entries[group.x.toInt()].key}\n${rod.toY.toInt()}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= entries.length) return const SizedBox();
                    final label = entries[idx].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        label.length > 6 ? '${label.substring(0, 6)}…' : label,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textMedium),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
                  ),
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppTheme.border,
                strokeWidth: 0.5,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: entries.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.value.toDouble(),
                    color: _calamityColor(entry.value.key),
                    width: 18,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Color _calamityColor(String type) {
    switch (type) {
      case 'Flood':     return const Color(0xFF42A5F5);
      case 'Storm':     return const Color(0xFF78909C);
      case 'Drought':   return const Color(0xFFFFCA28);
      case 'Pest Infestation': return const Color(0xFF66BB6A);
      case 'Disease Outbreak': return const Color(0xFFEF5350);
      case 'Fire':      return const Color(0xFFFF7043);
      default:          return const Color(0xFF9E9E9E);
    }
  }

  // ─── Production Line Chart (monthly) ───────────────────────────────────────

  Widget _buildProductionLineChart() {
    if (_monthlyProduction.isEmpty || _monthlyProduction.every((m) => m.value == 0)) {
      return _buildChartCard(
        title: 'Monthly Production (Last 6 Months)',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('No production data yet',
                style: TextStyle(color: AppTheme.textLight)),
          ),
        ),
      );
    }

    final maxY = _monthlyProduction
        .map((m) => m.value)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return _buildChartCard(
      title: 'Monthly Production (Last 6 Months)',
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY * 1.2,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(0)} kg',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList(),
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= _monthlyProduction.length) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _monthlyProduction[idx].label,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textMedium),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value >= 1000
                        ? '${(value / 1000).toStringAsFixed(1)}k'
                        : value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
                  ),
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppTheme.border,
                strokeWidth: 0.5,
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: _monthlyProduction.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.value);
                }).toList(),
                isCurved: true,
                color: const Color(0xFF43A047),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF43A047).withAlpha(30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Yield by Crop Bar Chart ───────────────────────────────────────────────

  Widget _buildYieldByCropChart() {
    final entries = _yieldByCrop.entries.toList();
    if (entries.isEmpty) {
      return _buildChartCard(
        title: 'Production Yield by Crop',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('No crop yield data yet',
                style: TextStyle(color: AppTheme.textLight)),
          ),
        ),
      );
    }

    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final colors = [
      const Color(0xFF43A047),
      const Color(0xFF1E88E5),
      const Color(0xFFFDD835),
      const Color(0xFFFF7043),
      const Color(0xFF7B1FA2),
      const Color(0xFF00ACC1),
      const Color(0xFF8D6E63),
      const Color(0xFFEC407A),
    ];

    return _buildChartCard(
      title: 'Production Yield by Crop (kg)',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, gIdx, rod, rIdx) {
                  return BarTooltipItem(
                    '${entries[group.x.toInt()].key}\n${rod.toY.toStringAsFixed(0)} kg',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= entries.length) return const SizedBox();
                    final label = entries[idx].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        label.length > 8 ? '${label.substring(0, 8)}…' : label,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textMedium),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value >= 1000
                        ? '${(value / 1000).toStringAsFixed(1)}k'
                        : value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
                  ),
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppTheme.border,
                strokeWidth: 0.5,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: entries.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.value,
                    color: colors[entry.key % colors.length],
                    width: 20,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ─── Equipment Pie Chart ───────────────────────────────────────────────────

  Widget _buildEquipmentPieChart() {
    final entries = _equipmentByCategory.entries.toList();
    if (entries.isEmpty) {
      return _buildChartCard(
        title: 'Equipment by Category',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('No equipment data yet',
                style: TextStyle(color: AppTheme.textLight)),
          ),
        ),
      );
    }

    final total = entries.fold<int>(0, (s, e) => s + e.value);
    final colors = [
      const Color(0xFF42A5F5),
      const Color(0xFF66BB6A),
      const Color(0xFFFFCA28),
      const Color(0xFFEF5350),
      const Color(0xFF7E57C2),
      const Color(0xFFFF7043),
      const Color(0xFF26C6DA),
      const Color(0xFF8D6E63),
      const Color(0xFFEC407A),
    ];

    return _buildChartCard(
      title: 'Equipment by Category',
      child: SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: entries.asMap().entries.map((entry) {
                    final pct = (entry.value.value / total * 100).toStringAsFixed(1);
                    return PieChartSectionData(
                      color: colors[entry.key % colors.length],
                      value: entry.value.value.toDouble(),
                      title: '$pct%',
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      radius: 55,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entries.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colors[entry.key % colors.length],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${entry.value.key} (${entry.value.value})',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMedium,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Chart card wrapper ────────────────────────────────────────────────────

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    Supabase.instance.client.auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

// ─── Helper data classes ───────────────────────────────────────────────────

class _SummaryCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCardData(this.label, this.value, this.icon, this.color);
}

class _MonthlyData {
  final String label;
  final double value;
  const _MonthlyData({required this.label, required this.value});
}
