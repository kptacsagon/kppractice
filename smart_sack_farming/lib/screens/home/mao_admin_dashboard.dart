import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin/farmer_management_screen.dart';
import '../admin/intervention_management_screen.dart';
import '../admin/market_prices_screen.dart';
import '../admin/alerts_notifications_screen.dart';
import '../admin/reports_analytics_screen.dart';
import '../admin/supply_map_screen.dart';
import '../auth/login_screen.dart';
import '../features/financial_forecast_screen.dart';
import '../features/supply_chain_dashboard_screen.dart';
import '../features/verification_workflow_screen.dart';
import '../mao/agrisense_municipal_dashboard.dart';
import '../mao/agrisense_municipal_analytics_screen.dart';
import '../admin/agrisense_farm_verification_screen.dart';
import '../admin/agri_financial_mao_screen.dart';
import '../features/agri_econ_frds_screen.dart';
import '../saturation/saturation_heatmap_screen.dart';
import '../../services/crop_declaration_service.dart';
import '../../services/agrisat_market_service.dart';
import '../../data/tubungan_barangays.dart';
import '../features/buyer_demand_board_screen.dart';

class MaoAdminDashboard extends StatefulWidget {
  const MaoAdminDashboard({super.key});

  @override
  State<MaoAdminDashboard> createState() => _MaoAdminDashboardState();
}

