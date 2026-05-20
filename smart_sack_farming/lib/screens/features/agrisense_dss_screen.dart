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
        market: market ?? _MarketSnapshot(crop: 'Ampalaya', latestPrice: 35.00, trendPercent: 6.5),
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
    market: _MarketSnapshot(crop: 'Ampalaya', latestPrice: 35.00, trendPercent: 6.5),
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
    // Use mock data immediately for fast render; swap live when future completes
    final mock = _mockHubData();
    return SafeArea(
      child: FutureBuilder<_HubData>(
        future: _hubFuture,
        builder: (context, snapshot) {
          final data = snapshot.data ?? mock;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGreeting(data.profile.fullName),
                const SizedBox(height: 20),
                _SectionTitle('Alerts'),
                const SizedBox(height: 10),
                _AlertSection(alerts: data.alerts, onTap: (m) => _openModule(context, m)),
                const SizedBox(height: 22),
                _SectionTitle('Key Metrics'),
                const SizedBox(height: 10),
                _KeyMetricsRow(scores: data.scores, market: data.market),
                const SizedBox(height: 22),
                _SectionTitle('Smart Recommendation'),
                const SizedBox(height: 10),
                _SmartRecommendationCard(
                  scores: data.scores,
                  market: data.market,
                  onSimulate: () => _openModule(context, 'Planting Advisor'),
                  onCompare: () => _openModule(context, 'Saturation'),
                ),
                const SizedBox(height: 22),
                _SectionTitle('Scenario Comparison'),
                const SizedBox(height: 10),
                _ScenarioComparison(scores: data.scores, market: data.market),
                const SizedBox(height: 22),
                _SectionTitle('Market Intelligence'),
                const SizedBox(height: 10),
                _MarketIntelligencePanel(
                  scores: data.scores,
                  market: data.market,
                  onViewBuyers: () => _openModule(context, 'Market'),
                ),
                const SizedBox(height: 22),
                _SectionTitle('Financial Forecast (Next 4 Months)'),
                const SizedBox(height: 10),
                _FinancialForecastTable(scores: data.scores, market: data.market),
                const SizedBox(height: 22),
                _SectionTitle('Module Status'),
                const SizedBox(height: 10),
                _StatusGrid(alerts: data.alerts, onTap: (m) => _openModule(context, m)),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
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

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// ─── Alert Section ────────────────────────────────────────────────────────────

class _AlertSection extends StatelessWidget {
  final List<AgrisenseAlert> alerts;
  final void Function(String module) onTap;

  const _AlertSection({required this.alerts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = <_AlertItem>[];

    if (alerts.isNotEmpty) {
      for (final a in alerts.take(3)) {
        final severity = a.severity.toLowerCase();
        items.add(_AlertItem(
          icon: _iconFor(a.module),
          title: a.title,
          subtitle: a.message,
          color: severity == 'critical' || severity == 'high'
              ? const Color(0xFFDC2626)
              : severity == 'warning' || severity == 'medium'
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF1E40AF),
          bg: severity == 'critical' || severity == 'high'
              ? const Color(0xFFFEE2E2)
              : severity == 'warning' || severity == 'medium'
                  ? const Color(0xFFFEF3C7)
                  : const Color(0xFFDBEAFE),
          ctaLabel: a.ctaLabel ?? 'View Details',
          module: _moduleFor(a.module),
        ));
      }
    } else {
      items.addAll(const [
        _AlertItem(
          icon: Icons.cloud_rounded,
          title: 'Weather Update',
          subtitle: 'No severe weather warnings for your area today.',
          color: Color(0xFF1E40AF),
          bg: Color(0xFFDBEAFE),
          ctaLabel: 'View Weather',
          module: 'Weather',
        ),
        _AlertItem(
          icon: Icons.storefront_rounded,
          title: 'New Buyer Available',
          subtitle: 'Processor X now accepts cabbage at ₱18/kg.',
          color: Color(0xFF047857),
          bg: Color(0xFFD1FAE5),
          ctaLabel: 'View Buyers',
          module: 'Market',
        ),
      ]);
    }

    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.color.withAlpha(60)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(color: item.color, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(color: item.color.withAlpha(220), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => onTap(item.module),
                style: TextButton.styleFrom(
                  foregroundColor: item.color,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                child: Text(item.ctaLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  IconData _iconFor(String module) {
    switch (module) {
      case 'WCRA': return Icons.cloud_rounded;
      case 'CSI': return Icons.heat_pump_rounded;
      case 'MPI': return Icons.storefront_rounded;
      case 'PDEW': return Icons.bug_report_rounded;
      default: return Icons.warning_amber_rounded;
    }
  }

  String _moduleFor(String code) {
    switch (code) {
      case 'WCRA': return 'Weather';
      case 'CSI': return 'Saturation';
      case 'MPI': return 'Market';
      case 'PDEW': return 'Pest Alert';
      default: return 'Saturation';
    }
  }
}

class _AlertItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bg;
  final String ctaLabel;
  final String module;

  const _AlertItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bg,
    required this.ctaLabel,
    required this.module,
  });
}

// ─── Key Metrics Row ──────────────────────────────────────────────────────────

class _KeyMetricsRow extends StatelessWidget {
  final List<AgrisenseSaturationScore> scores;
  final _MarketSnapshot? market;

  const _KeyMetricsRow({required this.scores, required this.market});

  @override
  Widget build(BuildContext context) {
    final topScore = scores.isEmpty ? null : scores.first;
    final secondScore = scores.length > 1 ? scores[1] : null;

    // Crop suitability (derived from SRS: lower SRS = higher suitability)
    final crop1 = topScore?.cropType ?? 'Ampalaya';
    final suit1 = topScore == null ? 87 : (100 - topScore.srsScore.round()).clamp(40, 99);
    final crop2 = secondScore?.cropType ?? 'Cabbage';
    final suit2 = secondScore == null ? 92 : (100 - secondScore.srsScore.round()).clamp(40, 99);

    // Profitability (estimated)
    final profit1 = topScore == null ? '₱45k/ha' : '₱${(45 - topScore.srsScore / 5).toStringAsFixed(0)}k/ha';
    final profit2 = secondScore == null ? '₱38k/ha' : '₱${(45 - secondScore.srsScore / 5).toStringAsFixed(0)}k/ha';

    // Market price + trend
    final priceCrop = market?.crop ?? 'Ampalaya';
    final price = market == null ? 18.50 : market!.latestPrice;
    final trend = market?.trendPercent ?? 6.5;
    final trendStr = '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(1)}%';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          return Row(
            children: [
              Expanded(child: _metricCard(
                icon: Icons.eco_rounded,
                color: const Color(0xFF16A34A),
                title: 'Crop Suitability',
                lines: ['$crop1: $suit1%', '$crop2: $suit2%'],
              )),
              const SizedBox(width: 12),
              Expanded(child: _metricCard(
                icon: Icons.attach_money_rounded,
                color: const Color(0xFFCA8A04),
                title: 'Profitability',
                lines: ['$crop1: $profit1', '$crop2: $profit2'],
              )),
              const SizedBox(width: 12),
              Expanded(child: _metricCard(
                icon: Icons.trending_up_rounded,
                color: trend >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                title: 'Market Price',
                lines: [priceCrop, '₱${price.toStringAsFixed(2)}/kg ($trendStr)'],
              )),
            ],
          );
        }
        return Column(
          children: [
            _metricCard(
              icon: Icons.eco_rounded,
              color: const Color(0xFF16A34A),
              title: 'Crop Suitability',
              lines: ['$crop1: $suit1%', '$crop2: $suit2%'],
            ),
            const SizedBox(height: 10),
            _metricCard(
              icon: Icons.attach_money_rounded,
              color: const Color(0xFFCA8A04),
              title: 'Profitability',
              lines: ['$crop1: $profit1', '$crop2: $profit2'],
            ),
            const SizedBox(height: 10),
            _metricCard(
              icon: Icons.trending_up_rounded,
              color: trend >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              title: 'Market Price',
              lines: [priceCrop, '₱${price.toStringAsFixed(2)}/kg ($trendStr)'],
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard({
    required IconData icon,
    required Color color,
    required String title,
    required List<String> lines,
  }) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
            ],
          ),
          const SizedBox(height: 10),
          ...lines.map((l) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
            ),
          )),
        ],
      ),
    );
  }
}

