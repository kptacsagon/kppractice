import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/tubungan_barangays.dart';
import '../../services/crop_declaration_service.dart';
import '../../services/agrisat_market_service.dart';
import '../../services/agri_financial_input_service.dart';

const _kRed = Color(0xFFDC2626);
final _phpK = NumberFormat('#,##0', 'en_PH');

const _kGreen = Color(0xFF1B7737);

// PRD §3.3 — AT/BAW Workflow: Pending Declarations Queue + Validate/Return actions
class BawValidationQueueScreen extends StatefulWidget {
  const BawValidationQueueScreen({super.key});

  @override
  State<BawValidationQueueScreen> createState() => _BawValidationQueueScreenState();
}

class _BawValidationQueueScreenState extends State<BawValidationQueueScreen> {
  final _svc = CropDeclarationService();
  final _mktSvc = AgrisatMarketService();
  final _finSvc = AgriFinancialInputService();
  List<CropDeclaration> _pending = [];
  List<CropDeclaration> _allValidated = [];
  List<HarvestReport> _harvestReports = [];
  List<Map<String, dynamic>> _pendingFarms = [];
  List<FinancialInputRecord> _pendingFinInputs = [];
  bool _loading = true;
  int _tab = 0;
  String? _selectedBarangay;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final pending = await _svc.getPendingDeclarations(barangay: _selectedBarangay);
    final validated = await _svc.getValidatedDeclarations(barangay: _selectedBarangay);
    final reports = await _mktSvc.getAllHarvestReports(barangay: _selectedBarangay);
    final farms = await _loadPendingFarms();
    final finInputs = await _finSvc.getPendingForBaw(barangay: _selectedBarangay);
    if (!mounted) return;
    setState(() {
      _pending = pending; _allValidated = validated;
      _harvestReports = reports; _pendingFarms = farms;
      _pendingFinInputs = finInputs; _loading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _loadPendingFarms() async {
    try {
      var q = Supabase.instance.client.from('agrisense_farms')
          .select('*, agrisense_farmer_profiles(full_name, contact_number, barangay)')
          .eq('verification_status', 'Pending Verification');
      if (_selectedBarangay != null) q = q.eq('barangay', _selectedBarangay!);
      final res = await q.order('submitted_at', ascending: true);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> _forwardFarmToMao(Map<String, dynamic> farm) async {
    try {
      await Supabase.instance.client.from('agrisense_farms').update({
        'verification_status': 'BAW Reviewed',
      }).eq('id', farm['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${farm['farm_name'] ?? 'Farm'} forwarded to MAO'), backgroundColor: _kGreen));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: _kRed));
    }
  }

  Future<void> _returnFarmToFarmer(Map<String, dynamic> farm) async {
    final notesCtl = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Return to Farmer'),
      content: TextField(
        controller: notesCtl, maxLines: 3,
        decoration: const InputDecoration(labelText: 'Correction notes', hintText: 'What does the farmer need to fix?'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: _kRed),
          child: const Text('Return', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
    if (confirmed != true || notesCtl.text.trim().isEmpty) return;
    try {
      await Supabase.instance.client.from('agrisense_farms').update({
        'verification_status': 'Needs Correction',
        'rejection_note': notesCtl.text.trim(),
      }).eq('id', farm['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Returned: ${farm['farm_name'] ?? 'Farm'}'), backgroundColor: _kRed));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: _kRed));
    }
  }

  Future<void> _validate(CropDeclaration d) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await _svc.validateDeclaration(d.id, user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Validated: ${d.cropName}'), backgroundColor: _kGreen));
    _load();
  }

