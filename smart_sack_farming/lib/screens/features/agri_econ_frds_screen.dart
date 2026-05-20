// ─────────────────────────────────────────────────────────────────────────────
// AgriEcon-FRDS — Agricultural Economic Intelligence & Financial Risk DSS
// Main hub screen + all 7 module screens (M1–M7).
// Designed per PRD v1.0 — Thesis & Capstone Edition.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/agri_econ_frds_service.dart';

// ─── Design tokens ───────────────────────────────────────────────────────────

const _kGreen     = Color(0xFF1B7737);
const _kGreenDark = Color(0xFF154D26);
const _kGold      = Color(0xFFC79A2A);
const _kBg        = Color(0xFFF3F4F6);
const _kCard      = Colors.white;
const _kBorder    = Color(0xFFE5E7EB);
const _kText      = Color(0xFF111827);
const _kMuted     = Color(0xFF6B7280);
const _kRed       = Color(0xFFDC2626);
const _kAmber     = Color(0xFFF59E0B);
const _kBlue      = Color(0xFF2563EB);

final _php = NumberFormat('#,##0.00', 'en_PH');
final _phpWhole = NumberFormat('#,##0', 'en_PH');

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN HUB
// ═══════════════════════════════════════════════════════════════════════════════

class AgriEconFrdsScreen extends StatelessWidget {
  const AgriEconFrdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              sliver: SliverList(delegate: SliverChildListDelegate([
                const _MissionBanner(),
                const SizedBox(height: 16),
                _SectionTitle('Module Architecture', 'Tap any module to open its dashboard'),
                const SizedBox(height: 12),
                _moduleCard(context, 1, 'Advanced Financial Modeling',
                  'P&L, break-even, scenario modeling', Icons.show_chart_rounded, _kGreen,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const M1FinancialModelingScreen()))),
                _moduleCard(context, 2, 'Risk-Adjusted Profitability',
                  'Monte Carlo · VaR · Composite Risk Score', Icons.assessment_rounded, _kBlue,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const M2RiskProfitabilityScreen()))),
                _moduleCard(context, 3, 'Oversupply Prediction System',
                  'Harvest calendar · ORI · Early warning', Icons.warning_amber_rounded, _kAmber,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const M3OversupplyScreen()))),
                _moduleCard(context, 4, 'Debt & Loan Analytics',
                  'DSCR · DDS · Restructuring simulator', Icons.account_balance_rounded, _kRed,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const M4DebtLoanScreen()))),
                _moduleCard(context, 5, 'Behavioral Farmer Modeling',
                  'Prospect Theory · Cognitive bias flags', Icons.psychology_rounded, const Color(0xFF7C3AED),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const M5BehavioralScreen()))),
                _moduleCard(context, 6, 'Intervention Economics',
                  'CBA · BCR · ROPI · Scenario engine', Icons.engineering_rounded, _kGold,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const M6InterventionScreen()))),
                _moduleCard(context, 7, 'Municipal Agricultural Intelligence',
                  'Heatmaps · Benchmarks · LGU dashboards', Icons.map_rounded, _kGreenDark,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const M7MunicipalIntelScreen()))),
                const SizedBox(height: 20),
                _SectionTitle('System Snapshot', 'Live metrics aggregated across all modules'),
                const SizedBox(height: 12),
                const _SnapshotPanel(),
                const SizedBox(height: 32),
              ])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard(BuildContext context, int n, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kCard, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                  child: Text('M$n', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kText))),
              ]),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: _kMuted, height: 1.3)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: _kMuted),
          ]),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [_kGreenDark, _kGreen]),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: Colors.white.withAlpha(35), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.insights_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AgriEcon-FRDS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            Text('Agricultural Economic Intelligence & Financial Risk DSS',
                style: TextStyle(color: Color(0xFFB2D9B8), fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _kGold.withAlpha(60), borderRadius: BorderRadius.circular(6)),
            child: const Text('v1.0', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 18),
        // KPI strip
        Row(children: [
          Expanded(child: _hdrKpi('6', 'Active Crops')),
          const SizedBox(width: 10),
          Expanded(child: _hdrKpi('5', 'Barangays')),
          const SizedBox(width: 10),
          Expanded(child: _hdrKpi('7', 'Modules')),
          const SizedBox(width: 10),
          Expanded(child: _hdrKpi('PHP 8.0M', 'GVA Tracked')),
        ]),
      ]),
    );
  }

  Widget _hdrKpi(String value, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withAlpha(40))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Color(0xFFB2D9B8), fontSize: 10)),
    ]),
  );
}

class _MissionBanner extends StatelessWidget {
  const _MissionBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F1E8), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.flag_rounded, color: _kGreen, size: 18),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Core Mission',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _kGreenDark)),
          SizedBox(height: 4),
          Text(
            'Transform raw agricultural & financial field data into risk-adjusted insights that protect farmer livelihoods, optimize resource allocation, and enable evidence-based LGU policy — before crises occur, not after.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF166534), height: 1.45)),
        ])),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle(this.title, [this.subtitle]);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kText)),
    if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2),
      child: Text(subtitle!, style: const TextStyle(fontSize: 11, color: _kMuted))),
  ]);
}

class _SnapshotPanel extends StatelessWidget {
  const _SnapshotPanel();
  @override
  Widget build(BuildContext context) {
    final svc = AgriEconFrdsService();
    final cycles = svc.cropCycles;
    final totalRevenue = cycles.fold(0.0, (s, c) => s + c.grossRevenue);
    final totalNfi = cycles.fold(0.0, (s, c) => s + c.netFarmIncome);
    final activeAlerts = svc.activeAlerts().length;
    final highRiskCount = cycles.where((c) {
      final mc = RiskAnalyzer.monteCarlo(c, iterations: 200);
      return RiskAnalyzer.crs(c, mc).total > 55;
    }).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder)),
      child: Column(children: [
        Row(children: [
          Expanded(child: _snapKpi('Total Revenue', 'PHP ${_phpWhole.format(totalRevenue)}', _kGreen, Icons.payments_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _snapKpi('Aggregate NFI', 'PHP ${_phpWhole.format(totalNfi)}',
              totalNfi >= 0 ? _kGreen : _kRed, Icons.trending_up_rounded)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _snapKpi('Active Alerts', '$activeAlerts', _kAmber, Icons.notifications_active_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _snapKpi('High/Crit Risk', '$highRiskCount records', _kRed, Icons.warning_rounded)),
        ]),
      ]),
    );
  }

  Widget _snapKpi(String label, String value, Color color, IconData icon) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 14),
      ),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: _kMuted, fontSize: 9.5)),
      ])),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED MODULE CHROME
// ═══════════════════════════════════════════════════════════════════════════════

Widget _moduleScaffold({
  required BuildContext context,
  required int moduleNum,
  required String title,
  required String subtitle,
  required Color accent,
  required Widget body,
  List<Widget>? actions,
}) {
  return Scaffold(
    backgroundColor: _kBg,
    body: SafeArea(child: Column(children: [
      Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [accent.withAlpha(220), accent])),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(6)),
            child: Text('M$moduleNum', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            Text(subtitle, style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 11)),
          ])),
          if (actions != null) ...actions,
        ]),
      ),
      Expanded(child: body),
    ])),
  );
}

Widget _card({required String title, String? subtitle, required Widget child, EdgeInsets? padding}) =>
  Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: padding ?? const EdgeInsets.all(14),
    decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _kBorder),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kText)),
      if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle, style: const TextStyle(fontSize: 11, color: _kMuted))),
      const SizedBox(height: 12),
      child,
    ]),
  );

Widget _kpi(String label, String value, Color color, {IconData? icon}) => Container(
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10)),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (icon != null) Padding(padding: const EdgeInsets.only(bottom: 4),
      child: Icon(icon, color: color, size: 14)),
    Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: const TextStyle(fontSize: 10, color: _kMuted)),
  ]),
);

Widget _label(String t) => Text(t,
  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted));

