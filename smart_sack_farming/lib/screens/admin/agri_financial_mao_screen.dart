import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/agri_dss_models.dart';
import '../../services/agri_dss_service.dart';
import '../../services/agri_ure_service.dart';

const _kGreen = Color(0xFF1B7737);
final _php = NumberFormat('#,##0', 'en_PH');

class AgriFinancialMaoScreen extends StatefulWidget {
  const AgriFinancialMaoScreen({super.key});
  @override
  State<AgriFinancialMaoScreen> createState() => _AgriFinancialMaoScreenState();
}

class _AgriFinancialMaoScreenState extends State<AgriFinancialMaoScreen>
    with SingleTickerProviderStateMixin {
  final _svc = AgriDssService();
  final _ureSvc = AgriUreService();

  List<MaoAggregationRow> _rows = [];
  List<UreEvent> _ureEvents = [];
  bool _loading = true;
  bool _ureLoading = true;
  String _sortBy = 'alerts';
  String _ureFilter = 'all';
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
    _loadUre();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _svc.getMaoAggregation();
    if (!mounted) return;
    setState(() { _rows = data; _loading = false; _sort(); });
  }

  Future<void> _loadUre() async {
    setState(() => _ureLoading = true);
    try {
      final data = await _ureSvc.getAllUreEvents();
      if (!mounted) return;
      setState(() { _ureEvents = data; _ureLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _ureLoading = false);
    }
  }

  void _sort() {
    switch (_sortBy) {
      case 'margin':
        _rows.sort((a, b) => b.totalNetMarginPhp.compareTo(a.totalNetMarginPhp));
        break;
      case 'mar':
        _rows.sort((a, b) => b.avgMar.compareTo(a.avgMar));
        break;
      case 'iur':
        _rows.sort((a, b) => b.avgIur.compareTo(a.avgIur));
        break;
      default:
        _rows.sort((a, b) => b.alertCount.compareTo(a.alertCount));
    }
  }

  List<UreEvent> get _filteredUre {
    if (_ureFilter == 'all') return _ureEvents;
    return _ureEvents.where((e) => e.status == _ureFilter).toList();
  }

  int get _pendingCount => _ureEvents.where((e) => e.status == 'pending').length;

  Future<void> _updateUreStatus(String id, String status, {String? notes}) async {
    await _ureSvc.updateVerificationStatus(eventId: id, status: status, notes: notes);
    _loadUre();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final totalMargin = _rows.fold(0.0, (s, r) => s + r.totalNetMarginPhp);
    final totalFarmers = _rows.fold(0, (s, r) => s + r.farmerCount);
    final totalAlerts  = _rows.fold(0, (s, r) => s + r.alertCount);
    final avgMar = _rows.isEmpty ? 0.0 : _rows.map((r) => r.avgMar).reduce((a, b) => a + b) / _rows.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F5F1),
      body: Column(children: [
        // ── Header ──
        Container(
          color: _kGreen,
          padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Cooperative Risk Aggregation', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                Text('MAO View — Tubungan, Iloilo', style: TextStyle(color: Color(0xFFB2D9B8), fontSize: 11)),
              ])),
              IconButton(onPressed: () { _load(); _loadUre(); }, icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20)),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _kpi('Farmers', '$totalFarmers', Icons.people_rounded),
              _divider(),
              _kpi('Total Net Margin', '₱${_php.format(totalMargin)}', Icons.payments_rounded),
              _divider(),
              _kpi('Active Alerts', '$totalAlerts', Icons.warning_amber_rounded, color: totalAlerts > 0 ? const Color(0xFFFBBF24) : Colors.white),
              _divider(),
              _kpi('Avg MAR', '${(avgMar * 100).toStringAsFixed(1)}%', Icons.shopping_bag_rounded),
            ]),
            const SizedBox(height: 10),
            TabBar(
              controller: _tabs,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              tabs: [
                const Tab(text: 'Barangay Risk'),
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('URE Reports', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    if (_pendingCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)),
                        child: Text('$_pendingCount', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                ),
              ],
            ),
          ]),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildRiskTab(),
              _buildUreTab(),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildRiskTab() {
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          const Text('Sort:', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          const SizedBox(width: 8),
          ...[['alerts', 'Alerts'], ['margin', 'Net Margin'], ['mar', 'MAR'], ['iur', 'IUR']].map((s) {
            final sel = _sortBy == s[0];
            return GestureDetector(
              onTap: () => setState(() { _sortBy = s[0]; _sort(); }),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: sel ? _kGreen : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(s[1], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? Colors.white : const Color(0xFF374151))),
              ),
            );
          }),
        ]),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kGreen))
            : _rows.isEmpty
                ? const Center(child: Text('No data available.', style: TextStyle(color: Color(0xFF6B7280))))
                : RefreshIndicator(
                    onRefresh: _load, color: _kGreen,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _BarangayCard(row: _rows[i]),
                    ),
                  ),
      ),
    ]);
  }

  Widget _buildUreTab() {
    final filtered = _filteredUre;
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            const Text('Filter:', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            const SizedBox(width: 8),
            ...[['all', 'All'], ['pending', 'Pending'], ['verified', 'Verified'], ['endorsed', 'Endorsed'], ['escalated', 'Escalated']].map((f) {
              final sel = _ureFilter == f[0];
              return GestureDetector(
                onTap: () => setState(() => _ureFilter = f[0]),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel ? _kGreen : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(f[1], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? Colors.white : const Color(0xFF374151))),
                ),
              );
            }),
          ]),
        ),
      ),
      Expanded(
        child: _ureLoading
            ? const Center(child: CircularProgressIndicator(color: _kGreen))
            : filtered.isEmpty
                ? Center(child: Text(_ureEvents.isEmpty ? 'No URE reports submitted yet.' : 'No reports match this filter.', style: const TextStyle(color: Color(0xFF6B7280))))
                : RefreshIndicator(
                    onRefresh: _loadUre, color: _kGreen,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _UreCard(
                        event: filtered[i],
                        onAction: (id, status, {notes}) => _updateUreStatus(id, status, notes: notes),
                      ),
                    ),
                  ),
      ),
    ]);
  }

  Widget _kpi(String label, String value, IconData icon, {Color color = Colors.white}) => Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: color, size: 14),
    const SizedBox(height: 3),
    Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF86EFAC))),
  ]);

  Widget _divider() => Container(width: 1, height: 36, color: Colors.white.withAlpha(40));
}

