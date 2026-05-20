import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' show min;

// ─── Color System ─────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0F2747);
const _kGreen = Color(0xFF1B7737);
const _kGold = Color(0xFFF59E0B);
const _kRed = Color(0xFFDC2626);
const _kBlue = Color(0xFF2563EB);
const _kTeal = Color(0xFF0891B2);
const _kOrange = Color(0xFFEA580C);
const _kBg = Color(0xFFF1F5F9);
const _kCard = Colors.white;
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kText = Color(0xFF0F172A);

// ─── Data Models ──────────────────────────────────────────────────────────────
class _CropData {
  final String crop;
  final double declaredKg;
  final double demandKg;
  final String status;
  final Color color;
  const _CropData(this.crop, this.declaredKg, this.demandKg, this.status, this.color);

  double get supplyRatio => declaredKg / (demandKg == 0 ? 1 : demandKg);
  double get gapKg => demandKg - declaredKg;
  String get statusLabel {
    if (status == 'oversupplied') return 'Oversupplied';
    if (status == 'moderate') return 'Moderate';
    return 'High Demand';
  }
  Color get statusColor {
    if (status == 'oversupplied') return _kRed;
    if (status == 'moderate') return _kGold;
    return _kGreen;
  }
  String get insight {
    if (status == 'oversupplied') {
      final pct = ((supplyRatio - 1) * 100).toStringAsFixed(0);
      return 'Supply is $pct% above demand. High price crash risk. Advise farmers to switch crops or find new buyers.';
    }
    if (status == 'moderate') {
      return 'Supply slightly exceeds demand. Monitor closely. Consider connecting to regional buyers.';
    }
    final covPct = (supplyRatio * 100).toStringAsFixed(0);
    return 'Only $covPct% of demand is covered. Strong market opportunity. Recommend to new farmers this season.';
  }
}

class _Rec {
  final String crop;
  final int score;
  final String reason;
  final int daysToMaturity;
  final double pricePerKg;
  final IconData icon;
  const _Rec(this.crop, this.score, this.reason, this.daysToMaturity, this.pricePerKg, this.icon);
}

class _Risk {
  final String crop;
  final int riskScore;
  final String reason;
  const _Risk(this.crop, this.riskScore, this.reason);
}

// ─── Widget ───────────────────────────────────────────────────────────────────
class CropIntelligenceScreen extends StatefulWidget {
  const CropIntelligenceScreen({super.key});

  @override
  State<CropIntelligenceScreen> createState() => _CropIntelligenceScreenState();
}

