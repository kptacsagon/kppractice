import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/agri_dss_models.dart';
import '../../services/agri_dss_service.dart';

const _kGreen = Color(0xFF1B7737);
const _kBg = Color(0xFFF0F5F1);
final _php = NumberFormat('#,##0.00', 'en_PH');
final _pct = NumberFormat('+#,##0.0;−#,##0.0', 'en_PH');

class AgriFinancialDssScreen extends StatefulWidget {
  const AgriFinancialDssScreen({super.key});
  @override
  State<AgriFinancialDssScreen> createState() => _AgriFinancialDssScreenState();
}

class _AgriFinancialDssScreenState extends State<AgriFinancialDssScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _svc = AgriDssService();
  List<CroppingCycle> _cycles = [];
  bool _loading = true;
  String? _filterCommodity;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _svc.getCycles();
    if (!mounted) return;
    setState(() { _cycles = data; _loading = false; });
  }

  List<CroppingCycle> get _filtered =>
      _filterCommodity == null ? _cycles : _cycles.where((c) => c.commodity == _filterCommodity).toList();

  List<String> get _commodities => _cycles.map((c) => c.commodity).toSet().toList()..sort();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        // ── Header ──
        Container(
          color: _kGreen,
          padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 0),
          child: Column(children: [
            Row(children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AgriFinancial DSS', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                Text('MAR · PPI · IUR  — Tubungan, Iloilo', style: TextStyle(color: Color(0xFFB2D9B8), fontSize: 11)),
              ])),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20)),
            ]),
            const SizedBox(height: 10),
            TabBar(
              controller: _tabs,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Profit'),
                Tab(text: 'Alerts'),
                Tab(text: 'Cycles'),
                Tab(text: 'Markets'),
              ],
            ),
          ]),
        ),
        // ── Body ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _kGreen))
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _ProfitTab(cycles: _filtered, commodities: _commodities,
                        filter: _filterCommodity, onFilter: (v) => setState(() => _filterCommodity = v)),
                    _AlertsTab(cycles: _cycles, svc: _svc),
                    _CyclesTab(cycles: _cycles, svc: _svc),
                    _MarketsTab(cycles: _filtered),
                  ],
                ),
        ),
      ]),
    );
  }
}

// ─── Tab 1: Profit Calculator ────────────────────────────────────────────────

class _ProfitTab extends StatelessWidget {
  final List<CroppingCycle> cycles;
  final List<String> commodities;
  final String? filter;
  final void Function(String?) onFilter;
  const _ProfitTab({required this.cycles, required this.commodities, this.filter, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    if (cycles.isEmpty) return _emptyState('No cropping cycle data recorded yet.');
    final sorted = [...cycles]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return Column(children: [
      // Commodity filter
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SizedBox(
          height: 30,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _filterChip('All', filter == null, () => onFilter(null)),
              ...commodities.map((c) => _filterChip(c, filter == c, () => onFilter(c))),
            ],
          ),
        ),
      ),
      // Summary cards
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            _SummaryKpiRow(cycles: cycles),
            const SizedBox(height: 14),
            ...sorted.map((c) => _CycleCard(c: c)),
          ]),
        ),
      ),
    ]);
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? _kGreen : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : const Color(0xFF374151)))),
    ),
  );
}