Widget _row2(String k, String v, {Color? c}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 2),
  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(k, style: const TextStyle(fontSize: 11.5, color: _kMuted)),
    Text(v, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c ?? _kText)),
  ]),
);

// ═══════════════════════════════════════════════════════════════════════════════
// M1 — Advanced Financial Modeling
// ═══════════════════════════════════════════════════════════════════════════════

class M1FinancialModelingScreen extends StatefulWidget {
  const M1FinancialModelingScreen({super.key});
  @override
  State<M1FinancialModelingScreen> createState() => _M1State();
}

class _M1State extends State<M1FinancialModelingScreen> {
  late CropCycleRecord _selected;
  final _svc = AgriEconFrdsService();

  @override
  void initState() {
    super.initState();
    _selected = _svc.cropCycles.first;
  }

  @override
  Widget build(BuildContext context) {
    return _moduleScaffold(
      context: context, moduleNum: 1,
      title: 'Advanced Financial Modeling',
      subtitle: 'P&L · Break-even · Multi-Scenario',
      accent: _kGreen,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _farmerSelector(),
          const SizedBox(height: 6),
          _pnlCard(),
          _breakEvenCard(),
          _costCompositionCard(),
          _scenariosCard(),
          _yoyTrendCard(),
        ]),
      ),
    );
  }

  Widget _farmerSelector() => _card(
    title: 'Crop Cycle Record',
    subtitle: 'Select a farmer-crop record to view full P&L decomposition',
    child: DropdownButtonFormField<String>(
      value: _selected.id,
      isExpanded: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: _svc.cropCycles.map((c) => DropdownMenuItem(value: c.id,
        child: Text('${c.farmerName} · ${c.crop} (${c.variety}) · ${c.barangay}',
            style: const TextStyle(fontSize: 12)))).toList(),
      onChanged: (v) => setState(() => _selected = _svc.cropCycles.firstWhere((c) => c.id == v)),
    ),
  );

  Widget _pnlCard() {
    final r = _selected;
    return _card(
      title: 'Crop Cycle Profit & Loss Statement',
      subtitle: '${r.crop} · ${r.areaHa.toStringAsFixed(2)} ha · ${r.barangay}',
      child: Column(children: [
        Row(children: [
          Expanded(child: _kpi('Gross Revenue', 'PHP ${_phpWhole.format(r.grossRevenue)}', _kBlue, icon: Icons.payments_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _kpi('Total Costs', 'PHP ${_phpWhole.format(r.totalCost)}', _kRed, icon: Icons.remove_circle_outline_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _kpi('Net Farm Income', 'PHP ${_phpWhole.format(r.netFarmIncome)}',
              r.netFarmIncome >= 0 ? _kGreen : _kRed, icon: Icons.trending_up_rounded)),
        ]),
        const Divider(height: 22),
        _row2('Yield', '${_phpWhole.format(r.yieldKg)} kg'),
        _row2('Farm Gate Price', 'PHP ${r.farmGatePrice.toStringAsFixed(2)}/kg'),
        const SizedBox(height: 8),
        _label('Variable Costs (TVC)'),
        const SizedBox(height: 4),
        _row2('  Seeds', 'PHP ${_php.format(r.seedCost)}'),
        _row2('  Fertilizer', 'PHP ${_php.format(r.fertilizerCost)}'),
        _row2('  Pesticide/Herbicide', 'PHP ${_php.format(r.pesticideCost)}'),
        _row2('  Hired Labor', 'PHP ${_php.format(r.laborCost)}'),
        _row2('  Irrigation', 'PHP ${_php.format(r.irrigationCost)}'),
        _row2('  Transport', 'PHP ${_php.format(r.transportCost)}'),
        _row2('  Total Variable Cost', 'PHP ${_php.format(r.totalVariableCost)}', c: _kRed),
        const SizedBox(height: 6),
        _label('Fixed Costs (TFC)'),
        const SizedBox(height: 4),
        _row2('  Land Rental/Amortization', 'PHP ${_php.format(r.landCost)}'),
        _row2('  Equipment Depreciation', 'PHP ${_php.format(r.equipmentDeprec)}'),
        _row2('  Total Fixed Cost', 'PHP ${_php.format(r.totalFixedCost)}', c: _kRed),
        const Divider(height: 20),
        _row2('Contribution Margin (CM)', 'PHP ${_php.format(r.contributionMargin)}', c: _kBlue),
        _row2('Contribution Margin Ratio (CMR)', '${r.cmr.toStringAsFixed(1)}%', c: _kBlue),
      ]),
    );
  }

  Widget _breakEvenCard() {
    final r = _selected;
    final aboveBep = r.farmGatePrice > r.breakEvenPrice;
    return _card(
      title: 'Break-Even Analysis',
      subtitle: 'Computed per PRD §5.2.2',
      child: Column(children: [
        Row(children: [
          Expanded(child: _kpi('Break-Even Price', 'PHP ${r.breakEvenPrice.toStringAsFixed(2)}/kg', _kAmber)),
          const SizedBox(width: 10),
          Expanded(child: _kpi('Break-Even Revenue', 'PHP ${_phpWhole.format(r.breakEvenRevenue)}', _kAmber)),
          const SizedBox(width: 10),
          Expanded(child: _kpi('Safety Margin', '${r.safetyMarginPct.toStringAsFixed(1)}%',
              r.safetyMarginPct >= 0 ? _kGreen : _kRed)),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (aboveBep ? _kGreen : _kRed).withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: (aboveBep ? _kGreen : _kRed).withAlpha(60)),
          ),
          child: Row(children: [
            Icon(aboveBep ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: aboveBep ? _kGreen : _kRed, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              aboveBep
                ? 'Farm gate price (PHP ${r.farmGatePrice.toStringAsFixed(2)}) is above break-even — every kg sold contributes profit.'
                : 'Farm gate price (PHP ${r.farmGatePrice.toStringAsFixed(2)}) is below break-even — operation at a loss.',
              style: TextStyle(fontSize: 11.5, color: aboveBep ? _kGreenDark : _kRed, fontWeight: FontWeight.w600),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _costCompositionCard() {
    final r = _selected;
    final parts = [
      ('Seeds', r.seedCost, const Color(0xFF10B981)),
      ('Fertilizer', r.fertilizerCost, const Color(0xFF3B82F6)),
      ('Pesticide', r.pesticideCost, const Color(0xFFF59E0B)),
      ('Labor', r.laborCost, const Color(0xFFEF4444)),
      ('Irrigation', r.irrigationCost, const Color(0xFF06B6D4)),
      ('Transport', r.transportCost, const Color(0xFF8B5CF6)),
      ('Land', r.landCost, const Color(0xFFEAB308)),
      ('Equipment', r.equipmentDeprec, const Color(0xFF6B7280)),
    ];
    final total = parts.fold(0.0, (s, p) => s + p.$2);
    return _card(
      title: 'Input Cost Composition',
      subtitle: 'Total cost breakdown by category',
      child: Column(children: [
        SizedBox(height: 160, child: PieChart(PieChartData(
          sectionsSpace: 2, centerSpaceRadius: 38,
          sections: parts.map((p) {
            final pct = total == 0 ? 0 : (p.$2 / total) * 100;
            return PieChartSectionData(
              value: p.$2.toDouble(), color: p.$3,
              title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
              titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
              radius: 50,
            );
          }).toList(),
        ))),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 6, children: parts.map((p) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: p.$3, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(p.$1, style: const TextStyle(fontSize: 10.5, color: _kText)),
        ])).toList()),
      ]),
    );
  }

  Widget _scenariosCard() {
    final r = _selected;
    final base   = FinancialScenario.base.computeNfi(r);
    final opt    = FinancialScenario.optimistic.computeNfi(r);
    final pess   = FinancialScenario.pessimistic.computeNfi(r);
    final maxAbs = [base, opt, pess].map((x) => x.abs()).reduce((a, b) => a > b ? a : b);
    return _card(
      title: 'Multi-Scenario Modeling',
      subtitle: 'Base · Optimistic · Pessimistic NFI per PRD §5.2.3',
      child: Column(children: [
        _scenarioBar('Optimistic', opt, _kGreen, maxAbs, '−15% input · +20% yield · +10% price'),
        _scenarioBar('Base Case', base, _kBlue, maxAbs, 'Current input · yield · price assumptions'),
        _scenarioBar('Pessimistic', pess, _kRed, maxAbs, '+20% input · −25% yield · −30% price'),
      ]),
    );
  }

  Widget _scenarioBar(String label, double value, Color color, double maxAbs, String desc) {
    final w = maxAbs == 0 ? 0.0 : value.abs() / maxAbs;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kText))),
          Text('PHP ${_phpWhole.format(value)}',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: value >= 0 ? color : _kRed)),
        ]),
        const SizedBox(height: 4),
        Container(height: 8, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)),
          child: FractionallySizedBox(widthFactor: w, alignment: Alignment.centerLeft,
            child: Container(decoration: BoxDecoration(color: value >= 0 ? color : _kRed, borderRadius: BorderRadius.circular(4))),
          )),
        const SizedBox(height: 3),
        Text(desc, style: const TextStyle(fontSize: 10, color: _kMuted)),
      ]),
    );
  }

  Widget _yoyTrendCard() {
    final r = _selected;
    // Synthetic 5-season trend around current NFI
    final base = r.netFarmIncome;
    final spots = <FlSpot>[
      FlSpot(0, base * 0.72), FlSpot(1, base * 0.86),
      FlSpot(2, base * 0.94), FlSpot(3, base * 1.05),
      FlSpot(4, base),
    ];
    return _card(
      title: 'Year-Over-Year NFI Trend',
      subtitle: '5-season history for ${r.farmerName}',
      child: SizedBox(height: 180, child: LineChart(LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22,
            getTitlesWidget: (v, _) => Text('S${v.toInt() + 1}', style: const TextStyle(fontSize: 10, color: _kMuted)))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50,
            getTitlesWidget: (v, _) => Text('₱${(v / 1000).toStringAsFixed(0)}k',
                style: const TextStyle(fontSize: 9, color: _kMuted)))),
        ),
        lineBarsData: [LineChartBarData(
          spots: spots, isCurved: true, color: _kGreen, barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: true, color: _kGreen.withAlpha(20)),
        )],
      ))),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// M2 — Risk-Adjusted Profitability
