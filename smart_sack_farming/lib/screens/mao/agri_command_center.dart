import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/crop_declaration_service.dart';
import '../../data/agrisat_real_data.dart';
import 'crop_intelligence_screen.dart';
import 'smart_crop_advisor_screen.dart';
import '../admin/agrisense_farm_verification_screen.dart';
import '../features/buyer_demand_board_screen.dart';
import '../features/agri_econ_frds_screen.dart';

// ─── Color System ─────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0F2747);
const _kGreen = Color(0xFF1B7737);
const _kGreenDark = Color(0xFF0D4A22);
const _kGold = Color(0xFFF59E0B);
const _kRed = Color(0xFFDC2626);
const _kBlue = Color(0xFF2563EB);
const _kTeal = Color(0xFF0891B2);
const _kOrange = Color(0xFFEA580C);
const _kPurple = Color(0xFF7C3AED);
const _kBg = Color(0xFFF1F5F9);
const _kCard = Colors.white;
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kText = Color(0xFF0F172A);

// ─── Data Models ──────────────────────────────────────────────────────────────
class _CropIntel {
  final String crop;
  final double declaredKg;
  final double demandKg;
  final String status;
  final Color color;
  const _CropIntel(this.crop, this.declaredKg, this.demandKg, this.status, this.color);
  String get statusLabel {
    if (status == 'oversupplied') return '🔴 Oversupplied';
    if (status == 'moderate') return '🟡 Moderate';
    return '🟢 High Demand';
  }
}

class _AlertModel {
  final String level;
  final String message;
  final IconData icon;
  final Color color;
  const _AlertModel(this.level, this.message, this.icon, this.color);
}

class _BarangayRank {
  final String name;
  final int farmers;
  final double hectares;
  final String topCrops;
  const _BarangayRank(this.name, this.farmers, this.hectares, this.topCrops);
}

class _PriceItem {
  final String crop;
  final double price;
  final double changePct;
  final String trend;
  const _PriceItem(this.crop, this.price, this.changePct, this.trend);
}

// ─── Widget ───────────────────────────────────────────────────────────────────
class AgriCommandCenter extends StatefulWidget {
  const AgriCommandCenter({super.key});

  @override
  State<AgriCommandCenter> createState() => _AgriCommandCenterState();
}

class _AgriCommandCenterState extends State<AgriCommandCenter> {
  final _declSvc = CropDeclarationService();
  bool _loading = true;
  int _totalFarmers = 0;
  int _totalDeclarations = 0;
  int _pendingValidation = 0;
  int _harvestThisMonth = 0;
  int _oversuppledCount = 3;
  int _highDemandCount = 3;

  // Real-data backed crop intel — Annual production MT (×1000 = kg) vs per-crop demand reference
  List<_CropIntel> get _cropIntel {
    final out = <_CropIntel>[];
    for (final key in kAgriSatCropKeys) {
      final totals = kAnnualTotals[key]!;
      final ppi = kPpiResults[key]!;
      String status;
      Color color;
      switch (ppi.alert) {
        case 'SEVERE':
        case 'SATURATION':
          status = 'oversupplied'; color = _kRed; break;
        case 'CAUTION':
          status = 'moderate'; color = _kGold; break;
        case 'HIGH_DEMAND':
          status = 'high_demand'; color = _kGreen; break;
        default:
          status = 'moderate'; color = _kGold;
      }
      final declaredMT = totals.productionMT;
      double demandMT;
      if (key == 'squash') {
        demandMT = 50;
      } else if (key == 'stringBeans') {
        demandMT = 60;
      } else if (key == 'ampalaya') {
        demandMT = 70;
      } else if (key == 'eggplant') {
        demandMT = 120;
      } else if (key == 'okra') {
        demandMT = 50;
      } else {
        demandMT = 50;
      }
      out.add(_CropIntel(
        kCropDisplayNames[key]!,
        declaredMT * 1000,
        demandMT * 1000,
        status,
        color,
      ));
    }
    return out;
  }

