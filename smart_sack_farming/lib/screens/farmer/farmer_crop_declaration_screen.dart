import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/hvc_master_list.dart';
import '../../data/tubungan_barangays.dart';
import '../../services/crop_declaration_service.dart';

const _kGreen = Color(0xFF1B7737);
const _kGreenLight = Color(0xFFE7F1E8);

class FarmerCropDeclarationScreen extends StatefulWidget {
  /// When set, the screen is in BAW-assisted mode — recording on behalf of a farmer.
  final String? assistedFarmerName;
  final String? assistedRsbsa;
  const FarmerCropDeclarationScreen({
    super.key,
    this.assistedFarmerName,
    this.assistedRsbsa,
  });

  @override
  State<FarmerCropDeclarationScreen> createState() => _FarmerCropDeclarationScreenState();
}

class _FarmerCropDeclarationScreenState extends State<FarmerCropDeclarationScreen> {
  final _farmLotController = TextEditingController();
  final _remarksController = TextEditingController();
  final _areaController = TextEditingController();

  HvcCrop? _selectedCrop;
  String? _selectedBarangay;
  DateTime? _plantingDate;
  DateTime? _expectedHarvestDate;
  String _farmingMethod = 'Organic';
  double _volumeKg = 500;
  bool _submitting = false;
  int _tab = 0;
  List<CropDeclaration> _myDeclarations = [];

  final _svc = CropDeclarationService();

  @override
  void initState() {
    super.initState();
    _loadMyDeclarations();
  }