// ═══════════════════════════════════════════════════════════════════════════════

class M2RiskProfitabilityScreen extends StatefulWidget {
  const M2RiskProfitabilityScreen({super.key});
  @override
  State<M2RiskProfitabilityScreen> createState() => _M2State();
}

class _M2State extends State<M2RiskProfitabilityScreen> {
  late CropCycleRecord _selected;
  late MonteCarloResult _mc;
  late CompositeRiskScore _crs;
  final _svc = AgriEconFrdsService();
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _selected = _svc.cropCycles.first;
    _runSimulation();
  }

  void _runSimulation() {
    setState(() => _running = true);
    _mc = RiskAnalyzer.monteCarlo(_selected, iterations: 1000);
    _crs = RiskAnalyzer.crs(_selected, _mc);
    setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    return _moduleScaffold(
      context: context, moduleNum: 2,
      title: 'Risk-Adjusted Profitability',
      subtitle: 'Monte Carlo · VaR · CRS',
      accent: _kBlue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _selectorCard(),
          _mcSummaryCard(),
          _varCard(),
          _crsCard(),
          _distributionCard(),
          _topRiskList(),
        ]),
      ),
    );
  }

  Widget _selectorCard() => _card(
    title: 'Monte Carlo Simulation',
    subtitle: '1,000 iterations per PRD §6.3 — sampling price, yield, cost, weather',
    child: Column(children: [
      DropdownButtonFormField<String>(
        value: _selected.id,
        isExpanded: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        items: _svc.cropCycles.map((c) => DropdownMenuItem(value: c.id,
          child: Text('${c.farmerName} · ${c.crop}', style: const TextStyle(fontSize: 12)))).toList(),
        onChanged: (v) {
          setState(() => _selected = _svc.cropCycles.firstWhere((c) => c.id == v));
          _runSimulation();
        },
      ),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: _running ? null : _runSimulation,
        icon: _running
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.play_arrow_rounded, size: 16),
        label: const Text('Re-run Simulation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(backgroundColor: _kBlue, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      )),
    ]),
  );

  Widget _mcSummaryCard() => _card(
    title: 'Simulation Output Summary',
    child: Column(children: [
      Row(children: [
        Expanded(child: _kpi('Expected NFI', 'PHP ${_phpWhole.format(_mc.expectedNfi)}',
            _mc.expectedNfi >= 0 ? _kGreen : _kRed, icon: Icons.trending_up_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _kpi('Std. Deviation', 'PHP ${_phpWhole.format(_mc.stdDev)}', _kAmber, icon: Icons.show_chart_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _kpi('P(Loss)', '${(_mc.probLoss * 100).toStringAsFixed(1)}%',
            _mc.probLoss > 0.3 ? _kRed : _kGreen, icon: Icons.warning_amber_rounded)),
      ]),
    ]),
  );

  Widget _varCard() => _card(
    title: 'Value-at-Risk (VaR)',
    subtitle: 'Confidence-bounded worst-case NFI',
    child: Column(children: [
      _row2('VaR @ 90% Confidence', 'PHP ${_phpWhole.format(_mc.var90)}',
          c: _mc.var90 >= 0 ? _kGreen : _kRed),
      _row2('VaR @ 95% Confidence', 'PHP ${_phpWhole.format(_mc.var95)}',
          c: _mc.var95 >= 0 ? _kGreen : _kRed),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBFDBFE))),
        child: Text(
          'With 95% confidence, this farmer\'s NFI will not fall below PHP ${_phpWhole.format(_mc.var95)} in the coming season.',
          style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF), height: 1.5)),
      ),
    ]),
  );

  Widget _crsCard() {
    final color = _crs.total <= 30 ? _kGreen : _crs.total <= 55 ? _kAmber : _crs.total <= 75 ? _kRed : _kRed;
    return _card(
      title: 'Composite Risk Score (CRS)',
      subtitle: 'Per PRD §6.5 — weighted across 5 risk factors',
      child: Column(children: [
        Row(children: [
          Container(
            width: 84, height: 84,
            decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle,
              border: Border.all(color: color, width: 3)),
            alignment: Alignment.center,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_crs.total.toStringAsFixed(0),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              const Text('/100', style: TextStyle(fontSize: 10, color: _kMuted)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
              child: Text(_crs.classification, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 6),
            Text(_actionFor(_crs.total), style: const TextStyle(fontSize: 11, color: _kText, height: 1.4)),
          ])),
        ]),
        const SizedBox(height: 14),
        _crsRow('Price Volatility', _crs.priceVol, 20, _kBlue),
        _crsRow('Yield Risk', _crs.yieldRisk, 20, _kAmber),
        _crsRow('Weather Risk', _crs.weatherRisk, 25, _kRed),
        _crsRow('Credit Exposure', _crs.creditExposure, 20, const Color(0xFF8B5CF6)),
        _crsRow('Market Access', _crs.marketAccess, 15, const Color(0xFF06B6D4)),
      ]),
    );
  }

  String _actionFor(double t) {
    if (t <= 30) return 'Normal monitoring cycle. No immediate intervention required.';
    if (t <= 55) return 'Enhanced monitoring; advisory notice issued to farmer.';
    if (t <= 75) return 'Extension worker field visit recommended; intervention eligibility flagged.';
    return 'Immediate LGU intervention; debt restructuring referral required.';
  }

  Widget _crsRow(String label, double value, double max, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: _kText))),
        Text('${value.toStringAsFixed(1)} / ${max.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 3),
      Container(height: 6, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(3)),
        child: FractionallySizedBox(widthFactor: (value / max).clamp(0, 1), alignment: Alignment.centerLeft,
          child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)))),
      ),
    ]),
  );

  Widget _distributionCard() {
    final samples = _mc.samples..sort();
    final buckets = 20;
    final minV = samples.first;
    final maxV = samples.last;
    final width = (maxV - minV) / buckets;
    final counts = List.filled(buckets, 0);
    for (final s in samples) {
      final i = ((s - minV) / width).floor().clamp(0, buckets - 1);
      counts[i]++;
    }
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    return _card(
      title: 'NFI Distribution (Monte Carlo)',
      subtitle: '${_mc.samples.length} iterations · bucketed histogram',
      child: SizedBox(height: 180, child: BarChart(BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22,
            interval: (buckets / 4).floorToDouble(),
            getTitlesWidget: (v, _) {
              final pos = v.toInt();
              if (pos < 0 || pos >= buckets) return const SizedBox();
              final val = minV + pos * width;
              return Text('₱${(val / 1000).toStringAsFixed(0)}k',
                style: const TextStyle(fontSize: 9, color: _kMuted));
            })),
        ),
        barGroups: List.generate(buckets, (i) {
          final midpoint = minV + (i + 0.5) * width;
          return BarChartGroupData(x: i, barRods: [BarChartRodData(
            toY: counts[i].toDouble(),
            color: midpoint >= 0 ? _kGreen : _kRed,
            width: 10, borderRadius: BorderRadius.circular(2),
          )]);
        }),
        maxY: (maxCount + 5).toDouble(),
      ))),
    );
  }

  Widget _topRiskList() {
    final scored = _svc.cropCycles.map((c) {
      final mc = RiskAnalyzer.monteCarlo(c, iterations: 250);
      final crs = RiskAnalyzer.crs(c, mc);
      return (c, crs);
    }).toList()..sort((a, b) => b.$2.total.compareTo(a.$2.total));
    return _card(
      title: 'Portfolio Top-Risk Records',
      subtitle: 'Highest CRS records flagged for intervention',
      child: Column(children: scored.take(5).map((e) {
        final c = e.$1; final crs = e.$2;
        final color = crs.total <= 30 ? _kGreen : crs.total <= 55 ? _kAmber : _kRed;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(width: 38, height: 38, alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
              child: Text(crs.total.toStringAsFixed(0),
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${c.farmerName} · ${c.crop}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              Text('${c.barangay} · ${c.areaHa.toStringAsFixed(2)} ha',
                style: const TextStyle(fontSize: 10.5, color: _kMuted)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(4)),
              child: Text(crs.classification, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w800)),
            ),
          ]),
        );
      }).toList()),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// M3 — Oversupply Prediction