// ─── Smart Recommendation Card ────────────────────────────────────────────────

class _SmartRecommendationCard extends StatelessWidget {
  final List<AgrisenseSaturationScore> scores;
  final _MarketSnapshot? market;
  final VoidCallback onSimulate;
  final VoidCallback onCompare;

  const _SmartRecommendationCard({
    required this.scores,
    required this.market,
    required this.onSimulate,
    required this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    // Pick recommended crop: lowest SRS = lowest saturation risk = best to plant
    final sortedByRisk = scores.isEmpty
        ? <AgrisenseSaturationScore>[]
        : (List.of(scores)..sort((a, b) => a.srsScore.compareTo(b.srsScore)));
    final recommended = sortedByRisk.isEmpty ? null : sortedByRisk.first;

    final crop = recommended?.cropType ?? 'Cabbage';
    final suit = recommended == null ? 92 : (100 - recommended.srsScore.round()).clamp(40, 99);
    final profit = recommended == null ? '₱38k/ha' : '₱${(45 - recommended.srsScore / 5).toStringAsFixed(0)}k/ha';
    final demand = recommended == null
        ? 'HIGH demand'
        : recommended.srsScore < 50 ? 'HIGH demand' : recommended.srsScore < 80 ? 'MODERATE demand' : 'LOW demand';
    final area = 0.8;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF16A34A).withAlpha(80)),
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
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'STRONG RECOMMENDATION',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF047857),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Plant ${area}ha $crop',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF064E3B)),
          ),
          const SizedBox(height: 12),
          _bullet('Excellent suitability ($suit%)'),
          _bullet('Good profit ($profit)'),
          _bullet('$demand (Barangay supply only ${recommended == null ? 65 : (100 - recommended.srsScore.round()).clamp(20, 95)}%)'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFB45309)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Risk: Medium price volatility; ensure quality for ₱18+ pricing.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: onSimulate,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.calculate_outlined, size: 16),
                label: const Text('Simulate', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onCompare,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF16A34A),
                  side: const BorderSide(color: Color(0xFF16A34A)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                label: const Text('Compare Crops', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF065F46)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scenario Comparison ──────────────────────────────────────────────────────

class _ScenarioComparison extends StatelessWidget {
  final List<AgrisenseSaturationScore> scores;
  final _MarketSnapshot? market;

  const _ScenarioComparison({required this.scores, required this.market});

  @override
  Widget build(BuildContext context) {
    final sorted = scores.isEmpty
        ? <AgrisenseSaturationScore>[]
        : (List.of(scores)..sort((a, b) => a.srsScore.compareTo(b.srsScore)));
    final best = sorted.isEmpty ? null : sorted.first;
    final worst = sorted.isEmpty ? null : sorted.last;

    final cropA = best?.cropType ?? 'Cabbage';
    final cropB = worst?.cropType ?? 'Ampalaya';
    final profitA = best == null ? 30400 : (38000 - best.srsScore * 100).round();
    final profitB = worst == null ? 22500 : (38000 - worst.srsScore * 100).round();
    final demandA = best == null || best.srsScore < 60 ? 'Adequate' : 'Oversupply';
    final demandB = worst == null || worst.srsScore >= 60 ? 'Oversupply' : 'Adequate';
    final riskA = best == null ? 'Medium' : best.srsScore < 50 ? 'Low' : best.srsScore < 80 ? 'Medium' : 'High';
    final riskB = worst == null ? 'High' : worst.srsScore < 50 ? 'Low' : worst.srsScore < 80 ? 'Medium' : 'High';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cardA = _scenarioCard(
          label: 'Scenario A',
          title: '0.8ha $cropA',
          profit: profitA,
          demand: demandA,
          risk: riskA,
          accent: const Color(0xFF16A34A),
        );
        final cardB = _scenarioCard(
          label: 'Scenario B',
          title: '0.5ha $cropB',
          profit: profitB,
          demand: demandB,
          risk: riskB,
          accent: const Color(0xFFDC2626),
        );
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cardA),
              const SizedBox(width: 12),
              Expanded(child: cardB),
            ],
          );
        }
        return Column(children: [cardA, const SizedBox(height: 10), cardB]);
      },
    );
  }

  Widget _scenarioCard({
    required String label,
    required String title,
    required int profit,
    required String demand,
    required String risk,
    required Color accent,
  }) {
    final demandOk = demand == 'Adequate';
    final riskColor = risk == 'Low'
        ? const Color(0xFF16A34A)
        : risk == 'Medium'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withAlpha(60), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: accent.withAlpha(30), borderRadius: BorderRadius.circular(999)),
            child: Text(label, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 10),
          _scenarioRow(Icons.attach_money_rounded, 'Expected Profit', '₱${_fmtMoney(profit)}', const Color(0xFF16A34A)),
          _scenarioRow(
            demandOk ? Icons.check_circle_rounded : Icons.cancel_rounded,
            'Market Demand',
            demand,
            demandOk ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
          _scenarioRow(Icons.warning_amber_rounded, 'Risk Level', risk, riskColor),
        ],
      ),
    );
  }

  Widget _scenarioRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  String _fmtMoney(int amount) {
    final str = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}

