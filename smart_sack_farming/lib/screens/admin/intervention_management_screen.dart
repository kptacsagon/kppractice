import 'package:flutter/material.dart';

import '../features/financial_forecast_screen.dart';
import 'alerts_notifications_screen.dart';
import 'reports_analytics_screen.dart';
import '../features/verification_workflow_screen.dart';
import '../features/supply_chain_dashboard_screen.dart';
import '../home/mao_admin_dashboard.dart';
import 'farmer_management_screen.dart';
import 'market_prices_screen.dart';
import 'supply_map_screen.dart';

class InterventionManagementScreen extends StatefulWidget {
  const InterventionManagementScreen({super.key});

  @override
  State<InterventionManagementScreen> createState() => _InterventionManagementScreenState();
}

class _InterventionManagementScreenState extends State<InterventionManagementScreen> {
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFD6DAE1);
  static const Color _text = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF4B5563);
  static const Color _sidebarGreen = Color(0xFF2E7D32);

  int _selectedNavIndex = 5;

  final List<_InterventionCard> _activeInterventions = const [
    _InterventionCard(
      icon: '🛒',
      title: 'Activate Kadiwa Rolling Store',
      subtitle: 'Deploy mobile market to absorb tomato surplus in Poblacion area',
      tags: ['Crop: Tomato', 'Assigned: Kadiwa Team A', 'Impact: Absorb 5-8 tons'],
      isWarning: false,
      primaryAction: 'Update',
      primaryColor: Color(0xFF2563EB),
    ),
    _InterventionCard(
      icon: '🏛️',
      title: 'LGU Bulk Purchase Program',
      subtitle: 'Municipality to purchase cabbage for feeding programs',
      tags: ['Crop: Cabbage', 'Assigned: Municipal Administrator', 'Impact: Absorb 10-12 tons'],
      isWarning: true,
      primaryAction: 'Execute',
      primaryColor: Color(0xFF2E7D32),
    ),
    _InterventionCard(
      icon: '🤝',
      title: 'Cooperative Market Coordination',
      subtitle: 'Alert cooperatives to redirect buyers to oversupply areas',
      tags: ['Crop: Lettuce', 'Assigned: Coop Coordinator', 'Impact: Redirect 8 tons'],
      isWarning: false,
      primaryAction: 'Update',
      primaryColor: Color(0xFF2563EB),
    ),
    _InterventionCard(
      icon: '📦',
      title: 'Emergency Cold Storage',
      subtitle: 'Secure additional storage facility in nearby municipality',
      tags: ['Crop: Multiple', 'Assigned: DA Regional Office', 'Impact: Add 20 tons capacity'],
      isWarning: true,
      primaryAction: 'Execute',
      primaryColor: Color(0xFF2E7D32),
    ),
  ];

  final List<_SuggestedIntervention> _suggested = const [
    _SuggestedIntervention(
      icon: '🍅',
      title: 'Emergency Food Bank Program',
      detail: 'Redirect tomato surplus to food banks and charitable institutions',
      potential: 'Potential: 8-10 tons',
    ),
    _SuggestedIntervention(
      icon: '🥬',
      title: 'Processing Partnership',
      detail: 'Partner with food processor for cabbage value-adding (kimchi, pickled)',
      potential: 'Potential: 12-15 tons',
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
              title: const Text('Intervention Management'),
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

    if (index == 5) return;
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
    if (index == 4) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MarketPricesScreen()),
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
    if (index == 7) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ReportsAnalyticsScreen()),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SupplyChainDashboardScreen()),
    );
  }

  Widget _buildContent({required bool isDesktop}) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(isDesktop ? 26 : 16, 22, isDesktop ? 26 : 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Intervention Management',
                        style: TextStyle(
                          color: _text,
                          fontSize: 44 / 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Coordinate actions to prevent and mitigate oversupply',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 34 / 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: _sidebarGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: const Text(
                    'New Intervention',
                    style: TextStyle(color: Colors.white, fontSize: 36 / 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryStrip(isDesktop),
            const SizedBox(height: 16),
            _buildActiveInterventionsPanel(),
            const SizedBox(height: 16),
            _buildSuggestedPanel(isDesktop),
            const SizedBox(height: 16),
            _buildBottomPanels(isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStrip(bool isDesktop) {
    final cards = const [
      _SummaryItem('2', 'Pending', Icons.schedule_rounded, Color(0xFFD97706), Color(0xFF1E3A8A)),
      _SummaryItem('2', 'Ongoing', Icons.play_arrow_rounded, Color(0xFF2563EB), Color(0xFF2563EB)),
      _SummaryItem('0', 'Completed', Icons.check_circle_outline_rounded, Color(0xFF16A34A), Color(0xFF16A34A)),
      _SummaryItem('42', 'Tons Absorbed', Icons.trending_up_rounded, Color(0xFF2E7D32), Color(0xFF2E7D32)),
    ];

    if (!isDesktop) {
      return Column(
        children: cards
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _summaryCard(item),
                ))
            .toList(),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: _summaryCard(cards[i])),
          if (i != cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _summaryCard(_SummaryItem item) {
    return Container(
      height: 122,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(item.icon, color: item.iconColor, size: 44 / 2),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: TextStyle(
                  color: item.valueColor,
                  fontSize: 66 / 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                item.label,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 36 / 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveInterventionsPanel() {
    return _panelWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Interventions',
              style: TextStyle(
                color: _text,
                fontSize: 50 / 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ..._activeInterventions.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _activeInterventionCard(item),
                )),
          ],
        ),
      ),
    );
  }

  Widget _activeInterventionCard(_InterventionCard item) {
    final bg = item.isWarning ? const Color(0xFFF6F3C8) : const Color(0xFFD7E5F6);
    final border = item.isWarning ? const Color(0xFFECD96E) : const Color(0xFFB7CCE8);
    final titleColor = item.isWarning ? const Color(0xFFB45309) : const Color(0xFF1D4ED8);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 40 / 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(color: _muted, fontSize: 37 / 2),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.tags
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(230),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(color: Color(0xFFB45309), fontSize: 16),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: item.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(86, 38),
                ),
                child: Text(item.primaryAction, style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(86, 38),
                ),
                child: Text(
                  'Details',
                  style: TextStyle(
                    color: item.isWarning ? const Color(0xFFB45309) : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedPanel(bool isDesktop) {
    return _panelWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI-Suggested Interventions',
              style: TextStyle(
                color: _text,
                fontSize: 50 / 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            if (isDesktop)
              Row(
                children: [
                  Expanded(child: _suggestedCard(_suggested[0])),
                  const SizedBox(width: 16),
                  Expanded(child: _suggestedCard(_suggested[1])),
                ],
              )
            else ...[
              _suggestedCard(_suggested[0]),
              const SizedBox(height: 12),
              _suggestedCard(_suggested[1]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _suggestedCard(_SuggestedIntervention item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 2, style: BorderStyle.solid),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 42 / 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.detail,
                  style: const TextStyle(color: _muted, fontSize: 37 / 2, height: 1.35),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      item.potential,
                      style: const TextStyle(color: _muted, fontSize: 36 / 2),
                    ),
                    const Spacer(),
                    const Text(
                      'Create Intervention',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 36 / 2,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildBottomPanels(bool isDesktop) {
    final left = _panelWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: Color(0xFF2563EB), size: 24),
                SizedBox(width: 10),
                Text(
                  'Transport Coordination',
                  style: TextStyle(
                    color: _text,
                    fontSize: 50 / 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _detailBox(
              bg: const Color(0xFFF1F3F5),
              leftTitle: 'Available Vehicles',
              leftSub: 'Capacity',
              rightTitle: '5 units',
              rightSub: 'Total: 25 tons',
              rightColor: _text,
            ),
            const SizedBox(height: 10),
            _detailBox(
              bg: const Color(0xFFDDE6F2),
              leftTitle: 'Scheduled Trips',
              leftSub: 'Destinations',
              rightTitle: '3 today',
              rightSub: 'Divisoria, Balintawak, QC',
              rightColor: const Color(0xFF2563EB),
            ),
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
            const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: Color(0xFF2E7D32), size: 24),
                SizedBox(width: 10),
                Text(
                  'Storage Allocation',
                  style: TextStyle(
                    color: _text,
                    fontSize: 50 / 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Text('Total Capacity', style: TextStyle(color: _text, fontSize: 37 / 2)),
                      Spacer(),
                      Text('150 tons', style: TextStyle(color: _text, fontSize: 37 / 2)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: 112 / 150,
                      minHeight: 14,
                      backgroundColor: const Color(0xFFD6DAE1),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF2E7D32)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Text('Used: 112 tons', style: TextStyle(color: _muted, fontSize: 36 / 2)),
                      Spacer(),
                      Text('Available: 38 tons', style: TextStyle(color: _muted, fontSize: 36 / 2)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F3C8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage Alert',
                    style: TextStyle(color: Color(0xFFB45309), fontSize: 39 / 2),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Nearing capacity. Consider activating emergency storage facility.',
                    style: TextStyle(color: Color(0xFFB45309), fontSize: 36 / 2, height: 1.35),
                  ),
                ],
              ),
            ),
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

  Widget _detailBox({
    required Color bg,
    required String leftTitle,
    required String leftSub,
    required String rightTitle,
    required String rightSub,
    required Color rightColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(leftTitle, style: TextStyle(color: _text, fontSize: 39 / 2)),
                const SizedBox(height: 4),
                Text(leftSub, style: const TextStyle(color: _muted, fontSize: 36 / 2)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rightTitle,
                style: TextStyle(color: rightColor, fontSize: 40 / 2),
              ),
              const SizedBox(height: 4),
              Text(rightSub, style: const TextStyle(color: _muted, fontSize: 36 / 2)),
            ],
          ),
        ],
      ),
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

class _SummaryItem {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color valueColor;

  const _SummaryItem(this.value, this.label, this.icon, this.iconColor, this.valueColor);
}

class _InterventionCard {
  final String icon;
  final String title;
  final String subtitle;
  final List<String> tags;
  final bool isWarning;
  final String primaryAction;
  final Color primaryColor;

  const _InterventionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.isWarning,
    required this.primaryAction,
    required this.primaryColor,
  });
}

class _SuggestedIntervention {
  final String icon;
  final String title;
  final String detail;
  final String potential;

  const _SuggestedIntervention({
    required this.icon,
    required this.title,
    required this.detail,
    required this.potential,
  });
}

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem(this.label, this.icon);
}