// ═══════════════════════════════════════════════════════════════════════════════

class M3OversupplyScreen extends StatefulWidget {
  const M3OversupplyScreen({super.key});
  @override
  State<M3OversupplyScreen> createState() => _M3State();
}

class _M3State extends State<M3OversupplyScreen> {
  String _commodity = 'Palay';
  final _svc = AgriEconFrdsService();

  @override
  Widget build(BuildContext context) {
    final all = _svc.harvestProjections();
    final forCommodity = all.where((p) => p.commodity == _commodity).toList();
    final alerts = _svc.activeAlerts();
    return _moduleScaffold(
      context: context, moduleNum: 3,
      title: 'Oversupply Prediction System',
      subtitle: 'Harvest calendar · Elasticity · ORI',
      accent: _kAmber,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _kpiStrip(alerts.length),
          _commoditySelector(),
          _harvestCurveCard(forCommodity),
          _alertsCard(alerts),
          _absorptionCard(),
        ]),
      ),
    );
  }

  Widget _kpiStrip(int alertCount) => _card(
    title: 'Municipal Harvest Pipeline',
    subtitle: '16-week rolling forecast window',
    child: Row(children: [
      Expanded(child: _kpi('Commodities Tracked', '5', _kBlue, icon: Icons.eco_rounded)),
      const SizedBox(width: 10),
      Expanded(child: _kpi('Active Alerts', '$alertCount weeks',
          alertCount > 0 ? _kRed : _kGreen, icon: Icons.notifications_active_rounded)),
      const SizedBox(width: 10),
      Expanded(child: _kpi('Forecast Horizon', '6-10 wks ahead', _kGreen, icon: Icons.event_rounded)),
    ]),
  );

  Widget _commoditySelector() => _card(
    title: 'Commodity Detail',
    child: Wrap(spacing: 8, children: ['Palay', 'Corn', 'Ampalaya', 'Tomato', 'Eggplant'].map((c) {
      final sel = c == _commodity;
      return GestureDetector(
        onTap: () => setState(() => _commodity = c),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? _kAmber : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(c, style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w700,
              color: sel ? Colors.white : _kText)),
        ),
      );
    }).toList()),
  );

  Widget _harvestCurveCard(List<HarvestWeekProjection> weeks) {
    final maxV = weeks.fold(0.0, (m, w) => w.projectedVolumeKg > m ? w.projectedVolumeKg : m);
    return _card(
      title: '$_commodity Weekly Harvest Projection',
      subtitle: 'Projected volume vs. historical average',
      child: SizedBox(height: 220, child: LineChart(LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22, interval: 3,
            getTitlesWidget: (v, _) => Text('W${v.toInt() + 1}',
                style: const TextStyle(fontSize: 9, color: _kMuted)))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 38,
            getTitlesWidget: (v, _) => Text('${(v / 1000).toStringAsFixed(0)}k',
                style: const TextStyle(fontSize: 9, color: _kMuted)))),
        ),
        minY: 0, maxY: maxV * 1.15,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(weeks.length, (i) => FlSpot(i.toDouble(), weeks[i].projectedVolumeKg)),
            isCurved: true, color: _kAmber, barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: _kAmber.withAlpha(30)),
          ),
          LineChartBarData(
            spots: List.generate(weeks.length, (i) => FlSpot(i.toDouble(), weeks[i].historicalAvgKg)),
            isCurved: true, color: _kMuted, barWidth: 2, dashArray: [4, 4],
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: List.generate(weeks.length, (i) => FlSpot(i.toDouble(), weeks[i].marketAbsorptionKg)),
            isCurved: false, color: _kRed, barWidth: 2, dashArray: [2, 3],
            dotData: const FlDotData(show: false),
          ),
        ],
      ))),
    );
  }

  Widget _alertsCard(List<HarvestWeekProjection> alerts) {
    final forThisCommodity = alerts.where((a) => a.commodity == _commodity).toList();
    if (forThisCommodity.isEmpty) {
      return _card(
        title: 'Active Oversupply Alerts',
        child: Container(
          padding: const EdgeInsets.all(14), alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFFE7F1E8), borderRadius: BorderRadius.circular(10)),
          child: const Row(children: [
            Icon(Icons.check_circle_rounded, color: _kGreen, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('No oversupply alerts for this commodity in the forecast window.',
                style: TextStyle(color: _kGreenDark, fontSize: 12))),
          ]),
        ),
      );
    }
    return _card(
      title: 'Active Oversupply Alerts',
      subtitle: '$_commodity — ORI threshold breaches',
      child: Column(children: forThisCommodity.take(6).map((a) {
        final color = a.alertLevel == 'Red' ? _kRed : _kAmber;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withAlpha(60))),
            child: Row(children: [
              Container(width: 8, height: 36, color: color),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Week of ${DateFormat('MMM d').format(a.weekStart)} · ${a.status}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                Text('ORI ${a.ori.toStringAsFixed(2)} · Volume +${a.volumeDeviationPct.toStringAsFixed(0)}% vs. avg',
                    style: const TextStyle(fontSize: 10.5, color: _kMuted)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                child: Text(a.alertLevel.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        );
      }).toList()),
    );
  }

  Widget _absorptionCard() => _card(
    title: 'Market Absorption Capacity',
    subtitle: 'PRD §7.4 — Four-channel demand model',
    child: Column(children: [
      _absorpRow('Local Retail Demand', 0.45, _kGreen, 'Municipal public market weekly off-take'),
      _absorpRow('Trader/Wholesaler', 0.32, _kBlue, 'Registered traders seasonal contracts'),
      _absorpRow('Institutional Demand', 0.15, _kGold, 'Schools, hospitals, LGU procurement'),
      _absorpRow('Inter-Municipal Export', 0.08, const Color(0xFF8B5CF6), 'Adjacent municipality demand'),
    ]),
  );

  Widget _absorpRow(String label, double frac, Color color, String desc) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kText))),
        Text('${(frac * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      ]),
      const SizedBox(height: 3),
      Container(height: 6, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(3)),
        child: FractionallySizedBox(widthFactor: frac, alignment: Alignment.centerLeft,
          child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))))),
      const SizedBox(height: 3),
      Text(desc, style: const TextStyle(fontSize: 10, color: _kMuted)),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// M4 — Debt & Loan Analytics
