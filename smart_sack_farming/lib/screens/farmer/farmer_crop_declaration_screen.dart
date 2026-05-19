import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/hvc_master_list.dart';
import '../../data/tubungan_barangays.dart';
import '../../services/crop_declaration_service.dart';

const _kGreen = Color(0xFF1B7737);

// PRD §3.2 — Farmer Crop Planting Declaration
class FarmerCropDeclarationScreen extends StatefulWidget {
  const FarmerCropDeclarationScreen({super.key});

  @override
  State<FarmerCropDeclarationScreen> createState() => _FarmerCropDeclarationScreenState();
}

class _FarmerCropDeclarationScreenState extends State<FarmerCropDeclarationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _farmLotController = TextEditingController();
  final _barangayController = TextEditingController();
  final _areaController = TextEditingController();
  final _volumeController = TextEditingController();
  final _remarksController = TextEditingController();

  HvcCrop? _selectedCrop;
  String? _selectedBarangay;
  DateTime? _plantingDate;
  DateTime? _expectedHarvestDate;
  String? _farmingMethod;
  bool _submitting = false;
  bool _showMyDeclarations = false;
  List<CropDeclaration> _myDeclarations = [];

  final _svc = CropDeclarationService();
  final _farmingMethods = ['Organic', 'Conventional', 'GAP-certified'];

  @override
  void dispose() {
    _farmLotController.dispose();
    _barangayController.dispose();
    _areaController.dispose();
    _volumeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  // PRD §3.2.2 — Harvest Date Auto-Suggestion Logic
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
    );
    if (picked != null) {
      setState(() => _plantingDate = picked);
      _recalcHarvestDate();
    }
  }

  Future<void> _pickHarvestDate() async {
    if (_plantingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select planting date first')));
      return;
    }
    // PRD §3.2.2 — ±30 day tolerance from auto-suggested
    final initial = _expectedHarvestDate ?? _plantingDate!.add(Duration(days: _selectedCrop?.avgDaysToMaturity ?? 60));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: initial.subtract(const Duration(days: 30)),
      lastDate: initial.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _expectedHarvestDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a crop')));
      return;
    }
    if (_plantingDate == null || _expectedHarvestDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete date fields')));
      return;
    }

    setState(() => _submitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final decl = CropDeclaration(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        farmerId: user.id,
        farmerName: user.userMetadata?['full_name'] as String? ?? user.email ?? 'Farmer',
        cropId: _selectedCrop!.id,
        cropName: _selectedCrop!.displayName,
        barangay: _barangayController.text.trim().isEmpty ? null : _barangayController.text.trim(),
        farmLot: _farmLotController.text.trim().isEmpty ? null : _farmLotController.text.trim(),
        areaPlantedHa: double.parse(_areaController.text.trim()),
        plantingDate: _plantingDate!,
        expectedHarvestDate: _expectedHarvestDate!,
        estimatedVolumeKg: double.parse(_volumeController.text.trim()),
        farmingMethod: _farmingMethod,
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        status: CropDeclarationStatus.pendingReview,
        submittedAt: DateTime.now(),
      );

      await _svc.submitDeclaration(decl);

      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Declaration submitted to your AT/BAW for review.'),
        backgroundColor: _kGreen, duration: Duration(seconds: 4),
      ));
      _resetForm();
      _loadMyDeclarations();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _farmLotController.clear();
    _barangayController.clear();
    _areaController.clear();
    _volumeController.clear();
    _remarksController.clear();
    setState(() {
      _selectedCrop = null;
      _selectedBarangay = null;
      _plantingDate = null;
      _expectedHarvestDate = null;
      _farmingMethod = null;
    });
  }

  Future<void> _loadMyDeclarations() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final list = await _svc.getMyDeclarations(user.id);
    if (mounted) setState(() => _myDeclarations = list);
  }

  @override
  void initState() {
    super.initState();
    _loadMyDeclarations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        title: const Text('Declare Crop Planting'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Row(children: [
            _tabBtn('New Declaration', !_showMyDeclarations, () => setState(() => _showMyDeclarations = false)),
            _tabBtn('My Declarations (${_myDeclarations.length})', _showMyDeclarations, () => setState(() => _showMyDeclarations = true)),
          ]),
        ),
      ),
      body: _showMyDeclarations ? _buildMyDeclarations() : _buildForm(),
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          border: Border(bottom: BorderSide(color: active ? _kGreen : Colors.transparent, width: 2)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(
          color: active ? _kGreen : Colors.white,
          fontSize: 13, fontWeight: FontWeight.w700,
        )),
      ),
    ));
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _infoBanner(),
        const SizedBox(height: 14),
        _section('Crop Selection', [
          DropdownButtonFormField<HvcCrop>(
            value: _selectedCrop,
            decoration: _deco('High-Value Crop (HVC)', ''),
            isExpanded: true,
            items: kHvcMasterList.map((c) => DropdownMenuItem(
              value: c,
              child: Text('${c.nameLocal} — ${c.nameEnglish} · ${c.avgDaysToMaturity}d', overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) { setState(() => _selectedCrop = v); _recalcHarvestDate(); },
            validator: (v) => v == null ? 'Required' : null,
          ),
        ]),
        const SizedBox(height: 12),
        _section('Farm Details', [
          TextFormField(controller: _farmLotController, decoration: _deco('Farm Lot / Parcel', 'e.g. Lot 3 — Eastern Plot')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedBarangay,
            decoration: _deco('Barangay', ''),
            isExpanded: true,
            items: kTubunganBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (v) => setState(() { _selectedBarangay = v; _barangayController.text = v ?? ''; }),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _areaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _deco('Area Planted (hectares)', 'e.g. 0.5'),
            validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter a valid number' : null,
          ),
        ]),
        const SizedBox(height: 12),
        _section('Schedule', [
          _dateRow('Planting Date', _plantingDate, _pickPlantingDate),
          const SizedBox(height: 10),
          _dateRow('Expected Harvest Date', _expectedHarvestDate, _pickHarvestDate),
          if (_selectedCrop != null && _plantingDate != null)
            Padding(padding: const EdgeInsets.only(top: 6), child: Text(
              'Auto-calculated from ${_selectedCrop!.avgDaysToMaturity} days to maturity. ±30 day adjust allowed.',
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
            )),
        ]),
        const SizedBox(height: 12),
        _section('Production', [
          TextFormField(
            controller: _volumeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _deco('Estimated Volume (kg)', 'e.g. 500'),
            validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter a valid number' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _farmingMethod,
            decoration: _deco('Farming Method (optional)', ''),
            items: _farmingMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _farmingMethod = v),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _remarksController,
            maxLines: 3,
            decoration: _deco('Remarks / Notes (optional)', 'Any context for your AT reviewer...'),
          ),
        ]),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _submitting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Submit Declaration to AT/BAW', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        )),
      ])),
    );
  }

  Widget _buildMyDeclarations() {
    if (_myDeclarations.isEmpty) {
      return const Center(child: Text('No declarations yet. Submit your first one.', style: TextStyle(color: Color(0xFF6B7280))));
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
      CropDeclarationStatus.validated => const Color(0xFF16A34A),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
            child: Text(cropStatusToString(d.status).toUpperCase().replaceAll('_', ' '),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ),
          const Spacer(),
          Text('${d.areaPlantedHa.toStringAsFixed(2)} ha · ${d.estimatedVolumeKg.toStringAsFixed(0)} kg',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ]),
        const SizedBox(height: 8),
        Text(d.cropName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Planted: ${_fmtDate(d.plantingDate)} · Harvest: ${_fmtDate(d.expectedHarvestDate)}',
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        if (d.atNotes != null && d.atNotes!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
            child: Text('AT Note: ${d.atNotes}', style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C))),
          ),
        ],
      ]),
    );
  }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1a1a1a))),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _dateRow(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: _deco(label, ''),
        child: Row(children: [
          Expanded(child: Text(value == null ? 'Select date' : _fmtDate(value),
            style: TextStyle(fontSize: 14, color: value == null ? const Color(0xFF9CA3AF) : Colors.black))),
          const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF6B7280)),
        ]),
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBFDBFE))),
      child: const Row(children: [
        Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 18),
        SizedBox(width: 8),
        Expanded(child: Text(
          'Reporting chain: Farmer → AT/BAW → MAO. Your declaration goes to your assigned AT for validation before reaching the MAO.',
          style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), height: 1.4),
        )),
      ]),
    );
  }

  InputDecoration _deco(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint.isEmpty ? null : hint,
    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kGreen)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    filled: true,
    fillColor: const Color(0xFFFAFAFA),
  );
}
