import 'package:flutter/material.dart';
import '../../models/recommendation_model.dart';
import '../../services/supply_chain_service.dart';
import '../../theme/app_theme.dart';
import 'farmer_profile_screen.dart';

class SupplyChainDashboardScreen extends StatefulWidget {
  const SupplyChainDashboardScreen({super.key});

  @override
  State<SupplyChainDashboardScreen> createState() => _SupplyChainDashboardScreenState();
}

class _SupplyChainDashboardScreenState extends State<SupplyChainDashboardScreen> with TickerProviderStateMixin {
  late final SupplyChainService _service;
  late TabController _tabController;
  
  SupplyChainSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service = SupplyChainService();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _service.getDashboardSummary();
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  bool _isAllowedCrop(String cropType) {
    // Implement your crop filtering logic here
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Supply Chain Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Projections'),
            Tab(text: 'Channels'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryStrip(),
                _buildFarmerListSection(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProjectionsTab(),
                      _buildChannelsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryStrip() {
    final s = _summary;
    if (s == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withAlpha(220)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSummaryItem(
            '${s.projections.length}',
            'Projections',
            Icons.trending_up_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerListSection() {
    final s = _summary;
    if (s == null) return const SizedBox.shrink();

    final farmersById = <String, FarmerSupplyInfo>{};
    for (final projection in s.projections) {
      for (final farmer in projection.farmerDetails) {
        final existing = farmersById[farmer.farmerId];
        if (existing == null) {
          farmersById[farmer.farmerId] = farmer;
        } else {
          farmersById[farmer.farmerId] = FarmerSupplyInfo(
            farmerId: existing.farmerId,
            name: existing.name == 'Farmer' && farmer.name != 'Farmer'
                ? farmer.name
                : existing.name,
            address: existing.address ?? farmer.address,
            barangay: existing.barangay ?? farmer.barangay,
            landSizeHa: existing.landSizeHa ?? farmer.landSizeHa,
            expectedYieldKg: existing.expectedYieldKg + farmer.expectedYieldKg,
            totalAreaHa: existing.totalAreaHa + farmer.totalAreaHa,
          );
        }
      }
    }
    final farmers = farmersById.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (farmers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Farmers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: farmers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, idx) {
                final farmer = farmers[idx];
                final farmerName = farmer.name.trim().isEmpty ? 'Unknown' : farmer.name;
                final address = farmer.address ?? '';
                final barangay = farmer.barangay ?? _extractBarangay(address) ?? '';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FarmerProfileScreen(farmer: farmer),
                      ),
                    );
                  },
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primary.withAlpha(50)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primary.withAlpha(80),
                          child: Icon(Icons.person, size: 24, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            farmerName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (barangay.isNotEmpty)
                          Text('Brgy. $barangay', style: const TextStyle(fontSize: 10, color: AppTheme.textMedium), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String? _extractBarangay(String? address) {
    if (address == null || address.isEmpty) return null;
    final match = RegExp(r"\b(?:Brgy\.?|Barangay)\s+([A-Za-z0-9\-\s]+)",
            caseSensitive: false)
        .firstMatch(address);
    return match?.group(1)?.trim();
  }

  Widget _buildSummaryItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withAlpha(200), size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withAlpha(50),
    );
  }

  Widget _buildProjectionsTab() {
    final projections =
        (_summary?.projections ?? []).where((p) => _isAllowedCrop(p.cropType)).toList();
    if (projections.isEmpty) {
      return _emptyState('No supply projections available',
          'Projections are generated from farmer planting records for selected crops.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projections.length,
      itemBuilder: (context, index) {
        final p = projections[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(p.cropType,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMiniStat(
                      '${(p.projectedYieldKg / 1000).toStringAsFixed(1)}T', 'Projected', Icons.scale),
                  _buildMiniStat('${p.farmerCount}', 'Farmers', Icons.people),
                  _buildMiniStat('${p.totalAreaHa.toStringAsFixed(1)}ha', 'Area',
                      Icons.landscape),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Harvest: ${_formatDate(p.harvestWindowStart)} – ${_formatDate(p.harvestWindowEnd)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.suggestedAction,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMedium,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (p.farmerDetails.isNotEmpty) ...[
                const SizedBox(height: 10),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Farmer details (${p.farmerDetails.length})',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  children: p.farmerDetails
                      .map((f) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(f.name,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                    'Address: ${f.address ?? 'N/A'}${f.barangay != null ? ' (Brgy. ${f.barangay})' : ''}',
                                    style: const TextStyle(
                                        fontSize: 11, color: AppTheme.textMedium)),
                                const SizedBox(height: 2),
                                Text(
                                    'Land area: ${f.landSizeHa != null ? '${f.landSizeHa!.toStringAsFixed(2)} ha' : 'Unknown'} • Expected yield: ${f.expectedYieldKg.toStringAsFixed(0)} kg',
                                    style: const TextStyle(
                                        fontSize: 11, color: AppTheme.textMedium)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textLight),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textLight)),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildChannelsTab() {
    final highRisk =
        (_summary?.highRiskProjections ?? []).where((p) => _isAllowedCrop(p.cropType)).toList();
    if (highRisk.isEmpty) {
      return _emptyState('No surplus detected',
          'Market channels will be suggested when oversupply risk is high for selected crops.');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: highRisk.map((p) {
        final channels = _service.getAlternativeChannels(
            p.cropType, p.projectedYieldKg);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${p.cropType} — ${(p.projectedYieldKg / 1000).toStringAsFixed(1)} tons surplus',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            ...channels.map(_buildChannelCard),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildChannelCard(MarketChannel ch) {
    const typeIcons = {
      'buyback': Icons.handshake_rounded,
      'storage': Icons.warehouse_rounded,
      'processing': Icons.factory_rounded,
      'export': Icons.local_shipping_rounded,
      'direct': Icons.storefront_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              typeIcons[ch.type] ?? Icons.store,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ch.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(ch.description,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                        height: 1.3)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (ch.estimatedPrice > 0)
                      Text(
                        '₱${ch.estimatedPrice.toStringAsFixed(0)}/kg',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success),
                      ),
                    if (ch.estimatedPrice > 0) const SizedBox(width: 12),
                    Text(
                      'Capacity: ${(ch.capacityKg / 1000).toStringAsFixed(1)}T',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textLight),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(ch.contactInfo,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.analytics_outlined,
              size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textMedium, fontSize: 15)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  color: AppTheme.textLight, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}