class _MaoAdminDashboardState extends State<MaoAdminDashboard> {
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFD6DAE1);
  static const Color _text = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF4B5563);
  static const Color _sidebarGreen = Color(0xFF2E7D32);

  bool _isLoading = true;
  String? _loadError;
  int _selectedNavIndex = 0;

  int _totalCalamities = 0;
  double _totalYieldKg = 0;
  int _totalProjects = 0;
  int _totalEquipment = 0;
  int _totalFarmers = 0;
  int _pendingVerifications = 0;
  int _activeSubsidies = 0;
  double _totalPlantedAreaHa = 13.5;

  // Crop declarations (PRD §3.4)
  final _declSvc = CropDeclarationService();
  final _mktSvc = AgrisatMarketService();
  List<CropDeclaration> _validatedDeclarations = [];
  List<CropIndicators> _indicators = [];
  int _upcomingHarvests30d = 0;
  String? _declBarangayFilter;

  List<_TrendPoint> _supplyTrend = const [
    _TrendPoint('Jan', 40),
    _TrendPoint('Feb', 48),
    _TrendPoint('Mar', 58),
    _TrendPoint('Apr', 71),
    _TrendPoint('May', 77),
    _TrendPoint('Jun', 66),
  ];
  List<_TrendPoint> _demandTrend = const [
    _TrendPoint('Jan', 45),
    _TrendPoint('Feb', 52),
    _TrendPoint('Mar', 67),
    _TrendPoint('Apr', 86),
    _TrendPoint('May', 92),
    _TrendPoint('Jun', 78),
  ];
  List<_BarangayValue> _barangayProduction = const [
    _BarangayValue('Poblacion', 42),
    _BarangayValue('Santa Cruz', 38),
    _BarangayValue('San Rafael', 29),
    _BarangayValue('San Jose', 25),
    _BarangayValue('Mabini', 20),
  ];
  List<_HarvestWeekValue> _harvestCalendar = const [
    _HarvestWeekValue('Week 1', tomato: 0, cabbage: 0, lettuce: 8),
    _HarvestWeekValue('Week 2', tomato: 0, cabbage: 0, lettuce: 12),
    _HarvestWeekValue('Week 3', tomato: 0, cabbage: 0, lettuce: 18),
    _HarvestWeekValue('Week 4', tomato: 0, cabbage: 0, lettuce: 15),
  ];
  List<_AlertItem> _recentAlerts = const [
    _AlertItem(
      title: 'Market Oversupply Alert',
      detail: 'Cabbage surplus reaching 60 tons. Market price declining.',
      dateLabel: '4/27/2026, 9:15:00 AM',
      tone: _AlertTone.warning,
    ),
    _AlertItem(
      title: 'Price Drop Alert',
      detail: 'Farmgate price for Cabbage dropped 15% in the last 3 days.',
      dateLabel: '4/26/2026, 2:20:00 PM',
      tone: _AlertTone.warning,
    ),
    _AlertItem(
      title: 'Storage Capacity Warning',
      detail: 'Storage facilities at 85% capacity. Additional space needed.',
      dateLabel: '4/26/2026, 11:00:00 AM',
      tone: _AlertTone.info,
    ),
  ];
  List<_RiskRow> _riskRows = const [
    _RiskRow('Tomato', 0.85, 29.5, 16.2),
    _RiskRow('Cabbage', 0.78, 64.0, 36.5),
    _RiskRow('Lettuce', 0.42, 18.5, 13.0),
    _RiskRow('Eggplant', 0.25, 12.0, 11.5),
    _RiskRow('Pepper', 0.18, 8.5, 8.8),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<List<dynamic>> _safeQuery(Future<List<dynamic>> query) async {
    try {
      return await query;
    } catch (e) {
      debugPrint('Query failed: $e');
      return [];
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final client = Supabase.instance.client;
      final results = await Future.wait([
        _safeQuery(client.from('calamity_reports').select()),
        _safeQuery(client.from('production_reports').select()),
        _safeQuery(client.from('farming_projects').select()),
        _safeQuery(client.from('equipment').select()),
        _safeQuery(client.from('profiles').select()),
      ]);

      final calamities = results[0];
      final productions = results[1];
      final projects = results[2];
      final equipment = results[3];
      final allProfiles = results[4];
      final farmers = allProfiles
          .where((p) => (p['role'] ?? '').toString().toLowerCase() == 'farmer')
          .toList();

      _totalCalamities = calamities.length;
      _totalProjects = projects.length;
      _totalEquipment = equipment.length;
      _totalFarmers = farmers.length;

      _totalYieldKg = 0;
      for (final p in productions) {
        _totalYieldKg += _toDouble(p['yield_kg']);
      }

      _pendingVerifications =
          calamities.where((c) => (c['status'] ?? 'reported') == 'reported').length;

      // Count farm registrations forwarded by BAW and ready for MAO review
      try {
        final pendingFarms = await client
            .from('agrisense_farms')
            .select('id')
            .eq('verification_status', 'BAW Reviewed');
        _pendingVerifications += (pendingFarms as List).length;
      } catch (_) {}

      _totalPlantedAreaHa = 0;
      for (final project in projects) {
        _totalPlantedAreaHa += _toDouble(project['area_ha']) +
            _toDouble(project['area_hectares']) +
            _toDouble(project['land_size']) +
            _toDouble(project['farm_size']);
      }
      if (_totalPlantedAreaHa <= 0) {
        _totalPlantedAreaHa = 13.5;
      }

      try {
        final subsidyData = await client.from('subsidy_allocations').select();
        _activeSubsidies = (subsidyData as List)
            .where((s) => s['status'] != 'disbursed' && s['status'] != 'rejected')
            .length;
      } catch (_) {
        _activeSubsidies = 0;
      }

      _buildVisualDataFromProduction(productions);

      // Load validated crop declarations + market indicators
      try {
        final decls = await _declSvc.getValidatedDeclarations(barangay: _declBarangayFilter);
        _validatedDeclarations = decls;
        _upcomingHarvests30d = decls.where((d) {
          final days = d.expectedHarvestDate.difference(DateTime.now()).inDays;
          return days >= 0 && days <= 30;
        }).length;
        final reports = await _mktSvc.getAllHarvestReports();
        _indicators = reports.isEmpty ? _mktSvc.getMockIndicators() : _mktSvc.computeIndicators(reports);
      } catch (_) {
        _indicators = _mktSvc.getMockIndicators();
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _buildVisualDataFromProduction(List productions) {
    if (productions.isEmpty) {
      return;
    }

    final cropYieldKg = <String, double>{};
    final barangayYieldKg = <String, double>{};

    for (final row in productions) {
      final crop = (row['crop_type'] ?? 'Other').toString();
      final barangay = (row['barangay'] ?? row['address_barangay'] ?? 'Poblacion')
          .toString();
      final yieldKg = _toDouble(row['yield_kg']);

      cropYieldKg[crop] = (cropYieldKg[crop] ?? 0) + yieldKg;
      barangayYieldKg[barangay] = (barangayYieldKg[barangay] ?? 0) + yieldKg;
    }

    final topCrops = cropYieldKg.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (topCrops.isNotEmpty) {
      final baseRows = <_RiskRow>[];
      for (final entry in topCrops.take(5)) {
        final supplyTons = entry.value / 1000;
        final demandTons = supplyTons * 0.72;
        final risk = (supplyTons - demandTons) <= 0
            ? 0.18
            : ((supplyTons - demandTons) / supplyTons).clamp(0.12, 0.92);
        baseRows.add(_RiskRow(entry.key, risk, supplyTons, demandTons));
      }
      if (baseRows.isNotEmpty) {
        _riskRows = baseRows;
      }
    }

    final topBarangays = barangayYieldKg.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (topBarangays.isNotEmpty) {
      _barangayProduction = topBarangays
          .take(5)
          .map((e) => _BarangayValue(e.key, e.value / 1000))
          .toList();
    }

    final now = DateTime.now();
    final monthData = <_TrendPoint>[];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      double monthYieldTons = 0;
      for (final row in productions) {
        final dateStr = row['harvest_date'] ?? row['created_at'];
        final parsed = DateTime.tryParse(dateStr?.toString() ?? '');
        if (parsed != null && parsed.year == month.year && parsed.month == month.month) {
          monthYieldTons += _toDouble(row['yield_kg']) / 1000;
        }
      }
      monthData.add(_TrendPoint(_monthAbbr(month.month), monthYieldTons));
    }

    final hasMonthData = monthData.any((point) => point.value > 0);
    if (hasMonthData) {
      _supplyTrend = monthData
          .map((p) => _TrendPoint(p.label, (p.value * 0.88).clamp(10, 95)))
          .toList();
      _demandTrend = monthData
          .map((p) => _TrendPoint(p.label, (p.value * 1.03).clamp(12, 97)))
          .toList();
    }

    final riskRows = _riskRows;
    if (riskRows.isNotEmpty) {
      final topRisk = riskRows.first;
      _recentAlerts = [
        _AlertItem(
          title: 'Market Oversupply Alert',
          detail:
              '${topRisk.crop} surplus reaching ${topRisk.surplus.toStringAsFixed(1)} tons. Market price declining.',
          dateLabel: '4/27/2026, 9:15:00 AM',
          tone: _AlertTone.warning,
        ),
        _AlertItem(
          title: 'Price Drop Alert',
          detail:
              'Farmgate price for ${topRisk.crop} dropped 15% in the last 3 days.',
          dateLabel: '4/26/2026, 2:20:00 PM',
          tone: _AlertTone.warning,
        ),
        _AlertItem(
          title: 'Storage Capacity Warning',
          detail: 'Storage facilities at 85% capacity. Additional space needed.',
          dateLabel: '4/26/2026, 11:00:00 AM',
          tone: _AlertTone.info,
        ),
      ];
    }
  }

  String _monthAbbr(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[(month - 1) % 12];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        if (!isDesktop) {
          return Scaffold(
            backgroundColor: _bg,
            appBar: AppBar(
              title: const Text('Municipal Dashboard'),
              backgroundColor: Colors.white,
              foregroundColor: _text,
              elevation: 0,
            ),
            drawer: Drawer(
              child: _buildSidebar(),
            ),
            body: _buildMainContent(isDesktop: false),
          );
        }

        return Scaffold(
          backgroundColor: _bg,
          body: Row(
            children: [
              SizedBox(width: 305, child: _buildSidebar()),
              Expanded(child: _buildMainContent(isDesktop: true)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    final items = <_NavItem>[
      const _NavItem('Dashboard', Icons.grid_view_rounded),
      const _NavItem('Farmers', Icons.people_outline_rounded),
      const _NavItem('Supply Map', Icons.map_outlined),
      const _NavItem('Forecast', Icons.trending_up_rounded),
      const _NavItem('Market & Prices', Icons.shopping_cart_outlined),
      const _NavItem('Interventions', Icons.build_outlined),
      const _NavItem('Alerts', Icons.notifications_none_rounded),
      const _NavItem('Reports', Icons.description_outlined),
      const _NavItem('AgriSense', Icons.location_city_rounded),
      const _NavItem('Saturation Analytics', Icons.analytics_rounded),
      const _NavItem('Farm Verification', Icons.fact_check_rounded),
      const _NavItem('SRS Heat Map', Icons.map_rounded),
      const _NavItem('Financial Risk', Icons.account_balance_rounded),
      const _NavItem('AgriEcon-FRDS', Icons.account_tree_rounded),
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
                            fontSize: 39 / 2,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Intelligence System',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 24 / 2,
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
                            size: 28 / 2,
                            color: selected ? Colors.white : const Color(0xFF364152),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: selected ? Colors.white : const Color(0xFF1E293B),
                              fontSize: 36 / 2,
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
    switch (index) {
      case 0:
        return;
      case 1:
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FarmerManagementScreen()),
        );
        break;
      case 2:
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SupplyMapScreen()),
        );
        break;
      case 3:
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FinancialForecastScreen()),
        );
        break;
      case 4:
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MarketPricesScreen()),
        );
        break;
      case 5:
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InterventionManagementScreen()),
        );
        break;
      case 6:
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AlertsNotificationsScreen()),
        );
        break;
      case 7:
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ReportsAnalyticsScreen()),
        );
        break;
      case 8:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AgrisenseMunicipalDashboardScreen()),
        );
        setState(() => _selectedNavIndex = 0);
        break;
      case 9:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AgrisenseMunicipalAnalyticsScreen()),
        );
        setState(() => _selectedNavIndex = 0);
        break;
      case 10:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AgrisenseFarmVerificationScreen()),
        );
        setState(() => _selectedNavIndex = 0);
        break;
      case 11:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SaturationHeatmapScreen(adminView: true)),
        );
        setState(() => _selectedNavIndex = 0);
        break;
      case 12:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AgriFinancialMaoScreen()),
        );
        setState(() => _selectedNavIndex = 0);
        break;
      case 13:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AgriEconFrdsScreen()),
        );
        setState(() => _selectedNavIndex = 0);
        break;
      default:
        return;
    }
  }

  Widget _buildMainContent({required bool isDesktop}) {
    final cards = [
      _KpiCardData(
        title: 'Active\nFarmers',
        value: _totalFarmers > 0 ? '$_totalFarmers' : '5',
        suffix: '',
        subText: '+3 this\nmonth',
        icon: Icons.people_outline_rounded,
        valueColor: const Color(0xFF2E7D32),
        iconBg: const Color(0xFFE7F1E8),
      ),
      _KpiCardData(
        title: 'Area\nPlanted',
        value: _totalPlantedAreaHa.toStringAsFixed(1),
        suffix: '\nha',
        subText: '+0.8 ha',
        icon: Icons.eco_outlined,
        valueColor: const Color(0xFF1565C0),
        iconBg: const Color(0xFFE7EDF8),
      ),
      _KpiCardData(
        title: 'Estimated\nYield',
        value: (_totalYieldKg > 0 ? _totalYieldKg / 1000 : 77).toStringAsFixed(0),
        suffix: '\ntons',
        subText: '+12%',
        icon: Icons.inventory_2_outlined,
        valueColor: const Color(0xFF2E7D32),
        iconBg: const Color(0xFFE7F1E8),
      ),
      _KpiCardData(
        title: 'Oversupply\nRisk',
        value: '${(_overallRisk * 100).toStringAsFixed(0)}%',
        suffix: '',
        subText: 'High Alert',
        icon: Icons.warning_amber_rounded,
        valueColor: const Color(0xFFF59E0B),
        iconBg: const Color(0xFFFAF1E3),
      ),
      _KpiCardData(
        title: 'Crops at\nRisk',
        value: '$_cropsAtRisk',
        suffix: '',
        subText: 'Intervention\nneeded',
        icon: Icons.show_chart_rounded,
        valueColor: const Color(0xFFDC2626),
        iconBg: const Color(0xFFFBEAEA),
      ),
    ];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 22, isDesktop ? 24 : 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Municipal Dashboard',
                          style: TextStyle(
                            color: _text,
                            fontSize: 46 / 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Real-time agricultural supply monitoring',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 33 / 2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop)
                    IconButton(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout_rounded, color: _muted),
                      tooltip: 'Logout',
                    ),
                ],
              ),
              if (_loadError != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Load error: $_loadError',
                    style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: cards
                    .map((card) => SizedBox(
                          width: isDesktop ? 184 : (MediaQuery.of(context).size.width - 52) / 2,
                          child: _buildKpiCard(card),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),
              _buildFarmVerificationBanner(context),
              const SizedBox(height: 16),
              _buildCropDeclarationsPanel(),
              const SizedBox(height: 14),
              _buildIurPpiAlertPanel(),
              const SizedBox(height: 14),
              _buildBuyerDemandTile(),
              const SizedBox(height: 18),
              _responsiveRow(
                isDesktop: isDesktop,
                left: _panel(
                  title: 'Supply vs Demand Trend',
                  child: _buildSupplyDemandChart(),
                ),
                right: _panel(
                  title: 'Production by Barangay',
                  child: _buildBarangayBarChart(),
                ),
              ),
              const SizedBox(height: 16),
              _responsiveRow(
                isDesktop: isDesktop,
                left: _panel(
                  title: 'Harvest Calendar (May 2026)',
                  child: _buildHarvestChart(),
                ),
                right: _panel(
                  title: 'Recent Alerts',
                  child: _buildAlertsList(),
                ),
              ),
              const SizedBox(height: 16),
              _panel(
                title: 'Oversupply Risk by Crop',
                child: _buildRiskTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _responsiveRow({
    required bool isDesktop,
    required Widget left,
    required Widget right,
  }) {
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

  Widget _buildFarmVerificationBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgrisenseFarmVerificationScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _pendingVerifications > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _pendingVerifications > 0 ? const Color(0xFFF59E0B) : const Color(0xFF86EFAC),
          ),
        ),
        child: Row(children: [
          Icon(
            Icons.fact_check_rounded,
            color: _pendingVerifications > 0 ? const Color(0xFFF59E0B) : const Color(0xFF16A34A),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _pendingVerifications > 0
                    ? '$_pendingVerifications Farm${_pendingVerifications > 1 ? 's' : ''} Pending Verification'
                    : 'All Farms Verified',
                style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13,
                  color: _pendingVerifications > 0 ? const Color(0xFF92400E) : const Color(0xFF166534),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _pendingVerifications > 0
                    ? 'Tap to review and approve farm submissions.'
                    : 'No pending farm verifications at this time.',
                style: TextStyle(
                  fontSize: 11,
                  color: _pendingVerifications > 0 ? const Color(0xFF78350F) : const Color(0xFF166534),
                ),
              ),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
        ]),
      ),
    );
  }

  Widget _buildKpiCard(_KpiCardData data) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 19 / 2,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: data.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.valueColor, size: 28 / 2),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${data.value}${data.suffix}',
            style: TextStyle(
              color: data.valueColor,
              fontSize: 66 / 2,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.subText,
            style: TextStyle(
              color: data.valueColor,
              fontSize: 17 / 2,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // PRD §6.3 — IUR Tracking Board + PPI Alert Panel
  Widget _buildIurPpiAlertPanel() {
    final danger = _indicators.where((i) => i.overall == SaturationLevel.danger).toList();
    final caution = _indicators.where((i) => i.overall == SaturationLevel.caution).toList();
    if (_indicators.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: danger.isNotEmpty ? const Color(0xFFFCA5A5) : _border),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.warning_amber_rounded, size: 18,
            color: danger.isNotEmpty ? const Color(0xFFDC2626) : const Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          const Expanded(child: Text('MAR / PPI / IUR Alert Panel',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _text))),
          if (danger.isNotEmpty) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
            child: Text('${danger.length} danger', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C))),
          ),
        ]),
        const SizedBox(height: 12),
        ..._indicators.map((ind) {
          final color = ind.overall == SaturationLevel.danger
            ? const Color(0xFFDC2626)
            : ind.overall == SaturationLevel.caution
              ? const Color(0xFFF59E0B)
              : const Color(0xFF16A34A);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withAlpha(40)),
            ),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(ind.cropName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              Text('MAR ${(ind.mar * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('PPI ${ind.ppi.toStringAsFixed(1)}%', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('IUR ${(ind.iur * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildBuyerDemandTile() => InkWell(
    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BuyerDemandBoardScreen(maoMode: true))),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.storefront_rounded, color: Color(0xFFEA8A1A), size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Buyer Demand Board', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
          SizedBox(height: 2),
          Text('Post & manage institutional buyer demand requests (LGU canteens, cooperatives, processors)',
            style: TextStyle(fontSize: 11, color: _muted)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: _muted),
      ]),
    ),
  );

  // PRD §3.4 — MAO sees validated crop declarations from AT/BAW
  Widget _buildCropDeclarationsPanel() {
    if (_validatedDeclarations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: const Row(children: [
          Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 20),
          SizedBox(width: 10),
          Text('No validated crop declarations yet. BAW/AT validation sends data here.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
        ]),
      );
    }

    final upcoming = _validatedDeclarations.where((d) {
      final days = d.expectedHarvestDate.difference(DateTime.now()).inDays;
      return days >= 0 && days <= 30;
    }).toList()..sort((a, b) => a.expectedHarvestDate.compareTo(b.expectedHarvestDate));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 18),
          const SizedBox(width: 8),
          const Expanded(child: Text('Active Crop Declarations',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _text))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFE7F1E8), borderRadius: BorderRadius.circular(8)),
            child: Text('${_validatedDeclarations.length} validated',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
          ),
          if (_upcomingHarvests30d > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
              child: Text('$_upcomingHarvests30d harvest in 30d',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
            ),
          ],
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _declBarangayFilter,
          decoration: InputDecoration(
            labelText: 'Filter by Barangay',
            prefixIcon: const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF2E7D32)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            isDense: true,
          ),
          isExpanded: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('All Barangays')),
            ...kTubunganBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))),
          ],
          onChanged: (v) { setState(() => _declBarangayFilter = v); _loadDashboardData(); },
        ),
        const SizedBox(height: 14),
        // KPI strip
        Row(children: [
          _declKpi('Total Active', '${_validatedDeclarations.length}', const Color(0xFF2E7D32)),
          _declKpi('Est. Volume', '${_validatedDeclarations.fold(0.0, (s, d) => s + d.estimatedVolumeKg).toStringAsFixed(0)} kg', const Color(0xFF1565C0)),
          _declKpi('Harvest 30d', '$_upcomingHarvests30d', const Color(0xFFF59E0B)),
          _declKpi('Crops', '${_validatedDeclarations.map((d) => d.cropId).toSet().length}', const Color(0xFF7C3AED)),
        ]),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Upcoming Harvests (next 30 days)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
          const SizedBox(height: 8),
          ...upcoming.take(5).map((d) {
            final days = d.expectedHarvestDate.difference(DateTime.now()).inDays;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(width: 4, height: 36, color: days <= 7 ? const Color(0xFFDC2626) : const Color(0xFFF59E0B)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${d.cropName} — ${d.farmerName}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('${d.estimatedVolumeKg.toStringAsFixed(0)} kg · ${d.barangay ?? "—"}',
                    style: const TextStyle(fontSize: 11, color: _muted)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${d.expectedHarvestDate.day}/${d.expectedHarvestDate.month}/${d.expectedHarvestDate.year}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  Text('in ${days}d', style: TextStyle(fontSize: 10,
                    color: days <= 7 ? const Color(0xFFDC2626) : const Color(0xFF6B7280))),
                ]),
              ]),
            );
          }),
          if (upcoming.length > 5)
            Text('+ ${upcoming.length - 5} more upcoming harvests',
              style: const TextStyle(fontSize: 12, color: _muted)),
        ],
      ]),
    );
  }

  Widget _declKpi(String label, String value, Color color) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: _muted)),
    ]));
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
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
          Text(
            title,
            style: const TextStyle(
              color: _text,
              fontSize: 50 / 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildSupplyDemandChart() {
    final maxY = [..._supplyTrend, ..._demandTrend]
            .map((e) => e.value)
            .fold<double>(0, (p, c) => p > c ? p : c) +
        8;

    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
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
                      interval: 1,
                      reservedSize: 34,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= _supplyTrend.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _supplyTrend[index].label,
                            style: const TextStyle(fontSize: 16, color: _muted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _supplyTrend
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                        .toList(),
                    isCurved: true,
                    barWidth: 3,
                    color: const Color(0xFFF59E0B),
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: _demandTrend
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                        .toList(),
                    isCurved: true,
                    barWidth: 3,
                    color: const Color(0xFF1D4ED8),
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: Color(0xFFF59E0B), label: 'Supply (tons)'),
              SizedBox(width: 14),
              _LegendDot(color: Color(0xFF1D4ED8), label: 'Demand (tons)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarangayBarChart() {
    final maxY = _barangayProduction
            .map((e) => e.value)
            .fold<double>(0, (p, c) => p > c ? p : c) +
        10;

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          maxY: maxY,
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
                  final index = value.toInt();
                  if (index < 0 || index >= _barangayProduction.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _barangayProduction[index].label,
                      style: const TextStyle(fontSize: 16, color: _muted),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: _barangayProduction
              .asMap()
              .entries
              .map((entry) => BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        width: 26,
                        color: const Color(0xFF2E7D32),
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(2)),
                      ),
                    ],
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildHarvestChart() {
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: 28,
                alignment: BarChartAlignment.spaceAround,
                groupsSpace: 16,
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
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 7,
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
                        final index = value.toInt();
                        if (index < 0 || index >= _harvestCalendar.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _harvestCalendar[index].week,
                            style: const TextStyle(fontSize: 16, color: _muted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: _harvestCalendar
                    .asMap()
                    .entries
                    .map(
                      (entry) => BarChartGroupData(
                        x: entry.key,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.tomato,
                            color: const Color(0xFFDC2626),
                            width: 12,
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(2)),
                          ),
                          BarChartRodData(
                            toY: entry.value.cabbage,
                            color: const Color(0xFF2E7D32),
                            width: 12,
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(2)),
                          ),
                          BarChartRodData(
                            toY: entry.value.lettuce,
                            color: const Color(0xFF1565C0),
                            width: 12,
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(2)),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: Color(0xFFDC2626), label: 'Tomato'),
              SizedBox(width: 12),
              _LegendDot(color: Color(0xFF2E7D32), label: 'Cabbage'),
              SizedBox(width: 12),
              _LegendDot(color: Color(0xFF1565C0), label: 'Lettuce'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return SizedBox(
      height: 300,
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView.separated(
          primary: true,
          itemCount: _recentAlerts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final alert = _recentAlerts[index];
            late final Color bg;
            late final Color side;
            late final IconData icon;

            switch (alert.tone) {
              case _AlertTone.warning:
                bg = const Color(0xFFF5F1D8);
                side = const Color(0xFFEAB308);
                icon = Icons.warning_amber_rounded;
                break;
              case _AlertTone.info:
                bg = const Color(0xFFDDE6F2);
                side = const Color(0xFF3B82F6);
                icon = Icons.error_outline_rounded;
                break;
            }

            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border(left: BorderSide(color: side, width: 4)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 33 / 2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(icon, color: side, size: 22),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alert.detail,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 30 / 2,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alert.dateLabel,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 27 / 2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRiskTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 980),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  SizedBox(width: 135, child: _HeaderCell('Crop')),
                  SizedBox(width: 235, child: _HeaderCell('Risk Level')),
                  SizedBox(width: 205, child: _HeaderCell('Supply Volume')),
                  SizedBox(width: 140, child: _HeaderCell('Demand')),
                  SizedBox(width: 140, child: _HeaderCell('Surplus')),
                  SizedBox(width: 130, child: _HeaderCell('Status')),
                ],
              ),
            ),
            Container(height: 1, color: _border),
            ..._riskRows.asMap().entries.map((entry) {
              final row = entry.value;
              final highlighted = entry.key == 3;
              return Container(
                color: highlighted ? const Color(0xFFF3F4F6) : Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 135,
                        child: Text(
                          row.crop,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 38 / 2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 235, child: _buildRiskBar(row.risk)),
                      SizedBox(
                        width: 205,
                        child: Text(
                          '${row.supply.toStringAsFixed(1)} tons',
                          style: const TextStyle(color: _text, fontSize: 36 / 2),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text(
                          '${row.demand.toStringAsFixed(1)} tons',
                          style: const TextStyle(color: _text, fontSize: 36 / 2),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text(
                          '${row.surplus.toStringAsFixed(1)} tons',
                          style: const TextStyle(color: _text, fontSize: 36 / 2),
                        ),
                      ),
                      SizedBox(width: 130, child: _buildStatusChip(row.risk)),
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

  Widget _buildRiskBar(double risk) {
    final color = _riskColor(risk);
    return Row(
      children: [
        Container(
          width: 120,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 120 * risk,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${(risk * 100).toStringAsFixed(0)}%',
          style: const TextStyle(color: _text, fontSize: 34 / 2),
        ),
      ],
    );
  }

  Widget _buildStatusChip(double risk) {
    final label = _riskLabel(risk);
    late final Color bg;
    late final Color fg;
    if (label == 'Critical') {
      bg = const Color(0xFFF3D9DC);
      fg = const Color(0xFFB91C1C);
    } else if (label == 'Warning') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
    } else {
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF047857);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 30 / 2,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _riskColor(double risk) {
    if (risk >= 0.7) return const Color(0xFFFC2E3F);
    if (risk >= 0.4) return const Color(0xFFEBAA00);
    return const Color(0xFF1DB954);
  }

  String _riskLabel(double risk) {
    if (risk >= 0.7) return 'Critical';
    if (risk >= 0.4) return 'Warning';
    return 'Normal';
  }

  double get _overallRisk {
    if (_riskRows.isEmpty) return 0.50;
    return _riskRows.map((row) => row.risk).reduce((a, b) => a > b ? a : b);
  }

  int get _cropsAtRisk => _riskRows.where((row) => row.risk >= 0.4).length;

  void _logout(BuildContext context) {
    Supabase.instance.client.auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;

  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF020617),
        fontSize: 38 / 2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 34 / 2,
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

class _KpiCardData {
  final String title;
  final String value;
  final String suffix;
  final String subText;
  final IconData icon;
  final Color valueColor;
  final Color iconBg;

  const _KpiCardData({
    required this.title,
    required this.value,
    required this.suffix,
    required this.subText,
    required this.icon,
    required this.valueColor,
    required this.iconBg,
  });
}

class _TrendPoint {
  final String label;
  final double value;

  const _TrendPoint(this.label, this.value);
}

class _BarangayValue {
  final String label;
  final double value;

  const _BarangayValue(this.label, this.value);
}

class _HarvestWeekValue {
  final String week;
  final double tomato;
  final double cabbage;
  final double lettuce;

  const _HarvestWeekValue(
    this.week, {
    required this.tomato,
    required this.cabbage,
    required this.lettuce,
  });
}

enum _AlertTone { warning, info }

class _AlertItem {
  final String title;
  final String detail;
  final String dateLabel;
  final _AlertTone tone;

  const _AlertItem({
    required this.title,
    required this.detail,
    required this.dateLabel,
    required this.tone,
  });
}

class _RiskRow {
  final String crop;
  final double risk;
  final double supply;
  final double demand;

  const _RiskRow(this.crop, this.risk, this.supply, this.demand);

  double get surplus => supply - demand;
}
