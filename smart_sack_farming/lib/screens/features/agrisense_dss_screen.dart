import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../mock/agrisense_mock_data.dart';
import '../../models/agrisense_alert.dart';
import '../../models/agrisense_farmer_profile.dart';
import '../../models/agrisense_program_enrollment.dart';
import '../../models/agrisense_saturation_score.dart';
import '../../repositories/agrisense_repository.dart';
import '../farmer/crop_cycling_monitoring_simple.dart';
import 'agri_financial_dss_screen.dart';
import 'agrisense_cpa_screen.dart';
import 'agrisense_csi_screen.dart';
import 'agrisense_dpac_screen.dart';
import 'agrisense_mpi_screen.dart';
import 'agrisense_pdew_screen.dart';
import 'agrisense_phml_screen.dart';
import 'agrisense_piae_screen.dart';
import 'agrisense_saturation_heatmap_screen.dart';
import 'agrisense_wcra_screen.dart';

const _kGreen = Color(0xFF1B7737);
const _kGreenDark = Color(0xFF145C29);
const _kBackground = Color(0xFFF0F5F1);

class AgriSenseDssScreen extends StatefulWidget {
  const AgriSenseDssScreen({super.key});

  @override
  State<AgriSenseDssScreen> createState() => _AgriSenseDssScreenState();
}

class _AgriSenseDssScreenState extends State<AgriSenseDssScreen> {
  late final Future<_HubData> _hubFuture;
  int _selectedNavIndex = 0;

  static const _border = Color(0xFFD6DAE1);
  static const _muted = Color(0xFF4B5563);
  static const _text = Color(0xFF0F172A);

