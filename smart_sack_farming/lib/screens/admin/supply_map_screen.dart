import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/agrisat_real_data.dart';
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

  static final List<String> _crops = kOfficialCropNames;

  static const List<String> _barangays = [
    'Abonan', 'Agcalaga', 'Agdao', 'Agdao Calinog', 'Aglalat', 'Agsuanu',
    'Ajuy', 'Alegria', 'Alimendras', 'Amatuan', 'Amulong', 'Anilao',
    'Aninihon', 'Añog', 'Arangaren', 'Arangel', 'Arao', 'Arapiles',
    'Arimbay', 'Asilo', 'Asuga', 'Atipulo', 'Bacao', 'Bacoor',
    'Bagacay', 'Bagacayan', 'Bagumbayan', 'Baguios', 'Balatong', 'Balilihan',
    'Baliwag', 'Baloctoc', 'Baloran', 'Baluarte', 'Balyuan', 'Bamban',
    'Banacoy', 'Banago', 'Banaoang', 'Bandera', 'Bangao', 'Bania',
    'Banisilan', 'Banuang Daan', 'Banyaga', 'Barangay Uno', 'Barbaza',
  ];

  bool _isLoading = true;
  String? _error;
  int _selectedNavIndex = 2;
  String _filterBarangay = 'All Barangays';
  _CropSummary? _selectedCrop;

  List<_CropSummary> _crops_ = <_CropSummary>[];

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
            .select('*');
      } catch (_) {
        productionRows = const <dynamic>[];
      }

      if (productionRows.isNotEmpty) {
        final productionByCrop = <String, double>{};
        final farmersByCrop = <String, int>{};
        final barangaysByCrop = <String, Set<String>>{};

        for (final row in List<Map<String, dynamic>>.from(productionRows)) {
          final barangay = _normalizeBarangay('Unknown');
          final crop = (row['crop_type'] ?? '').toString().trim();
          final yieldTons = _toDouble(row['yield_kg'] ?? 0) / 1000;

          if (yieldTons <= 0 || crop.isEmpty) continue;

          productionByCrop[crop] = (productionByCrop[crop] ?? 0) + yieldTons;
          barangaysByCrop.putIfAbsent(crop, () => <String>{});
          barangaysByCrop[crop]!.add(barangay);
          farmersByCrop[crop] = (farmersByCrop[crop] ?? 0) + 1;
        }

        var items = productionByCrop.entries
            .map((entry) {
              final crop = entry.key;
              final production = entry.value;
              final farmers = farmersByCrop[crop] ?? 0;
              final surplus = (production - (production * 0.34)).clamp(0.0, 99.0);
              final risk = surplus >= 20
                  ? _RiskLevel.high
                  : (surplus >= 10 ? _RiskLevel.medium : _RiskLevel.low);

              return _CropSummary(
                cropName: crop,
                totalProductionTons: production,
                farmers: farmers,
                surplusTons: surplus,
                risk: risk,
                barangays: barangaysByCrop[crop]?.toList() ?? const <String>[],
              );
            })
            .toList()
          ..sort((a, b) => b.totalProductionTons.compareTo(a.totalProductionTons));

        if (_filterBarangay != 'All Barangays') {
          items = items
              .where((item) => item.barangays.contains(_filterBarangay))
              .toList();
        }

        if (items.isNotEmpty) {
          _crops_ = items;
        }
      }

      // Also try loading from validated crop declarations
      List<dynamic> declarationRows = const <dynamic>[];
      try {
        declarationRows = await client
            .from('crop_declarations')
            .select('crop_name, estimated_volume_kg, area_planted_ha, barangay, farmer_name, expected_harvest_date, status')
            .in_('status', ['validated', 'harvested', 'approved', 'verified']);
      } catch (_) {
        declarationRows = const <dynamic>[];
      }

      // Merge declaration rows into _crops_ if production_reports was empty
      if (_crops_.isEmpty && declarationRows.isNotEmpty) {
        final productionByCrop = <String, double>{};
        final farmersByCrop = <String, int>{};
        final barangaysByCrop = <String, Set<String>>{};

        for (final row in List<Map<String, dynamic>>.from(declarationRows)) {
          var cropRaw = (row['crop_name'] ?? '').toString().trim();
          final cropKey = AgriSatData.cropKeyFromName(cropRaw);
          final crop = cropKey != null ? (kCropDisplayNames[cropKey] ?? cropRaw) : cropRaw;

          if (!kOfficialCropNames.contains(crop)) continue;

          final yieldTons = _toDouble(row['estimated_volume_kg'] ?? 0) / 1000;
          final barangay = _normalizeBarangay(row['barangay']);

          productionByCrop[crop] = (productionByCrop[crop] ?? 0) + yieldTons;
          barangaysByCrop.putIfAbsent(crop, () => <String>{});
          barangaysByCrop[crop]!.add(barangay);
          farmersByCrop[crop] = (farmersByCrop[crop] ?? 0) + 1;
        }

        var items = productionByCrop.entries.map((entry) {
          final crop = entry.key;
          final production = entry.value;
          final farmers = farmersByCrop[crop] ?? 0;
          final cropKey = kCropNameToKey[crop];
          final ppi = cropKey != null ? kPpiResults[cropKey]?.latestPPI ?? 0 : 0.0;
          final surplus = (production * (ppi < -15 ? 1.5 : ppi > 10 ? 0.3 : 0.8)).clamp(0.0, 99.0);
          final risk = ppi <= -25 ? _RiskLevel.high : ppi <= -10 ? _RiskLevel.medium : _RiskLevel.low;
          return _CropSummary(
            cropName: crop,
            totalProductionTons: production,
            farmers: farmers,
            surplusTons: surplus,
            risk: risk,
            barangays: barangaysByCrop[crop]?.toList() ?? const <String>[],
          );
        }).toList()..sort((a, b) => b.totalProductionTons.compareTo(a.totalProductionTons));

        _crops_ = items;
      }

      // Demo fallback: use real AgriSat 2025 data when both tables are empty
      if (_crops_.isEmpty) {
        _crops_ = kAgriSatCropKeys.map((key) {
          final totals = kAnnualTotals[key]!;
          final ppi = kPpiResults[key]!;
          final risk = ppi.alert == 'SEVERE' ? _RiskLevel.high
              : ppi.alert == 'CAUTION' ? _RiskLevel.medium : _RiskLevel.low;
          final surplus = ppi.latestPPI < -15
              ? totals.productionMT * 0.5
              : totals.productionMT * 0.1;
          return _CropSummary(
            cropName: kCropDisplayNames[key]!,
            totalProductionTons: totals.productionMT,
            farmers: totals.totalFarmers ~/ 12,
            surplusTons: surplus.clamp(0, 99),
            risk: risk,
            barangays: const ['Agboy-o', 'Agta', 'Alibunan', 'Alegria', 'Alobo'],
          );
        }).toList()
          ..sort((a, b) => b.totalProductionTons.compareTo(a.totalProductionTons));
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedCrop ??= _crops_.isNotEmpty ? _crops_.first : null;
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

  void _showSupplyDialog({_CropSummary? existing}) {
    final productionController = TextEditingController();
    final storageController = TextEditingController();
    final farmersController = TextEditingController();

    String selectedCrop = existing?.cropName ?? _crops.first;
    String selectedBarangay = existing?.barangays.firstOrNull ?? _barangays.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Supply' : 'Update Supply'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCrop,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Crop', border: OutlineInputBorder()),
                  items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() {
                        selectedCrop = v;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedBarangay,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Barangay', border: OutlineInputBorder()),
                  items: _barangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() {
                        selectedBarangay = v;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: productionController,
                  decoration: const InputDecoration(labelText: 'Production (kg)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: storageController,
                  decoration: const InputDecoration(labelText: 'Storage (kg)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: farmersController,
                  decoration: const InputDecoration(labelText: 'Farmers Count', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                productionController.dispose();
                storageController.dispose();
                farmersController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final production = _toDouble(productionController.text);
                if (production <= 0) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter valid production amount')),
                    );
                  }
                  return;
                }

                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User not authenticated')),
                    );
                  }
                  return;
                }

                try {
                  final now = DateTime.now();
                  await Supabase.instance.client.from('production_reports').insert({
                    'farmer_id': user.id,
                    'crop_type': selectedCrop,
                    'yield_kg': production,
                    'area_hectares': 0,
                    'planting_date': now.subtract(const Duration(days: 120)).toIso8601String().split('T').first,
                    'harvest_date': now.toIso8601String().split('T').first,
                    'quality_rating': 3,
                    'notes': 'Added via Supply Map',
                  });

                  // Save references before navigation
                  final nav = Navigator.of(context);
                  productionController.dispose();
                  storageController.dispose();
                  farmersController.dispose();
                  nav.pop();

                  if (mounted) {
                    await _loadData();
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Supply added successfully')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                        'Crop production and supply by barangay',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => _showSupplyDialog(),
                    style: FilledButton.styleFrom(
                      backgroundColor: _sidebarGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Supply'),
                  ),
                ],
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
                value: _filterBarangay,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: [
                  const DropdownMenuItem(value: 'All Barangays', child: Text('All Barangays')),
                  ..._barangays.map((b) => DropdownMenuItem(value: b, child: Text(b))),
                ],
                onChanged: (value) async {
                  if (value == null) return;
                  setState(() => _filterBarangay = value);
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
              'Crop Supply Overview',
              style: TextStyle(
                color: _text,
                fontSize: 20,
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
                    children: _crops_
                        .map((item) => _buildCropCard(item))
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
                          Text('Municipality: Tubungan',
                              style: TextStyle(fontSize: 16, color: _text)),
                          SizedBox(height: 8),
                          Text('Click a crop for details',
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

  Widget _buildCropCard(_CropSummary item) {
    final selected = _selectedCrop?.cropName == item.cropName;
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

    return InkWell(
      onTap: () => setState(() => _selectedCrop = item),
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
                const Icon(Icons.local_florist_outlined,
                    size: 20, color: Color(0xFF047857)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.cropName,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 14,
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
              'Prod: ${item.totalProductionTons.toStringAsFixed(1)}t',
              style: const TextStyle(color: Color(0xFF334155), fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text('Farmers: ${item.farmers}',
                style: const TextStyle(color: Color(0xFF334155), fontSize: 13)),
            Text(
              'Surplus: ${item.surplusTons.toStringAsFixed(1)}t',
              style: TextStyle(
                color: item.risk == _RiskLevel.high
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF334155),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPanel() {
    if (_selectedCrop == null) {
      return _cardWrap(
        child: const SizedBox(
          height: 500,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_florist_outlined, size: 70, color: Color(0xFFCBD5E1)),
                SizedBox(height: 12),
                Text(
                  'Select a crop to view\nbarangay breakdown',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 18, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item = _selectedCrop!;
    return _cardWrap(
      child: SizedBox(
        height: 500,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.cropName,
                style: const TextStyle(
                  color: _text,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _detailRow('Total Production', '${item.totalProductionTons.toStringAsFixed(1)} tons'),
              _detailRow('Farmers', '${item.farmers}'),
              _detailRow('Total Surplus', '${item.surplusTons.toStringAsFixed(1)} tons'),
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
                'Growing in Barangays',
                style: TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.barangays
                        .map(
                          (barangay) => Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(barangay,
                                style:
                                    const TextStyle(color: Color(0xFF334155), fontSize: 13)),
                          ),
                        )
                        .toList(),
                  ),
                ),
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
          Text(value, style: const TextStyle(color: _text, fontSize: 16)),
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
              'Crop Supply Summary',
              style: TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w700),
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
                        SizedBox(width: 190, child: _HeaderText('Crop')),
                        SizedBox(width: 200, child: _HeaderText('Production')),
                        SizedBox(width: 160, child: _HeaderText('Farmers')),
                        SizedBox(width: 170, child: _HeaderText('Surplus')),
                        SizedBox(width: 130, child: _HeaderText('Risk Level')),
                        SizedBox(width: 100, child: _HeaderText('Action')),
                      ],
                    ),
                  ),
                  Container(height: 1, color: _border),
                  ..._crops_.map((item) {
                    return Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: _border)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 190,
                            child: Text(item.cropName,
                                style: const TextStyle(color: _text, fontSize: 16)),
                          ),
                          SizedBox(
                            width: 200,
                            child: Text('${item.totalProductionTons.toStringAsFixed(1)} tons',
                                style: const TextStyle(color: _text, fontSize: 16)),
                          ),
                          SizedBox(
                            width: 160,
                            child: Text('${item.farmers}',
                                style: const TextStyle(color: _text, fontSize: 16)),
                          ),
                          SizedBox(
                            width: 170,
                            child: Text('${item.surplusTons.toStringAsFixed(1)} tons',
                                style: const TextStyle(color: _text, fontSize: 16)),
                          ),
                          SizedBox(width: 130, child: _riskChip(item.risk)),
                          SizedBox(
                            width: 100,
                            child: IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Color(0xFF1E40AF)),
                              onPressed: () => _showSupplyDialog(existing: item),
                            ),
                          ),
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

class _CropSummary {
  final String cropName;
  final double totalProductionTons;
  final int farmers;
  final double surplusTons;
  final _RiskLevel risk;
  final List<String> barangays;

  const _CropSummary({
    required this.cropName,
    required this.totalProductionTons,
    required this.farmers,
    required this.surplusTons,
    required this.risk,
    required this.barangays,
  });
}