// ─── Market Intelligence Panel ────────────────────────────────────────────────

class _MarketIntelligencePanel extends StatelessWidget {
  final List<AgrisenseSaturationScore> scores;
  final _MarketSnapshot? market;
  final VoidCallback onViewBuyers;

  const _MarketIntelligencePanel({
    required this.scores,
    required this.market,
    required this.onViewBuyers,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <_PriceTrendRow>[];
    if (market != null) {
      rows.add(_PriceTrendRow(market!.crop, market!.latestPrice, market!.trendPercent ?? 0));
    }
    if (rows.isEmpty || rows.length < 3) {
      // Add fallback data
      final defaults = [
        _PriceTrendRow('Ampalaya', 35.00, 6.5),
        _PriceTrendRow('Talong',   30.00, 3.2),
        _PriceTrendRow('Kamatis',  40.00, -4.1),
        _PriceTrendRow('Okra',     32.00, 8.0),
        _PriceTrendRow('Sitaw',    45.00, 2.5),
      ];
      for (final d in defaults) {
        if (!rows.any((r) => r.crop == d.crop)) rows.add(d);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Current Market Prices (Farm Gate)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
              ),
              Spacer(),
              Text('30-Day Trend', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.take(3).map((r) {
            final up = r.trend >= 0;
            final color = up ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${r.crop}: ₱${r.price.toStringAsFixed(2)}/kg',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                  Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: color, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${up ? '+' : ''}${r.trend.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onViewBuyers,
              icon: const Icon(Icons.storefront_rounded, size: 14),
              label: const Text('View Buyer Directory', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF1B7737)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceTrendRow {
  final String crop;
  final double price;
  final double trend;
  const _PriceTrendRow(this.crop, this.price, this.trend);
}

// ─── Financial Forecast Table ─────────────────────────────────────────────────

class _FinancialForecastTable extends StatelessWidget {
  final List<AgrisenseSaturationScore> scores;
  final _MarketSnapshot? market;

  const _FinancialForecastTable({required this.scores, required this.market});

  @override
  Widget build(BuildContext context) {
    final sorted = scores.isEmpty
        ? <AgrisenseSaturationScore>[]
        : (List.of(scores)..sort((a, b) => a.srsScore.compareTo(b.srsScore)));
    final crop = sorted.isEmpty ? 'Cabbage' : sorted.first.cropType;

    final now = DateTime.now();
    final months = List.generate(4, (i) {
      final d = DateTime(now.year, now.month + i);
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return monthNames[(d.month - 1) % 12];
    });

    final rows = <_ForecastRow>[
      _ForecastRow(months[0], 15000, 0, -15000, 'Seed, fert, labor'),
      _ForecastRow(months[1], 8000, 0, -23000, 'Maintenance'),
      _ForecastRow(months[2], 2000, 0, -25000, 'Pest control'),
      _ForecastRow(months[3], 0, 48000, 23000, 'Harvest & sale'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B7737).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF1B7737), size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'Assuming $crop planting (1 hectare)',
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 600),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 70, child: Text('Month', style: _hStyle)),
                        SizedBox(width: 110, child: Text('Input Cost', style: _hStyle)),
                        SizedBox(width: 110, child: Text('Revenue', style: _hStyle)),
                        SizedBox(width: 130, child: Text('Cash Balance', style: _hStyle)),
                        SizedBox(width: 160, child: Text('Notes', style: _hStyle)),
                      ],
                    ),
                  ),
                  ...rows.map((r) {
                    final balanceColor = r.balance >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 70, child: Text(r.month, style: _cellStyle)),
                          SizedBox(
                            width: 110,
                            child: Text(
                              r.cost == 0 ? '-' : '₱${_fmt(r.cost)}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: Text(
                              r.revenue == 0 ? '-' : '₱${_fmt(r.revenue)}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: Text(
                              '${r.balance < 0 ? '-' : ''}₱${_fmt(r.balance.abs())}',
                              style: TextStyle(fontSize: 12, color: balanceColor, fontWeight: FontWeight.w700),
                            ),
                          ),
                          SizedBox(width: 160, child: Text(r.notes, style: _cellStyle)),
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

  static const _hStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF666666));
  static const _cellStyle = TextStyle(fontSize: 12, color: Color(0xFF1A1A1A));

  String _fmt(int amount) {
    final str = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}

class _ForecastRow {
  final String month;
  final int cost;
  final int revenue;
  final int balance;
  final String notes;
  const _ForecastRow(this.month, this.cost, this.revenue, this.balance, this.notes);
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