// ═══════════════════════════════════════════════════════════════════════════════

class M4DebtLoanScreen extends StatefulWidget {
  const M4DebtLoanScreen({super.key});
  @override
  State<M4DebtLoanScreen> createState() => _M4State();
}

class _M4State extends State<M4DebtLoanScreen> {
  late String _farmerId;
  final _svc = AgriEconFrdsService();
  double _restructureTerm = 0;
  double _restructureRate = 0;
  double _restructureForgive = 0;

  @override
  void initState() {
    super.initState();
    _farmerId = _svc.cropCycles.first.farmerId;
  }

  CropCycleRecord get _farmer => _svc.cropCycles.firstWhere((c) => c.farmerId == _farmerId);
  List<LoanRecord> get _loans => _svc.loansForFarmer(_farmerId);

  @override
  Widget build(BuildContext context) {
    final metrics = DebtAnalyzer.compute(_loans, _farmer.netFarmIncome,
        _farmer.totalCost * 4, _farmer.grossRevenue);
    final restructured = DebtAnalyzer.simulateRestructuring(_loans, _farmer.netFarmIncome,
        _farmer.totalCost * 4, _farmer.grossRevenue,
        termExtensionMonths: _restructureTerm, rateReduction: _restructureRate,
        partialForgivenessPct: _restructureForgive);
    return _moduleScaffold(
      context: context, moduleNum: 4,
      title: 'Debt & Loan Analytics',
      subtitle: 'DSCR · DDS · Restructuring Sim',
      accent: _kRed,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _farmerSelector(),
          _ratiosCard(metrics),
          _ddsCard(metrics),
          _stackCard(),
          _restructureCard(metrics, restructured),
        ]),
      ),
    );
  }

  Widget _farmerSelector() => _card(
    title: 'Farmer Debt Portfolio',
    child: DropdownButtonFormField<String>(
      value: _farmerId, isExpanded: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: _svc.cropCycles.map((c) => DropdownMenuItem(value: c.farmerId,
        child: Text('${c.farmerName} · ${_svc.loansForFarmer(c.farmerId).length} loan(s)',
            style: const TextStyle(fontSize: 12)))).toList(),
      onChanged: (v) => setState(() => _farmerId = v!),
    ),
  );

  Widget _ratiosCard(DebtMetrics m) {
    final color = switch (m.serviceability) {
      'Strong' => _kGreen,
      'Adequate' => _kBlue,
      'Stressed' => _kAmber,
      _ => _kRed,
    };
    return _card(
      title: 'Debt Serviceability Ratios',
      subtitle: 'PRD §8.3 — Computed against current NFI',
      child: Column(children: [
        Row(children: [
          Expanded(child: _kpi('DSCR', m.dscr > 99 ? '∞' : m.dscr.toStringAsFixed(2), color)),
          const SizedBox(width: 8),
          Expanded(child: _kpi('DTI', m.dti > 99 ? '∞' : '${(m.dti * 100).toStringAsFixed(0)}%', _kAmber)),
          const SizedBox(width: 8),
          Expanded(child: _kpi('LTAr', '${(m.ltAr * 100).toStringAsFixed(0)}%', _kBlue)),
          const SizedBox(width: 8),
          Expanded(child: _kpi('IBR', '${m.ibr.toStringAsFixed(1)}%', const Color(0xFF8B5CF6))),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withAlpha(60))),
          child: Row(children: [
            Icon(Icons.account_balance_wallet_rounded, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Classification: ${m.serviceability} Serviceability',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800))),
          ]),
        ),
      ]),
    );
  }

  Widget _ddsCard(DebtMetrics m) {
    final color = m.dds < 30 ? _kGreen : m.dds < 60 ? _kAmber : _kRed;
    return _card(
      title: 'Debt Distress Score (DDS)',
      subtitle: '0–100 composite — higher = greater repayment stress',
      child: Row(children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle,
            border: Border.all(color: color, width: 3)),
          alignment: Alignment.center,
          child: Text(m.dds.toStringAsFixed(0),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.dds < 30 ? 'Low Distress' : m.dds < 60 ? 'Moderate Distress' : 'Severe Distress',
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            m.dds < 30 ? 'Healthy debt profile. Eligible for additional concessional lending.' :
            m.dds < 60 ? 'Some financial strain detected. Enhanced monitoring recommended.' :
            'Critical distress. Restructuring referral required — Playbook B activation.',
            style: const TextStyle(fontSize: 11, color: _kMuted, height: 1.45)),
        ])),
      ]),
    );
  }

  Widget _stackCard() {
    if (_loans.isEmpty) return const SizedBox();
    return _card(
      title: 'Debt Stack Visualization',
      subtitle: 'Breakdown by lender type (informal lending highlighted in red)',
      child: Column(children: _loans.map((l) {
        final color = l.lenderType == 'informal' ? _kRed
          : l.lenderType == 'formal_bank' ? _kBlue
          : l.lenderType == 'cooperative' ? _kGreen
          : l.lenderType == 'lgu' ? _kGold
          : const Color(0xFF8B5CF6);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Container(width: 6, height: 32, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${l.lenderType.toUpperCase().replaceAll('_', ' ')} · ${l.purpose.replaceAll('_', ' ')}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                Text('${(l.interestRateAnnual * 100).toStringAsFixed(1)}% APR · ${l.termMonths} months · ${l.latePayments} late pmt',
                    style: const TextStyle(fontSize: 10.5, color: _kMuted)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('PHP ${_phpWhole.format(l.outstandingBalance)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                Text('of ${_phpWhole.format(l.principal)}',
                    style: const TextStyle(fontSize: 10, color: _kMuted)),
              ]),
            ]),
          ),
        );
      }).toList()),
    );
  }

  Widget _restructureCard(DebtMetrics now, DebtMetrics after) {
    return _card(
      title: 'Loan Restructuring Simulator',
      subtitle: 'PRD §8.6 — Model term extension, rate cut, or partial forgiveness',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _slider('Term Extension', '${_restructureTerm.toInt()} months', _restructureTerm, 0, 24,
            (v) => setState(() => _restructureTerm = v)),
        _slider('Interest Rate Reduction', '${(_restructureRate * 100).toStringAsFixed(1)}%', _restructureRate, 0, 0.20,
            (v) => setState(() => _restructureRate = v)),
        _slider('Partial Forgiveness', '${(_restructureForgive * 100).toStringAsFixed(0)}%', _restructureForgive, 0, 0.50,
            (v) => setState(() => _restructureForgive = v)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE))),
          child: Column(children: [
            const Row(children: [
              Icon(Icons.compare_arrows_rounded, color: _kBlue, size: 16),
              SizedBox(width: 6),
              Text('Before vs. After Restructuring', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _kBlue)),
            ]),
            const SizedBox(height: 8),
            _compareRow('DSCR', now.dscr, after.dscr, isRatio: true),
            _compareRow('DDS', now.dds, after.dds, lowerBetter: true),
            _compareRow('DTI', now.dti, after.dti, isPct: true, lowerBetter: true),
          ]),
        ),
      ]),
    );
  }

  Widget _slider(String label, String valueLabel, double value, double min, double max, ValueChanged<double> onChanged) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _kText))),
          Text(valueLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _kBlue)),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            activeTrackColor: _kBlue, inactiveTrackColor: const Color(0xFFE5E7EB),
            thumbColor: _kBlue, overlayColor: _kBlue.withAlpha(30),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ]),
    );

  Widget _compareRow(String label, double before, double after, {bool isPct = false, bool isRatio = false, bool lowerBetter = false}) {
    String fmt(double v) {
      if (v > 99) return '∞';
      if (isPct) return '${(v * 100).toStringAsFixed(0)}%';
      if (isRatio) return v.toStringAsFixed(2);
      return v.toStringAsFixed(1);
    }
    final improved = lowerBetter ? after < before : after > before;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 11.5, color: _kText, fontWeight: FontWeight.w600))),
        Expanded(child: Text(fmt(before), style: const TextStyle(fontSize: 11.5, color: _kMuted))),
        const Icon(Icons.arrow_forward_rounded, size: 12, color: _kMuted),
        const SizedBox(width: 4),
        Expanded(child: Text(fmt(after),
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800,
                color: improved ? _kGreen : _kRed))),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// M5 — Behavioral Farmer Modeling
