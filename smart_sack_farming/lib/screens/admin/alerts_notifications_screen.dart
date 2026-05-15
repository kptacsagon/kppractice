import 'package:flutter/material.dart';

import '../features/financial_forecast_screen.dart';
import '../features/supply_chain_dashboard_screen.dart';
import '../features/verification_workflow_screen.dart';
import '../home/mao_admin_dashboard.dart';
import 'farmer_management_screen.dart';
import 'intervention_management_screen.dart';
import 'market_prices_screen.dart';
import 'reports_analytics_screen.dart';
import 'supply_map_screen.dart';

class AlertsNotificationsScreen extends StatefulWidget {
  const AlertsNotificationsScreen({super.key});

  @override
  State<AlertsNotificationsScreen> createState() => _AlertsNotificationsScreenState();
}

class _AlertsNotificationsScreenState extends State<AlertsNotificationsScreen> {
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFD6DAE1);
  static const Color _text = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF4B5563);
  static const Color _sidebarGreen = Color(0xFF2E7D32);

  int _selectedNavIndex = 6;
  String _priorityFilter = 'All Priorities';
  String _typeFilter = 'All Types';

  bool _smsNotif = true;
  bool _emailNotif = true;
  bool _inAppNotif = true;
  bool _criticalOnly = true;
  bool _warningAlerts = true;
  bool _infoAlerts = false;

  final List<_AlertItem> _alerts = const [
    _AlertItem(
      level: 'CRITICAL',
      title: 'Critical Oversupply Warning',
      description: 'Tomato production exceeds demand by 45%. Immediate intervention needed.',
      crop: 'Tomato',
      location: 'Poblacion',
      dateLabel: '4/27/2026, 8:30:00 AM',
      icon: Icons.warning_amber_rounded,
      accent: Color(0xFFDC2626),
      cardBg: Color(0xFFFBEAEA),
      border: Color(0xFFF2B8B8),
      badgeBg: Color(0xFFF3D9DC),
    ),
    _AlertItem(
      level: 'WARNING',
      title: 'Cabbage Oversupply Alert',
      description: 'Cabbage surplus reaching 60 tons. Market price declining.',
      crop: 'Cabbage',
      location: 'San Isidro',
      dateLabel: '4/27/2026, 9:15:00 AM',
      icon: Icons.warning_amber_rounded,
      accent: Color(0xFFD97706),
      cardBg: Color(0xFFF6F3C8),
      border: Color(0xFFECD96E),
      badgeBg: Color(0xFFF3E9AE),
    ),
    _AlertItem(
      level: 'WARNING',
      title: 'Price Drop Alert',
      description: 'Farmgate price for Cabbage dropped 15% in the last 3 days.',
      crop: 'Cabbage',
      location: null,
      dateLabel: '4/26/2026, 2:20:00 PM',
      icon: Icons.trending_down_rounded,
      accent: Color(0xFFD97706),
      cardBg: Color(0xFFF6F3C8),
      border: Color(0xFFECD96E),
      badgeBg: Color(0xFFF3E9AE),
    ),
    _AlertItem(
      level: 'INFO',
      title: 'Storage Capacity Warning',
      description: 'Storage facilities at 85% capacity. Additional space needed.',
      crop: 'Multiple',
      location: 'Poblacion',
      dateLabel: '4/26/2026, 11:00:00 AM',
      icon: Icons.inventory_2_outlined,
      accent: Color(0xFF2563EB),
      cardBg: Color(0xFFDDE6F2),
      border: Color(0xFFB7CCE8),
      badgeBg: Color(0xFFCAD9EE),
    ),
  ];

  List<_AlertItem> get _filteredAlerts {
    return _alerts.where((item) {
      final priorityOk = _priorityFilter == 'All Priorities' ||
          (_priorityFilter == 'Critical' && item.level == 'CRITICAL') ||
          (_priorityFilter == 'Warning' && item.level == 'WARNING') ||
          (_priorityFilter == 'Info' && item.level == 'INFO');

      final typeOk = _typeFilter == 'All Types' ||
          (_typeFilter == 'Oversupply' && item.title.toLowerCase().contains('oversupply')) ||
          (_typeFilter == 'Price' && item.title.toLowerCase().contains('price')) ||
          (_typeFilter == 'Storage' && item.title.toLowerCase().contains('storage'));

      return priorityOk && typeOk;
    }).toList();
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
              title: const Text('Alerts & Notifications'),
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

    if (index == 6) return;
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
    if (index == 7) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ReportsAnalyticsScreen()),
      );
      return;
    }

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SupplyChainDashboardScreen()),
    );
  }

  Widget _buildContent({required bool isDesktop}) {
    final alerts = _filteredAlerts;
    final criticalCount = alerts.where((a) => a.level == 'CRITICAL').length;
    final warningCount = alerts.where((a) => a.level == 'WARNING').length;
    final infoCount = alerts.where((a) => a.level == 'INFO').length;

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
                        'Alerts & Notifications',
                        style: TextStyle(
                          color: _text,
                          fontSize: 44 / 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Real-time monitoring and alert management',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 34 / 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.notifications_none_rounded, color: _text),
                  label: const Text(
                    'Settings',
                    style: TextStyle(color: _text, fontSize: 34 / 2, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryCards(isDesktop, criticalCount, warningCount, infoCount),
            const SizedBox(height: 16),
            _buildFilterPanel(alerts.length),
            const SizedBox(height: 16),
            ...alerts.map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAlertCard(alert),
                )),
            const SizedBox(height: 16),
            _buildPreferencesPanel(isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isDesktop, int critical, int warning, int info) {
    final cards = [
      _SummaryCardData(
        count: critical,
        label: 'Critical Alerts',
        icon: Icons.warning_amber_rounded,
        bg: const Color(0xFFFBEAEA),
        border: const Color(0xFFF2B8B8),
        color: const Color(0xFFDC2626),
      ),
      _SummaryCardData(
        count: warning,
        label: 'Warning Alerts',
        icon: Icons.warning_amber_rounded,
        bg: const Color(0xFFF6F3C8),
        border: const Color(0xFFECD96E),
        color: const Color(0xFFD97706),
      ),
      _SummaryCardData(
        count: info,
        label: 'Info Alerts',
        icon: Icons.notifications_none_rounded,
        bg: const Color(0xFFDDE6F2),
        border: const Color(0xFFB7CCE8),
        color: const Color(0xFF2563EB),
      ),
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

  Widget _summaryCard(_SummaryCardData item) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: item.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.border),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: item.color, size: 24),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.count}',
                style: TextStyle(color: item.color, fontSize: 66 / 2, fontWeight: FontWeight.w500),
              ),
              Text(
                item.label,
                style: TextStyle(color: item.color, fontSize: 36 / 2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(int count) {
    return _panelWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            const Icon(Icons.filter_alt_outlined, color: Color(0xFF64748B), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Priority', style: TextStyle(color: _muted, fontSize: 15)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _priorityFilter,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'All Priorities', child: Text('All Priorities')),
                          DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                          DropdownMenuItem(value: 'Warning', child: Text('Warning')),
                          DropdownMenuItem(value: 'Info', child: Text('Info')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _priorityFilter = value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Type', style: TextStyle(color: _muted, fontSize: 15)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _typeFilter,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'All Types', child: Text('All Types')),
                          DropdownMenuItem(value: 'Oversupply', child: Text('Oversupply')),
                          DropdownMenuItem(value: 'Price', child: Text('Price')),
                          DropdownMenuItem(value: 'Storage', child: Text('Storage')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _typeFilter = value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$count alerts',
              style: const TextStyle(color: _muted, fontSize: 34 / 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(_AlertItem item) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: item.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: item.badgeBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.accent, size: 30 / 2),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(color: _text, fontSize: 44 / 2, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: item.badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.level,
                        style: TextStyle(color: item.accent, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(color: _muted, fontSize: 37 / 2, height: 1.35),
                ),
                const SizedBox(height: 8),
                Text(
                  item.location == null
                      ? 'Crop: ${item.crop}    ${item.dateLabel}'
                      : 'Crop: ${item.crop}    Location: ${item.location}    ${item.dateLabel}',
                  style: const TextStyle(color: _muted, fontSize: 34 / 2),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: _sidebarGreen,
                        minimumSize: const Size(120, 38),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Create Intervention', style: TextStyle(color: Colors.white)),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(108, 38),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('View Details', style: TextStyle(color: _text)),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(90, 38),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Dismiss', style: TextStyle(color: _text)),
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

  Widget _buildPreferencesPanel(bool isDesktop) {
    return _panelWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Preferences',
              style: TextStyle(color: _text, fontSize: 50 / 2, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _prefsColumn(
                      'Alert Channels',
                      [
                        _PrefRow('SMS Notifications', _smsNotif, (v) => setState(() => _smsNotif = v)),
                        _PrefRow('Email Notifications', _emailNotif, (v) => setState(() => _emailNotif = v)),
                        _PrefRow('In-App Notifications', _inAppNotif, (v) => setState(() => _inAppNotif = v)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _prefsColumn(
                      'Alert Types',
                      [
                        _PrefRow('Critical Alerts Only', _criticalOnly,
                            (v) => setState(() => _criticalOnly = v)),
                        _PrefRow('Warning Alerts', _warningAlerts,
                            (v) => setState(() => _warningAlerts = v)),
                        _PrefRow('Info Alerts', _infoAlerts, (v) => setState(() => _infoAlerts = v)),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              _prefsColumn(
                'Alert Channels',
                [
                  _PrefRow('SMS Notifications', _smsNotif, (v) => setState(() => _smsNotif = v)),
                  _PrefRow('Email Notifications', _emailNotif, (v) => setState(() => _emailNotif = v)),
                  _PrefRow('In-App Notifications', _inAppNotif, (v) => setState(() => _inAppNotif = v)),
                ],
              ),
              const SizedBox(height: 14),
              _prefsColumn(
                'Alert Types',
                [
                  _PrefRow('Critical Alerts Only', _criticalOnly,
                      (v) => setState(() => _criticalOnly = v)),
                  _PrefRow('Warning Alerts', _warningAlerts,
                      (v) => setState(() => _warningAlerts = v)),
                  _PrefRow('Info Alerts', _infoAlerts, (v) => setState(() => _infoAlerts = v)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _prefsColumn(String title, List<_PrefRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: _muted, fontSize: 40 / 2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...rows.map((row) {
          return SizedBox(
            height: 40,
            child: Row(
              children: [
                Checkbox(
                  value: row.value,
                  onChanged: (v) => row.onChanged(v ?? false),
                  activeColor: const Color(0xFF2563EB),
                ),
                Text(row.label, style: TextStyle(color: _text, fontSize: 39 / 2)),
              ],
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

class _AlertItem {
  final String level;
  final String title;
  final String description;
  final String crop;
  final String? location;
  final String dateLabel;
  final IconData icon;
  final Color accent;
  final Color cardBg;
  final Color border;
  final Color badgeBg;

  const _AlertItem({
    required this.level,
    required this.title,
    required this.description,
    required this.crop,
    required this.location,
    required this.dateLabel,
    required this.icon,
    required this.accent,
    required this.cardBg,
    required this.border,
    required this.badgeBg,
  });
}

class _SummaryCardData {
  final int count;
  final String label;
  final IconData icon;
  final Color bg;
  final Color border;
  final Color color;

  const _SummaryCardData({
    required this.count,
    required this.label,
    required this.icon,
    required this.bg,
    required this.border,
    required this.color,
  });
}

class _PrefRow {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrefRow(this.label, this.value, this.onChanged);
}

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem(this.label, this.icon);
}