// ─── Barangay Card ────────────────────────────────────────────────────────────

class _BarangayCard extends StatelessWidget {
  final MaoAggregationRow row;
  const _BarangayCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final hasAlerts = row.alertCount > 0;
    final ppiColor = row.avgPpi >= 0 ? _kGreen : row.avgPpi < -10 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: hasAlerts ? Border.all(color: const Color(0xFFF59E0B).withAlpha(80)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Row 1: barangay + alert badge
        Row(children: [
          const Icon(Icons.location_on_rounded, color: _kGreen, size: 14),
          const SizedBox(width: 6),
          Expanded(child: Text(row.barangay, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
          if (hasAlerts)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
              child: Text('${row.alertCount} alert${row.alertCount > 1 ? "s" : ""}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF92400E), fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 2),
        Text('${row.farmerCount} farmers · Primary: ${row.dominantCommodity}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        const SizedBox(height: 10),
        // Metrics grid
        Row(children: [
          _metric('MAR', '${(row.avgMar * 100).toStringAsFixed(1)}%',
              row.avgMar >= 0.8 ? _kGreen : const Color(0xFFF59E0B)),
          _metric('Avg PPI', '${row.avgPpi >= 0 ? "+" : ""}${row.avgPpi.toStringAsFixed(1)}%', ppiColor),
          _metric('Avg IUR', '${(row.avgIur * 100).toStringAsFixed(1)}%',
              row.avgIur < 0.2 ? _kGreen : const Color(0xFFEF4444)),
          _metric('Net Margin', '₱${_php.format(row.totalNetMarginPhp)}',
              row.totalNetMarginPhp >= 0 ? _kGreen : const Color(0xFFEF4444)),
        ]),
        // PPI trend bar
        const SizedBox(height: 8),
        _ppiBar(row.avgPpi),
      ]),
    );
  }

  Widget _metric(String label, String value, Color color) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
    ]),
  );

  Widget _ppiBar(double ppi) {
    final norm = ((ppi + 30) / 60).clamp(0.0, 1.0);
    final color = ppi >= 0 ? _kGreen : ppi < -10 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('PPI Trend', style: TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
      const SizedBox(height: 3),
      Stack(children: [
        Container(height: 6, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4))),
        FractionallySizedBox(
          widthFactor: norm,
          child: Container(height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        ),
      ]),
    ]);
  }
}

// ─── URE Event Card ───────────────────────────────────────────────────────────

typedef _UreAction = void Function(String id, String status, {String? notes});

class _UreCard extends StatelessWidget {
  final UreEvent event;
  final _UreAction onAction;
  const _UreCard({required this.event, required this.onAction});

  Color get _statusColor {
    switch (event.status) {
      case 'verified': return const Color(0xFF16A34A);
      case 'endorsed': return const Color(0xFF2563EB);
      case 'escalated': return const Color(0xFFDC2626);
      case 'rejected': return const Color(0xFF9CA3AF);
      default: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final php = NumberFormat('#,##0', 'en_PH');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: event.status == 'pending' ? Border.all(color: const Color(0xFFF59E0B).withAlpha(100)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _statusColor.withAlpha(20), borderRadius: BorderRadius.circular(6)),
            child: Text(event.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor)),
          ),
          const Spacer(),
          Text(
            '${event.createdAt.day}/${event.createdAt.month}/${event.createdAt.year}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
          ),
        ]),
        const SizedBox(height: 8),
        Text('${event.eventType} — ${event.cropType}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1a1a1a))),
        const SizedBox(height: 4),
        Text(event.description,
            maxLines: 3, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.4)),
        if (event.financialImpact != null) ...[
          const SizedBox(height: 6),
          Text('Est. Impact: ₱${php.format(event.financialImpact!)}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
        ],
        const SizedBox(height: 10),
        if (event.status == 'pending')
          Row(children: [
            _actionBtn('Verify', const Color(0xFF16A34A), () => onAction(event.id, 'verified')),
            const SizedBox(width: 8),
            _actionBtn('Endorse', const Color(0xFF2563EB), () => onAction(event.id, 'endorsed')),
            const SizedBox(width: 8),
            _actionBtn('Escalate', const Color(0xFFDC2626), () => onAction(event.id, 'escalated')),
          ]),
        if (event.status != 'pending')
          TextButton(
            onPressed: () => onAction(event.id, 'pending'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Reset to Pending', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ),
      ]),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withAlpha(60))),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}