  static const _navItems = <_DssNavItem>[
    _DssNavItem('Dashboard', Icons.grid_view_rounded),
    _DssNavItem('Saturation', Icons.heat_pump_rounded),
    _DssNavItem('Planting', Icons.grass_rounded),
    _DssNavItem('Weather', Icons.cloud_rounded),
    _DssNavItem('Pest Alert', Icons.bug_report_rounded),
    _DssNavItem('Market', Icons.storefront_rounded),
    _DssNavItem('Financial Model', Icons.account_balance_rounded),
    _DssNavItem('Harvest', Icons.agriculture_rounded),
    _DssNavItem('Programs', Icons.verified_user_rounded),
    _DssNavItem('Crop Cycling', Icons.loop_rounded),
    _DssNavItem('Planting Advisor', Icons.tips_and_updates_rounded),
    _DssNavItem('Heatmap', Icons.map_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _hubFuture = _loadHubData();
  }

  Future<_HubData> _loadHubData() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return _mockHubData();

      final repository = AgrisenseRepository(client);
      final profile = await repository.getFarmerProfile(userId);
      if (profile == null || profile.id == null) return _mockHubData();

      final alerts = await repository.getAlerts(profile.id!);
      final programs = await repository.getProgramEnrollments(profile.id!);
      final scoresResponse = await client
          .from('agrisense_saturation_scores')
          .select()
          .eq('municipality', profile.municipality)
          .order('last_updated', ascending: false)
          .limit(20);

      final scores = (scoresResponse as List)
          .map((json) => AgrisenseSaturationScore.fromJson(json))
          .toList();

      final crop = profile.primaryCrops.isNotEmpty
          ? profile.primaryCrops.first
          : profile.preferredCrops.isNotEmpty
              ? profile.preferredCrops.first
              : null;

      _MarketSnapshot? market;
      if (crop != null) {
        final marketRows = await client
            .from('agrisense_market_prices')
            .select()
            .eq('municipality', profile.municipality)
            .eq('crop_type', crop)
            .order('recorded_date', ascending: false)
            .limit(30);

        if (marketRows is List && marketRows.isNotEmpty) {
          final latest = marketRows.first;
          final earliest = marketRows.last;
          final latestPrice = (latest['price_per_kg'] as num).toDouble();
          final earliestPrice = (earliest['price_per_kg'] as num).toDouble();
          final trendPercent = earliestPrice == 0
              ? null
              : ((latestPrice - earliestPrice) / earliestPrice) * 100;

          market = _MarketSnapshot(
            crop: crop,
            latestPrice: latestPrice,
            trendPercent: trendPercent,
          );
        }
      }

      return _HubData(
        profile: profile,
        alerts: alerts.isNotEmpty ? alerts : AgrisenseMockData.alerts,
        scores: scores.isNotEmpty ? scores : AgrisenseMockData.saturationScores,
        programs: programs,
        market: market ?? _MarketSnapshot(crop: 'Sweet Corn', latestPrice: 18.50, trendPercent: 6.5),
      );
    } catch (_) {
      return _mockHubData();
    }
  }

  static _HubData _mockHubData() => _HubData(
    profile: AgrisenseMockData.profile,
    alerts: AgrisenseMockData.alerts,
    scores: AgrisenseMockData.saturationScores,
    programs: AgrisenseMockData.programEnrollments,
    market: _MarketSnapshot(crop: 'Sweet Corn', latestPrice: 18.50, trendPercent: 6.5),
  );

  void _openModule(BuildContext context, String module) {
    final idx = _navItems.indexWhere((n) => n.label == module);
    if (idx >= 0) {
      setState(() => _selectedNavIndex = idx);
    }
  }

  Widget _moduleForIndex(int index) {
    switch (_navItems[index].label) {
      case 'Saturation': return const AgrisenseCsiScreen();
      case 'Planting': return const AgrisensePiaeScreen();
      case 'Weather': return const AgrisenseWcraScreen();
      case 'Pest Alert': return const AgrisensePdewScreen();
      case 'Market': return const AgrisenseMpiScreen();
      case 'Financial Model': return const AgriFinancialDssScreen();
      case 'Harvest': return const AgrisensePhmlScreen();
      case 'Programs': return const AgrisenseDpacScreen();
      case 'Crop Cycling': return const CropCyclingMonitoringSimple();
      case 'Planting Advisor': return const AgrisenseCpaScreen();
      case 'Heatmap': return const AgrisenseSaturationHeatmapScreen();
    }
    return const SizedBox.shrink();
  }

  Widget _embedModule(Widget child) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation from within module
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        if (!isDesktop) {
          return Scaffold(
            backgroundColor: _kBackground,
            appBar: AppBar(
              title: Text(_navItems[_selectedNavIndex].label),
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            drawer: Drawer(child: _buildSidebar()),
            body: _buildContent(),
          );
        }
        return Scaffold(
          backgroundColor: _kBackground,
          body: Row(
            children: [
              SizedBox(width: 280, child: _buildSidebar()),
              Expanded(child: _buildContent()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_selectedNavIndex == 0) {
      return _buildDashboardHub();
    }
    return _embedModule(_moduleForIndex(_selectedNavIndex));
  }

  Widget _buildSidebar() {
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _kGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.insights_rounded, color: Color(0xFFECFDF3), size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AgriSense',
                          style: TextStyle(
                            color: Color(0xFF207538),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Decision Support',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 11,
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
            const SizedBox(height: 22),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _navItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final selected = index == _selectedNavIndex;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedNavIndex = index),
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: selected ? _kGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 18,
                            color: selected ? Colors.white : const Color(0xFF364152),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: selected ? Colors.white : const Color(0xFF1E293B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _border)),
              ),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 18, color: _muted),
                      SizedBox(width: 10),
                      Text(
                        'Back to App',
                        style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHub() {
    return FutureBuilder<_HubData>(
      future: _hubFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _kGreen));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load AgriSense data.\n${snapshot.error}',
                style: const TextStyle(color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final data = snapshot.data!;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(data.profile.fullName),
                const SizedBox(height: 24),
                _UrgentActionCard(alerts: data.alerts, onViewTap: () => _openModule(context, 'Weather')),
                const SizedBox(height: 20),
                _QuickStatsRow(alerts: data.alerts, scores: data.scores),
                const SizedBox(height: 20),
                _TopRecommendationCard(scores: data.scores),
                const SizedBox(height: 20),
                _MarketSnapshotCard(market: data.market),
                const SizedBox(height: 20),
                const Text('Module Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _text)),
                const SizedBox(height: 12),
                _StatusGrid(alerts: data.alerts, onTap: (m) => _openModule(context, m)),
                const SizedBox(height: 20),
                _NextMilestoneCard(programs: data.programs),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreeting(String name) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kGreen, _kGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${name.split(' ').first}! 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your AI-powered farming decision support',
            style: TextStyle(color: Color(0xFFB2D9B8), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Stats Row ──────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final List<AgrisenseAlert> alerts;
  final List<AgrisenseSaturationScore> scores;

  const _QuickStatsRow({required this.alerts, required this.scores});

  @override
  Widget build(BuildContext context) {
    final criticalAlerts = alerts.where((a) => a.severity == 'critical' || a.severity == 'high').length;
    final avgSaturation = scores.isEmpty ? 0 : (scores.fold<double>(0, (sum, score) => sum + score.srsScore) / scores.length).round();
    final safeModules = 11 - (alerts.isEmpty ? 0 : 1);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Alerts',
            value: '$criticalAlerts',
            icon: Icons.warning_rounded,
            color: criticalAlerts > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Avg Saturation',
            value: '$avgSaturation%',
            icon: Icons.heat_pump_rounded,
            color: avgSaturation > 70 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Safe Modules',
            value: '$safeModules',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _DssNavItem {
  final String label;
  final IconData icon;
  const _DssNavItem(this.label, this.icon);
}

// ─── Green Header ─────────────────────────────────────────────────────────────

class _GreenHeader extends StatelessWidget {
  final String farmerName;
  final int unreadCount;

  const _GreenHeader({required this.farmerName, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      color: _kGreen,
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 14),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AgriSense DSS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Smart Sack Farming Decision Support',
                  style: TextStyle(color: Color(0xFFB2D9B8), fontSize: 12),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(Icons.help_outline_rounded, color: Color(0xFFB2D9B8), size: 22),
        ],
      ),
    );
  }
}

// ─── Urgent Action Card ───────────────────────────────────────────────────────

class _UrgentActionCard extends StatelessWidget {
  final List<AgrisenseAlert> alerts;
  final VoidCallback onViewTap;

  const _UrgentActionCard({required this.alerts, required this.onViewTap});

  @override
  Widget build(BuildContext context) {
    final urgent = alerts.isEmpty ? null : alerts.first;
    final severity = urgent?.severity ?? '';

    final title = urgent?.title ?? 'No urgent alerts';
    final message = urgent?.message ?? 'You are up to date with current advisories.';
    final ctaLabel = urgent?.ctaLabel ?? 'View Details';

    final Color startColor;
    final Color endColor;
    if (severity == 'critical' || severity == 'high') {
      startColor = const Color(0xFFF97316);
      endColor = const Color(0xFFDC2626);
    } else if (severity == 'warning') {
      startColor = const Color(0xFFF59E0B);
      endColor = const Color(0xFFF97316);
    } else {
      startColor = _kGreen;
      endColor = _kGreenDark;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(color: Color(0xFFFFE4C4), fontSize: 13),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: endColor,
              backgroundColor: Colors.white,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onPressed: onViewTap,
            child: Text(ctaLabel),
          ),
        ],
      ),
    );
  }
}