class _SummaryKpiRow extends StatelessWidget {
  final List<CroppingCycle> cycles;
  const _SummaryKpiRow({required this.cycles});
  @override
  Widget build(BuildContext context) {
    final totalRev  = cycles.fold(0.0, (s, c) => s + c.grossRevenue);
    final totalNet  = cycles.fold(0.0, (s, c) => s + c.netMargin);
    final avgMar    = cycles.isEmpty ? 0.0 : cycles.map((c) => c.mar).reduce((a, b) => a + b) / cycles.length;
    final avgPpi    = cycles.isEmpty ? 0.0 : cycles.map((c) => c.ppi).reduce((a, b) => a + b) / cycles.length;
    return Row(children: [
      Expanded(child: _kpi('Total Revenue', 'PHP ${_php.format(totalRev)}', _kGreen, Icons.payments_rounded)),
      const SizedBox(width: 10),
      Expanded(child: _kpi('Net Margin', 'PHP ${_php.format(totalNet)}', totalNet >= 0 ? _kGreen : const Color(0xFFDC2626), Icons.trending_up_rounded)),
      const SizedBox(width: 10),
      Expanded(child: _kpi('Avg MAR', '${(avgMar * 100).toStringAsFixed(1)}%', const Color(0xFF2563EB), Icons.shopping_bag_rounded)),
      const SizedBox(width: 10),
      Expanded(child: _kpi('Avg PPI', '${_pct.format(avgPpi)}%', avgPpi >= 0 ? _kGreen : const Color(0xFFF59E0B), Icons.price_change_rounded)),
    ]);
  }

  Widget _kpi(String label, String value, Color color, IconData icon) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
    ]),
  );
}

class _CycleCard extends StatelessWidget {
  final CroppingCycle c;
  const _CycleCard({required this.c});
  @override
  Widget build(BuildContext context) {
    final marginColor = c.netMargin >= 0 ? _kGreen : const Color(0xFFDC2626);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          const Icon(Icons.eco_rounded, color: _kGreen, size: 15),
          const SizedBox(width: 6),
          Expanded(child: Text('${c.commodity}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
          _confidenceBadge(c.confidenceLevel),
        ]),
        const SizedBox(height: 2),
        Text('${c.seasonName}  ·  ${c.barangay}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        if (c.dataSource != null) Text('Source: ${c.dataSource}', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        const Divider(height: 16),
        // Three metrics row
        Row(children: [
          _metric('MAR', '${(c.mar * 100).toStringAsFixed(1)}%', 'Sold ratio', const Color(0xFF2563EB)),
          _metric('PPI', '${_pct.format(c.ppi)}%', 'vs baseline', c.ppi >= 0 ? _kGreen : const Color(0xFFF59E0B)),
          _metric('IUR', '${(c.iur * 100).toStringAsFixed(1)}%', 'Unsold', c.iur < 0.2 ? _kGreen : const Color(0xFFEF4444)),
        ]),
        const Divider(height: 16),
        // Financial breakdown
        _finRow('Gross Revenue', c.grossRevenue, const Color(0xFF2563EB)),
        _finRow('Input + Labor', -(c.inputCostPhp + c.laborCostPhp), const Color(0xFF6B7280)),
        _finRow('Gross Margin', c.grossMargin, c.grossMargin >= 0 ? _kGreen : const Color(0xFFEF4444)),
        _finRow('Land + Transport', -(c.landCostPhp + c.transportCostPhp), const Color(0xFF6B7280)),
        const Divider(height: 10, thickness: 1),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Net Margin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('PHP ${_php.format(c.netMargin)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: marginColor)),
            Text('${c.marginRate.toStringAsFixed(1)}% margin rate', style: TextStyle(fontSize: 10, color: marginColor)),
          ]),
        ]),
      ]),
    );
  }

  Widget _metric(String code, String value, String sub, Color color) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(code, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        Text(sub, style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
      ]),
    ),
  );

  Widget _finRow(String label, double amount, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      Text(
        amount >= 0 ? 'PHP ${_php.format(amount)}' : '− PHP ${_php.format(amount.abs())}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    ]),
  );

  Widget _confidenceBadge(String level) {
    final color = level == 'High' ? _kGreen : level == 'Medium' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
      child: Text(level, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Tab 2: Alerts ───────────────────────────────────────────────────────────

class _AlertsTab extends StatelessWidget {
  final List<CroppingCycle> cycles;
  final AgriDssService svc;
  const _AlertsTab({required this.cycles, required this.svc});

  @override
  Widget build(BuildContext context) {
    final alerts = svc.allAlerts(cycles);
    if (alerts.isEmpty) {
      return _emptyState('No financial alerts. All metrics within normal range.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _AlertCard(a: alerts[i]),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final FinancialAlert a;
  const _AlertCard({required this.a});
  @override
  Widget build(BuildContext context) {
    final color = a.severity.color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
          child: Icon(a.severity.icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(a.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
              child: Text(a.severity.label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(a.description, style: const TextStyle(fontSize: 11, color: Color(0xFF374151), height: 1.4)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF0F5F1), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline_rounded, size: 13, color: _kGreen),
              const SizedBox(width: 6),
              Expanded(child: Text(a.recommendation, style: const TextStyle(fontSize: 11, color: _kGreen, height: 1.4))),
            ]),
          ),
          const SizedBox(height: 4),
          Text(DateFormat('MMM d, yyyy').format(a.triggeredAt), style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ])),
      ]),
    );
  }
}

