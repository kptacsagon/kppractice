import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/tubungan_barangays.dart';
import '../../services/crop_declaration_service.dart';

const _kGreen = Color(0xFF1B7737);

// PRD §3.3 — AT/BAW Workflow: Pending Declarations Queue + Validate/Return actions
class BawValidationQueueScreen extends StatefulWidget {
  const BawValidationQueueScreen({super.key});

  @override
  State<BawValidationQueueScreen> createState() => _BawValidationQueueScreenState();
}

class _BawValidationQueueScreenState extends State<BawValidationQueueScreen> {
  final _svc = CropDeclarationService();
  List<CropDeclaration> _pending = [];
  List<CropDeclaration> _allValidated = [];
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
    if (!mounted) return;
    setState(() { _pending = pending; _allValidated = validated; _loading = false; });
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
          child: Row(children: [
            _tabBtn('Pending (${_pending.length})', 0),
            _tabBtn('Validated (${_allValidated.length})', 1),
            _tabBtn('Harvest Calendar', 2),
          ]),
        ),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : _tab == 0 ? _buildPending()
            : _tab == 1 ? _buildValidated()
            : _buildHarvestCalendar()),
      ]),
    );
  }

  Widget _tabBtn(String label, int idx) {
    final sel = _tab == idx;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: Container(
        height: 42,
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: sel ? _kGreen : Colors.transparent, width: 2))),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? _kGreen : const Color(0xFF6B7280))),
      ),
    ));
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