// ═══════════════════════════════════════════════════════════════════════════════

class M5BehavioralScreen extends StatefulWidget {
  const M5BehavioralScreen({super.key});
  @override
  State<M5BehavioralScreen> createState() => _M5State();
}

class _M5State extends State<M5BehavioralScreen> {
  late BehavioralProfile _selected;
  final _svc = AgriEconFrdsService();

  @override
  void initState() {
    super.initState();
    _selected = _svc.behavioralProfiles.first;
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _svc.behavioralProfiles;
    return _moduleScaffold(
      context: context, moduleNum: 5,
      title: 'Behavioral Farmer Modeling',
      subtitle: 'Prospect Theory · Bias detection',
      accent: const Color(0xFF7C3AED),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _theoryBanner(),
          _distributionCard(profiles),
          _farmerSelector(profiles),
          _profileDetailCard(),
          _biasFlagsCard(),
          _advisoryCard(),
        ]),
      ),
    );
  }

  Widget _theoryBanner() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFDDD6FE))),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.psychology_rounded, color: Color(0xFF7C3AED), size: 18),
      SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Theoretical Foundation',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF5B21B6))),
        SizedBox(height: 4),
        Text('Kahneman & Tversky Prospect Theory: farmers weight losses ~2× more than equivalent gains, anchor decisions to reference points, and exhibit systematic probability distortion.',
            style: TextStyle(fontSize: 11, color: Color(0xFF5B21B6), height: 1.45)),
      ])),
    ]),
  );

  Widget _distributionCard(List<BehavioralProfile> profiles) {
    final counts = <String, int>{};
    for (final p in profiles) {
      counts[p.riskAttitude] = (counts[p.riskAttitude] ?? 0) + 1;
    }
    final palette = {
      'Risk Averse': _kBlue, 'Risk Neutral': _kGreen,
      'Risk Tolerant': _kAmber, 'Loss Averse': _kRed,
    };
    return _card(
      title: 'Risk Attitude Distribution',
      subtitle: 'Population-level profile across registered farmers',
      child: Column(children: counts.entries.map((e) {
        final frac = e.value / profiles.length;
        final color = palette[e.key] ?? _kMuted;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kText))),
              Text('${e.value} farmer(s) · ${(frac * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
            ]),
            const SizedBox(height: 3),
            Container(height: 6, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(3)),
              child: FractionallySizedBox(widthFactor: frac, alignment: Alignment.centerLeft,
                child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))))),
          ]),
        );
      }).toList()),
    );
  }

  Widget _farmerSelector(List<BehavioralProfile> profiles) => _card(
    title: 'Farmer Profile',
    child: DropdownButtonFormField<String>(
      value: _selected.farmerId, isExpanded: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: profiles.map((p) => DropdownMenuItem(value: p.farmerId,
        child: Text('${p.farmerName} · ${p.riskAttitude}', style: const TextStyle(fontSize: 12)))).toList(),
      onChanged: (v) => setState(() => _selected = profiles.firstWhere((p) => p.farmerId == v)),
    ),
  );

  Widget _profileDetailCard() {
    final p = _selected;
    final color = switch (p.riskAttitude) {
      'Risk Averse'   => _kBlue,
      'Risk Neutral'  => _kGreen,
      'Risk Tolerant' => _kAmber,
      _ => _kRed,
    };
    return _card(
      title: '${p.farmerName} — Behavioral Profile',
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
              child: Icon(Icons.person_rounded, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.riskAttitude, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
              Text('Selling Pattern: ${p.sellingPattern}', style: const TextStyle(fontSize: 10.5, color: _kMuted)),
            ])),
          ]),
        ),
        const SizedBox(height: 10),
        _row2('Advisory Compliance Rate', '${(p.advisoryComplianceRate * 100).toStringAsFixed(0)}%',
            c: p.advisoryComplianceRate > 0.7 ? _kGreen : p.advisoryComplianceRate > 0.5 ? _kAmber : _kRed),
        _row2('Diversification Index', p.diversificationIndex.toStringAsFixed(2),
            c: p.diversificationIndex > 0.5 ? _kGreen : _kAmber),
        _row2('Active Bias Flags', '${p.biasFlags.length}',
            c: p.biasFlags.length > 2 ? _kRed : p.biasFlags.length > 0 ? _kAmber : _kGreen),
      ]),
    );
  }

  Widget _biasFlagsCard() {
    final p = _selected;
    final allBiases = const {
      'Anchoring Bias': 'Pricing decisions tied to single reference year; ignores current signals.',
      'Sunk Cost Fallacy': 'Over-investing in failing crops to "recover" prior input expense.',
      'Herding Behavior': 'Planting choices mirror barangay majority despite differing conditions.',
      'Optimism Bias': 'Yield forecasts consistently exceed actual historical performance.',
      'Status Quo Bias': 'Resistance to crop diversification or technology adoption.',
      'Availability Heuristic': 'Decisions over-influenced by most recent climate event.',
    };
    return _card(
      title: 'Cognitive Bias Detection Flags',
      subtitle: 'PRD §9.3 — Detected from decision pattern analysis',
      child: Column(children: allBiases.entries.map((e) {
        final active = p.biasFlags.contains(e.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFEF2F2) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? const Color(0xFFFCA5A5) : _kBorder),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(active ? Icons.flag_rounded : Icons.flag_outlined,
                  color: active ? _kRed : _kMuted, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.key, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: active ? _kRed : _kText)),
                Text(e.value, style: const TextStyle(fontSize: 10.5, color: _kMuted, height: 1.4)),
              ])),
            ]),
          ),
        );
      }).toList()),
    );
  }

  Widget _advisoryCard() {
    final p = _selected;
    return _card(
      title: 'Profile-Matched Advisory Framing',
      subtitle: 'Recommended communication strategy for extension worker',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDD6FE))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.record_voice_over_rounded, color: Color(0xFF7C3AED), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(p.advisoryFraming,
              style: const TextStyle(fontSize: 12, color: Color(0xFF5B21B6), height: 1.5, fontWeight: FontWeight.w600))),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// M6 — Intervention Economics
// ═══════════════════════════════════════════════════════════════════════════════

class M6InterventionScreen extends StatefulWidget {
  const M6InterventionScreen({super.key});
  @override
  State<M6InterventionScreen> createState() => _M6State();
}

class _M6State extends State<M6InterventionScreen> {
  late InterventionScenario _selected;
  final _svc = AgriEconFrdsService();

  @override
  void initState() {
    super.initState();
    _selected = _svc.demoInterventions.first;
  }