  Future<void> _returnDecl(CropDeclaration d) async {
    final notesCtl = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Return Declaration'),
      content: TextField(
        controller: notesCtl,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Correction notes', hintText: 'Explain what the farmer needs to fix...'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)), child: const Text('Return', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (confirmed != true || notesCtl.text.trim().isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await _svc.returnDeclaration(d.id, user.id, notesCtl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Returned: ${d.cropName}'), backgroundColor: const Color(0xFFDC2626)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: _kGreen, foregroundColor: Colors.white, elevation: 0,
        title: const Text('AT/BAW Validation Queue'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: DropdownButtonFormField<String>(
            value: _selectedBarangay,
            decoration: InputDecoration(
              labelText: 'Filter by Barangay',
              prefixIcon: const Icon(Icons.location_on_rounded, size: 18, color: _kGreen),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Barangays')),
              ...kTubunganBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))),
            ],
            onChanged: (v) { setState(() => _selectedBarangay = v); _load(); },
          ),
        ),
        Container(
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _tabBtn('Declarations (${_pending.length})', 0),
              _tabBtn('Farm Registry (${_pendingFarms.length})', 1),
              _tabBtn('Financial Inputs (${_pendingFinInputs.length})', 2),
              _tabBtn('Validated (${_allValidated.length})', 3),
              _tabBtn('Harvest Calendar', 4),
              _tabBtn('Unsold IUR', 5),
            ]),
          ),
        ),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : _tab == 0 ? _buildPending()
            : _tab == 1 ? _buildFarmRegistry()
            : _tab == 2 ? _buildFinancialInputs()
            : _tab == 3 ? _buildValidated()
            : _tab == 4 ? _buildHarvestCalendar()
            : _buildUnsoldTracker()),
      ]),
    );
  }

  Widget _tabBtn(String label, int idx) {
    final sel = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: sel ? _kGreen : Colors.transparent, width: 2))),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? _kGreen : const Color(0xFF6B7280))),
      ),
    );
  }

  Widget _buildFarmRegistry() {
    if (_pendingFarms.isEmpty) {
      return const Center(child: Text('No farm registrations pending BAW review.', style: TextStyle(color: Color(0xFF6B7280))));
    }
    return RefreshIndicator(
      onRefresh: _load, color: _kGreen,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _pendingFarms.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final farm = _pendingFarms[i];
          final profile = farm['agrisense_farmer_profiles'];
          final farmerName = (profile is Map ? profile['full_name'] : null) ?? '—';
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withAlpha(100)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.eco_rounded, color: _kGreen, size: 14),
                const SizedBox(width: 6),
                Expanded(child: Text(farm['farm_name'] ?? 'Unnamed Farm',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                  child: const Text('PENDING BAW REVIEW', style: TextStyle(fontSize: 9, color: Color(0xFF92400E), fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 8),
              _kv('Farmer', farmerName),
              _kv('Barangay', farm['barangay'] ?? '—'),
              _kv('Area', '${((farm['total_area_hectares'] as num?) ?? 0).toStringAsFixed(4)} ha'),
              _kv('Primary Crop', farm['primary_crop'] ?? '—'),
              _kv('Ownership', farm['ownership_type'] ?? '—'),
              if (farm['submitted_at'] != null)
                _kv('Submitted', farm['submitted_at'].toString().split('T').first),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => _forwardFarmToMao(farm),
                  icon: const Icon(Icons.forward_rounded, size: 16),
                  label: const Text('Forward to MAO'),
                  style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _returnFarmToFarmer(farm),
                  icon: const Icon(Icons.reply_rounded, size: 16, color: _kRed),
                  label: const Text('Return', style: TextStyle(color: _kRed)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: _kRed)),
                )),
              ]),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildFinancialInputs() {
    if (_pendingFinInputs.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calculate_outlined, size: 52, color: Color(0xFFD1D5DB)),
          SizedBox(height: 12),
          Text('No financial inputs pending review.',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Farmers submit crop cycle cost and yield data here for your verification.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12), textAlign: TextAlign.center),
        ]),
      ));
    }
    return RefreshIndicator(
      onRefresh: _load, color: _kGreen,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _pendingFinInputs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _financialInputCard(_pendingFinInputs[i]),
      ),
    );
  }

  Widget _financialInputCard(FinancialInputRecord r) {
    final nfi = r.netFarmIncome;
    final lossRate = r.lossRatePct;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF93C5FD).withAlpha(150)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Row(children: [
          const Icon(Icons.menu_book_rounded, color: Color(0xFF2563EB), size: 15),
          const SizedBox(width: 6),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${r.farmerName} · ${r.cropType}${r.cropVariety.isEmpty ? '' : ' (${r.cropVariety})'}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            Text('${r.barangay} · ${r.areaPlantedHa.toStringAsFixed(2)} ha · planted ${_fmtDate(r.plantingDate)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
            child: const Text('PENDING REVIEW',
                style: TextStyle(fontSize: 9, color: Color(0xFF2563EB), fontWeight: FontWeight.w800)),
          ),
        ]),
        const Divider(height: 16),
        // ── 6-Stage Summary ──
        _stageBlock('1', 'Pre-Planting',
            'Land prep PHP ${_phpK.format(r.landPrepCost)} · Soil PHP ${_phpK.format(r.soilPrepCost)} · Seed ${r.seedQtyKg.toStringAsFixed(0)} kg / PHP ${_phpK.format(r.seedCostPhp)} (${r.seedSource})'),
        _stageBlock('2', 'Planting',
            'Labor PHP ${_phpK.format(r.laborPlantingPhp)} · Basal fert PHP ${_phpK.format(r.fertBasalPhp)} · Irrigation PHP ${_phpK.format(r.irrigationPhp)} · Pesticide PHP ${_phpK.format(r.pesticidePlantingPhp)}'),
        _stageBlock('3', 'Maintenance',
            'Weeding PHP ${_phpK.format(r.laborWeedingPhp)} · Spraying PHP ${_phpK.format(r.sprayingCostPhp)} · Top-dress PHP ${_phpK.format(r.fertTopDressPhp)}'
            '${r.pestIncidents.isEmpty ? '' : '\n  ⚠ ${r.pestIncidents}'}'),
        _stageBlock('4', 'Harvest',
            'Gross ${r.grossHarvestKg.toStringAsFixed(0)} kg → Marketable ${r.marketableYieldKg.toStringAsFixed(0)} · Damaged ${r.damagedYieldKg.toStringAsFixed(0)} · Rejected ${r.rejectedYieldKg.toStringAsFixed(0)} kg'),
        _stageBlock('5', 'Post-Harvest',
            'Storage loss ${r.storageLossKg.toStringAsFixed(0)} kg · Unsold ${r.unsoldKg.toStringAsFixed(0)} kg · Transport PHP ${_phpK.format(r.transportPhp)} · Packaging PHP ${_phpK.format(r.packagingPhp)}'),
        _stageBlock('6', 'Sales',
            'Sold ${r.quantitySoldKg.toStringAsFixed(0)} kg @ PHP ${r.sellingPricePhp.toStringAsFixed(2)}/kg to ${r.buyerType}'),
        const SizedBox(height: 10),
        // ── Computed KPIs ──
        Row(children: [
          Expanded(child: _finKpi('Net Farm Income',
              'PHP ${_phpK.format(nfi)}', nfi >= 0 ? _kGreen : _kRed)),
          const SizedBox(width: 6),
          Expanded(child: _finKpi('Loss Rate',
              '${lossRate.toStringAsFixed(1)}%',
              lossRate > 15 ? _kRed : lossRate > 5 ? const Color(0xFFCA8A04) : _kGreen)),
          const SizedBox(width: 6),
          Expanded(child: _finKpi('Yield/ha',
              '${r.yieldPerHa.toStringAsFixed(0)} kg', const Color(0xFF2563EB))),
        ]),
        const SizedBox(height: 12),
        // ── Actions ──
        Row(children: [
          Expanded(child: ElevatedButton.icon(
            onPressed: () => _verifyFinInput(r),
            icon: const Icon(Icons.fact_check_rounded, size: 15),
            label: const Text('Open Verification Checklist',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          )),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _returnFinInput(r),
            icon: const Icon(Icons.reply_rounded, size: 14, color: _kRed),
            label: const Text('Return', style: TextStyle(fontSize: 11, color: _kRed, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kRed),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ]),
      ]),
    );
  }

  Widget _stageBlock(String n, String stage, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 18, height: 18, alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
        child: Text(n, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
      ),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(stage, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
        Text(body, style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280), height: 1.4)),
      ])),
    ]),
  );

  Widget _finKpi(String label, String value, Color color) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF9CA3AF))),
    ]),
  );

  Future<void> _verifyFinInput(FinancialInputRecord r) async {
    final notesCtl = TextEditingController();
    final result = await showDialog<BawVerificationChecklist>(
      context: context,
      builder: (_) => _ChecklistDialog(record: r, notesController: notesCtl),
    );
    if (result == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await _finSvc.bawVerify(r.id, user.id, result,
        notes: notesCtl.text.trim().isEmpty ? null : notesCtl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✓ Verified: ${r.farmerName} · ${r.cropType} — forwarded to MAO'),
      backgroundColor: _kGreen));
    _load();
  }

  Future<void> _returnFinInput(FinancialInputRecord r) async {
    final notesCtl = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Row(children: [
        Icon(Icons.reply_rounded, color: _kRed, size: 20),
        SizedBox(width: 8),
        Text('Return to Farmer', style: TextStyle(fontSize: 15)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: notesCtl, maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Correction notes *',
            hintText: 'What data needs to be corrected?',
            border: OutlineInputBorder(), isDense: true)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton.icon(
          onPressed: () {
            if (notesCtl.text.trim().isEmpty) return;
            Navigator.pop(context, true);
          },
          icon: const Icon(Icons.reply_rounded, size: 14),
          label: const Text('Return'),
          style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
        ),
      ],
    ));
    if (confirmed != true || notesCtl.text.trim().isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await _finSvc.bawReturn(r.id, user.id, notesCtl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Returned to ${r.farmerName}'),
      backgroundColor: _kRed));
    _load();
  }

  Widget _buildPending() {
    if (_pending.isEmpty) {
      return const Center(child: Text('No pending declarations.', style: TextStyle(color: Color(0xFF6B7280))));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _pendingCard(_pending[i]),
    );
  }

  Widget _buildValidated() {
    if (_allValidated.isEmpty) {
      return const Center(child: Text('No validated declarations yet.', style: TextStyle(color: Color(0xFF6B7280))));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _allValidated.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _validatedCard(_allValidated[i]),
    );
  }

  Widget _buildHarvestCalendar() {
    // PRD §3.3.2 — Harvest Calendar: timeline view of expected harvests
    if (_allValidated.isEmpty) {
      return const Center(child: Text('No upcoming harvests.', style: TextStyle(color: Color(0xFF6B7280))));
    }
    final sorted = List<CropDeclaration>.from(_allValidated)
      ..sort((a, b) => a.expectedHarvestDate.compareTo(b.expectedHarvestDate));
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final d = sorted[i];
        final days = d.expectedHarvestDate.difference(DateTime.now()).inDays;
        final urgent = days >= 0 && days <= 14;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10),
            border: urgent ? Border.all(color: const Color(0xFFF59E0B).withAlpha(120)) : null,
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: urgent ? const Color(0xFFFEF3C7) : const Color(0xFFE7F1E8), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.event_rounded, color: urgent ? const Color(0xFF92400E) : _kGreen, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.cropName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text('${d.farmerName} · ${d.estimatedVolumeKg.toStringAsFixed(0)} kg',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_fmtDate(d.expectedHarvestDate), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              Text(days < 0 ? 'overdue' : 'in ${days}d',
                style: TextStyle(fontSize: 10, color: urgent ? const Color(0xFF92400E) : const Color(0xFF6B7280))),
            ]),
          ]),
        );
      },
    );
  }

  // PRD FR-B06 — Unsold Inventory Tracker
  Widget _buildUnsoldTracker() {
    final highIur = _harvestReports.where((r) => r.iur > 0.25).toList()
      ..sort((a, b) => b.iur.compareTo(a.iur));
    if (_harvestReports.isEmpty) {
      return const Center(child: Text('No harvest reports yet.', style: TextStyle(color: Color(0xFF6B7280))));
    }
    if (highIur.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.check_circle_rounded, color: _kGreen, size: 48),
        SizedBox(height: 12),
        Text('No farmers with high unsold inventory.', style: TextStyle(color: Color(0xFF6B7280))),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: highIur.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = highIur[i];
        final iurColor = r.iur > 0.40 ? const Color(0xFFDC2626) : const Color(0xFFF59E0B);
        final iurLabel = r.iur > 0.40 ? 'CRITICAL — MAO buyer match needed' : 'HIGH — Consider storage referral';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: iurColor.withAlpha(80)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(r.farmerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: iurColor.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                child: Text('IUR ${(r.iur * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: iurColor)),
              ),
            ]),
            const SizedBox(height: 6),
            Text('${r.cropName} · ${r.quantityUnsoldKg.toStringAsFixed(0)} kg unsold',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            const SizedBox(height: 4),
            Text(iurLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: iurColor)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Referral sent for ${r.farmerName}'), backgroundColor: _kGreen)),
                icon: const Icon(Icons.warehouse_rounded, size: 14),
                label: const Text('Refer to Storage', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFD1D5DB))),
              )),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('MAO buyer match request sent for ${r.farmerName}'), backgroundColor: const Color(0xFF2563EB))),
                icon: const Icon(Icons.storefront_rounded, size: 14),
                label: const Text('Buyer Match', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              )),
            ]),
          ]),
        );
      },
    );
  }

  Widget _pendingCard(CropDeclaration d) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withAlpha(100)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Expanded(child: Text(d.farmerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
            child: const Text('PENDING REVIEW', style: TextStyle(fontSize: 9, color: Color(0xFF92400E), fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(d.cropName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 4, children: [
          _kv('Area', '${d.areaPlantedHa.toStringAsFixed(2)} ha'),
          _kv('Volume', '${d.estimatedVolumeKg.toStringAsFixed(0)} kg'),
          if (d.barangay != null) _kv('Brgy', d.barangay!),
          if (d.farmLot != null) _kv('Lot', d.farmLot!),
          _kv('Planted', _fmtDate(d.plantingDate)),
          _kv('Harvest', _fmtDate(d.expectedHarvestDate)),
          if (d.farmingMethod != null) _kv('Method', d.farmingMethod!),
        ]),
        if (d.remarks != null && d.remarks!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(6)),
            child: Text('Farmer Note: ${d.remarks}', style: const TextStyle(fontSize: 11, color: Color(0xFF374151))),
          ),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ElevatedButton.icon(
            onPressed: () => _validate(d),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Validate'),
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
            onPressed: () => _returnDecl(d),
            icon: const Icon(Icons.reply_rounded, size: 16, color: Color(0xFFDC2626)),
            label: const Text('Return', style: TextStyle(color: Color(0xFFDC2626))),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFDC2626))),
          )),
        ]),
      ]),
    );
  }

  Widget _validatedCard(CropDeclaration d) {
    final color = switch (d.status) {
      CropDeclarationStatus.validated => _kGreen,
      CropDeclarationStatus.returned => const Color(0xFFDC2626),
      CropDeclarationStatus.harvested => const Color(0xFF2563EB),
      _ => const Color(0xFF9CA3AF),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Container(width: 4, height: 40, color: color),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${d.cropName} · ${d.farmerName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          Text('${d.areaPlantedHa.toStringAsFixed(2)} ha · harvest ${_fmtDate(d.expectedHarvestDate)}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(4)),
          child: Text(cropStatusToString(d.status).toUpperCase(),
            style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _kv(String k, String v) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text('$k: ', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
    Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
  ]);

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}

// ═════════════════════════════════════════════════════════════════════════════
// BAW Verification Checklist Dialog — 5-point field validation
// ═════════════════════════════════════════════════════════════════════════════

class _ChecklistDialog extends StatefulWidget {
  final FinancialInputRecord record;
  final TextEditingController notesController;
  const _ChecklistDialog({required this.record, required this.notesController});

  @override
  State<_ChecklistDialog> createState() => _ChecklistDialogState();
}

class _ChecklistDialogState extends State<_ChecklistDialog> {
  bool _areaVerified = false;
  bool _cropVerified = false;
  bool _yieldReasonable = false;
  bool _lossesValidated = false;
  bool _marketConfirmed = false;

  bool get _isComplete =>
      _areaVerified && _cropVerified && _yieldReasonable && _lossesValidated && _marketConfirmed;
  int get _count => [_areaVerified, _cropVerified, _yieldReasonable, _lossesValidated, _marketConfirmed]
      .where((b) => b).length;

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          // ── Header ──
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: _kGreen.withAlpha(20), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.fact_check_rounded, color: _kGreen, size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Field Verification Checklist',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
              Text('Confirm each item before forwarding to MAO',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF6B7280))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _isComplete ? _kGreen : const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$_count / 5', style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 14),
          // ── Submission context ──
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${r.farmerName} · ${r.cropType}${r.cropVariety.isEmpty ? '' : ' (${r.cropVariety})'}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
              Text('${r.barangay} · ${r.areaPlantedHa.toStringAsFixed(2)} ha',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280))),
            ]),
          ),
          const SizedBox(height: 12),
          // ── Checklist items ──
          Expanded(child: SingleChildScrollView(child: Column(children: [
            _checkItem('Area Verified',
                'Reported area (${r.areaPlantedHa.toStringAsFixed(2)} ha) matches field measurement.',
                _areaVerified, (v) => setState(() => _areaVerified = v!)),
            _checkItem('Crop Verified',
                'Confirmed ${r.cropType}${r.cropVariety.isEmpty ? '' : ' (${r.cropVariety})'} was actually planted on this farm.',
                _cropVerified, (v) => setState(() => _cropVerified = v!)),
            _checkItem('Yield Reasonable',
                'Reported gross harvest (${r.grossHarvestKg.toStringAsFixed(0)} kg) is plausible for this area & crop.',
                _yieldReasonable, (v) => setState(() => _yieldReasonable = v!)),
            _checkItem('Losses Validated',
                'Reported damaged/rejected/storage losses (${(r.damagedYieldKg + r.rejectedYieldKg + r.storageLossKg).toStringAsFixed(0)} kg) are supported by field evidence.',
                _lossesValidated, (v) => setState(() => _lossesValidated = v!)),
            _checkItem('Market Condition Confirmed',
                'Selling price (PHP ${r.sellingPricePhp.toStringAsFixed(2)}/kg) and unsold (${r.unsoldKg.toStringAsFixed(0)} kg) align with local market.',
                _marketConfirmed, (v) => setState(() => _marketConfirmed = v!)),
            const SizedBox(height: 10),
            TextField(
              controller: widget.notesController,
              maxLines: 2,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                labelText: 'Verification notes (optional)',
                labelStyle: TextStyle(fontSize: 11),
                border: OutlineInputBorder(), isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ]))),
          const SizedBox(height: 12),
          // ── Footer ──
          if (!_isComplete) Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFFCA8A04)),
                SizedBox(width: 6),
                Expanded(child: Text(
                    'Check all 5 boxes to forward to MAO. Use "Return" if data needs correction.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E)))),
              ]),
            ),
          ),
          Row(children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isComplete
                  ? () => Navigator.pop(context, BawVerificationChecklist(
                      areaVerified: _areaVerified,
                      cropVerified: _cropVerified,
                      yieldReasonable: _yieldReasonable,
                      lossesValidated: _lossesValidated,
                      marketConfirmed: _marketConfirmed))
                  : null,
              icon: const Icon(Icons.send_rounded, size: 14),
              label: const Text('Verify & Forward to MAO',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen, foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD1D5DB),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _checkItem(String title, String desc, bool value, ValueChanged<bool?> onChanged) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: value ? const Color(0xFFE7F1E8) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: value ? _kGreen : const Color(0xFFE5E7EB)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 22, height: 22, child: Checkbox(
              value: value, onChanged: onChanged, activeColor: _kGreen,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            )),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: value ? const Color(0xFF154D26) : const Color(0xFF111827))),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280), height: 1.4)),
            ])),
          ]),
        ),
      ),
    );
}