class _CropIntelligenceScreenState extends State<CropIntelligenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedBarangay = 'All Barangays';
  int _selectedMonthIndex = 0;

  static const _crops = [
    _CropData('Tomato', 4820, 2500, 'oversupplied', _kRed),
    _CropData('Pechay', 3200, 2000, 'oversupplied', _kRed),
    _CropData('Cabbage', 2800, 2400, 'moderate', _kGold),
    _CropData('Eggplant', 1500, 2800, 'high_demand', _kGreen),
    _CropData('Ampalaya', 1200, 2200, 'high_demand', _kGreen),
    _CropData('Onion', 800, 3500, 'high_demand', _kGreen),
  ];

  static const _recommendations = [
    _Rec('Onion', 92, 'Low supply vs high demand. Strong market opportunity.', 120, 95.0, Icons.bubble_chart_rounded),
    _Rec('Eggplant', 87, 'Consistent demand. Low competition in current season.', 75, 25.0, Icons.eco_rounded),
    _Rec('Ampalaya', 81, 'High institutional buyer demand. Good price trend.', 65, 38.0, Icons.spa_rounded),
    _Rec('Okra', 74, 'Fast-growing. Low input cost. Steady local market.', 55, 22.0, Icons.grass_rounded),
  ];

  static const _riskyCrops = [
    _Risk('Tomato', 89, 'Declared supply is 93% above market demand. Price crash risk.'),
    _Risk('Pechay', 60, 'Moderate oversupply. Consider reducing planting volume.'),
  ];

  static const _barangays = [
    'All Barangays', 'Agboy-o', 'Agta', 'Alibunan', 'Alegria', 'Alobo',
  ];

  static const _months = ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        title: const Text(
          'Crop Supply Intelligence Engine',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: _kGold,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF93C5FD),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Supply Overview'),
            Tab(text: 'Saturation Analysis'),
            Tab(text: 'Smart Recommendations'),
            Tab(text: 'Harvest Forecast'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSupplyOverview(),
          _buildSaturationAnalysis(),
          _buildSmartRecommendations(),
          _buildHarvestForecast(),
        ],
      ),
    );
  }

  // ─── Tab 1: Supply Overview ─────────────────────────────────────────────────
  Widget _buildSupplyOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _sectionCard(
            title: 'Declared Supply vs Market Demand',
            subtitle: 'Current season — all barangays combined',
            child: Column(
              children: [
                Row(children: [
                  _legendDot(_kGreen, 'Declared Supply'),
                  const SizedBox(width: 16),
                  _legendDot(const Color(0xFFCBD5E1), 'Market Demand'),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  child: BarChart(
                    BarChartData(
                      maxY: 6,
                      alignment: BarChartAlignment.spaceAround,
                      groupsSpace: 14,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFE2E8F0), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: 2,
                            getTitlesWidget: (v, _) => Text(
                              '${v.toInt()}T',
                              style: const TextStyle(fontSize: 10, color: _kMuted),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= _crops.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _crops[i].crop,
                                  style: const TextStyle(fontSize: 10, color: _kMuted),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(_crops.length, (i) {
                        final c = _crops[i];
                        return BarChartGroupData(
                          x: i,
                          barsSpace: 4,
                          barRods: [
                            BarChartRodData(
                              toY: c.declaredKg / 1000,
                              color: c.color,
                              width: 12,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: c.demandKg / 1000,
                              color: const Color(0xFFCBD5E1),
                              width: 12,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _sectionCard(
            title: 'Crop Supply Data Table',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('Crop', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  DataColumn(label: Text('Declared (kg)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  DataColumn(label: Text('Demand (kg)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  DataColumn(label: Text('Gap (kg)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                ],
                rows: _crops.map((c) {
                  final gap = c.gapKg;
                  return DataRow(cells: [
                    DataCell(Text(c.crop, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                    DataCell(Text(NumberFormat('#,###').format(c.declaredKg.toInt()), style: const TextStyle(fontSize: 12))),
                    DataCell(Text(NumberFormat('#,###').format(c.demandKg.toInt()), style: const TextStyle(fontSize: 12))),
                    DataCell(Text(
                      '${gap >= 0 ? '+' : ''}${NumberFormat('#,###').format(gap.toInt())}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: gap >= 0 ? _kGreen : _kRed),
                    )),
                    DataCell(_statusBadge(c.statusLabel, c.statusColor)),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 2: Saturation Analysis ─────────────────────────────────────────────
  Widget _buildSaturationAnalysis() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final cols = constraints.maxWidth >= 600 ? 3 : 2;
          return Column(
            children: [
              for (int row = 0; row * cols < _crops.length; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      min(cols, _crops.length - row * cols),
                      (col) {
                        final c = _crops[row * cols + col];
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: col < cols - 1 ? 12 : 0),
                            child: _saturationCard(c),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _saturationCard(_CropData c) {
    final ratio = (c.supplyRatio).clamp(0.0, 2.0);
    final barFill = (ratio / 2.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.statusColor.withAlpha(60)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.crop, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kText)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: c.statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(c.statusLabel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: c.statusColor)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Supply ratio:', style: TextStyle(fontSize: 10, color: _kMuted)),
              const SizedBox(width: 4),
              Text(
                '${(c.supplyRatio * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.statusColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: barFill,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(c.statusColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            c.insight,
            style: const TextStyle(fontSize: 10.5, color: _kMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ─── Tab 3: Smart Recommendations ──────────────────────────────────────────
  Widget _buildSmartRecommendations() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intro
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kBlue.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBlue.withAlpha(60)),
            ),
            child: const Text(
              'The recommendation engine analyzes current supply-demand gaps, market price trends, seasonal patterns, and soil suitability to suggest optimal crops for each barangay.',
              style: TextStyle(fontSize: 12, color: _kText, height: 1.5),
            ),
          ),
          const SizedBox(height: 14),

          // Barangay filter
          _sectionCard(
            title: 'Filter by Barangay',
            child: DropdownButtonFormField<String>(
              value: _selectedBarangay,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                isDense: true,
              ),
              items: _barangays.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _selectedBarangay = v ?? 'All Barangays'),
            ),
          ),

          // Recommended crops
          _sectionCard(
            title: 'Recommended Crops to Plant',
            subtitle: 'Based on supply-demand analysis for $_selectedBarangay',
            child: Column(
              children: _recommendations.map((rec) {
                final scoreColor = rec.score >= 80 ? _kGreen : rec.score >= 60 ? _kGold : _kRed;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scoreColor.withAlpha(8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scoreColor.withAlpha(50)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: scoreColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${rec.score}',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(rec.icon, size: 14, color: scoreColor),
                                const SizedBox(width: 4),
                                Text(rec.crop, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kText)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: scoreColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('${rec.score}/100', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: scoreColor)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(rec.reason, style: const TextStyle(fontSize: 11, color: _kMuted, height: 1.4)),
                            const SizedBox(height: 6),
                            Row(children: [
                              _infoBadge(Icons.schedule_rounded, '${rec.daysToMaturity} days', _kTeal),
                              const SizedBox(width: 8),
                              _infoBadge(Icons.attach_money_rounded, '₱${rec.pricePerKg.toStringAsFixed(0)}/kg', _kGreen),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Risky crops
          _sectionCard(
            title: 'Crops to Avoid This Season',
            child: Column(
              children: _riskyCrops.map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kRed.withAlpha(10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kRed.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.block_rounded, color: _kRed, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(r.crop, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kRed)),
                              const SizedBox(width: 6),
                              Text('Risk: ${r.riskScore}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kRed)),
                            ]),
                            const SizedBox(height: 2),
                            Text(r.reason, style: const TextStyle(fontSize: 11, color: _kMuted, height: 1.4)),
                          ],
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
    );
  }

  // ─── Tab 4: Harvest Forecast ────────────────────────────────────────────────
  Widget _buildHarvestForecast() {
    // harvest volume data per crop per month (tons)
    final tomatoData = [2.1, 3.5, 5.8, 4.2, 2.8, 1.5];
    final cabbageData = [1.8, 2.2, 3.1, 3.8, 2.5, 1.9];
    final eggplantData = [0.8, 1.2, 1.5, 1.8, 2.1, 1.6];

    // September (index 3) has all 3 crops at high volume — congestion risk
    final congestionMonths = {3}; // Sep

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month selector
          _sectionCard(
            title: 'Select Month',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_months.length, (i) {
                  final selected = i == _selectedMonthIndex;
                  final hasCongestion = congestionMonths.contains(i);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMonthIndex = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? _kNavy : hasCongestion ? _kOrange.withAlpha(20) : _kBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? _kNavy : hasCongestion ? _kOrange : _kBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _months[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : hasCongestion ? _kOrange : _kText,
                            ),
                          ),
                          if (hasCongestion)
                            const Text('⚠️', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Line chart
          _sectionCard(
            title: 'Harvest Volume Forecast (tons)',
            subtitle: 'Jun–Nov 2026 · All barangays',
            child: Column(
              children: [
                Row(children: [
                  _legendDot(_kRed, 'Tomato'),
                  const SizedBox(width: 12),
                  _legendDot(_kGold, 'Cabbage'),
                  const SizedBox(width: 12),
                  _legendDot(_kGreen, 'Eggplant'),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 7,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFE2E8F0), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 2,
                            getTitlesWidget: (v, _) => Text('${v.toInt()}T', style: const TextStyle(fontSize: 9, color: _kMuted)),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= _months.length) return const SizedBox.shrink();
                              return Text(_months[i], style: const TextStyle(fontSize: 10, color: _kMuted));
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        _lineBar(_kRed, tomatoData),
                        _lineBar(_kGold, cabbageData),
                        _lineBar(_kGreen, eggplantData),
                      ],
                      // highlight selected month with a vertical line
                      extraLinesData: ExtraLinesData(
                        verticalLines: [
                          VerticalLine(
                            x: _selectedMonthIndex.toDouble(),
                            color: _kNavy.withAlpha(60),
                            strokeWidth: 2,
                            dashArray: [4, 4],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Harvest schedule table for selected month
          _sectionCard(
            title: 'Harvest Schedule — ${_months[_selectedMonthIndex]} 2026',
            child: Column(
              children: [
                if (congestionMonths.contains(_selectedMonthIndex))
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kOrange.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kOrange.withAlpha(80)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: _kOrange, size: 16),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'HIGH CONGESTION RISK: Multiple crops peak simultaneously this month.',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kOrange),
                          ),
                        ),
                      ],
                    ),
                  ),
                _scheduleRow('Tomato', tomatoData[_selectedMonthIndex], 'Agboy-o, Agta',
                    _selectedMonthIndex == 2 ? 'HIGH' : 'MODERATE'),
                _scheduleRow('Cabbage', cabbageData[_selectedMonthIndex], 'Agta, Alibunan',
                    congestionMonths.contains(_selectedMonthIndex) ? 'HIGH' : 'LOW'),
                _scheduleRow('Eggplant', eggplantData[_selectedMonthIndex], 'Alegria, Alobo', 'LOW'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleRow(String crop, double tons, String barangay, String risk) {
    final riskColor = risk == 'HIGH' ? _kRed : risk == 'MODERATE' ? _kOrange : _kGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(crop, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kText)),
              Text(barangay, style: const TextStyle(fontSize: 10.5, color: _kMuted)),
            ]),
          ),
          Text(
            '${tons.toStringAsFixed(1)}T',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kText),
          ),
          const SizedBox(width: 10),
          _statusBadge(risk, riskColor),
        ],
      ),
    );
  }

  LineChartBarData _lineBar(Color color, List<double> data) {
    return LineChartBarData(
      spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withAlpha(15)),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionCard({required String title, String? subtitle, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _kText)),
                if (subtitle != null)
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: _kMuted)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10.5, color: _kMuted)),
      ],
    );
  }

  Widget _infoBadge(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