  @override
  Widget build(BuildContext context) {
    final scenarios = _svc.demoInterventions;
    return _moduleScaffold(
      context: context, moduleNum: 6,
      title: 'Intervention Economics',
      subtitle: 'CBA · BCR · ROPI · Scenario Engine',
      accent: _kGold,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _scenarioSelector(scenarios),
          _cbaSummaryCard(),
          _comparisonCard(scenarios),
          _playbooksCard(),
        ]),
      ),
    );
  }

  Widget _scenarioSelector(List<InterventionScenario> scenarios) => _card(
    title: 'Intervention Scenario',
    subtitle: 'Pre-loaded LGU intervention programs for CBA modeling',
    child: Column(children: scenarios.map((s) {
      final sel = s.name == _selected.name;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => setState(() => _selected = s),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: sel ? _kGold.withAlpha(20) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? _kGold : _kBorder, width: sel ? 1.5 : 1),
            ),
            child: Row(children: [
              Container(width: 28, height: 28, alignment: Alignment.center,
                decoration: BoxDecoration(color: _kGold.withAlpha(30), shape: BoxShape.circle),
                child: Icon(_iconFor(s.type), color: _kGold, size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kText)),
                Text('${s.type.label} · ${s.beneficiaries} beneficiaries · PHP ${_phpWhole.format(s.budgetPhp)}',
                    style: const TextStyle(fontSize: 10, color: _kMuted)),
              ])),
              if (sel) const Icon(Icons.check_circle_rounded, color: _kGold, size: 18),
            ]),
          ),
        ),
      );
    }).toList()),
  );

  IconData _iconFor(InterventionType t) {
    switch (t) {
      case InterventionType.inputSubsidy:     return Icons.local_florist_rounded;
      case InterventionType.priceSupport:     return Icons.price_check_rounded;
      case InterventionType.postHarvestInfra: return Icons.warehouse_rounded;
      case InterventionType.loanProgram:      return Icons.account_balance_rounded;
      case InterventionType.marketLinkage:    return Icons.storefront_rounded;
      case InterventionType.diversificationIncentive: return Icons.eco_rounded;
      case InterventionType.cooperativeSupport: return Icons.groups_rounded;
    }
  }

  Widget _cbaSummaryCard() {
    final s = _selected;
    final approved = s.bcr >= 1.5;
    return _card(
      title: 'Cost-Benefit Analysis: ${s.name}',
      subtitle: 'PRD §10.3 — Full economic decomposition',
      child: Column(children: [
        Row(children: [
          Expanded(child: _kpi('BCR', s.bcr.toStringAsFixed(2),
              approved ? _kGreen : s.bcr >= 1 ? _kAmber : _kRed, icon: Icons.compare_arrows_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _kpi('ROPI', '${s.ropi.toStringAsFixed(0)}%',
              s.ropi > 50 ? _kGreen : _kAmber, icon: Icons.trending_up_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _kpi('Payback', '${s.paybackSeasons} seasons', _kBlue, icon: Icons.schedule_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _kpi('Farmers', '${s.beneficiaries}', _kGreen, icon: Icons.people_rounded)),
        ]),
        const Divider(height: 22),
        _label('Cost Decomposition'),
        const SizedBox(height: 6),
        _row2('Direct Program Cost', 'PHP ${_phpWhole.format(s.directCost)}', c: _kRed),
        _row2('Admin Cost (${(s.adminCostPct * 100).toStringAsFixed(0)}%)',
            'PHP ${_phpWhole.format(s.adminCost)}', c: _kRed),
        _row2('Opportunity Cost', 'PHP ${_phpWhole.format(s.opportunityCost)}', c: _kRed),
        _row2('Total Cost', 'PHP ${_phpWhole.format(s.totalCost)}', c: _kRed),
        const Divider(height: 16),
        _label('Benefit Decomposition'),
        const SizedBox(height: 6),
        _row2('Income Uplift (Aggregate)', 'PHP ${_phpWhole.format(s.incomeGain)}', c: _kGreen),
        _row2('Debt Prevention Value', 'PHP ${_phpWhole.format(s.debtPrevention)}', c: _kGreen),
        _row2('Market Stabilization', 'PHP ${_phpWhole.format(s.marketStabilizationValue)}', c: _kGreen),
        _row2('Multiplier Effect (×${s.multiplierCoefficient})',
            'PHP ${_phpWhole.format(s.multiplierBenefit)}', c: _kGreen),
        _row2('Total Benefit', 'PHP ${_phpWhole.format(s.totalBenefit)}', c: _kGreen),
        const Divider(height: 16),
        _row2('Net Present Value', 'PHP ${_phpWhole.format(s.npv)}',
            c: s.npv >= 0 ? _kGreen : _kRed),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (approved ? _kGreen : _kAmber).withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: (approved ? _kGreen : _kAmber).withAlpha(60)),
          ),
          child: Row(children: [
            Icon(approved ? Icons.thumb_up_rounded : Icons.info_outline_rounded,
                color: approved ? _kGreen : _kAmber, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              approved
                ? 'Recommendation: APPROVE FOR FUNDING. BCR exceeds 1.5 threshold per PRD §10.4.'
                : 'Recommendation: REVIEW & ITERATE. BCR below 1.5 approval threshold.',
              style: TextStyle(color: approved ? _kGreenDark : const Color(0xFF92400E),
                  fontSize: 11.5, fontWeight: FontWeight.w700),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _comparisonCard(List<InterventionScenario> scenarios) => _card(
    title: 'Scenario Comparison',
    subtitle: 'Side-by-side BCR & ROPI for funding prioritization',
    child: Column(children: scenarios.map((s) {
      final color = s.bcr >= 1.5 ? _kGreen : s.bcr >= 1.0 ? _kAmber : _kRed;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Container(width: 4, height: 38, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
            Text('${s.beneficiaries} farmers · PHP ${_phpWhole.format(s.budgetPhp)}',
                style: const TextStyle(fontSize: 10, color: _kMuted)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('BCR ${s.bcr.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            Text('ROPI ${s.ropi.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 10, color: _kMuted)),
          ]),
        ]),
      );
    }).toList()),
  );

  Widget _playbooksCard() => _card(
    title: 'Emergency Intervention Playbooks',
    subtitle: 'PRD §10.5 — Pre-configured rapid response',
    child: Column(children: [
      _playbookRow('A', 'Oversupply Price Crash',
          'Triggered when ORI ≥ 1.35. Auto-populates price support CBA.', _kAmber, false),
      _playbookRow('B', 'Debt Distress Cascade',
          'Triggered when >15% of farmers reach DDS > 75. Generates restructuring program.', _kRed, true),
      _playbookRow('C', 'Climate Disaster Response',
          'Post-typhoon/drought. Computes income loss and input subsidy requirement.', _kBlue, false),
    ]),
  );

  Widget _playbookRow(String letter, String title, String desc, Color color, bool active) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active ? color.withAlpha(15) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? color : _kBorder),
      ),
      child: Row(children: [
        Container(width: 32, height: 32, alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Playbook $letter — $title',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: active ? color : _kText)),
            if (active) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
              ),
            ],
          ]),
          Text(desc, style: const TextStyle(fontSize: 10.5, color: _kMuted, height: 1.4)),
        ])),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// M7 — Municipal Agricultural Intelligence
// ═══════════════════════════════════════════════════════════════════════════════

class M7MunicipalIntelScreen extends StatefulWidget {
  const M7MunicipalIntelScreen({super.key});
  @override
  State<M7MunicipalIntelScreen> createState() => _M7State();
}

class _M7State extends State<M7MunicipalIntelScreen> {
  String _heatmapMetric = 'CRS';
  final _svc = AgriEconFrdsService();

