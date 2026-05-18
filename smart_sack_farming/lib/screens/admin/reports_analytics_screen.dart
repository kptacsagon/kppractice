import 'package:flutter/material.dart';

import '../features/financial_forecast_screen.dart';
import '../home/mao_admin_dashboard.dart';
import 'agri_financial_mao_screen.dart';
import 'alerts_notifications_screen.dart';
import 'farmer_management_screen.dart';
import 'intervention_management_screen.dart';
import 'market_prices_screen.dart';
import 'supply_map_screen.dart';
import '../../services/agri_ure_service.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFD6DAE1);
  static const Color _text = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF4B5563);
  static const Color _sidebarGreen = Color(0xFF2E7D32);

  int _selectedNavIndex = 7;
  final _ureSvc = AgriUreService();
  List<UreEvent> _ureEvents = [];
  bool _ureLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUre();
  }

  Future<void> _loadUre() async {
    try {
      final data = await _ureSvc.getAllUreEvents();
      if (!mounted) return;
      setState(() { _ureEvents = data; _ureLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _ureLoading = false);
    }
  }

  final List<_MetricCardData> _metrics = const [
    _MetricCardData(
      value: '24',
      label: 'Reports Generated',
      icon: Icons.description_outlined,
      color: Color(0xFF2E7D32),
      bg: Color(0xFFE7F1E8),
    ),
    _MetricCardData(
      value: '156',
      label: 'Downloads',
      icon: Icons.download_rounded,
      color: Color(0xFF2563EB),
      bg: Color(0xFFDDE6F2),
    ),
    _MetricCardData(
      value: '12',
      label: 'Scheduled',
      icon: Icons.calendar_month_outlined,
      color: Color(0xFFF59E0B),
      bg: Color(0xFFF9F3D9),
    ),
    _MetricCardData(
      value: '5',
      label: 'This Week',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF2E7D32),
      bg: Color(0xFFE7F1E8),
    ),
  ];

  final List<_TemplateCardData> _templates = const [
    _TemplateCardData(
      title: 'Production Report',
      subtitle: 'Weekly/monthly\nproduction aggregation',
      action: 'Generate Report',
      icon: Icons.description_outlined,
      iconColor: Color(0xFF2E7D32),
      iconBg: Color(0xFFBFE8CC),
    ),
    _TemplateCardData(
      title: 'Risk Assessment',
      subtitle: 'Oversupply risk analysis by\ncrop',
      action: 'Generate Report',
      icon: Icons.trending_up_rounded,
      iconColor: Color(0xFFE6A100),
      iconBg: Color(0xFFF3E9AE),
    ),
    _TemplateCardData(
      title: 'Data Export',
      subtitle: 'Export farmer and\nproduction data',
      action: 'Generate Report',
      icon: Icons.download_rounded,
      iconColor: Color(0xFF2563EB),
      iconBg: Color(0xFFCAD9EE),
    ),
  ];

  final List<_RecentReportItem> _recentReports = const [
    _RecentReportItem(
      title: 'Weekly Production Summary',
      subtitle: 'Aggregate production data by crop and barangay',
      tag: 'Production',
      dateLabel: '4/27/2026',
    ),
    _RecentReportItem(
      title: 'Oversupply Risk Analysis',
      subtitle: 'Comprehensive risk assessment and mitigation tracking',
      tag: 'Risk Analysis',
      dateLabel: '4/27/2026',
    ),
    _RecentReportItem(
      title: 'Market Price Trends',
      subtitle: 'Price movements and demand patterns for key crops',
      tag: 'Market',
      dateLabel: '4/26/2026',
    ),
    _RecentReportItem(
      title: 'Intervention Impact Report',
      subtitle: 'Effectiveness of implemented interventions',
      tag: 'Interventions',
      dateLabel: '4/25/2026',
    ),
    _RecentReportItem(
      title: 'Farmer Database Export',
      subtitle: 'Complete farmer profiles and contact information',
      tag: 'Data Export',
      dateLabel: '4/24/2026',
    ),
  ];

  final List<_ScheduledReportItem> _scheduledReports = const [
    _ScheduledReportItem(
      title: 'Weekly Production Summary',
      subtitle: 'Every Monday at 8:00 AM',
      icon: Icons.calendar_month_outlined,
      bg: Color(0xFFDDE6F2),
      border: Color(0xFFB7CCE8),
      textColor: Color(0xFF1D4ED8),
    ),
    _ScheduledReportItem(
      title: 'Monthly Risk Assessment',
      subtitle: '1st of every month at 9:00 AM',
      icon: Icons.calendar_month_outlined,
      bg: Color(0xFFD9EEE1),
      border: Color(0xFFB5DFC5),
      textColor: Color(0xFF047857),
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
              title: const Text('Reports & Analytics'),
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

    if (index == 7) return;
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
    if (index == 5) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InterventionManagementScreen()),
      );
      return;
    }

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AlertsNotificationsScreen()),
    );
  }

  Widget _buildContent({required bool isDesktop}) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(isDesktop ? 26 : 16, 22, isDesktop ? 26 : 16, 22),
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
                        'Reports & Analytics',
                        style: TextStyle(
                          color: _text,
                          fontSize: 44 / 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Generate and download comprehensive reports',
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                  icon: const Icon(Icons.description_outlined, color: Colors.white),
                  label: const Text(
                    'New Report',
                    style: TextStyle(color: Colors.white, fontSize: 36 / 2, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricStrip(isDesktop),
            const SizedBox(height: 16),
            _buildUrePanel(),
            const SizedBox(height: 16),
            _buildTemplatesPanel(isDesktop),
            const SizedBox(height: 16),
            _buildRecentReportsPanel(),
            const SizedBox(height: 16),
            _buildScheduledPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildUrePanel() {
    final pending = _ureEvents.where((e) => e.status == 'pending').length;
    return _panelWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('URE Reports Inbox', style: TextStyle(color: _text, fontSize: 25, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Farmer-submitted Uncontrolled Risk Event reports', style: TextStyle(color: _muted, fontSize: 14)),
              ]),
            ),
            if (pending > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                child: Text('$pending pending', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
              ),
            const SizedBox(width: 10),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AgriFinancialMaoScreen())),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Full Inbox'),
              style: TextButton.styleFrom(foregroundColor: _sidebarGreen),
            ),
          ]),
          const SizedBox(height: 14),
          if (_ureLoading)
            const Center(child: CircularProgressIndicator())
          else if (_ureEvents.isEmpty)
            const Text('No URE reports submitted yet.', style: TextStyle(color: _muted))
          else ...[
            ..._ureEvents.take(3).map((e) => _ureRow(e)),
            if (_ureEvents.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('+ ${_ureEvents.length - 3} more reports — open Full Inbox to view all.',
                    style: const TextStyle(fontSize: 12, color: _muted)),
              ),
          ],
        ]),
      ),
    );
  }

  Widget _ureRow(UreEvent e) {
    final statusColor = e.status == 'pending'
        ? const Color(0xFFF59E0B)
        : e.status == 'verified'
            ? const Color(0xFF16A34A)
            : e.status == 'endorsed'
                ? const Color(0xFF2563EB)
                : const Color(0xFFDC2626);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${e.eventType} — ${e.cropType}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
          const SizedBox(height: 2),
          Text(e.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _muted)),
        ])),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(6)),
          child: Text(e.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
        ),
      ]),
    );
  }

  Widget _buildMetricStrip(bool isDesktop) {
    if (!isDesktop) {
      return Column(
        children: _metrics
            .map(
              (metric) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _metricCard(metric),
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < _metrics.length; i++) ...[
          Expanded(child: _metricCard(_metrics[i])),
          if (i != _metrics.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _metricCard(_MetricCardData data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(data.icon, color: data.color, size: 34),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: TextStyle(
                  color: data.color,
                  fontSize: 66 / 2,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.label,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 36 / 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesPanel(bool isDesktop) {
    return _panelWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Templates',
              style: TextStyle(
                color: _text,
                fontSize: 50 / 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (isDesktop)
              Row(
                children: [
                  for (int i = 0; i < _templates.length; i++) ...[
                    Expanded(child: _templateCard(_templates[i])),
                    if (i != _templates.length - 1) const SizedBox(width: 14),
                  ],
                ],
              )
            else
              Column(
                children: _templates
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _templateCard(item),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _templateCard(_TemplateCardData data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC9D2DE), style: BorderStyle.solid),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: data.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, color: data.iconColor, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 46 / 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.subtitle,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 37 / 2,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Generate Report',
                style: TextStyle(
                  color: _sidebarGreen,
                  fontSize: 38 / 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReportsPanel() {
    return _panelWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 20, 22, 14),
            child: Text(
              'Recent Reports',
              style: TextStyle(
                color: _text,
                fontSize: 50 / 2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE1E5EA)),
          for (int i = 0; i < _recentReports.length; i++)
            _recentRow(_recentReports[i], isLast: i == _recentReports.length - 1),
        ],
      ),
    );
  }

  Widget _recentRow(_RecentReportItem item, {required bool isLast}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_outlined, color: Color(0xFF64748B), size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 50 / 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(color: _muted, fontSize: 37 / 2),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.tag,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      item.dateLabel,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 33 / 2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: _sidebarGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
            label: const Text(
              'Download',
              style: TextStyle(color: Colors.white, fontSize: 37 / 2, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            child: const Text(
              'View',
              style: TextStyle(color: _text, fontSize: 37 / 2, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledPanel() {
    return _panelWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scheduled Reports',
              style: TextStyle(
                color: _text,
                fontSize: 50 / 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ..._scheduledReports.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: item.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: item.border),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, color: item.textColor, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: item.textColor,
                              fontSize: 44 / 2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              color: item.textColor,
                              fontSize: 35 / 2,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          color: item.textColor,
                          fontSize: 35 / 2,
                          fontWeight: FontWeight.w600,
                        ),
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

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem(this.label, this.icon);
}

class _MetricCardData {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;

  const _MetricCardData({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

class _TemplateCardData {
  final String title;
  final String subtitle;
  final String action;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _TemplateCardData({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

class _RecentReportItem {
  final String title;
  final String subtitle;
  final String tag;
  final String dateLabel;

  const _RecentReportItem({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.dateLabel,
  });
}

class _ScheduledReportItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bg;
  final Color border;
  final Color textColor;

  const _ScheduledReportItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bg,
    required this.border,
    required this.textColor,
  });
}
