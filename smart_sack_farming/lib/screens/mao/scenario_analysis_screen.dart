// ─────────────────────────────────────────────────────────────────────────────
// ScenarioAnalysisScreen — AgriSense DSS  FR06
// PRD v1.0 §7  Scenario Analysis Framework + §8.3  Market Saturation Dashboard
//
// MAO officers adjust price, yield, demand, loss rate to run
// Best / Expected / Worst Case analyses per crop.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/financial_model_assumptions.dart';
import '../../services/agri_forecast_engine.dart';

const _kGreen  = Color(0xFF1B7737);
const _kAmber  = Color(0xFFF59E0B);
const _kRed    = Color(0xFFDC2626);
const _kBlue   = Color(0xFF1D4ED8);
const _kBg     = Color(0xFFF9FAFB);
const _kCard   = Colors.white;
const _kText   = Color(0xFF111827);
const _kMuted  = Color(0xFF6B7280);

final _php = NumberFormat('#,##0', 'en_PH');
final _phpD = NumberFormat('#,##0.00', 'en_PH');

class ScenarioAnalysisScreen extends StatefulWidget {
  const ScenarioAnalysisScreen({super.key});
  @override
  State<ScenarioAnalysisScreen> createState() => _ScenarioAnalysisScreenState();
}

class _ScenarioAnalysisScreenState extends State<ScenarioAnalysisScreen> {
  String _selectedCropKey = 'ampalaya';

  // Adjustable assumptions (MAO can override — FR01)
  double _farmSizeHa    = 1.0;
  double _farmerCount   = 50;
  double _municipalSupplyKg = 45000; // default from monthly demand baseline

  // Custom scenario drivers — user-adjustable sliders
  double _customPriceMult   = 1.0;
  double _customYieldMult   = 1.0;
  double _customDemandMult  = 1.0;
  double _customLossRate    = 0.08;
  double _customSupplyMult  = 1.0;

  bool _showCustom = false; // toggle custom scenario panel

  // ── Computed results ────────────────────────────────────────────────────────

  CropScenarioResult? get _result => AgriForecastEngine.computeScenarios(
    cropKey: _selectedCropKey,
    farmSizeHa: _farmSizeHa,
    activeFarmers: _farmerCount,
    municipalSupplyKg: _municipalSupplyKg,
  );

  ScenarioOutput? get _customResult {
    if (!_showCustom) return null;
    final drivers = ScenarioDrivers(
      priceMult: _customPriceMult,
      yieldMult: _customYieldMult,
      demandMult: _customDemandMult,
      postHarvestLoss: _customLossRate,
      supplyMult: _customSupplyMult,
    );
    return AgriForecastEngine.runScenario(
      name: 'Custom',
      cropKey: _selectedCropKey,
      farmSizeHa: _farmSizeHa,
      activeFarmers: _farmerCount,
      municipalSupplyKg: _municipalSupplyKg,
      drivers: drivers,
    );
  }