  @override
  Widget build(BuildContext context) {
    final barangays = _svc.barangayIntel;
    return _moduleScaffold(
      context: context, moduleNum: 7,
      title: 'Municipal Agricultural Intelligence',
      subtitle: 'Spatial · Benchmark · Executive Report',
      accent: _kGreenDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _executiveSnapshotCard(barangays),
          _heatmapCard(barangays),
          _landUseCard(barangays),
          _benchmarksCard(barangays),
          _executiveReportCard(),
        ]),
      ),
    );
  }

  Widget _executiveSnapshotCard(List<BarangayIntel> barangays) {
    final totalHh = barangays.fold(0, (s, b) => s + b.farmingHouseholds);
    final totalHa = barangays.fold(0.0, (s, b) => s + b.totalHa);
    final avgCrs = barangays.fold(0.0, (s, b) => s + b.avgCrs) / barangays.length;
    final avgCoverage = barangays.fold(0.0, (s, b) => s + b.interventionCoveragePct) / barangays.length;
    return _card(
      title: 'Executive Municipal Snapshot',
      subtitle: 'Tubungan, Iloilo — Current Period',
      child: Column(children: [
        Row(children: [
          Expanded(child: _kpi('Farming HHs', '$totalHh', _kGreen, icon: Icons.people_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _kpi('Total Ag Area', '${totalHa.toStringAsFixed(0)} ha', _kBlue, icon: Icons.landscape_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _kpi('Avg CRS', avgCrs.toStringAsFixed(0),
              avgCrs <= 30 ? _kGreen : avgCrs <= 55 ? _kAmber : _kRed, icon: Icons.assessment_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _kpi('Coverage', '${(avgCoverage * 100).toStringAsFixed(0)}%', _kGold, icon: Icons.shield_rounded)),
        ]),
      ]),
    );
  }

  Widget _heatmapCard(List<BarangayIntel> barangays) {
    final metricGetters = {
      'CRS': (BarangayIntel b) => b.avgCrs,
      'Distress': (BarangayIntel b) => b.pctHighDistress * 100,
      'Revenue/ha': (BarangayIntel b) => b.avgRevenuePerHa / 1000,
      'ORI Contribution': (BarangayIntel b) => b.oriContribution * 100,
    };
    final get = metricGetters[_heatmapMetric]!;
    final sorted = [...barangays]..sort((a, b) => get(b).compareTo(get(a)));
    final maxV = sorted.map(get).reduce((a, b) => a > b ? a : b);
    final isLowerBetter = _heatmapMetric == 'CRS' || _heatmapMetric == 'Distress' || _heatmapMetric == 'ORI Contribution';
    return _card(
      title: 'Barangay Heatmap',
      subtitle: 'Choropleth-style ranking by selected metric',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 6, children: metricGetters.keys.map((m) {
          final sel = m == _heatmapMetric;
          return GestureDetector(
            onTap: () => setState(() => _heatmapMetric = m),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: sel ? _kGreenDark : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(m, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : _kText)),
            ),
          );
        }).toList()),
        const SizedBox(height: 12),
        ...sorted.map((b) {
          final v = get(b);
          final frac = maxV == 0 ? 0.0 : v / maxV;
          final intensity = isLowerBetter ? frac : 1 - frac;
          final color = Color.lerp(_kGreen, _kRed, intensity)!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              SizedBox(width: 85, child: Text(b.barangay,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700))),
              Expanded(child: Stack(children: [
                Container(height: 22, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4))),
                FractionallySizedBox(widthFactor: frac, alignment: Alignment.centerLeft,
                  child: Container(height: 22, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)))),
              ])),
              const SizedBox(width: 8),
              SizedBox(width: 55, child: Text(
                _heatmapMetric == 'Revenue/ha' ? '₱${v.toStringAsFixed(0)}k'
                  : _heatmapMetric.contains('CRS') ? v.toStringAsFixed(0)
                  : '${v.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                textAlign: TextAlign.right,
              )),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _landUseCard(List<BarangayIntel> barangays) {
    final totals = {
      'Rice': barangays.fold(0.0, (s, b) => s + b.riceHa),
      'Corn': barangays.fold(0.0, (s, b) => s + b.cornHa),
      'Vegetables': barangays.fold(0.0, (s, b) => s + b.vegetableHa),
      'HVC': barangays.fold(0.0, (s, b) => s + b.hvcHa),
      'Orchard': barangays.fold(0.0, (s, b) => s + b.orchardHa),
      'Idle': barangays.fold(0.0, (s, b) => s + b.idleHa),
    };
    final colors = [_kGreen, _kAmber, _kBlue, const Color(0xFF7C3AED), const Color(0xFFE11D48), _kMuted];
    final total = totals.values.reduce((a, b) => a + b);
    return _card(
      title: 'Municipal Land Utilization',
      subtitle: 'Breakdown by crop category (hectares)',
      child: Column(children: [
        SizedBox(height: 140, child: PieChart(PieChartData(
          sectionsSpace: 2, centerSpaceRadius: 30,
          sections: totals.entries.toList().asMap().entries.map((e) {
            final pct = total == 0 ? 0 : (e.value.value / total) * 100;
            return PieChartSectionData(
              value: e.value.value, color: colors[e.key],
              title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
              titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
              radius: 44,
            );
          }).toList(),
        ))),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 5, children: totals.entries.toList().asMap().entries.map((e) =>
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: colors[e.key], shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('${e.value.key} · ${e.value.value.toStringAsFixed(0)} ha',
                style: const TextStyle(fontSize: 10, color: _kText)),
          ])).toList()),
      ]),
    );
  }

  Widget _benchmarksCard(List<BarangayIntel> barangays) {
    final avgYield = barangays.fold(0.0, (s, b) => s + b.avgYieldPerHa) / barangays.length;
    final avgRevenue = barangays.fold(0.0, (s, b) => s + b.avgRevenuePerHa) / barangays.length;
    return _card(
      title: 'Land Utilization Benchmarks',
      subtitle: 'PRD §11.4 — Productivity vs. municipal average',
      child: Column(children: [
        _row2('Land Productivity Index (Municipal Avg)', 'PHP ${_phpWhole.format(avgRevenue)}/ha', c: _kBlue),
        _row2('Average Yield per Hectare', '${_phpWhole.format(avgYield)} kg/ha', c: _kGreen),
        const SizedBox(height: 12),
        _label('Per-Barangay Performance vs. Municipal Average'),
        const SizedBox(height: 6),
        ...barangays.map((b) {
          final score = (b.avgRevenuePerHa / avgRevenue) * 100;
          final color = score >= 100 ? _kGreen : score >= 85 ? _kAmber : _kRed;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              SizedBox(width: 90, child: Text(b.barangay, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
              Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(2)),
                child: FractionallySizedBox(widthFactor: (score / 130).clamp(0, 1), alignment: Alignment.centerLeft,
                  child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))))),
              const SizedBox(width: 8),
              SizedBox(width: 48, child: Text('${score.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color), textAlign: TextAlign.right)),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _executiveReportCard() => _card(
    title: 'Quarterly Intelligence Report',
    subtitle: 'PRD §11.6 — Auto-generated for Sangguniang Bayan',
    child: Column(children: [
      _reportSection('Top 3 Concerns', [
        'Barangay Canabuan: CRS at 56 (High Risk) — 28% of farmers in distress',
        'Ampalaya market: Critical oversupply forecasted at Week 4-5',
        'Informal lending exposure rising 14% YoY in Buenavista',
      ], _kRed),
      _reportSection('Top 3 Achievements', [
        'Cabilauan: 58% intervention coverage — highest in municipality',
        'Average yield up 8% vs. prior season for vegetable crops',
        'DSCR > 1.5 in 72% of cooperative-affiliated farmer accounts',
      ], _kGreen),
      _reportSection('Recommendations', [
        'Activate Playbook B for Canabuan and Alegria (DDS cluster)',
        'Pre-position Ampalaya market linkage 6 weeks before peak',
        'Expand SURE-Aid restructuring to 80 additional farmers',
      ], _kBlue),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Exporting full PDF report...'), backgroundColor: _kGreenDark));
        },
        icon: const Icon(Icons.picture_as_pdf_rounded, size: 14, color: _kGreenDark),
        label: const Text('Export Full PDF Report',
            style: TextStyle(fontSize: 12, color: _kGreenDark, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: _kGreenDark),
          padding: const EdgeInsets.symmetric(vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      )),
    ]),
  );

  Widget _reportSection(String title, List<String> items, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 4),
      ...items.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 3, left: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('• ', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
          Expanded(child: Text(s, style: const TextStyle(fontSize: 11, color: _kText, height: 1.4))),
        ]),
      )),
    ]),
  );
}