  @override
  void dispose() {
    _farmLotController.dispose();
    _remarksController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _recalcHarvestDate() {
    if (_selectedCrop != null && _plantingDate != null) {
      setState(() {
        _expectedHarvestDate = _plantingDate!.add(Duration(days: _selectedCrop!.avgDaysToMaturity));
      });
    }
  }

  Future<void> _pickPlantingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _kGreen)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _plantingDate = picked);
      _recalcHarvestDate();
    }
  }

  Future<void> _submit({bool draft = false}) async {
    if (!draft) {
      if (_selectedCrop == null) { _snack('Please select a crop'); return; }
      if (_plantingDate == null) { _snack('Please set planting date'); return; }
      if ((double.tryParse(_areaController.text) ?? 0) <= 0) { _snack('Please enter area planted'); return; }
    }

    setState(() => _submitting = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final isAssisted = widget.assistedFarmerName != null;
      String? remarks = _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim();
      if (isAssisted && widget.assistedRsbsa != null && widget.assistedRsbsa!.isNotEmpty) {
        final rsbsaTag = '[RSBSA: ${widget.assistedRsbsa}]';
        remarks = remarks == null ? rsbsaTag : '$rsbsaTag $remarks';
      }

      await _svc.submitDeclaration(CropDeclaration(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        farmerId: user.id,
        farmerName: widget.assistedFarmerName ?? user.userMetadata?['full_name'] as String? ?? user.email ?? 'Farmer',
        cropId: _selectedCrop?.id ?? '',
        cropName: _selectedCrop?.displayName ?? '',
        barangay: _selectedBarangay,
        farmLot: _farmLotController.text.trim().isEmpty ? null : _farmLotController.text.trim(),
        areaPlantedHa: double.tryParse(_areaController.text) ?? 0,
        plantingDate: _plantingDate ?? DateTime.now(),
        expectedHarvestDate: _expectedHarvestDate ?? DateTime.now().add(const Duration(days: 60)),
        estimatedVolumeKg: _volumeKg,
        farmingMethod: _farmingMethod,
        remarks: remarks,
        status: CropDeclarationStatus.pendingReview,
        submittedAt: DateTime.now(),
      ));

      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(draft ? 'Draft saved.' : 'Declaration submitted to your AT/BAW for validation.'),
        backgroundColor: _kGreen, duration: const Duration(seconds: 4),
      ));
      _resetForm();
      await _loadMyDeclarations();
      setState(() => _tab = 1);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _resetForm() {
    _farmLotController.clear();
    _remarksController.clear();
    _areaController.clear();
    setState(() {
      _selectedCrop = null;
      _selectedBarangay = null;
      _plantingDate = null;
      _expectedHarvestDate = null;
      _farmingMethod = 'Organic';
      _volumeKg = 500;
    });
  }

  Future<void> _loadMyDeclarations() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final list = await _svc.getMyDeclarations(user.id);
    if (mounted) setState(() => _myDeclarations = list);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: widget.assistedFarmerName != null ? const Color(0xFF1D4ED8) : _kGreen,
        foregroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            widget.assistedFarmerName != null
                ? 'Assisted: ${widget.assistedFarmerName}'
                : 'Declare Crop Planting',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis),
          Text(
            widget.assistedFarmerName != null
                ? (widget.assistedRsbsa != null && widget.assistedRsbsa!.isNotEmpty
                    ? 'RSBSA / ID: ${widget.assistedRsbsa}'
                    : 'BAW Assisted Entry')
                : 'Submit to your assigned AT/BAW',
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      ),
      bottomNavigationBar: _tab == 0 ? Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: _submitting ? null : () => _submit(),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: _submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  widget.assistedFarmerName != null
                      ? 'Submit Declaration for ${widget.assistedFarmerName}'
                      : 'Submit Declaration to AT/BAW',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: _submitting ? null : () => _submit(draft: true),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save as Draft', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          )),
        ]),
      ) : null,
      body: Column(children: [
        // ── Tabs ──
        Container(
          color: Colors.white,
          child: Row(children: [
            _tabBtn(0, '1', 'New Declaration', null),
            _tabBtn(1, '2', 'My Declarations', _myDeclarations.isNotEmpty ? '${_myDeclarations.length}' : null),
          ]),
        ),
        Expanded(child: _tab == 0 ? _buildForm() : _buildMyDeclarations()),
      ]),
    );
  }

  Widget _tabBtn(int idx, String num, String label, String? badge) {
    final active = _tab == idx;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: active ? _kGreen : Colors.transparent, width: 2)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(color: active ? _kGreen : const Color(0xFFE5E7EB), shape: BoxShape.circle),
            child: Center(child: Text(num, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF6B7280)))),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? _kGreen : const Color(0xFF6B7280))),
          if (badge != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: active ? _kGreen : const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(10)),
              child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF6B7280))),
            ),
          ],
        ]),
      ),
    ));
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── BAW Assisted Entry banner ──
        if (widget.assistedFarmerName != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF93C5FD))),
            child: Row(children: [
              const Icon(Icons.support_agent_rounded, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('BAW Assisted Entry',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8))),
                const SizedBox(height: 2),
                Text('Recording on behalf of: ${widget.assistedFarmerName}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                if (widget.assistedRsbsa != null && widget.assistedRsbsa!.isNotEmpty)
                  Text('RSBSA / Farmer ID: ${widget.assistedRsbsa}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6))),
              ])),
            ]),
          ),
          const SizedBox(height: 10),
        ],
        // ── Reporting chain ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: _kGreenLight, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.compare_arrows_rounded, size: 16, color: _kGreen),
            const SizedBox(width: 8),
            const Text('Reporting chain', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kGreen)),
            const SizedBox(width: 8),
            _chip(widget.assistedFarmerName != null ? 'BAW (you)' : 'You', const Color(0xFF374151), Colors.white),
            _arrow(),
            _chip('MAO', const Color(0xFF1F4E8C), Colors.white),
          ]),
        ),
        const SizedBox(height: 12),

        // ── Crop Selection ──
        _sectionCard(icon: Icons.eco_rounded, title: 'Crop Selection', subtitle: 'Choose from approved HVC master list', children: [
          DropdownButtonFormField<HvcCrop>(
            value: _selectedCrop,
            isExpanded: true,
            decoration: _deco(''),
            hint: const Text('Select a crop...', style: TextStyle(color: Color(0xFF9CA3AF))),
            items: kHvcMasterList.map((c) => DropdownMenuItem(
              value: c,
              child: Text('${c.nameLocal} — ${c.nameEnglish} · ${c.avgDaysToMaturity}d', overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) { setState(() => _selectedCrop = v); _recalcHarvestDate(); },
          ),
          if (_selectedCrop != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _kGreenLight, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.grass_rounded, color: _kGreen, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_selectedCrop!.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  Text('${_selectedCrop!.category} · Avg. ${_selectedCrop!.avgDaysToMaturity} days to maturity',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(6)),
                  child: Text('${_selectedCrop!.avgDaysToMaturity}d',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ]),
            ),
          ],
        ]),
        const SizedBox(height: 12),

        // ── Farm Details ──
        _sectionCard(icon: Icons.location_on_rounded, title: 'Farm Details', subtitle: 'Location and area information', children: [
          _fieldLabel('FARM LOT / PARCEL'),
          const SizedBox(height: 6),
          TextFormField(controller: _farmLotController, decoration: _deco('e.g. Lot 3 — Eastern Plot')),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _fieldLabel('BARANGAY'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedBarangay,
                isExpanded: true,
                decoration: _deco(''),
                hint: const Text('Select', style: TextStyle(color: Color(0xFF9CA3AF))),
                items: kTubunganBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _selectedBarangay = v),
              ),
            ])),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _fieldLabel('AREA (HA)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _areaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _deco('0.00'),
              ),
            ])),
          ]),
        ]),
        const SizedBox(height: 12),

        // ── Schedule ──
        _sectionCard(icon: Icons.calendar_month_rounded, title: 'Schedule', subtitle: 'Planting and expected harvest dates', children: [
          _fieldLabel('PLANTING DATE'),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickPlantingDate,
            child: InputDecorator(
              decoration: _deco(''),
              child: Row(children: [
                Expanded(child: Text(
                  _plantingDate == null ? 'mm/dd/yyyy'
                    : '${_plantingDate!.month.toString().padLeft(2,'0')}/${_plantingDate!.day.toString().padLeft(2,'0')}/${_plantingDate!.year}',
                  style: TextStyle(fontSize: 14, color: _plantingDate == null ? const Color(0xFF9CA3AF) : Colors.black87),
                )),
                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF6B7280)),
              ]),
            ),
          ),
          if (_selectedCrop != null && _plantingDate == null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCD34D))),
              child: Row(children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Set a planting date — auto-suggest your harvest window based on ${_selectedCrop!.nameLocal}\'s ${_selectedCrop!.avgDaysToMaturity}-day maturity cycle.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                )),
              ]),
            ),
          ],
          if (_expectedHarvestDate != null) ...[
            const SizedBox(height: 10),
            _fieldLabel('EXPECTED HARVEST DATE'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(color: _kGreenLight, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.event_available_rounded, size: 16, color: _kGreen),
                const SizedBox(width: 8),
                Text(
                  '${_expectedHarvestDate!.month.toString().padLeft(2,'0')}/${_expectedHarvestDate!.day.toString().padLeft(2,'0')}/${_expectedHarvestDate!.year}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kGreen),
                ),
                const SizedBox(width: 6),
                const Text('(auto-calculated)', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
              ]),
            ),
          ],
        ]),
        const SizedBox(height: 12),

        // ── Production ──
        _sectionCard(icon: Icons.agriculture_rounded, title: 'Production', subtitle: 'Estimated yield and farming method', children: [
          _fieldLabel('ESTIMATED VOLUME'),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(child: Slider(
              value: _volumeKg, min: 0, max: 5000, activeColor: _kGreen,
              onChanged: (v) => setState(() => _volumeKg = v),
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: _kGreenLight, borderRadius: BorderRadius.circular(6)),
              child: Text('${_volumeKg.toStringAsFixed(0)} kg',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kGreen)),
            ),
          ]),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('0 kg', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            Text('5,000 kg', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          ]),
          const SizedBox(height: 14),
          _fieldLabel('FARMING METHOD'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _methodCard('Organic', Icons.spa_rounded, 'Natural inputs only')),
            const SizedBox(width: 8),
            Expanded(child: _methodCard('Conventional', Icons.agriculture_rounded, 'Standard practice')),
            const SizedBox(width: 8),
            Expanded(child: _methodCard('GAP Certified', Icons.verified_rounded, 'Good Agricultural Practice')),
          ]),
          const SizedBox(height: 14),
          _fieldLabel('REMARKS / NOTES'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _remarksController, maxLines: 3,
            decoration: _deco('Optional notes for your Agricultural Technician...'),
          ),
        ]),
        const SizedBox(height: 12),

        // ── Summary ──
        if (_selectedCrop != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Column(children: [
              _summaryRow('Crop', _selectedCrop!.displayName),
              const SizedBox(height: 6),
              _summaryRow('Est. Volume', '${_volumeKg.toStringAsFixed(0)} kg'),
              const SizedBox(height: 10),
              const Row(children: [
                Icon(Icons.send_rounded, size: 12, color: _kGreen),
                SizedBox(width: 6),
                Expanded(child: Text('Submitting to your assigned AT/BAW for validation',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)))),
              ]),
            ]),
          ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildMyDeclarations() {
    if (_myDeclarations.isEmpty) {
      return const Center(child: Text('No declarations yet.', style: TextStyle(color: Color(0xFF6B7280))));
    }
    return RefreshIndicator(
      onRefresh: _loadMyDeclarations, color: _kGreen,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _myDeclarations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _declCard(_myDeclarations[i]),
      ),
    );
  }

  Widget _declCard(CropDeclaration d) {
    final color = switch (d.status) {
      CropDeclarationStatus.validated => _kGreen,
      CropDeclarationStatus.returned => const Color(0xFFDC2626),
      CropDeclarationStatus.harvested => const Color(0xFF2563EB),
      CropDeclarationStatus.cancelled => const Color(0xFF9CA3AF),
      _ => const Color(0xFFF59E0B),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
            child: Text(cropStatusToString(d.status).toUpperCase().replaceAll('_', ' '), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color))),
          const Spacer(),
          Text('${d.areaPlantedHa.toStringAsFixed(2)} ha · ${d.estimatedVolumeKg.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ]),
        const SizedBox(height: 8),
        Text(d.cropName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Planted: ${_fmt(d.plantingDate)} · Harvest: ${_fmt(d.expectedHarvestDate)}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        if (d.atNotes != null && d.atNotes!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
            child: Text('AT Note: ${d.atNotes}', style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C)))),
        ],
      ]),
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required String subtitle, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: _kGreen, size: 18),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1a1a1a))),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ]),
        ]),
        const Divider(height: 20),
        ...children,
      ]),
    );
  }

  Widget _methodCard(String method, IconData icon, String subtitle) {
    final selected = _farmingMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _farmingMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? _kGreenLight : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? _kGreen : const Color(0xFFE5E7EB), width: selected ? 1.5 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? _kGreen : const Color(0xFF9CA3AF), size: 22),
          const SizedBox(height: 4),
          Text(method, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? _kGreen : const Color(0xFF374151))),
          const SizedBox(height: 2),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
        ]),
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(label,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151), letterSpacing: 0.4));

  Widget _summaryRow(String label, String value) => Row(children: [
    Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
    const Spacer(),
    Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
  ]);

  Widget _chip(String label, Color bg, Color fg) => Container(
    margin: const EdgeInsets.only(right: 2),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
  );

  Widget _arrow() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 2),
    child: Icon(Icons.arrow_forward_rounded, size: 12, color: _kGreen),
  );

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint.isEmpty ? null : hint,
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kGreen, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    filled: true, fillColor: const Color(0xFFFAFAFA),
  );

  String _fmt(DateTime d) => '${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')}/${d.year}';
}