  // ── Crop display name ───────────────────────────────────────────────────────
  String get _cropDisplayName => kCropKeyToName[_selectedCropKey] ?? _selectedCropKey;

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Scenario Analysis', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        centerTitle: false,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showCustom = !_showCustom),
            icon: Icon(_showCustom ? Icons.tune : Icons.tune_outlined, color: Colors.white70, size: 18),
            label: Text(_showCustom ? 'Hide Custom' : 'Custom Scenario',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
      body: r == null
        ? const Center(child: CircularProgressIndicator(color: _kGreen))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildAssumptionsPanel(),
              const SizedBox(height: 16),
              if (_showCustom) ...[_buildCustomScenarioPanel(), const SizedBox(height: 16)],
              _buildScenarioHeader(),
              const SizedBox(height: 12),
              _buildScenarioComparison(r),
              const SizedBox(height: 16),
              _buildMsiMatrix(r),
              const SizedBox(height: 16),
              _buildCashFlowSection(r.expected),
            ]),
          ),
    );
  }

  // ── §FR01 Assumptions panel ──────────────────────────────────────────────────

  Widget _buildAssumptionsPanel() => _card(
    title: 'Planning Assumptions',
    icon: Icons.tune_rounded,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Crop selector
      const Text('Crop', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kMuted)),
      const SizedBox(height: 4),
      DropdownButtonFormField<String>(
        value: _selectedCropKey,
        decoration: InputDecoration(
          isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: kFmCropKeys.map((k) => DropdownMenuItem(
          value: k,
          child: Text(kCropKeyToName[k] ?? k, style: const TextStyle(fontSize: 13)),
        )).toList(),
        onChanged: (v) => setState(() { if (v != null) _selectedCropKey = v; }),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _numInput('Farm Size (ha)', _farmSizeHa, (v) => setState(() => _farmSizeHa = v), 0.1, 20, 0.5)),
        const SizedBox(width: 12),
        Expanded(child: _numInput('Active Farmers', _farmerCount, (v) => setState(() => _farmerCount = v), 1, 500, 10)),
      ]),
      const SizedBox(height: 12),
      _numInput('Municipal Supply (kg/month)', _municipalSupplyKg,
          (v) => setState(() => _municipalSupplyKg = v), 0, 500000, 5000),
      const SizedBox(height: 4),
      Row(children: [
        const Icon(Icons.info_outline_rounded, size: 11, color: _kMuted),
        const SizedBox(width: 4),
        Text('Monthly demand: ${_php.format(kMonthlyDemand[_selectedCropKey] ?? 0)} kg  ·  '
            'Base price: ₱${kFmBasePrices[_selectedCropKey]?.toStringAsFixed(0)}/kg  ·  '
            'Yield: ${_php.format(kYieldPerHa[_selectedCropKey] ?? 0)} kg/ha',
          style: const TextStyle(fontSize: 10, color: _kMuted)),
      ]),
    ]),
  );

  // ── Custom scenario sliders ──────────────────────────────────────────────────

  Widget _buildCustomScenarioPanel() => _card(
    title: 'Custom Scenario Drivers',
    icon: Icons.settings_rounded,
    borderColor: const Color(0xFF93C5FD),
    bgColor: const Color(0xFFEFF6FF),
    child: Column(children: [
      _sliderRow('Price Multiplier', _customPriceMult, 0.5, 1.5, (v) => setState(() => _customPriceMult = v),
          label2: '${(_customPriceMult * 100 - 100).toStringAsFixed(0)}% vs baseline'),
      _sliderRow('Yield Multiplier', _customYieldMult, 0.5, 1.5, (v) => setState(() => _customYieldMult = v),
          label2: '${(_customYieldMult * 100 - 100).toStringAsFixed(0)}% vs average'),
      _sliderRow('Demand Multiplier', _customDemandMult, 0.5, 1.5, (v) => setState(() => _customDemandMult = v),
          label2: '${(_customDemandMult * 100 - 100).toStringAsFixed(0)}% vs baseline'),
      _sliderRow('Post-Harvest Loss', _customLossRate, 0.01, 0.30, (v) => setState(() => _customLossRate = v),
          label2: '${(_customLossRate * 100).toStringAsFixed(0)}%'),
      _sliderRow('Competing Supply', _customSupplyMult, 0.5, 2.0, (v) => setState(() => _customSupplyMult = v),
          label2: '${(_customSupplyMult * 100).toStringAsFixed(0)}% of baseline'),
      if (_customResult != null) ...[
        const Divider(height: 20),
        _buildCustomResult(_customResult!),
      ],
    ]),
  );

  Widget _buildCustomResult(ScenarioOutput r) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Custom Scenario Result', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kBlue)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _kpiSmall('Farmgate Price', '₱${_phpD.format(r.forecastedPrice)}/kg', _kBlue)),
        Expanded(child: _kpiSmall('NFI/Farmer', '₱${_php.format(r.avgNfiPerFarmer)}', r.avgNfiPerFarmer >= 0 ? _kGreen : _kRed)),
        Expanded(child: _kpiSmall('MSI', r.msi.toStringAsFixed(2), Color(r.msiStatus.colorValue))),
        Expanded(child: _kpiSmall('ROI', '${r.roi.toStringAsFixed(1)}%', r.roi >= 0 ? _kGreen : _kRed)),
      ]),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Color(r.msiStatus.colorValue).withAlpha(30), borderRadius: BorderRadius.circular(6)),
        child: Text(r.msiStatus.action, style: TextStyle(fontSize: 11, color: Color(r.msiStatus.colorValue), fontWeight: FontWeight.w600)),
      ),
    ]),
  );

  // ── Scenario header ──────────────────────────────────────────────────────────

  Widget _buildScenarioHeader() => Row(children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF1B5E20), borderRadius: BorderRadius.circular(6)),
      child: Text(_cropDisplayName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    ),
    const SizedBox(width: 10),
    const Expanded(child: Text('3-Scenario Comparison', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kText))),
  ]);

  // ── §7  3-Column scenario comparison ────────────────────────────────────────

  Widget _buildScenarioComparison(CropScenarioResult r) {
    return LayoutBuilder(builder: (ctx, box) {
      if (box.maxWidth >= 700) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _scenarioCard(r.best,    const Color(0xFF16A34A), const Color(0xFFF0FDF4), '🟢')),
          const SizedBox(width: 10),
          Expanded(child: _scenarioCard(r.expected, const Color(0xFF1D4ED8), const Color(0xFFEFF6FF), '🔵')),
          const SizedBox(width: 10),
          Expanded(child: _scenarioCard(r.worst,   const Color(0xFFDC2626), const Color(0xFFFEF2F2), '🔴')),
        ]);
      }
      // Mobile: vertical
      return Column(children: [
        _scenarioCard(r.best,    const Color(0xFF16A34A), const Color(0xFFF0FDF4), '🟢'),
        const SizedBox(height: 10),
        _scenarioCard(r.expected, const Color(0xFF1D4ED8), const Color(0xFFEFF6FF), '🔵'),
        const SizedBox(height: 10),
        _scenarioCard(r.worst,   const Color(0xFFDC2626), const Color(0xFFFEF2F2), '🔴'),
      ]);
    });
  }

  Widget _scenarioCard(ScenarioOutput s, Color color, Color bg, String emoji) {
    final msiColor = Color(s.msiStatus.colorValue);
    return Container(
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
          ),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(child: Text(s.scenarioName,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Key metrics
            _metricRow('Farmgate Price', '₱${_phpD.format(s.forecastedPrice)}/kg', color),
            _metricRow('Gross Revenue', '₱${_php.format(s.grossRevenue)}', _kText),
            _metricRow('Production Cost', '₱${_php.format(s.totalCost)}', _kMuted),
            _metricRow('Net Farm Income', '₱${_php.format(s.avgNfiPerFarmer)}',
                s.avgNfiPerFarmer >= 0 ? _kGreen : _kRed),
            _metricRow('ROI', '${s.roi.toStringAsFixed(1)}%',
                s.roi >= 0 ? _kGreen : _kRed),
            _metricRow('Net Sellable Qty', '${_php.format(s.nsqKg)} kg', _kText),
            _metricRow('Loss Value', '₱${_php.format(s.lossValue)}', _kAmber),
            const Divider(height: 16),
            // Municipal aggregates
            const Text('Municipal Impact', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kMuted)),
            const SizedBox(height: 4),
            _metricRow('Total Revenue', '₱${_php.format(s.totalMunicipalRevenue)}', _kText),
            _metricRow('Total NFI', '₱${_php.format(s.totalMunicipalNfi)}',
                s.totalMunicipalNfi >= 0 ? _kGreen : _kRed),
            const Divider(height: 16),
            // MSI
            Row(children: [
              Expanded(child: Text('MSI', style: const TextStyle(fontSize: 11, color: _kMuted))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: msiColor.withAlpha(25), borderRadius: BorderRadius.circular(6)),
                child: Text(s.msi.toStringAsFixed(2), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: msiColor)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(s.msiStatus.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: msiColor)),
            const SizedBox(height: 2),
            Text(s.msiStatus.action, style: const TextStyle(fontSize: 10, color: _kMuted, height: 1.3)),
          ]),
        ),
      ]),
    );
  }

  Widget _metricRow(String label, String value, Color valueColor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: _kMuted))),
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: valueColor)),
    ]),
  );

  // ── §8.3  MSI Saturation Matrix ───────────────────────────────────────────────

  Widget _buildMsiMatrix(CropScenarioResult current) {
    return _card(
      title: 'Market Saturation Index Matrix — All Crops',
      icon: Icons.grid_view_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('MSI = Municipal Supply ÷ Monthly Demand. Values above 1.0 indicate oversupply risk.',
            style: TextStyle(fontSize: 11, color: _kMuted, height: 1.4)),
        const SizedBox(height: 12),
        // Header
        _msiHeaderRow(),
        const Divider(height: 8),
        ...kFmCropKeys.map((key) {
          final r = AgriForecastEngine.computeScenarios(
            cropKey: key, farmSizeHa: _farmSizeHa,
            activeFarmers: _farmerCount, municipalSupplyKg: kMonthlyDemand[key] ?? 50000,
          );
          return _msiDataRow(key, r.best, r.expected, r.worst);
        }),
      ]),
    );
  }

  Widget _msiHeaderRow() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: const [
      Expanded(flex: 3, child: Text('Crop', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kMuted))),
      Expanded(flex: 2, child: Text('MSI Current', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kGreen), textAlign: TextAlign.center)),
      Expanded(flex: 2, child: Text('MSI Best', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kBlue), textAlign: TextAlign.center)),
      Expanded(flex: 2, child: Text('MSI Worst', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kRed), textAlign: TextAlign.center)),
      Expanded(flex: 3, child: Text('Recommended Action', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kMuted))),
    ]),
  );

  Widget _msiDataRow(String key, ScenarioOutput best, ScenarioOutput expected, ScenarioOutput worst) {
    final name = kCropKeyToName[key] ?? key;
    final expStatus = expected.msiStatus;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(flex: 3, child: Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kText))),
        Expanded(flex: 2, child: _msiBadge(expected.msi)),
        Expanded(flex: 2, child: _msiBadge(best.msi)),
        Expanded(flex: 2, child: _msiBadge(worst.msi)),
        Expanded(flex: 3, child: Text(expStatus.action,
            style: TextStyle(fontSize: 9.5, color: Color(expStatus.colorValue), height: 1.3))),
      ]),
    );
  }

  Widget _msiBadge(double msi) {
    final s = getMsiStatus(msi);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Color(s.colorValue).withAlpha(25),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(msi.toStringAsFixed(2),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(s.colorValue))),
      ),
    );
  }

  // ── §8.2  Municipal Cash Flow section ────────────────────────────────────────

  Widget _buildCashFlowSection(ScenarioOutput expected) {
    final cf = AgriForecastEngine.buildMunicipalCashFlow(
      cropKey: _selectedCropKey,
      totalFarmerCount: _farmerCount,
      avgFarmSizeHa: _farmSizeHa,
      forecastedPrice: expected.forecastedPrice,
      costPerHa: kTotalDefaultCostPerHa,
    );

    return _card(
      title: 'Municipal Cash Flow Projection — Expected Case',
      icon: Icons.waterfall_chart_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Revenue and costs mapped month-by-month from harvest date projections.',
            style: TextStyle(fontSize: 11, color: _kMuted)),
        const SizedBox(height: 12),
        _cfHeaderRow(),
        const Divider(height: 8),
        ...cf.map((m) => _cfDataRow(m)),
        const Divider(height: 12),
        Row(children: [
          const Expanded(child: Text('TOTAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
          Expanded(child: Text('${_php.format(cf.fold(0.0, (s, m) => s + m.harvestVolumeKg))} kg',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
          Expanded(child: Text('₱${_php.format(cf.fold(0.0, (s, m) => s + m.expectedRevenue))}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kGreen), textAlign: TextAlign.right)),
          Expanded(child: Text('₱${_php.format(cf.fold(0.0, (s, m) => s + m.cumulativeInputCosts))}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kRed), textAlign: TextAlign.right)),
          Expanded(child: () {
            final net = cf.fold(0.0, (s, m) => s + m.netCashFlow);
            return Text('₱${_php.format(net)}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: net >= 0 ? _kGreen : _kRed),
                textAlign: TextAlign.right);
          }()),
        ]),
      ]),
    );
  }

  Widget _cfHeaderRow() => Row(children: const [
    Expanded(child: Text('Month', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: _kMuted))),
    Expanded(child: Text('Volume (kg)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: _kMuted), textAlign: TextAlign.right)),
    Expanded(child: Text('Revenue (₱)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: _kGreen), textAlign: TextAlign.right)),
    Expanded(child: Text('Input Costs (₱)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: _kRed), textAlign: TextAlign.right)),
    Expanded(child: Text('Net Cash (₱)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: _kMuted), textAlign: TextAlign.right)),
  ]);

  Widget _cfDataRow(MonthlyCashFlow m) {
    final net = m.netCashFlow;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(m.month, style: const TextStyle(fontSize: 11, color: _kText))),
        Expanded(child: Text(m.harvestVolumeKg > 0 ? _php.format(m.harvestVolumeKg) : '—',
            style: const TextStyle(fontSize: 11, color: _kText), textAlign: TextAlign.right)),
        Expanded(child: Text(m.expectedRevenue > 0 ? _php.format(m.expectedRevenue) : '—',
            style: const TextStyle(fontSize: 11, color: _kGreen), textAlign: TextAlign.right)),
        Expanded(child: Text(_php.format(m.cumulativeInputCosts),
            style: const TextStyle(fontSize: 11, color: _kRed), textAlign: TextAlign.right)),
        Expanded(child: Text(net != 0 ? '${net >= 0 ? '+' : ''}${_php.format(net)}' : '—',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: net >= 0 ? _kGreen : _kRed),
            textAlign: TextAlign.right)),
      ]),
    );
  }

  // ── Widget helpers ───────────────────────────────────────────────────────────

  Widget _card({required String title, required IconData icon, required Widget child,
      Color? borderColor, Color? bgColor}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor ?? _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: _kGreen),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kText)),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );

  Widget _numInput(String label, double value, ValueChanged<double> onChanged,
      double min, double max, double step) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kMuted)),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(child: Slider(
          value: value.clamp(min, max),
          min: min, max: max, divisions: ((max - min) / step).round(),
          activeColor: _kGreen,
          onChanged: onChanged,
        )),
        SizedBox(
          width: 70,
          child: Text(value >= 1000 ? _php.format(value) : value.toStringAsFixed(value < 10 ? 1 : 0),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kText),
              textAlign: TextAlign.right),
        ),
      ]),
    ]);
  }

  Widget _sliderRow(String label, double value, double min, double max,
      ValueChanged<double> onChanged, {String? label2}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 11, color: _kMuted))),
        Expanded(child: Slider(
          value: value.clamp(min, max), min: min, max: max,
          divisions: 20, activeColor: _kBlue,
          onChanged: onChanged,
        )),
        SizedBox(width: 80, child: Text(label2 ?? value.toStringAsFixed(2),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kBlue),
            textAlign: TextAlign.right)),
      ]),
    );
  }

  Widget _kpiSmall(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: const TextStyle(fontSize: 9, color: _kMuted)),
  ]);
}