// ─── Tab 3: Crop Comparison Across Cycles ────────────────────────────────────

class _CyclesTab extends StatelessWidget {
  final List<CroppingCycle> cycles;
  final AgriDssService svc;
  const _CyclesTab({required this.cycles, required this.svc});

  @override
  Widget build(BuildContext context) {
    final commodities = cycles.map((c) => c.commodity).toSet().toList()..sort();
    if (commodities.isEmpty) return _emptyState('No cycle data available.');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: commodities.map((comm) {
        final forCrop = cycles.where((c) => c.commodity == comm).toList()
          ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
        final recs = svc.cropSwitchRecommendations(cycles, comm);
        return _CropCycleBlock(commodity: comm, cycles: forCrop, switchRecs: recs);
      }).toList()),
    );
  }
}

class _CropCycleBlock extends StatelessWidget {
  final String commodity;
  final List<CroppingCycle> cycles;
  final List<String> switchRecs;
  const _CropCycleBlock({required this.commodity, required this.cycles, required this.switchRecs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF0F5F1),
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            const Icon(Icons.grass_rounded, size: 15, color: _kGreen),
            const SizedBox(width: 8),
            Text(commodity, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kGreen)),
            const SizedBox(width: 8),
            Text('${cycles.length} cycle${cycles.length == 1 ? "" : "s"}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Cycle comparison table
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.2),
                4: FlexColumnWidth(1.5),
              },
              children: [
                _headerRow(),
                ...cycles.map(_dataRow),
              ],
            ),
            // Trend indicators
            if (cycles.length >= 2) ...[
              const SizedBox(height: 12),
              _trendIndicators(cycles),
            ],
            // Crop switch recommendation
            if (switchRecs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.swap_horiz_rounded, color: Color(0xFFF59E0B), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Crop Switch Recommended', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                    const SizedBox(height: 3),
                    Text('IUR > 30% in 2+ consecutive cycles. Consider switching to:', style: const TextStyle(fontSize: 11, color: Color(0xFF78350F))),
                    const SizedBox(height: 4),
                    ...switchRecs.asMap().entries.map((e) => Row(children: [
                      Container(
                        width: 18, height: 18,
                        margin: const EdgeInsets.only(right: 6, bottom: 3),
                        decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(4)),
                        child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
                      ),
                      Text(e.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ])),
                  ])),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  TableRow _headerRow() => TableRow(
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
    children: ['Season', 'MAR', 'PPI', 'IUR', 'Net Margin'].map((h) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(h, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
    )).toList(),
  );

  TableRow _dataRow(CroppingCycle c) => TableRow(
    children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text(c.seasonName, style: const TextStyle(fontSize: 10))),
      _cell('${(c.mar * 100).toStringAsFixed(0)}%', c.mar >= 0.8 ? _kGreen : const Color(0xFFF59E0B)),
      _cell('${_pct.format(c.ppi)}%', c.ppi >= 0 ? _kGreen : const Color(0xFFEF4444)),
      _cell('${(c.iur * 100).toStringAsFixed(0)}%', c.iur < 0.2 ? _kGreen : const Color(0xFFEF4444)),
      _cell('₱${_php.format(c.netMargin)}', c.netMargin >= 0 ? _kGreen : const Color(0xFFEF4444)),
    ],
  );

  Widget _cell(String text, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );

  Widget _trendIndicators(List<CroppingCycle> clist) {
    final prev = clist[clist.length - 2];
    final curr = clist.last;
    final netDiff = curr.netMargin - prev.netMargin;
    final marDiff = curr.mar - prev.mar;
    return Row(children: [
      _trendChip('Net Margin', netDiff, 'PHP', isPercent: false),
      const SizedBox(width: 8),
      _trendChip('MAR', marDiff * 100, '%', isPercent: true),
      const SizedBox(width: 8),
      _trendChip('PPI', curr.ppi - prev.ppi, 'pp', isPercent: true),
    ]);
  }

  Widget _trendChip(String label, double diff, String unit, {required bool isPercent}) {
    final up = diff >= 0;
    final color = up ? _kGreen : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: color, size: 12),
        const SizedBox(width: 3),
        Text('$label ${diff.abs().toStringAsFixed(isPercent ? 1 : 0)}$unit', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── Tab 4: Market Price Comparison ─────────────────────────────────────────

class _MarketsTab extends StatelessWidget {
  final List<CroppingCycle> cycles;
  const _MarketsTab({required this.cycles});

  @override
  Widget build(BuildContext context) {
    if (cycles.isEmpty) return _emptyState('No cycle data for market comparison.');
    final svc = AgriDssService();
    // Get most recent cycle per commodity
    final latest = <String, CroppingCycle>{};
    for (final c in cycles) {
      if (!latest.containsKey(c.commodity) || c.recordedAt.isAfter(latest[c.commodity]!.recordedAt)) {
        latest[c.commodity] = c;
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: latest.values.map((cycle) {
        final destinations = svc.getMarketDestinations(cycle);
        final best = destinations.reduce((a, b) => a.effectiveNetPrice > b.effectiveNetPrice ? a : b);
        return _MarketCard(cycle: cycle, destinations: destinations, bestName: best.name);
      }).toList()),
    );
  }
}

class _MarketCard extends StatelessWidget {
  final CroppingCycle cycle;
  final List<MarketDestination> destinations;
  final String bestName;
  const _MarketCard({required this.cycle, required this.destinations, required this.bestName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF0F5F1),
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            const Icon(Icons.storefront_rounded, size: 15, color: _kGreen),
            const SizedBox(width: 8),
            Text('${cycle.commodity} — Market Comparison', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kGreen)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: destinations.map((d) {
            final isBest = d.name == bestName;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isBest ? const Color(0xFFDCFCE7) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isBest ? _kGreen : const Color(0xFFE5E7EB)),
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(d.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    if (isBest) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(4)),
                        child: const Text('Best', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                  Text(_destTypeLabel(d.type), style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₱${d.effectiveNetPrice.toStringAsFixed(2)}/kg', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isBest ? _kGreen : const Color(0xFF374151))),
                  Text('Price: ₱${d.pricePerKg.toStringAsFixed(2)}  Transport: ₱${d.transportCostPerKg.toStringAsFixed(2)}', style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
                ]),
              ]),
            );
          }).toList()),
        ),
      ]),
    );
  }

  String _destTypeLabel(String type) {
    switch (type) {
      case 'local_lgu': return 'Local LGU Market';
      case 'regional_hub': return 'Regional Hub';
      case 'provincial_market': return 'Provincial Market';
      default: return type;
    }
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Widget _emptyState(String msg) => Center(
  child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.inbox_rounded, size: 56, color: Color(0xFFD1D5DB)),
    const SizedBox(height: 12),
    Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
  ]),
);
