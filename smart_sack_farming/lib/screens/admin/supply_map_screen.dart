import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'alerts_notifications_screen.dart';
import 'reports_analytics_screen.dart';
import '../features/financial_forecast_screen.dart';
import 'farmer_management_screen.dart';
import 'intervention_management_screen.dart';
import 'market_prices_screen.dart';
import '../home/mao_admin_dashboard.dart';

class SupplyMapScreen extends StatefulWidget {
  const SupplyMapScreen({super.key});

  @override
  State<SupplyMapScreen> createState() => _SupplyMapScreenState();
}

class _SupplyMapScreenState extends State<SupplyMapScreen> {
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFD6DAE1);
  static const Color _text = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF4B5563);
  static const Color _sidebarGreen = Color(0xFF2E7D32);

  bool _isLoading = true;
  String? _error;
  int _selectedNavIndex = 2;
  String _selectedCrop = 'All Crops';
  _BarangaySummary? _selectedBarangay;

  List<_BarangaySummary> _barangays = const <_BarangaySummary>[
    _BarangaySummary(
      name: 'Poblacion',
      productionTons: 42.5,
      farmers: 2,
      storageKg: 1700,
      risk: _RiskLevel.high,
    ),
    _BarangaySummary(
      name: 'San Isidro',
      productionTons: 38.2,
      farmers: 2,
      storageKg: 1400,
      risk: _RiskLevel.medium,
    ),
    _BarangaySummary(
      name: 'Santa Cruz',
      productionTons: 28.8,
      farmers: 1,
      storageKg: 300,
      risk: _RiskLevel.low,
    ),
    _BarangaySummary(
      name: 'San Miguel',
      productionTons: 25.3,
      farmers: 0,
      storageKg: 0,
      risk: _RiskLevel.low,
    ),
    _BarangaySummary(
      name: 'San Rafael',
      productionTons: 19.7,
      farmers: 0,
      storageKg: 0,
      risk: _RiskLevel.low,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;

      List<dynamic> productionRows = const <dynamic>[];
      try {
        productionRows = await client
            .from('production_reports')
            .select('barangay, address_barangay, crop_type, yield_kg, created_at');
      } catch (_) {
        productionRows = const <dynamic>[];
      }

      List<dynamic> farmerRows = const <dynamic>[];
      try {
        farmerRows = await client
            .from('profiles')
            .select('id, address')
            .eq('role', 'farmer');
      } catch (_) {
        farmerRows = const <dynamic>[];
      }

      if (productionRows.isNotEmpty || farmerRows.isNotEmpty) {
        final productionByBarangay = <String, double>{};
        final cropsByBarangay = <String, Set<String>>{};
        final farmersByBarangay = <String, int>{};

        for (final row in List<Map<String, dynamic>>.from(productionRows)) {
          final barangay = _normalizeBarangay(
            row['barangay'] ?? row['address_barangay'] ?? 'Unknown',
          );
          final crop = (row['crop_type'] ?? '').toString().trim();
          final yieldTons = _toDouble(row['yield_kg']) / 1000;

          if (yieldTons <= 0) continue;

          productionByBarangay[barangay] =
              (productionByBarangay[barangay] ?? 0) + yieldTons;
          cropsByBarangay.putIfAbsent(barangay, () => <String>{});
          if (crop.isNotEmpty) {
            cropsByBarangay[barangay]!.add(crop);
          }
        }

        for (final row in List<Map<String, dynamic>>.from(farmerRows)) {
          final barangay = _normalizeBarangay(row['address'] ?? 'Unknown');
          farmersByBarangay[barangay] = (farmersByBarangay[barangay] ?? 0) + 1;
        }

        var items = productionByBarangay.entries
            .map((entry) {
              final production = entry.value;
              final farmers = farmersByBarangay[entry.key] ?? 0;
              final surplus = (production - (production * 0.34)).clamp(0.0, 99.0);
              final risk = surplus >= 20
                  ? _RiskLevel.high
                  : (surplus >= 10 ? _RiskLevel.medium : _RiskLevel.low);

              return _BarangaySummary(
                name: entry.key,
                productionTons: production,
                farmers: farmers,
                storageKg: risk == _RiskLevel.high
                    ? 1700
                    : (risk == _RiskLevel.medium ? 1400 : 300),
                risk: risk,
                crops: cropsByBarangay[entry.key]?.toList() ?? const <String>[],
              );
            })
            .toList()
          ..sort((a, b) => b.productionTons.compareTo(a.productionTons));

        if (_selectedCrop != 'All Crops') {
          items = items
              .where(
                (item) => item.crops.any(
                  (crop) => crop.toLowerCase() == _selectedCrop.toLowerCase(),
                ),
              )
              .toList();
        }

        if (items.isNotEmpty) {
          _barangays = items.take(5).toList();
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedBarangay ??= _barangays.isNotEmpty ? _barangays.first : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load supply map data: $e';
        });
      }
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _normalizeBarangay(dynamic raw) {
    final value = (raw ?? '').toString().trim();
    if (value.isEmpty) return 'Unknown';
    final words = value.split(RegExp(r'\s+'));
    return words
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
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
              title: const Text('Supply Map'),
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
                          Icon(item.icon,
                              size: 14,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF364152)),
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

    if (index == 2) return;
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
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 22, isDesktop ? 24 : 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Supply Map',
                style: TextStyle(
                  color: _text,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Geographic distribution of production and supply risk',
                style: TextStyle(
                  color: _muted,
                  fontSize: 34 / 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              _buildTopFilterCard(),
              const SizedBox(height: 16),
              if (_isLoading)
                const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
                )
              else
                _buildMapSection(isDesktop),
              const SizedBox(height: 16),
              _buildSummaryTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopFilterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCrop,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: const [
                  DropdownMenuItem(value: 'All Crops', child: Text('All Crops')),
                  DropdownMenuItem(value: 'Tomato', child: Text('Tomato')),
                  DropdownMenuItem(value: 'Cabbage', child: Text('Cabbage')),
                  DropdownMenuItem(value: 'Lettuce', child: Text('Lettuce')),
                  DropdownMenuItem(value: 'Eggplant', child: Text('Eggplant')),
                ],
                onChanged: (value) async {
                  if (value == null) return;
                  setState(() => _selectedCrop = value);
                  await _loadData();
                },
              ),
            ),
          ),
          const Spacer(),
          const _RiskLegend(color: Color(0xFF22C55E), label: 'Low Risk'),
          const SizedBox(width: 18),
          const _RiskLegend(color: Color(0xFFEAB308), label: 'Medium Risk'),
          const SizedBox(width: 18),
          const _RiskLegend(color: Color(0xFFFC2E3F), label: 'High Risk'),
        ],
      ),
    );
  }

  Widget _buildMapSection(bool isDesktop) {
    if (!isDesktop) {
      return Column(
        children: [
          _buildOverviewPanel(),
          const SizedBox(height: 16),
          _buildDetailPanel(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildOverviewPanel()),
        const SizedBox(width: 16),
        Expanded(child: _buildDetailPanel()),
      ],
    );
  }

  Widget _buildOverviewPanel() {
    return _cardWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Barangay Supply Overview',
              style: TextStyle(
                color: _text,
                fontSize: 40 / 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: _barangays
                        .map((item) => _buildBarangayCard(item))
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 210,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Municipality: San Juan',
                              style: TextStyle(fontSize: 16, color: _text)),
                          SizedBox(height: 8),
                          Text('Click a barangay for details',
                              style: TextStyle(fontSize: 16, color: Color(0xFF1E40AF))),
                        ],
                      ),
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

  Widget _buildBarangayCard(_BarangaySummary item) {
    final selected = _selectedBarangay?.name == item.name;
    final bg = switch (item.risk) {
      _RiskLevel.high => const Color(0xFFF8DDDD),
      _RiskLevel.medium => const Color(0xFFF3ECBE),
      _RiskLevel.low => const Color(0xFFD0F2DF),
    };
    final dot = switch (item.risk) {
      _RiskLevel.high => const Color(0xFFFC2E3F),
      _RiskLevel.medium => const Color(0xFFEBAA00),
      _RiskLevel.low => const Color(0xFF0CCB5A),
    };

    final surplus = item.surplusTons;

    return InkWell(
      onTap: () => setState(() => _selectedBarangay = item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 155,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF1E40AF) : const Color(0xFFCBD5E1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 20, color: Color(0xFF047857)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Production:${item.productionTons.toStringAsFixed(1)}\n tons',
              style: const TextStyle(color: Color(0xFF334155), fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text('Farmers:      ${item.farmers}',
                style: const TextStyle(color: Color(0xFF334155), fontSize: 16)),
            Text(
              'Surplus:   ${surplus.toStringAsFixed(1)} tons',
              style: TextStyle(
                color: item.risk == _RiskLevel.high
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF334155),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPanel() {
    if (_selectedBarangay == null) {
      return _cardWrap(
        child: const SizedBox(
          height: 500,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined, size: 70, color: Color(0xFFCBD5E1)),
                SizedBox(height: 12),
                Text(
                  'Select a barangay to view\ndetails',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 18, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item = _selectedBarangay!;
    return _cardWrap(
      child: SizedBox(
        height: 500,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  color: _text,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _detailRow('Production', '${item.productionTons.toStringAsFixed(1)} tons'),
              _detailRow('Farmers', '${item.farmers}'),
              _detailRow('Surplus', '${item.surplusTons.toStringAsFixed(1)} tons'),
              _detailRow('Storage', '${item.storageKg} kg'),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Risk Level:', style: TextStyle(color: _muted, fontSize: 16)),
                  const SizedBox(width: 8),
                  _riskChip(item.risk),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Crop Presence',
                style: TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (item.crops.isEmpty ? ['Tomato', 'Cabbage'] : item.crops)
                    .map(
                      (crop) => Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(crop,
                            style:
                                const TextStyle(color: Color(0xFF334155), fontSize: 14)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(color: _muted, fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          Text(value, style: TextStyle(color: _text, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSummaryTable() {
    return _cardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Text(
              'Barangay Summary',
              style: TextStyle(color: _text, fontSize: 40 / 2, fontWeight: FontWeight.w700),
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
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        SizedBox(width: 190, child: _HeaderText('Barangay')),
                        SizedBox(width: 200, child: _HeaderText('Production')),
                        SizedBox(width: 160, child: _HeaderText('Farmers')),
                        SizedBox(width: 170, child: _HeaderText('Surplus')),
                        SizedBox(width: 155, child: _HeaderText('Storage')),
                        SizedBox(width: 130, child: _HeaderText('Risk Level')),
                      ],
                    ),
                  ),
                  Container(height: 1, color: _border),
                  ..._barangays.map((item) {
                    return Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: _border)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 190,
                            child: Text(item.name,
                                style: TextStyle(color: _text, fontSize: 33 / 2)),
                          ),
                          SizedBox(
                            width: 200,
                            child: Text('${item.productionTons.toStringAsFixed(1)} tons',
                                style: TextStyle(color: _text, fontSize: 33 / 2)),
                          ),
                          SizedBox(
                            width: 160,
                            child: Text('${item.farmers}',
                                style: TextStyle(color: _text, fontSize: 33 / 2)),
                          ),
                          SizedBox(
                            width: 170,
                            child: Text('${item.surplusTons.toStringAsFixed(1)} tons',
                                style: TextStyle(color: _text, fontSize: 33 / 2)),
                          ),
                          SizedBox(
                            width: 155,
                            child: Text('${item.storageKg} kg',
                                style: TextStyle(color: _text, fontSize: 33 / 2)),
                          ),
                          SizedBox(width: 130, child: _riskChip(item.risk)),
                        ],
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

  Widget _riskChip(_RiskLevel risk) {
    final label = switch (risk) {
      _RiskLevel.high => 'HIGH',
      _RiskLevel.medium => 'MEDIUM',
      _RiskLevel.low => 'LOW',
    };
    final bg = switch (risk) {
      _RiskLevel.high => const Color(0xFFF3D9DC),
      _RiskLevel.medium => const Color(0xFFF3E9AE),
      _RiskLevel.low => const Color(0xFFD1FAE5),
    };
    final fg = switch (risk) {
      _RiskLevel.high => const Color(0xFFDC2626),
      _RiskLevel.medium => const Color(0xFFA16207),
      _RiskLevel.low => const Color(0xFF047857),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _cardWrap({required Widget child}) {
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

class _RiskLegend extends StatelessWidget {
  final Color color;
  final String label;
  final Color textColor;

  const _RiskLegend({required this.color, required this.label, this.textColor = const Color(0xFF0F172A)});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: textColor, fontSize: 16)),
      ],
    );
  }
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

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem(this.label, this.icon);
}

enum _RiskLevel { low, medium, high }

class _BarangaySummary {
  final String name;
  final double productionTons;
  final int farmers;
  final int storageKg;
  final _RiskLevel risk;
  final List<String> crops;

  const _BarangaySummary({
    required this.name,
    required this.productionTons,
    required this.farmers,
    required this.storageKg,
    required this.risk,
    this.crops = const <String>[],
  });

  double get surplusTons => (productionTons * 0.66).clamp(0, productionTons);
}
