import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../admin/alerts_notifications_screen.dart';
import '../admin/farmer_management_screen.dart';
import '../admin/intervention_management_screen.dart';
import '../admin/market_prices_screen.dart';
import '../admin/reports_analytics_screen.dart';
import '../admin/supply_map_screen.dart';
import '../home/mao_admin_dashboard.dart';
import 'supply_chain_dashboard_screen.dart';
import 'verification_workflow_screen.dart';

class FinancialForecastScreen extends StatefulWidget {
  const FinancialForecastScreen({super.key});

  @override
  State<FinancialForecastScreen> createState() => _FinancialForecastScreenState();
}

class _FinancialForecastScreenState extends State<FinancialForecastScreen> {
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFD6DAE1);
  static const Color _text = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF4B5563);
  static const Color _sidebarGreen = Color(0xFF2E7D32);

  int _selectedNavIndex = 3;
  int _forecastMode = 0; // 0 current, 1 staggered

  final List<_RiskCardData> _riskCards = const [
    _RiskCardData(
      crop: 'Tomato',
      level: 'Critical',
      risk: 0.85,
      supply: 29.5,
      demand: 16.2,
      surplus: 13.3,
      barColor: Color(0xFFFC2E3F),
      levelBg: Color(0xFFF3D9DC),
      levelFg: Color(0xFFDC2626),
    ),
    _RiskCardData(
      crop: 'Cabbage',
      level: 'Critical',
      risk: 0.78,
      supply: 64.0,
      demand: 36.5,
      surplus: 27.5,
      barColor: Color(0xFFFC2E3F),
      levelBg: Color(0xFFF3D9DC),
      levelFg: Color(0xFFDC2626),
    ),
    _RiskCardData(
      crop: 'Lettuce',
      level: 'Warning',
      risk: 0.42,
      supply: 18.5,
      demand: 13.0,
      surplus: 5.5,
      barColor: Color(0xFFEBAA00),
      levelBg: Color(0xFFF3E9AE),
      levelFg: Color(0xFFA16207),
    ),
  ];

  final List<_RecommendationData> _recommendations = const [
    _RecommendationData(
      title: 'Delay Planting',
      detail: 'Recommend farmers to delay tomato planting by 2-3 weeks to avoid harvest overlap.',
      bg: Color(0xFFDDE6F2),
      border: Color(0xFFB7CCE8),
      iconColor: Color(0xFF2563EB),
      textColor: Color(0xFF1D4ED8),
      icon: Icons.waves,
    ),
    _RecommendationData(
      title: 'Redirect Buyers',
      detail: 'Connect 3 institutional buyers to absorb cabbage surplus. Potential: 15 tons.',
      bg: Color(0xFFD9EEE1),
      border: Color(0xFFB5DFC5),
      iconColor: Color(0xFF15803D),
      textColor: Color(0xFF047857),
      icon: Icons.trending_up_rounded,
    ),
    _RecommendationData(
      title: 'Switch Crops',
      detail: 'High demand for eggplant and pepper. Suggest shifting 20% of tomato area.',
      bg: Color(0xFFF9F3D9),
      border: Color(0xFFEAD98F),
      iconColor: Color(0xFFB45309),
      textColor: Color(0xFFB45309),
      icon: Icons.remove_rounded,
    ),
  ];

  final List<_RiskFactorData> _contributingFactors = const [
    _RiskFactorData(
      title: 'Synchronized harvest dates',
      status: 'High Impact',
      bg: Color(0xFFF4E5E7),
      statusColor: Color(0xFFDC2626),
    ),
    _RiskFactorData(
      title: 'Limited storage capacity',
      status: 'Medium Impact',
      bg: Color(0xFFF3EFDA),
      statusColor: Color(0xFFD97706),
    ),
    _RiskFactorData(
      title: 'Market access constraints',
      status: 'Medium Impact',
      bg: Color(0xFFF3EFDA),
      statusColor: Color(0xFFD97706),
    ),
  ];

  final List<_RiskFactorData> _mitigationStatus = const [
    _RiskFactorData(
      title: 'Kadiwa activation',
      status: 'In Progress',
      bg: Color(0xFFDDE6F2),
      statusColor: Color(0xFF2563EB),
    ),
    _RiskFactorData(
      title: 'Buyer coordination',
      status: 'Planned',
      bg: Color(0xFFD9EEE1),
      statusColor: Color(0xFF16A34A),
    ),
    _RiskFactorData(
      title: 'Cold storage expansion',
      status: 'Pending Budget',
      bg: Color(0xFFF1F3F5),
      statusColor: Color(0xFF475569),
    ),
  ];

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
              title: const Text('Oversupply Prediction & Forecast'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MaoAdminDashboard())),
              ),
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
    if (!mounted) return;

    if (index == 3) return;
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
    if (index == 4) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MarketPricesScreen()),
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(isDesktop ? 26 : 16, 22, isDesktop ? 26 : 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Oversupply Prediction & Forecast',
              style: TextStyle(
                color: _text,
                fontSize: 44 / 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI-powered supply forecasting and intervention recommendations',
              style: TextStyle(
                color: _muted,
                fontSize: 34 / 2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            _buildRiskCards(isDesktop),
            const SizedBox(height: 16),
            _buildRecommendationsPanel(),
            const SizedBox(height: 16),
            _buildForecastPanel(),
            const SizedBox(height: 16),
            _buildRiskFactorsPanel(isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCards(bool isDesktop) {
    if (!isDesktop) {
      return Column(
        children: _riskCards
            .map((card) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRiskCard(card),
                ))
            .toList(),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < _riskCards.length; i++) ...[
          Expanded(child: _buildRiskCard(_riskCards[i])),
          if (i != _riskCards.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _buildRiskCard(_RiskCardData data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                data.crop,
                style: const TextStyle(
                  color: _text,
                  fontSize: 40 / 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: data.levelBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  data.level,
                  style: TextStyle(
                    color: data.levelFg,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Risk Score',
                style: TextStyle(color: _muted, fontSize: 35 / 2),
              ),
              const Spacer(),
              Text(
                '${(data.risk * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 64 / 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 16,
              value: data.risk,
              backgroundColor: const Color(0xFFD9DDE3),
              valueColor: AlwaysStoppedAnimation<Color>(data.barColor),
            ),
          ),
          const SizedBox(height: 14),
          _statRow('Supply Volume:', '${data.supply.toStringAsFixed(1)} tons'),
          _statRow('Demand:', '${data.demand.toStringAsFixed(1)} tons'),
          _statRow(
            'Surplus:',
            '+${data.surplus.toStringAsFixed(1)} tons',
            valueColor: const Color(0xFFFC2E3F),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 37 / 2),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(color: valueColor ?? _text, fontSize: 37 / 2),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsPanel() {
    return _panelWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF59E0B), size: 28),
                SizedBox(width: 10),
                Text(
                  'AI Recommendations',
                  style: TextStyle(
                    color: _text,
                    fontSize: 44 / 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                if (!isWide) {
                  return Column(
                    children: _recommendations
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _recommendationCard(item),
                            ))
                        .toList(),
                  );
                }

                return Row(
                  children: [
                    for (int i = 0; i < _recommendations.length; i++) ...[
                      Expanded(child: _recommendationCard(_recommendations[i])),
                      if (i != _recommendations.length - 1) const SizedBox(width: 14),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendationCard(_RecommendationData data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: data.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: data.iconColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: data.textColor,
                    fontSize: 38 / 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.detail,
                  style: TextStyle(
                    color: data.textColor,
                    fontSize: 33 / 2,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastPanel() {
    final labels = ['May', 'Jun', 'Jul'];
    final currentData = [86.0, 93.0, 78.0];
    final staggeredData = [72.0, 68.0, 64.0];

    return _panelWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '3-Month Supply Forecast',
                  style: TextStyle(
                    color: _text,
                    fontSize: 50 / 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                _modeButton('Current Trend', selected: _forecastMode == 0, onTap: () {
                  setState(() => _forecastMode = 0);
                }),
                const SizedBox(width: 10),
                _modeButton('Staggered Planting', selected: _forecastMode == 1, onTap: () {
                  setState(() => _forecastMode = 1);
                }),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 360,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,
                  alignment: BarChartAlignment.spaceAround,
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
                        interval: 25,
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
                          if (i < 0 || i >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[i],
                              style: const TextStyle(fontSize: 32 / 2, color: _muted),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(labels.length, (i) {
                    final current = currentData[i];
                    final staggered = staggeredData[i];

                    if (_forecastMode == 1) {
                      return BarChartGroupData(
                        x: i,
                        barsSpace: 6,
                        barRods: [
                          BarChartRodData(
                            toY: staggered,
                            width: 42,
                            color: const Color(0xFF2E7D32),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                          ),
                        ],
                      );
                    }

                    return BarChartGroupData(
                      x: i,
                      barsSpace: 6,
                      barRods: [
                        BarChartRodData(
                          toY: current,
                          width: 80,
                          color: const Color(0xFFF5A623),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _LegendItem(color: Color(0xFFF5A623), label: 'Current Scenario (tons)'),
                SizedBox(width: 16),
                _LegendItem(color: Color(0xFF2E7D32), label: 'Staggered Planting (tons)'),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Insight: Implementing staggered planting schedules can reduce oversupply risk by 32% over the next quarter. Coordinate with BAOs to adjust farmer planting calendars.',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 36 / 2,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String text, {required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2E7D32) : const Color(0xFFD7DCE4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF334155),
            fontSize: 37 / 2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRiskFactorsPanel(bool isDesktop) {
    return _panelWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Risk Factors Analysis',
              style: TextStyle(
                color: _text,
                fontSize: 50 / 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _factorColumn('Contributing Factors', _contributingFactors)),
                  const SizedBox(width: 16),
                  Expanded(child: _factorColumn('Mitigation Status', _mitigationStatus)),
                ],
              )
            else ...[
              _factorColumn('Contributing Factors', _contributingFactors),
              const SizedBox(height: 16),
              _factorColumn('Mitigation Status', _mitigationStatus),
            ],
          ],
        ),
      ),
    );
  }

  Widget _factorColumn(String title, List<_RiskFactorData> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 39 / 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: row.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.title,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 37 / 2,
                      ),
                    ),
                  ),
                  Text(
                    row.status,
                    style: TextStyle(
                      color: row.statusColor,
                      fontSize: 37 / 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
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
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 18, height: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 37 / 2,
            fontWeight: FontWeight.w500,
          ),
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

class _RiskCardData {
  final String crop;
  final String level;
  final double risk;
  final double supply;
  final double demand;
  final double surplus;
  final Color barColor;
  final Color levelBg;
  final Color levelFg;

  const _RiskCardData({
    required this.crop,
    required this.level,
    required this.risk,
    required this.supply,
    required this.demand,
    required this.surplus,
    required this.barColor,
    required this.levelBg,
    required this.levelFg,
  });
}

class _RecommendationData {
  final String title;
  final String detail;
  final Color bg;
  final Color border;
  final Color iconColor;
  final Color textColor;
  final IconData icon;

  const _RecommendationData({
    required this.title,
    required this.detail,
    required this.bg,
    required this.border,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });
}

class _RiskFactorData {
  final String title;
  final String status;
  final Color bg;
  final Color statusColor;

  const _RiskFactorData({
    required this.title,
    required this.status,
    required this.bg,
    required this.statusColor,
  });
}