  // Real-data backed alerts from MAO system insights
  List<_AlertModel> get _alerts => kSystemInsights.map((insight) {
    final crop = kCropDisplayNames[insight.crop] ?? insight.crop;
    IconData icon;
    Color color;
    switch (insight.severity) {
      case 'CRITICAL':
        icon = Icons.warning_rounded; color = _kRed; break;
      case 'WARNING':
        icon = Icons.event_busy_rounded; color = _kOrange; break;
      case 'OPPORTUNITY':
        icon = Icons.trending_up_rounded; color = _kGreen; break;
      default:
        icon = Icons.info_rounded; color = _kBlue;
    }
    return _AlertModel(insight.severity, '$crop — ${insight.message}', icon, color);
  }).toList();

  static const _rankings = [
    _BarangayRank('Agboy-o', 45, 12.5, 'Tomato, Pechay'),
    _BarangayRank('Agta', 38, 9.8, 'Cabbage, Eggplant'),
    _BarangayRank('Alibunan', 32, 8.2, 'Ampalaya'),
    _BarangayRank('Alegria', 28, 7.1, 'Onion, Rice'),
    _BarangayRank('Alobo', 24, 6.3, 'Corn, Pechay'),
  ];

  // Real-data backed market prices (latest week prices from kWeeklyPrices)
  List<_PriceItem> get _prices => kAgriSatCropKeys.map((key) {
    final price = AgriSatData.getLatestPrice(key);
    final dir = AgriSatData.getPriceDirection(key);
    final change = AgriSatData.getWeekOverWeekChange(key);
    return _PriceItem(kCropDisplayNames[key]!, price, change, dir);
  }).toList();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final pending = await _declSvc.getPendingDeclarations();
      final validated = await _declSvc.getValidatedDeclarations();
      final farmersRes = await Supabase.instance.client
          .from('agrisense_farmer_profiles')
          .select('id');
      setState(() {
        _pendingValidation = pending.length;
        _totalDeclarations = pending.length + validated.length;
        _totalFarmers = (farmersRes as List).length;
        _harvestThisMonth = validated.where((d) {
          final now = DateTime.now();
          return d.expectedHarvestDate.month == now.month &&
              d.expectedHarvestDate.year == now.year;
        }).length;
      });
    } catch (_) {
      setState(() {
        _totalFarmers = 847;
        _totalDeclarations = 234;
        _pendingValidation = 18;
        _harvestThisMonth = 23;
      });
    } finally {
      // Compute real-data KPI counts from PPI results
      setState(() {
        _oversuppledCount = kPpiResults.values
            .where((p) => p.alert == 'SEVERE' || p.alert == 'SATURATION')
            .length;
        _highDemandCount = kPpiResults.values
            .where((p) => p.alert == 'HIGH_DEMAND')
            .length;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kGreen)),
      );
    }
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final wide = constraints.maxWidth >= 800;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildKpiStrip(wide),
                        const SizedBox(height: 14),
                        _buildSaturationStrip(),
                        const SizedBox(height: 14),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _buildLeftPanel(context)),
                              const SizedBox(width: 14),
                              Expanded(flex: 2, child: _buildRightPanel(context)),
                            ],
                          )
                        else
                          Column(children: [
                            _buildLeftPanel(context),
                            _buildRightPanel(context),
                          ]),
                        const SizedBox(height: 14),
                        _buildQuickNav(context),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kNavy, Color(0xFF1E3A5F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kGreen.withAlpha(60),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.agriculture_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agricultural Decision Support and Supply Monitoring System',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Municipality of Tubungan, Iloilo · ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                      style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {},
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: _kRed, shape: BoxShape.circle),
                      child: Text(
                        '${_alerts.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Color(0xFF93C5FD)),
                onPressed: () => Navigator.of(context).pop(),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── KPI Strip ──────────────────────────────────────────────────────────────
  Widget _buildKpiStrip(bool wide) {
    final kpis = [
      _kpiCard(Icons.people_rounded, '$_totalFarmers', 'Registered Farmers', _kGreen),
      _kpiCard(Icons.eco_rounded, '$_totalDeclarations', 'Crop Declarations', _kBlue),
      _kpiCard(Icons.warning_rounded, '$_oversuppledCount', 'Oversupplied Crops', _kRed),
      _kpiCard(Icons.trending_up_rounded, '$_highDemandCount', 'High Demand Crops', _kGold),
      _kpiCard(Icons.local_shipping_rounded, '$_harvestThisMonth', 'Harvests This Month', _kTeal),
      _kpiCard(Icons.pending_actions_rounded, '$_pendingValidation', 'Pending Validation', _kOrange),
    ];

    if (wide) {
      return Row(
        children: kpis
            .map((w) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 10), child: w)))
            .toList(),
      );
    }
    return Column(
      children: [
        Row(
          children: kpis
              .take(3)
              .map((w) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: w)))
              .toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: kpis
              .skip(3)
              .map((w) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: w)))
              .toList(),
        ),
      ],
    );
  }

  // ─── Saturation Strip ───────────────────────────────────────────────────────
  Widget _buildSaturationStrip() {
    return _card(
      title: 'Crop Saturation Monitor',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _cropIntel.map((crop) {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: crop.color.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: crop.color.withAlpha(80)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: crop.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${crop.crop} ${crop.statusLabel}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: crop.color),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Left Panel ─────────────────────────────────────────────────────────────
  Widget _buildLeftPanel(BuildContext context) {
    return Column(
      children: [
        // Supply vs Demand Bar Chart
        _card(
          title: 'Supply vs Demand Analysis',
          subtitle: 'Declared production vs market demand — current season',
          child: Column(
            children: [
              Row(children: [
                _legendDot(_kGreen, 'Declared Supply'),
                const SizedBox(width: 16),
                _legendDot(const Color(0xFFE2E8F0), 'Market Demand'),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    maxY: 120,
                    alignment: BarChartAlignment.spaceAround,
                    groupsSpace: 12,
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: Color(0xFFE2E8F0),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 30,
                          getTitlesWidget: (v, _) => Text(
                            '${v.toInt()}T',
                            style: const TextStyle(fontSize: 9, color: _kMuted),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= _cropIntel.length) return const SizedBox.shrink();
                            final name = _cropIntel[i].crop;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                name.length > 7 ? name.substring(0, 7) : name,
                                style: const TextStyle(fontSize: 9, color: _kMuted),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(_cropIntel.length, (i) {
                      final c = _cropIntel[i];
                      return BarChartGroupData(
                        x: i,
                        barsSpace: 3,
                        barRods: [
                          BarChartRodData(
                            toY: c.declaredKg / 1000,
                            color: c.color,
                            width: 10,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                          BarChartRodData(
                            toY: c.demandKg / 1000,
                            color: const Color(0xFFE2E8F0),
                            width: 10,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
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

        // Harvest Volume Forecast Line Chart — real Jul–Dec 2025 production data
        _card(
          title: 'Harvest Volume Forecast',
          subtitle: 'Squash (red) · Eggplant (green) · String Beans (gold) — Jul–Dec 2025 (MT)',
          child: Column(
            children: [
              Row(children: [
                _legendDot(_kRed, 'Squash'),
                const SizedBox(width: 12),
                _legendDot(_kGreen, 'Eggplant'),
                const SizedBox(width: 12),
                _legendDot(_kGold, 'String Beans'),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 20,
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: Color(0xFFE2E8F0),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: 5,
                          getTitlesWidget: (v, _) => Text(
                            v.toInt().toString(),
                            style: const TextStyle(fontSize: 9, color: _kMuted),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 20,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            // Months 6..11 → Jul..Dec
                            final monthIdx = i + 6;
                            if (monthIdx < 0 || monthIdx >= kMonthAbbreviations.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(kMonthAbbreviations[monthIdx],
                                style: const TextStyle(fontSize: 9, color: _kMuted));
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(6,
                            (i) => FlSpot(i.toDouble(), kHarvestData['squash']!.production[i + 6])),
                        isCurved: true,
                        color: _kRed,
                        barWidth: 2,
                        belowBarData: BarAreaData(show: true, color: _kRed.withAlpha(15)),
                        dotData: const FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: List.generate(6,
                            (i) => FlSpot(i.toDouble(), kHarvestData['eggplant']!.production[i + 6])),
                        isCurved: true,
                        color: _kGreen,
                        barWidth: 2,
                        belowBarData: BarAreaData(show: true, color: _kGreen.withAlpha(15)),
                        dotData: const FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: List.generate(6,
                            (i) => FlSpot(i.toDouble(), kHarvestData['stringBeans']!.production[i + 6])),
                        isCurved: true,
                        color: _kGold,
                        barWidth: 2,
                        belowBarData: BarAreaData(show: true, color: _kGold.withAlpha(15)),
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Right Panel ────────────────────────────────────────────────────────────
  Widget _buildRightPanel(BuildContext context) {
    return Column(
      children: [
        // Active Alerts
        _card(
          title: 'Active Alerts',
          action: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _kRed.withAlpha(20), borderRadius: BorderRadius.circular(10)),
            child: Text('${_alerts.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kRed)),
          ),
          child: Column(
            children: _alerts.map((alert) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: alert.color.withAlpha(12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: alert.color, width: 3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: alert.color, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        alert.level,
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.message,
                        style: const TextStyle(fontSize: 10.5, color: _kText, height: 1.4),
                      ),
                    ),
                    Icon(alert.icon, size: 14, color: alert.color),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // Top Producing Barangays
        _card(
          title: 'Top Producing Barangays',
          child: Column(
            children: List.generate(_rankings.length, (i) {
              final r = _rankings[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: i.isOdd ? const Color(0xFFF8FAFC) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: i == 0 ? _kGold.withAlpha(30) : _kMuted.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: i == 0 ? _kGold : _kMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kText)),
                          Text('${r.topCrops} · ${r.hectares} ha', style: const TextStyle(fontSize: 10, color: _kMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _kGreen.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        '${r.farmers} farmers',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kGreen),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),

        // Market Price Ticker
        _card(
          title: "Today's Market Prices",
          child: Column(
            children: _prices.map((p) {
              final isUp = p.trend == 'up';
              final isDown = p.trend == 'down';
              final trendColor = isUp ? _kGreen : isDown ? _kRed : _kMuted;
              final trendIcon = isUp ? Icons.arrow_upward_rounded : isDown ? Icons.arrow_downward_rounded : Icons.remove_rounded;
              final sign = p.changePct > 0 ? '+' : '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(p.crop, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kText)),
                    ),
                    Text(
                      '₱${p.price.toStringAsFixed(0)}/kg',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kText),
                    ),
                    const SizedBox(width: 8),
                    Icon(trendIcon, size: 12, color: trendColor),
                    Text(
                      '$sign${p.changePct.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: trendColor),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Quick Nav ──────────────────────────────────────────────────────────────
  Widget _buildQuickNav(BuildContext context) {
    final modules = [
      _QuickNavItem('Crop Intelligence', Icons.analytics_outlined, _kBlue, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CropIntelligenceScreen()));
      }),
      _QuickNavItem('Smart Advisor', Icons.tips_and_updates_rounded, _kGreen, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartCropAdvisorScreen()));
      }),
      _QuickNavItem('Harvest Forecast', Icons.calendar_today_rounded, _kTeal, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CropIntelligenceScreen()));
      }),
      _QuickNavItem('Buyer Demands', Icons.storefront_rounded, _kOrange, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyerDemandBoardScreen(maoMode: true)));
      }),
      _QuickNavItem('Farm Verification', Icons.fact_check_rounded, _kPurple, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AgrisenseFarmVerificationScreen()));
      }),
      _QuickNavItem('FRDS Analytics', Icons.account_tree_rounded, _kNavy, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AgriEconFrdsScreen()));
      }),
      _QuickNavItem('Farmers Directory', Icons.people_rounded, _kGreenDark, () {}),
      _QuickNavItem('Reports', Icons.description_rounded, _kMuted, () {}),
    ];

    return _card(
      title: 'Quick Access — All Modules',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: modules.map((m) => _quickNavCard(m)).toList(),
      ),
    );
  }

  Widget _quickNavCard(_QuickNavItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _kText, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────
  Widget _card({
    required String title,
    String? subtitle,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _kText)),
                      if (subtitle != null)
                        Text(subtitle, style: const TextStyle(fontSize: 11, color: _kMuted)),
                    ],
                  ),
                ),
                if (action != null) action,
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

  Widget _kpiCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, height: 1)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 10.5, color: _kMuted, height: 1.3)),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: _kMuted)),
      ],
    );
  }
}

// ─── Quick Nav Item helper ────────────────────────────────────────────────────
class _QuickNavItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickNavItem(this.label, this.icon, this.color, this.onTap);
}