// ─── Status Grid ─────────────────────────────────────────────────────────────

class _StatusGrid extends StatelessWidget {
  final List<AgrisenseAlert> alerts;
  final void Function(String module) onTap;

  const _StatusGrid({required this.alerts, required this.onTap});

  static const _modules = [
    _ModuleMeta('Saturation', Icons.heat_pump_rounded, 'CSI'),
    _ModuleMeta('Planting', Icons.grass_rounded, 'PIAE'),
    _ModuleMeta('Weather', Icons.cloud_rounded, 'WCRA'),
    _ModuleMeta('Planting Advisor', Icons.tips_and_updates_rounded, 'CPA'),
    _ModuleMeta('Pest Alert', Icons.bug_report_rounded, 'PDEW'),
    _ModuleMeta('Market', Icons.storefront_rounded, 'MPI'),
    _ModuleMeta('Financial Model', Icons.account_balance_rounded, 'FFP'),
    _ModuleMeta('Harvest', Icons.agriculture_rounded, 'PHML'),
    _ModuleMeta('Programs', Icons.verified_user_rounded, 'DPAC'),
    _ModuleMeta('Crop Cycling', Icons.loop_rounded, 'CCM'),
    _ModuleMeta('Heatmap', Icons.map_rounded, 'HMP'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: _modules.map((m) {
        final moduleAlerts = alerts.where((a) => a.module == m.code).toList();
        final statusColor = _statusColor(moduleAlerts);
        final statusLabel = _statusLabel(m.code, moduleAlerts);
        return _StatusCard(
          meta: m,
          statusColor: statusColor,
          statusLabel: statusLabel,
          onTap: () => onTap(m.name),
        );
      }).toList(),
    );
  }

