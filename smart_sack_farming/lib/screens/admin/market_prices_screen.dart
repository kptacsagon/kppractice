import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/agrisat_real_data.dart';

import '../features/financial_forecast_screen.dart';
import 'alerts_notifications_screen.dart';
import 'intervention_management_screen.dart';
import 'reports_analytics_screen.dart';
import '../features/supply_chain_dashboard_screen.dart';
import '../features/verification_workflow_screen.dart';
import '../home/mao_admin_dashboard.dart';
import 'farmer_management_screen.dart';
import 'supply_map_screen.dart';

class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFD6DAE1);
  static const Color _text = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF4B5563);
  static const Color _sidebarGreen = Color(0xFF2E7D32);

  bool _loading = true;
  String? _error;
  int _selectedNavIndex = 4;

  List<Map<String, dynamic>> _prices = [];

  List<_PriceRow> get _fallbackPrices => kAgriSatCropKeys.map((key) {
    final ppi = kPpiResults[key]!;
    final trend = ppi.latestPPI > 5 ? 'Rising' : ppi.latestPPI < -5 ? 'Falling' : 'Stable';
    final demand = ppi.alert == 'HIGH_DEMAND' ? 'High' : ppi.alert == 'SEVERE' ? 'Low' : 'Medium';
    final farmgate = (ppi.latestPrice * 0.62).roundToDouble();
    return _PriceRow(kCropDisplayNames[key]!, farmgate, ppi.latestPrice, trend, demand);
  }).toList();

  final List<_DemandPartner> _partners = const [
    _DemandPartner('School Feeding Programs', 25, 'Active'),
    _DemandPartner('Divisoria Market', 40, 'Active'),
    _DemandPartner('Supermarket Chains', 18, 'Pending'),
    _DemandPartner('Food Processors', 15, 'Active'),
    _DemandPartner('Institutional Buyers', 12, 'Negotiating'),
  ];

  List<_InfoBlock> get _opportunities => kSystemInsights.map((insight) {
    final crop = kCropDisplayNames[insight.crop] ?? insight.crop;
    Color bg, border, text;
    switch (insight.severity) {
      case 'OPPORTUNITY':
        bg = const Color(0xFFD9EEE1); border = const Color(0xFFB5DFC5); text = const Color(0xFF047857); break;
      case 'WARNING':
        bg = const Color(0xFFFEF3C7); border = const Color(0xFFFCD34D); text = const Color(0xFF92400E); break;
      case 'CRITICAL':
        bg = const Color(0xFFFEE2E2); border = const Color(0xFFFCA5A5); text = const Color(0xFFB91C1C); break;
      default:
        bg = const Color(0xFFF0FDF4); border = const Color(0xFFBBF7D0); text = const Color(0xFF166534);
    }
    return _InfoBlock(
      title: '$crop — ${insight.severity}',
      detail: insight.message,
      bg: bg, border: border, text: text,
    );
  }).toList();

  List<_InfoBlock> get _alerts => kSystemInsights
      .where((i) => i.severity == 'CRITICAL' || i.severity == 'WARNING')
      .map((insight) {
    final crop = kCropDisplayNames[insight.crop] ?? insight.crop;
    return _InfoBlock(
      title: '$crop — ${insight.severity}',
      detail: insight.message,
      bg: const Color(0xFFFBEAEA),
      border: const Color(0xFFF2B8B8),
      text: insight.severity == 'CRITICAL'
          ? const Color(0xFFB91C1C)
          : const Color(0xFFDC2626),
    );
  }).toList();

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('market_prices')
          .select()
          .order('crop_type', ascending: true);

      if (context.mounted) {
        setState(() {
          _prices = List<Map<String, dynamic>>.from(response);
          _loading = false;
        });
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        if (!isDesktop) {
          return Scaffold(
            backgroundColor: _bg,
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: _text,
              elevation: 0,
              title: const Text('Market & Price Intelligence'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MaoAdminDashboard())),
              ),
              actions: [
                IconButton(
                  onPressed: () => _showPriceDialog(null),
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Add Crop Price',
                ),
              ],
            ),
            drawer: Drawer(child: _buildSidebar()),
            body: _buildContent(isDesktop: false),
          );
        }

        return Scaffold(
          backgroundColor: _bg,
          body: Row(
            children: [
              SizedBox(width: 305, child: _buildSidebar()),
              Expanded(child: _buildContent(isDesktop: true)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    const items = <_NavItem>[
      _NavItem('Dashboard', Icons.grid_view_rounded),
      _NavItem('Farmers', Icons.people_outline_rounded),
      _NavItem('Supply Map', Icons.map_outlined),
      _NavItem('Forecast', Icons.trending_up_rounded),
      _NavItem('Market & Prices', Icons.shopping_cart_outlined),
      _NavItem('Interventions', Icons.build_outlined),
      _NavItem('Alerts', Icons.notifications_none_rounded),
      _NavItem('Reports', Icons.description_outlined),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F6F8),
        border: Border(right: BorderSide(color: _border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: _sidebarGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.agriculture_rounded,
                        color: Color(0xFFECFDF3), size: 30),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AgriSupply',
                          style: TextStyle(
                            color: Color(0xFF207538),
                            fontSize: 19.5,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Intelligence System',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = index == _selectedNavIndex;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _onNavTap(index),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: selected ? _sidebarGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 14,
                            color: selected ? Colors.white : const Color(0xFF364152),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: selected ? Colors.white : const Color(0xFF1E293B),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _border)),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: Color(0xFFE5E7EB),
                    child: Text(
                      'MS',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Maria Santos',
                          style: TextStyle(
                            color: _text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'MAO - San Juan',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
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

  Future<void> _onNavTap(int index) async {
    setState(() => _selectedNavIndex = index);
    if (!context.mounted) return;

    if (index == 4) return;
    if (index == 0) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MaoAdminDashboard()),
      );
      return;
    }
    if (index == 1) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FarmerManagementScreen()),
      );
      return;
    }
    if (index == 2) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SupplyMapScreen()),
      );
      return;
    }
    if (index == 3) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FinancialForecastScreen()),
      );
      return;
    }
    if (index == 5) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InterventionManagementScreen()),
      );
      return;
    }
    if (index == 6) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AlertsNotificationsScreen()),
      );
      return;
    }

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ReportsAnalyticsScreen()),
    );
  }

  Widget _buildContent({required bool isDesktop}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final rows = _buildPriceRows();

    return RefreshIndicator(
      onRefresh: _loadPrices,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(isDesktop ? 26 : 16, 22, isDesktop ? 26 : 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Market & Price Intelligence',
                      style: TextStyle(
                        color: _text,
                        fontSize: 44 / 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Real-time market prices and buyer demand tracking',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 34 / 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (isDesktop)
                  FilledButton.icon(
                    onPressed: () => _showPriceDialog(null),
                    style: FilledButton.styleFrom(
                      backgroundColor: _sidebarGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Price'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  'Load error: $_error',
                  style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildMarketPricesTable(rows),
            const SizedBox(height: 16),
            _buildTrendPanel(),
            const SizedBox(height: 16),
            _buildDemandPanel(),
            const SizedBox(height: 16),
            _buildBottomPanels(isDesktop),
          ],
        ),
      ),
    );
  }

  List<_PriceRow> _buildPriceRows() {
    if (_prices.isEmpty) {
      return _fallbackPrices;
    }

    return _prices.map((price) {
      final crop = (price['crop_type'] ?? 'Unknown').toString();
      final farmgate = (price['price_per_kg'] as num?)?.toDouble() ?? 0;
      final trend = (price['trend'] ?? 'stable').toString();
      final market = (farmgate <= 0 ? 0 : (farmgate * 1.78)).toDouble();
      final demand = trend.toLowerCase() == 'rising'
          ? 'High'
          : (trend.toLowerCase() == 'falling' ? 'Low' : 'Medium');

      return _PriceRow(
        crop,
        farmgate,
        market,
        _capitalize(trend),
        demand,
        id: (price['id'] ?? '').toString(),
      );
    }).toList();
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }

  Widget _buildMarketPricesTable(List<_PriceRow> rows) {
    return _panelWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Text(
              'Current Market Prices',
              style: TextStyle(
                color: _text,
                fontSize: 50 / 2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(height: 1, color: _border),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 980),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        SizedBox(width: 165, child: _HeaderText('Crop')),
                        SizedBox(width: 185, child: _HeaderText('Farmgate Price')),
                        SizedBox(width: 170, child: _HeaderText('Market Price')),
                        SizedBox(width: 165, child: _HeaderText('Margin')),
                        SizedBox(width: 125, child: _HeaderText('Trend')),
                        SizedBox(width: 150, child: _HeaderText('Demand Level')),
                      ],
                    ),
                  ),
                  Container(height: 1, color: _border),
                  ...rows.map((row) {
                    final marginValue = row.marketPrice - row.farmgatePrice;
                    final marginPct = row.farmgatePrice <= 0
                        ? 0
                        : ((marginValue / row.farmgatePrice) * 100);

                    final trendInfo = _trendInfo(row.trend);
                    final demandInfo = _demandInfo(row.demandLevel);

                    return InkWell(
                      onTap: row.id == null ? null : () => _showPriceDialog(_toPriceMap(row)),
                      onLongPress: row.id == null ? null : () => _confirmDelete(row.id!, row.crop),
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: _border)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 165,
                              child: Text(row.crop,
                                  style: TextStyle(color: _text, fontSize: 35 / 2)),
                            ),
                            SizedBox(
                              width: 185,
                              child: Text('₱${row.farmgatePrice.toStringAsFixed(2)}/kg',
                                  style: TextStyle(color: _text, fontSize: 35 / 2)),
                            ),
                            SizedBox(
                              width: 170,
                              child: Text('₱${row.marketPrice.toStringAsFixed(2)}/kg',
                                  style: TextStyle(color: _text, fontSize: 35 / 2)),
                            ),
                            SizedBox(
                              width: 165,
                              child: Text(
                                '₱${marginValue.toStringAsFixed(2)} (${marginPct.toStringAsFixed(0)}%)',
                                style: const TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontSize: 35 / 2,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 125,
                              child: Row(
                                children: [
                                  Icon(trendInfo.icon, size: 16, color: trendInfo.color),
                                  const SizedBox(width: 6),
                                  Text(
                                    row.trend,
                                    style: TextStyle(color: trendInfo.color, fontSize: 34 / 2),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: demandInfo.bg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  row.demandLevel,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: demandInfo.fg,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendPanel() {
    const labels = ['Apr 20', 'Apr 21', 'Apr 22', 'Apr 23', 'Apr 24', 'Apr 25', 'Apr 26'];
    const tomato = [45.0, 44.0, 44.0, 45.0, 45.0, 45.0, 45.0];
    const cabbage = [30.0, 29.0, 29.0, 30.0, 30.0, 30.0, 30.0];
    const lettuce = [52.0, 50.0, 48.5, 47.5, 46.5, 45.0, 45.0];

    return _panelWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '7-Day Price Trends',
              style: TextStyle(
                color: _text,
                fontSize: 50 / 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 360,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 60,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: const Color(0xFFD1D5DB),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                    getDrawingVerticalLine: (_) => FlLine(
                      color: const Color(0xFFD1D5DB),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(color: Color(0xFF6B7280), width: 1.2),
                      bottom: BorderSide(color: Color(0xFF6B7280), width: 1.2),
                      right: BorderSide.none,
                      top: BorderSide.none,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 15,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 14, color: _muted),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(labels[i], style: const TextStyle(fontSize: 16, color: _muted)),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    _lineSeries(tomato, const Color(0xFFFC2E3F)),
                    _lineSeries(cabbage, const Color(0xFF2E7D32)),
                    _lineSeries(lettuce, const Color(0xFF1565C0)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: Color(0xFFFC2E3F), label: 'Tomato (₱/kg)'),
                SizedBox(width: 14),
                _LegendItem(color: Color(0xFF2E7D32), label: 'Cabbage (₱/kg)'),
                SizedBox(width: 14),
                _LegendItem(color: Color(0xFF1565C0), label: 'Lettuce (₱/kg)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _lineSeries(List<double> values, Color color) {
    return LineChartBarData(
      spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
          radius: 3.5,
          color: Colors.white,
          strokeColor: color,
          strokeWidth: 2,
        ),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildDemandPanel() {
    return _panelWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buyer Demand & Partnerships',
              style: TextStyle(
                color: _text,
                fontSize: 50 / 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ..._partners.map((partner) {
              final status = _partnerStatus(partner.status);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              partner.title,
                              style: TextStyle(color: _text, fontSize: 39 / 2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Weekly demand: ${partner.weeklyDemandTons} tons',
                              style: const TextStyle(color: _muted, fontSize: 37 / 2),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: status.bg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          partner.status,
                          style: TextStyle(
                            color: status.fg,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanels(bool isDesktop) {
    final left = _panelWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Market Opportunities',
              style: TextStyle(
                color: _text,
                fontSize: 50 / 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ..._opportunities.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _infoCard(item),
                )),
          ],
        ),
      ),
    );

    final right = _panelWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Alerts',
              style: TextStyle(
                color: _text,
                fontSize: 50 / 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ..._alerts.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _infoCard(item),
                )),
          ],
        ),
      ),
    );

    if (!isDesktop) {
      return Column(
        children: [
          left,
          const SizedBox(height: 16),
          right,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }

  Widget _infoCard(_InfoBlock item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: item.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: TextStyle(color: item.text, fontSize: 40 / 2),
          ),
          const SizedBox(height: 4),
          Text(
            item.detail,
            style: TextStyle(color: item.text, fontSize: 34 / 2, height: 1.35),
          ),
        ],
      ),
    );
  }

  _TrendInfo _trendInfo(String trend) {
    switch (trend.toLowerCase()) {
      case 'rising':
        return const _TrendInfo(Icons.trending_up_rounded, Color(0xFF16A34A));
      case 'falling':
        return const _TrendInfo(Icons.trending_down_rounded, Color(0xFFFC2E3F));
      default:
        return const _TrendInfo(Icons.horizontal_rule_rounded, Color(0xFF64748B));
    }
  }

  _StatusInfo _demandInfo(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return const _StatusInfo(Color(0xFFD1FAE5), Color(0xFF047857));
      case 'low':
        return const _StatusInfo(Color(0xFFF3D9DC), Color(0xFFB91C1C));
      default:
        return const _StatusInfo(Color(0xFFF3E9AE), Color(0xFFA16207));
    }
  }

  _StatusInfo _partnerStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const _StatusInfo(Color(0xFFD1FAE5), Color(0xFF047857));
      case 'pending':
        return const _StatusInfo(Color(0xFFF3E9AE), Color(0xFFA16207));
      case 'negotiating':
        return const _StatusInfo(Color(0xFFDDE6F2), Color(0xFF1D4ED8));
      default:
        return const _StatusInfo(Color(0xFFF1F5F9), Color(0xFF475569));
    }
  }

  Widget _panelWrap({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Map<String, dynamic> _toPriceMap(_PriceRow row) {
    return {
      'id': row.id,
      'crop_type': row.crop,
      'price_per_kg': row.farmgatePrice,
      'trend': row.trend.toLowerCase(),
      'source': 'Manual Entry',
    };
  }

  void _showPriceDialog(Map<String, dynamic>? existing) {
    final isEditing = existing != null;
    final cropController = TextEditingController(text: existing?['crop_type'] ?? '');
    final priceController = TextEditingController(
      text: existing != null ? (existing['price_per_kg'] as num).toString() : '',
    );
    final sourceController = TextEditingController(text: existing?['source'] ?? 'Manual Entry');
    String selectedTrend = (existing?['trend'] as String?) ?? 'stable';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Price' : 'Add Crop Price'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: cropController,
                    enabled: !isEditing,
                    decoration: const InputDecoration(labelText: 'Crop Type', hintText: 'e.g., Tomato'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Farmgate Price (₱/kg)', hintText: '0.00'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTrend,
                    items: const [
                      DropdownMenuItem(value: 'rising', child: Text('Rising')),
                      DropdownMenuItem(value: 'stable', child: Text('Stable')),
                      DropdownMenuItem(value: 'falling', child: Text('Falling')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedTrend = v);
                    },
                    decoration: const InputDecoration(labelText: 'Trend'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sourceController,
                    decoration: const InputDecoration(labelText: 'Source', hintText: 'Manual Entry'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final crop = cropController.text.trim();
                  final price = double.tryParse(priceController.text.trim()) ?? 0;
                  final source = sourceController.text.trim();

                  if (crop.isEmpty || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Crop type and valid price are required')),
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  try {
                    if (isEditing) {
                      await Supabase.instance.client.from('market_prices').update({
                        'price_per_kg': price,
                        'trend': selectedTrend,
                        'source': source,
                        'price_date': DateTime.now().toIso8601String().substring(0, 10),
                      }).eq('id', existing['id']);
                    } else {
                      await Supabase.instance.client.from('market_prices').insert({
                        'crop_type': crop,
                        'price_per_kg': price,
                        'trend': selectedTrend,
                        'source': source,
                        'price_date': DateTime.now().toIso8601String().substring(0, 10),
                      });
                    }

                    await _loadPrices();
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'Price updated' : 'Price added')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: Text(isEditing ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(String id, String cropType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Price'),
        content: Text('Are you sure you want to delete the price for "$cropType"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.from('market_prices').delete().eq('id', id);
                await _loadPrices();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Price deleted')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _PriceRow {
  final String crop;
  final double farmgatePrice;
  final double marketPrice;
  final String trend;
  final String demandLevel;
  final String? id;

  const _PriceRow(this.crop, this.farmgatePrice, this.marketPrice, this.trend,
      this.demandLevel, {this.id});
}

class _TrendInfo {
  final IconData icon;
  final Color color;

  const _TrendInfo(this.icon, this.color);
}

class _StatusInfo {
  final Color bg;
  final Color fg;

  const _StatusInfo(this.bg, this.fg);
}

class _DemandPartner {
  final String title;
  final int weeklyDemandTons;
  final String status;

  const _DemandPartner(this.title, this.weeklyDemandTons, this.status);
}

class _InfoBlock {
  final String title;
  final String detail;
  final Color bg;
  final Color border;
  final Color text;

  const _InfoBlock({
    required this.title,
    required this.detail,
    required this.bg,
    required this.border,
    required this.text,
  });
}

class _HeaderText extends StatelessWidget {
  final String text;
  final Color textColor;

  const _HeaderText(this.text, {this.textColor = const Color(0xFF0F172A)});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 34 / 2),
        ),
      ],
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem(this.label, this.icon);
}
