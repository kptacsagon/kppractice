import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/agrisat_market_service.dart';

const _kGreen = Color(0xFF1B7737);

// PRD §6.1 — Farmer Dashboard: Market Signal Indicator (simplified MAR/PPI/IUR)
class AgrisatMarketSignalsScreen extends StatefulWidget {
  const AgrisatMarketSignalsScreen({super.key});

  @override
  State<AgrisatMarketSignalsScreen> createState() => _AgrisatMarketSignalsScreenState();
}

class _AgrisatMarketSignalsScreenState extends State<AgrisatMarketSignalsScreen> {
  final _svc = AgrisatMarketService();
  List<CropIndicators> _indicators = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final reports = await _svc.getAllHarvestReports();
        final computed = _svc.computeIndicators(reports);
        setState(() {
          _indicators = computed.isEmpty ? _svc.getMockIndicators() : computed;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() { _indicators = _svc.getMockIndicators(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: _kGreen, foregroundColor: Colors.white, elevation: 0,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Market Signals', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text('MAR · PPI · IUR per crop', style: TextStyle(fontSize: 10, color: Colors.white70)),
        ]),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: _kGreen))
        : RefreshIndicator(
            onRefresh: _load, color: _kGreen,
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _legendCard(),
                const SizedBox(height: 12),
                ..._indicators.map((ind) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _cropCard(ind),
                )),
                _formulaCard(),
              ],
            ),
          ),
    );
  }

  Widget _legendCard() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('How to read this', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Row(children: [
        _dot(const Color(0xFF16A34A)), const SizedBox(width: 6),
        const Text('Good — market is healthy', style: TextStyle(fontSize: 11)),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        _dot(const Color(0xFFF59E0B)), const SizedBox(width: 6),
        const Text('Caution — monitor closely', style: TextStyle(fontSize: 11)),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        _dot(const Color(0xFFDC2626)), const SizedBox(width: 6),
        const Text('Oversupply Risk — consider adjusting plan', style: TextStyle(fontSize: 11)),
      ]),
    ]),
  );

  Widget _dot(Color c) => Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  Widget _cropCard(CropIndicators ind) {
    final overallColor = ind.overall == SaturationLevel.safe
      ? const Color(0xFF16A34A)
      : ind.overall == SaturationLevel.caution
        ? const Color(0xFFF59E0B)
        : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: ind.overall == SaturationLevel.danger
          ? Border.all(color: const Color(0xFFDC2626).withAlpha(80))
          : null,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(ind.cropName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: overallColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: overallColor, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(ind.overallLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: overallColor)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _indicatorGauge('MAR', ind.mar, '${(ind.mar * 100).toStringAsFixed(1)}%',
            _levelColor(ind.marLevel), 'Absorption\n≥85% safe')),
          Expanded(child: _indicatorGauge('PPI', ind.ppi / 100, '${ind.ppi.toStringAsFixed(1)}%',
            _levelColor(ind.ppiLevel), 'Price Pressure\n±10% safe')),
          Expanded(child: _indicatorGauge('IUR', ind.iur, '${(ind.iur * 100).toStringAsFixed(1)}%',
            _levelColor(ind.iurLevel), 'Unsold Ratio\n<15% safe')),
        ]),
        if (ind.overall == SaturationLevel.danger) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
            child: const Row(children: [
              Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Contact your BAW — this crop may be approaching oversupply.',
                style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C)))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _indicatorGauge(String label, double value, String display, Color color, String subtitle) {
    final clamped = value.clamp(0.0, 1.0);
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      SizedBox(
        width: 56, height: 56,
        child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(
            value: clamped, strokeWidth: 6,
            color: color,
            backgroundColor: color.withAlpha(25),
          ),
          Text(display, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color), textAlign: TextAlign.center),
        ]),
      ),
      const SizedBox(height: 4),
      Text(subtitle, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF), height: 1.3)),
    ]);
  }

  Color _levelColor(SaturationLevel l) {
    switch (l) {
      case SaturationLevel.safe: return const Color(0xFF16A34A);
      case SaturationLevel.caution: return const Color(0xFFF59E0B);
      case SaturationLevel.danger: return const Color(0xFFDC2626);
    }
  }

  Widget _formulaCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      Text('Indicator Formulas (PRD §7.1)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
      SizedBox(height: 8),
      Text('MAR = Q_sold ÷ Q_total   (≥0.85 safe)', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      SizedBox(height: 4),
      Text('PPI = ((P_current − P_baseline) ÷ P_baseline) × 100   (±10% safe)', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      SizedBox(height: 4),
      Text('IUR = I_unsold ÷ Q_total   (<0.15 safe)', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
    ]),
  );
}