  Color _statusColor(List<AgrisenseAlert> moduleAlerts) {
    if (moduleAlerts.isEmpty) return const Color(0xFF16A34A);
    final severity = moduleAlerts.first.severity.toLowerCase();
    if (severity == 'critical' || severity == 'high') return const Color(0xFFDC2626);
    if (severity == 'warning' || severity == 'medium') return const Color(0xFFF59E0B);
    return const Color(0xFF16A34A);
  }

  String _statusLabel(String code, List<AgrisenseAlert> moduleAlerts) {
    if (code == 'MPI' && moduleAlerts.isEmpty) return 'Good';
    if (code == 'DPAC' && moduleAlerts.isEmpty) return 'New';
    if (moduleAlerts.isEmpty) return 'Safe';
    final severity = moduleAlerts.first.severity.toLowerCase();
    if (severity == 'critical' || severity == 'high') return 'Alert';
    if (severity == 'warning' || severity == 'medium') return 'Warning';
    return 'Safe';
  }
}

class _ModuleMeta {
  final String name;
  final IconData icon;
  final String code;
  const _ModuleMeta(this.name, this.icon, this.code);
}

class _StatusCard extends StatelessWidget {
  final _ModuleMeta meta;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;

  const _StatusCard({
    required this.meta,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusColor.withAlpha(50), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: statusColor.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(meta.icon, color: statusColor, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              meta.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Recommendation Card ──────────────────────────────────────────────────

class _TopRecommendationCard extends StatelessWidget {
  final List<AgrisenseSaturationScore> scores;

  const _TopRecommendationCard({required this.scores});

  @override
  Widget build(BuildContext context) {
    final topScore = scores.isEmpty ? null : scores.first;
    final riskLevel = topScore == null ? 'Unknown' : topScore.srsScore >= 81 ? 'High Risk' : topScore.srsScore >= 50 ? 'Moderate' : 'Low Risk';
    final riskColor = topScore == null
        ? const Color(0xFF9CA3AF)
        : topScore.srsScore >= 81
            ? const Color(0xFFDC2626)
            : topScore.srsScore >= 50
                ? const Color(0xFFF59E0B)
                : const Color(0xFF16A34A);

    final recommendation = topScore == null
        ? 'Recommendations will appear after your data syncs.'
        : topScore.srsScore >= 81
            ? 'Market saturation detected! Consider alternative crops or adjust planting timing.'
            : 'Current crop choice shows good market potential. Monitor market trends.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            riskColor.withAlpha(15),
            riskColor.withAlpha(8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: riskColor.withAlpha(40)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: riskColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_up_rounded, color: riskColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Smart Recommendation",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      riskLevel,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: riskColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.5),
          ),
          if (topScore != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniTile(
                    label: 'SRS Score',
                    value: '${topScore.srsScore.toStringAsFixed(0)}/100',
                    valueColor: riskColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniTile(
                    label: 'Crop',
                    value: topScore.cropType,
                    valueColor: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Market Snapshot Card ─────────────────────────────────────────────────────

class _MarketSnapshotCard extends StatelessWidget {
  final _MarketSnapshot? market;

  const _MarketSnapshotCard({required this.market});

  @override
  Widget build(BuildContext context) {
    if (market == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: const Text('No market price data available yet.', style: TextStyle(color: Color(0xFF6B7280))),
      );
    }

    final trendPercent = market!.trendPercent;
    final trendLabel = trendPercent == null
        ? 'n/a'
        : '${trendPercent >= 0 ? '+' : ''}${trendPercent.toStringAsFixed(1)}%';
    final trendColor = trendPercent == null
        ? const Color(0xFF3B82F6)
        : trendPercent >= 0
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626);
    final trendIcon = trendPercent == null
        ? Icons.remove
        : trendPercent >= 0
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, const Color(0xFFFAFBFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFFF59E0B), size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Market Snapshot',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        market!.crop,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₱${market!.latestPrice.toStringAsFixed(2)}/kg',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Farm Gate Price',
                        style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: trendColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: trendColor.withAlpha(40)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '30-Day Trend',
                        style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(trendIcon, size: 18, color: trendColor),
                          const SizedBox(width: 6),
                          Text(
                            trendLabel,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: trendColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Price Change',
                        style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Widget? trailing;

  const _MiniTile({
    required this.label,
    required this.value,
    required this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor),
              ),
              if (trailing != null) ...[const SizedBox(width: 4), trailing!],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Next Milestone Card ──────────────────────────────────────────────────────

class _NextMilestoneCard extends StatelessWidget {
  final List<AgrisenseProgramEnrollment> programs;

  const _NextMilestoneCard({required this.programs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = programs
        .where((p) => p.expiryDate != null && p.expiryDate!.isAfter(now))
        .toList()
      ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));

    final next = upcoming.isEmpty ? null : upcoming.first;
    final daysLeft = next == null ? null : next.expiryDate!.difference(now).inDays;
    final subtitle = next == null
        ? 'No upcoming DA program deadlines.'
        : '${next.programName} closes in $daysLeft days';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_rounded, color: Color(0xFF3B82F6), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Next Milestone', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            onPressed: () {},
            child: Text(next == null ? 'Programs' : 'Apply'),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final void Function(String module) onModuleTap;

  const _BottomNav({required this.onModuleTap});

  static const _items = [
    _NavItem('Dashboard', Icons.home_rounded, null),
    _NavItem('Saturation', Icons.heat_pump_rounded, 'Saturation'),
    _NavItem('Planting', Icons.grass_rounded, 'Planting'),
    _NavItem('Weather', Icons.cloud_rounded, 'Weather'),
    _NavItem('Pest Alert', Icons.bug_report_rounded, 'Pest Alert'),
    _NavItem('Market', Icons.storefront_rounded, 'Market'),
    _NavItem('Financial Model', Icons.account_balance_rounded, 'Financial Model'),
    _NavItem('Harvest', Icons.agriculture_rounded, 'Harvest'),
    _NavItem('Programs', Icons.verified_user_rounded, 'Programs'),
    _NavItem('Crop Cycle', Icons.loop_rounded, 'Crop Cycling'),
    _NavItem('Planting', Icons.tips_and_updates_rounded, 'Planting Advisor'),
    _NavItem('Heatmap', Icons.map_rounded, 'Heatmap'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: EdgeInsets.only(bottom: bottomPad, top: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: _items.map((item) {
            final isSelected = item.module == null;
            return _NavChip(item: item, isSelected: isSelected, onTap: () {
              if (item.module != null) onModuleTap(item.module!);
            });
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String? module;
  const _NavItem(this.label, this.icon, this.module);
}

class _NavChip extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavChip({required this.item, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _kGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class _MarketSnapshot {
  final String crop;
  final double latestPrice;
  final double? trendPercent;

  const _MarketSnapshot({
    required this.crop,
    required this.latestPrice,
    required this.trendPercent,
  });
}

class _HubData {
  final AgrisenseFarmerProfile profile;
  final List<AgrisenseAlert> alerts;
  final List<AgrisenseSaturationScore> scores;
  final List<AgrisenseProgramEnrollment> programs;
  final _MarketSnapshot? market;

  const _HubData({
    required this.profile,
    required this.alerts,
    required this.scores,
    required this.programs,
    required this.market,
  });
}
