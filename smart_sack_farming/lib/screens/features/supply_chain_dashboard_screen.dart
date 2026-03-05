import 'package:flutter/material.dart';
import '../../models/recommendation_model.dart';
import '../../services/supply_chain_service.dart';
import '../../theme/app_theme.dart';

/// Supply chain dashboard for MAO/Associations providing forward-looking
/// supply projections, harvest synchronization, and market channel recommendations.
class SupplyChainDashboardScreen extends StatefulWidget {
  const SupplyChainDashboardScreen({super.key});

  @override
  State<SupplyChainDashboardScreen> createState() =>
      _SupplyChainDashboardScreenState();
}

class _SupplyChainDashboardScreenState
    extends State<SupplyChainDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _service = SupplyChainService();
  late TabController _tabController;
  SupplyChainSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      _summary = await _service.getDashboardSummary();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading supply data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            Tab(text: 'Collisions'),
            Tab(text: 'Channels'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryStrip(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProjectionsTab(),
                      _buildCollisionsTab(),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildSummaryItem(
            '${(s.totalUpcomingYieldKg / 1000).toStringAsFixed(1)}',
            'Tons Expected',
            Icons.inventory_2_rounded,
          ),
          _divider(),
          _buildSummaryItem(
            '${s.totalFarmersHarvesting}',
            'Farmers Active',
            Icons.people_rounded,
          ),
          _divider(),
          _buildSummaryItem(
            '${s.criticalOversupplyCrops.length}',
            'At-Risk Crops',
            Icons.warning_amber_rounded,
          ),
          _divider(),
          _buildSummaryItem(
            '${s.collisions.length}',
            'Collisions',
            Icons.timeline_rounded,
          ),
        ],
      ),
    );
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

  // ================================================================
  // TAB 1: SUPPLY PROJECTIONS
  // ================================================================
  Widget _buildProjectionsTab() {
    final projections = _summary?.projections ?? [];
    if (projections.isEmpty) {
      return _emptyState('No supply projections available',
          'Projections are generated from farmer planting records.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projections.length,
      itemBuilder: (context, index) {
        final p = projections[index];
        return _buildProjectionCard(p);
      },
    );
  }

  Widget _buildProjectionCard(SupplyProjection p) {
    final riskColor = p.riskOfOversupply >= 75
        ? AppTheme.error
        : p.riskOfOversupply >= 50
            ? AppTheme.warning
            : p.riskOfOversupply >= 25
                ? const Color(0xFFFFA726)
                : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: p.riskOfOversupply >= 50
            ? Border.all(color: riskColor.withAlpha(60), width: 1.5)
            : null,
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${p.oversupplyRiskLabel} RISK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Risk bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p.riskOfOversupply / 100,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation(riskColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Oversupply Risk: ${p.riskOfOversupply.toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 11, color: riskColor),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStat(
                  '${p.projectedYieldTons}T', 'Projected', Icons.scale),
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
              color: riskColor.withAlpha(8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 16, color: riskColor),
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
          if (p.riskOfOversupply >= 50) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _tabController.animateTo(2);
                },
                icon: const Icon(Icons.store, size: 16),
                label: const Text('View Market Channels',
                    style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: riskColor,
                  side: BorderSide(color: riskColor.withAlpha(80)),
                ),
              ),
            ),
          ],
        ],
      ),
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

  // ================================================================
  // TAB 2: HARVEST COLLISIONS
  // ================================================================
  Widget _buildCollisionsTab() {
    final collisions = _summary?.collisions ?? [];
    if (collisions.isEmpty) {
      return _emptyState('No harvest collisions detected',
          'The system monitors for farmers harvesting simultaneously.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: collisions.length,
      itemBuilder: (context, index) {
        final c = collisions[index];
        return _buildCollisionCard(c);
      },
    );
  }

  Widget _buildCollisionCard(HarvestCollision c) {
    final color = c.severity == 'critical'
        ? AppTheme.error
        : c.severity == 'high'
            ? AppTheme.warning
            : const Color(0xFFFFA726);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
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
              Text(c.severityEmoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${c.cropType} — ${c.severity.toUpperCase()}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${c.farmerCount} farmers harvesting ${(c.totalYieldKg / 1000).toStringAsFixed(1)} tons around ${_formatDate(c.harvestDate)}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              c.recommendation,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textMedium, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // TAB 3: ALTERNATIVE MARKET CHANNELS
  // ================================================================
  Widget _buildChannelsTab() {
    final highRisk = _summary?.highRiskProjections ?? [];
    if (highRisk.isEmpty) {
      return _emptyState('No surplus detected',
          'Market channels will be suggested when oversupply risk is high.');
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
                '${p.cropType} — ${p.projectedYieldTons} tons surplus',
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

  // ================================================================
  // COMMON
  // ================================================================
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
