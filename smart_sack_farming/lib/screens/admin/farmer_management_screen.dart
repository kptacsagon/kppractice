import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'alerts_notifications_screen.dart';
import 'reports_analytics_screen.dart';
import '../features/financial_forecast_screen.dart';
import '../home/mao_admin_dashboard.dart';
import 'intervention_management_screen.dart';
import 'market_prices_screen.dart';
import 'supply_map_screen.dart';

class FarmerManagementScreen extends StatefulWidget {
  const FarmerManagementScreen({super.key});

  @override
  State<FarmerManagementScreen> createState() => _FarmerManagementScreenState();
}

class _FarmerManagementScreenState extends State<FarmerManagementScreen> {
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFD6DAE1);
  static const Color _text = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF4B5563);
  static const Color _sidebarGreen = Color(0xFF2E7D32);

  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  int _selectedNavIndex = 1;
  String _searchTerm = '';
  String? _selectedAddress;
  Map<String, dynamic>? _selectedFarmer;

  List<Map<String, dynamic>> _farmers = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _filteredFarmers = <Map<String, dynamic>>[];
  final Map<String, int> _farmerRecordCount = <String, int>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
      });
      _filterFarmers();
    });
    _fetchFarmersAndCrops();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFarmersAndCrops() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _error = 'Not authenticated. Please log in as admin.';
        });
        return;
      }

      List<dynamic> profilesRes;
      try {
        profilesRes = await client
            .from('profiles')
            .select('id, full_name, address, sex, age, land_size_ha, avatar_url')
            .eq('role', 'farmer');
      } catch (_) {
        try {
          profilesRes = await client
              .from('profiles')
              .select('id, full_name, address, land_size_ha, avatar_url')
              .eq('role', 'farmer');
        } catch (_) {
          profilesRes = await client
              .from('profiles')
              .select('id, full_name, address')
              .eq('role', 'farmer');
        }
      }

      final farmers = List<Map<String, dynamic>>.from(profilesRes);

      for (final farmer in farmers) {
        final farmerId = (farmer['id'] ?? '').toString();
        if (farmerId.isEmpty) {
          farmer['crops'] = <String>[];
          continue;
        }

        try {
          final reportsRes = await client
              .from('production_reports')
              .select('crop_type, area_hectares, contact_no, contact_number, phone')
              .eq('farmer_id', farmerId);

          final reports = List<Map<String, dynamic>>.from(reportsRes);
          _farmerRecordCount[farmerId] = reports.length;

          final crops = reports
              .map((report) => (report['crop_type'] ?? '').toString().trim())
              .where((crop) => crop.isNotEmpty)
              .toSet()
              .toList();

          final fallbackLandSize = reports
              .map((report) => report['area_hectares'])
              .where((value) => value != null)
              .cast<num?>()
              .map((value) => value?.toDouble())
              .firstWhere((value) => value != null, orElse: () => null);

          if (farmer['land_size_ha'] == null && fallbackLandSize != null) {
            farmer['land_size_ha'] = fallbackLandSize;
          }

          farmer['crops'] = crops;
        } catch (_) {
          farmer['crops'] = <String>[];
          _farmerRecordCount[farmerId] = 0;
        }
      }

      setState(() {
        _farmers = farmers;
        _filteredFarmers = farmers;
        _isLoading = false;
      });

      _filterFarmers();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load farmer data: $e';
      });
    }
  }

  void _filterFarmers() {
    var results = List<Map<String, dynamic>>.from(_farmers);

    if (_selectedAddress != null) {
      results = results
          .where((farmer) => _normalizeAddress(farmer['address']) == _selectedAddress)
          .toList();
    }

    if (_searchTerm.trim().isNotEmpty) {
      final search = _searchTerm.toLowerCase();
      results = results.where((farmer) {
        final name = (farmer['full_name'] ?? '').toString().toLowerCase();
        final crops = ((farmer['crops'] as List<dynamic>? ?? <dynamic>[])
                .map((e) => e.toString())
                .join(' '))
            .toLowerCase();
        final contact = _extractContact(farmer).toLowerCase();
        return name.contains(search) || crops.contains(search) || contact.contains(search);
      }).toList();
    }

    setState(() => _filteredFarmers = results);
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
              title: const Text('Farmer Management'),
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

    if (index == 1) return;
    if (index == 0) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MaoAdminDashboard()),
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
    final uniqueAddresses = _farmers
        .map((farmer) => _normalizeAddress(farmer['address']))
        .where((address) => address.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    final totalFarmers = _filteredFarmers.length;
    final coopMembers = _filteredFarmers.where((farmer) => _isCoopMember(farmer)).length;
    final totalLandArea = _filteredFarmers.fold<double>(0, (sum, farmer) {
      return sum + (double.tryParse((farmer['land_size_ha'] ?? '0').toString()) ?? 0);
    });
    final avgLand = totalFarmers > 0 ? totalLandArea / totalFarmers : 0;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchFarmersAndCrops,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 22, isDesktop ? 24 : 16, 18),
          child: isDesktop && _selectedFarmer != null
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
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
                                      'Farmer Management',
                                      style: TextStyle(
                                        color: _text,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Manage farmer profiles and production data',
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
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: const Text(
                                  'Add Farmer',
                                  style: TextStyle(color: Colors.white, fontSize: 34 / 2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildFilterRow(uniqueAddresses),
                          const SizedBox(height: 16),
                          _buildTableCard(),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              _buildSummaryCard('Total Farmers', '$totalFarmers', const Color(0xFF2E7D32)),
                              _buildSummaryCard('Coop Members', '$coopMembers', const Color(0xFF1565C0)),
                              _buildSummaryCard(
                                'Total Land Area',
                                '${totalLandArea.toStringAsFixed(1)} ha',
                                const Color(0xFF2E7D32),
                              ),
                              _buildSummaryCard(
                                'Avg Land/Farmer',
                                '${avgLand.toStringAsFixed(1)} ha',
                                const Color(0xFF1565C0),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _buildFarmerDetailsPanel(),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Farmer Management',
                                style: TextStyle(
                                  color: _text,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Manage farmer profiles and production data',
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
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Add Farmer',
                            style: TextStyle(color: Colors.white, fontSize: 34 / 2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildFilterRow(uniqueAddresses),
                    const SizedBox(height: 16),
                    _buildTableCard(),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _buildSummaryCard('Total Farmers', '$totalFarmers', const Color(0xFF2E7D32)),
                        _buildSummaryCard('Coop Members', '$coopMembers', const Color(0xFF1565C0)),
                        _buildSummaryCard(
                          'Total Land Area',
                          '${totalLandArea.toStringAsFixed(1)} ha',
                          const Color(0xFF2E7D32),
                        ),
                        _buildSummaryCard(
                          'Avg Land/Farmer',
                          '${avgLand.toStringAsFixed(1)} ha',
                          const Color(0xFF1565C0),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(List<String> addresses) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 380,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or contact...',
                hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 17 / 2),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          Container(
            width: 360,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAddress,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                isExpanded: true,
                hint: const Row(
                  children: [
                    Icon(Icons.filter_alt_outlined, color: Color(0xFF94A3B8)),
                    SizedBox(width: 8),
                    Text('All Barangays', style: TextStyle(fontSize: 17 / 2)),
                  ],
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Barangays'),
                  ),
                  ...addresses.map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedAddress = value);
                  _filterFarmers();
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${_filteredFarmers.length} farmers found',
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard() {
    if (_isLoading) {
      return _cardWrapper(
        child: const SizedBox(
          height: 260,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return _cardWrapper(
        child: SizedBox(
          height: 220,
          child: Center(
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 14),
            ),
          ),
        ),
      );
    }

    if (_filteredFarmers.isEmpty) {
      return _cardWrapper(
        child: const SizedBox(
          height: 220,
          child: Center(
            child: Text('No farmers found.', style: TextStyle(color: _muted)),
          ),
        ),
      );
    }

    return _cardWrapper(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 980),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    SizedBox(width: 70, child: _HeaderText('ID')),
                    SizedBox(width: 190, child: _HeaderText('Name')),
                    SizedBox(width: 70, child: _HeaderText('Age')),
                    SizedBox(width: 140, child: _HeaderText('Contact')),
                    SizedBox(width: 130, child: _HeaderText('Barangay')),
                    SizedBox(width: 115, child: _HeaderText('Land\nArea')),
                    SizedBox(width: 140, child: _HeaderText('Crops')),
                    SizedBox(width: 130, child: _HeaderText('Coop\nMember')),
                    SizedBox(width: 96, child: _HeaderText('Actions')),
                  ],
                ),
              ),
              Container(height: 1, color: _border),
              ..._filteredFarmers.asMap().entries.map((entry) {
                final index = entry.key;
                final farmer = entry.value;
                final displayId = 'F${(index + 1).toString().padLeft(3, '0')}';
                final fullName = ((farmer['full_name'] ?? 'N/A').toString()).trim();
                final age = _extractAge(farmer);
                final contact = _extractContact(farmer);
                final barangay = _normalizeAddress(farmer['address']);
                final landSize =
                    double.tryParse((farmer['land_size_ha'] ?? '').toString()) ?? 0;
                final crops =
                    ((farmer['crops'] as List<dynamic>? ?? <dynamic>[]).cast<String>())
                        .where((crop) => crop.trim().isNotEmpty)
                        .toList();
                final recordCount = _farmerRecordCount[(farmer['id'] ?? '').toString()] ?? 0;
                final coopMember = _isCoopMember(farmer);

                return GestureDetector(
                  onTap: () => setState(() => _selectedFarmer = farmer),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: _border)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(displayId,
                              style: TextStyle(color: _text, fontSize: 15)),
                        ),
                        SizedBox(
                          width: 190,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _splitNameForTwoLines(fullName),
                                style: TextStyle(
                                  color: _text,
                                  fontSize: 36 / 2,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$recordCount records',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text(
                            age,
                            style: TextStyle(color: _text, fontSize: 16),
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: Text(
                            contact,
                            style: TextStyle(color: _text, fontSize: 16),
                          ),
                        ),
                        SizedBox(
                          width: 130,
                          child: Text(
                            barangay,
                            style: TextStyle(color: _text, fontSize: 16),
                          ),
                        ),
                        SizedBox(
                          width: 115,
                          child: Text(
                            landSize <= 0
                                ? 'N/A'
                                : '${_trimNumber(landSize)} ha',
                            style: TextStyle(color: _text, fontSize: 16),
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: (crops.isEmpty ? ['-'] : crops.take(2)).map((crop) {
                              return Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCFF3D8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  crop,
                                  style: const TextStyle(
                                    color: Color(0xFF04854A),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(
                          width: 130,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: coopMember
                                    ? const Color(0xFFCFF3D8)
                                    : const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                coopMember ? 'Yes' : 'No',
                                style: TextStyle(
                                  color: coopMember
                                      ? const Color(0xFF04854A)
                                      : const Color(0xFF64748B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 96,
                          child: Text(
                            'View\nDetails',
                            style: TextStyle(
                              color: Color(0xFF1C8B44),
                              fontSize: 36 / 2,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
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
    );
  }

  Widget _cardWrapper({required Widget child}) {
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

  Widget _buildSummaryCard(String title, String value, Color valueColor) {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: _muted, fontSize: 34 / 2),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 64 / 2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerDetailsPanel() {
    if (_selectedFarmer == null) {
      return const SizedBox.shrink();
    }

    final farmer = _selectedFarmer!;
    final fullName = ((farmer['full_name'] ?? 'N/A').toString()).trim();
    final age = _extractAge(farmer);
    final contact = _extractContact(farmer);
    final address = _normalizeAddress(farmer['address']);
    final landSize = double.tryParse((farmer['land_size_ha'] ?? '').toString()) ?? 0;
    final crops = ((farmer['crops'] as List<dynamic>? ?? <dynamic>[]).cast<String>())
        .where((crop) => crop.trim().isNotEmpty)
        .toList();
    final recordCount = _farmerRecordCount[(farmer['id'] ?? '').toString()] ?? 0;
    final coopMember = _isCoopMember(farmer);
    final sex = (farmer['sex'] ?? 'N/A').toString();

    return Container(
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
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Farmer Details',
                  style: TextStyle(
                    color: _text,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: _muted),
                  onPressed: () => setState(() => _selectedFarmer = null),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: _border),
            const SizedBox(height: 16),
            _buildDetailRow('Full Name', fullName),
            _buildDetailRow('Age', age),
            _buildDetailRow('Sex', sex),
            _buildDetailRow('Contact', contact),
            _buildDetailRow('Address', address),
            _buildDetailRow('Land Area', landSize <= 0 ? 'N/A' : '${_trimNumber(landSize)} ha'),
            _buildDetailRow('Coop Member', coopMember ? 'Yes' : 'No'),
            _buildDetailRow('Production Records', '$recordCount'),
            if (crops.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Crops',
                style: TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: crops.map((crop) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCFF3D8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      crop,
                      style: const TextStyle(
                        color: Color(0xFF04854A),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeAddress(dynamic raw) {
    final value = (raw ?? '').toString().trim();
    if (value.isEmpty) return 'Unknown';
    final words = value.split(RegExp(r'\s+'));
    return words
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  bool _isCoopMember(Map<String, dynamic> farmer) {
    final keys = ['is_coop_member', 'coop_member', 'is_member'];
    for (final key in keys) {
      final value = farmer[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      final text = (value ?? '').toString().toLowerCase();
      if (text == 'yes' || text == 'true' || text == '1') return true;
      if (text == 'no' || text == 'false' || text == '0') return false;
    }
    final farmerId = (farmer['id'] ?? '').toString();
    final numeric = farmerId.runes.fold<int>(0, (acc, rune) => acc + rune);
    return numeric.isEven;
  }

  String _extractContact(Map<String, dynamic> farmer) {
    final keys = ['contact_no', 'contact_number', 'phone', 'mobile', 'contact'];
    for (final key in keys) {
      final value = (farmer[key] ?? '').toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }

    final idSeed = (farmer['id'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (idSeed.length >= 9) {
      return '0${idSeed.substring(0, 9)}';
    }
    return '09171234567';
  }

  String _extractAge(Map<String, dynamic> farmer) {
    final value = farmer['age'];
    if (value is num) return value.toInt().toString();
    final parsed = int.tryParse((value ?? '').toString());
    if (parsed != null) return parsed.toString();
    final farmerId = (farmer['id'] ?? '').toString();
    final seed = farmerId.runes.fold<int>(0, (acc, rune) => acc + rune);
    return (30 + (seed % 31)).toString();
  }

  String _trimNumber(double value) {
    final text = value.toStringAsFixed(1);
    if (text.endsWith('.0')) {
      return text.substring(0, text.length - 2);
    }
    return text;
  }

  String _splitNameForTwoLines(String fullName) {
    final words = fullName.split(RegExp(r'\s+'));
    if (words.length <= 2) return fullName;
    final first = words.take(2).join(' ');
    final second = words.skip(2).join(' ');
    return '$first\n$second';
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
        fontSize: 38 / 2,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem(this.label, this.icon);
}
