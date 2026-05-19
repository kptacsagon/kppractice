import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/hvc_master_list.dart';
import '../../data/tubungan_barangays.dart';
import '../../services/agrisat_market_service.dart';

const _kGreen = Color(0xFF1B7737);

// PRD FR-F03 — Harvest Report Submission
class HarvestReportScreen extends StatefulWidget {
  const HarvestReportScreen({super.key});

  @override
  State<HarvestReportScreen> createState() => _HarvestReportScreenState();
}

class _HarvestReportScreenState extends State<HarvestReportScreen> {
  final _actualYieldCtl = TextEditingController();
  final _soldCtl = TextEditingController();
  final _unsoldCtl = TextEditingController();
  final _priceCtl = TextEditingController();

  HvcCrop? _selectedCrop;
  String? _selectedBarangay;
  String _disposalMethod = 'Sold at farm gate';
  bool _submitting = false;
  List<HarvestReport> _myReports = [];

  final _svc = AgrisatMarketService();
  final _disposalOptions = ['Sold at farm gate', 'Sold at market', 'Cooperative', 'Stored', 'Wasted/Spoiled'];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _actualYieldCtl.dispose();
    _soldCtl.dispose();
    _unsoldCtl.dispose();
    _priceCtl.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final list = await _svc.getMyHarvestReports(user.id);
    if (mounted) setState(() => _myReports = list);
  }

  // Auto-compute unsold when sold is entered
  void _onSoldChanged(String val) {
    final total = double.tryParse(_actualYieldCtl.text) ?? 0;
    final sold = double.tryParse(val) ?? 0;
    final unsold = (total - sold).clamp(0.0, double.infinity);
    _unsoldCtl.text = unsold.toStringAsFixed(1);
    setState(() {});
  }

  Future<void> _submit() async {
    if (_selectedCrop == null) { _snack('Select a crop'); return; }
    final yield_ = double.tryParse(_actualYieldCtl.text) ?? 0;
    final sold = double.tryParse(_soldCtl.text) ?? 0;
    final unsold = double.tryParse(_unsoldCtl.text) ?? 0;
    final price = double.tryParse(_priceCtl.text) ?? 0;
    if (yield_ <= 0) { _snack('Enter actual yield'); return; }
    if (price <= 0) { _snack('Enter price received'); return; }

    setState(() => _submitting = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await _svc.submitHarvestReport(HarvestReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        farmerId: user.id,
        farmerName: user.userMetadata?['full_name'] as String? ?? user.email ?? 'Farmer',
        cropId: _selectedCrop!.id,
        cropName: _selectedCrop!.displayName,
        barangay: _selectedBarangay,
        actualYieldKg: yield_,
        quantitySoldKg: sold,
        quantityUnsoldKg: unsold,
        priceReceivedPerKg: price,
        disposalMethod: _disposalMethod,
        reportedAt: DateTime.now(),
      ));

      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Harvest report submitted. BAW will verify your data.'),
        backgroundColor: _kGreen, duration: Duration(seconds: 4),
      ));
      _actualYieldCtl.clear(); _soldCtl.clear(); _unsoldCtl.clear(); _priceCtl.clear();
      setState(() { _selectedCrop = null; _selectedBarangay = null; });
      _loadReports();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: _kGreen, foregroundColor: Colors.white, elevation: 0,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Report Harvest Outcome', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text('PRD FR-F03 — Actual yield, sold, unsold', style: TextStyle(fontSize: 10, color: Colors.white70)),
        ]),
        bottom: const TabBar(
          labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [Tab(text: 'New Report'), Tab(text: 'My Reports')],
        ),
      ),
      body: TabBarView(children: [
        _buildForm(),
        _buildHistory(),
      ]),
    ));
  }

  Widget _buildForm() {
    final yield_ = double.tryParse(_actualYieldCtl.text) ?? 0;
    final sold = double.tryParse(_soldCtl.text) ?? 0;
    final unsold = double.tryParse(_unsoldCtl.text) ?? 0;
    final mar = yield_ > 0 ? sold / yield_ : 0.0;
    final iur = yield_ > 0 ? unsold / yield_ : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _infoCard('Report actual harvest outcomes so the system can compute MAR and IUR for your crops. BAW will verify your submission.'),
        const SizedBox(height: 12),

        _sectionCard('Crop & Location', Icons.grass_rounded, [
          _dropdown<HvcCrop>('Crop', _selectedCrop, kHvcMasterList,
            (c) => c.displayName, (v) => setState(() => _selectedCrop = v)),
          const SizedBox(height: 10),
          _dropdown<String>('Barangay', _selectedBarangay, kTubunganBarangays,
            (b) => b, (v) => setState(() => _selectedBarangay = v)),
        ]),
        const SizedBox(height: 12),

        _sectionCard('Harvest Data', Icons.inventory_2_rounded, [
          _label('ACTUAL YIELD (kg)'),
          const SizedBox(height: 6),
          TextFormField(controller: _actualYieldCtl, keyboardType: TextInputType.number,
            decoration: _deco('e.g. 350'),
            onChanged: (_) => _onSoldChanged(_soldCtl.text)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('QUANTITY SOLD (kg)'),
              const SizedBox(height: 6),
              TextFormField(controller: _soldCtl, keyboardType: TextInputType.number,
                decoration: _deco('kg sold'), onChanged: _onSoldChanged),
            ])),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('QUANTITY UNSOLD (kg)'),
              const SizedBox(height: 6),
              TextFormField(controller: _unsoldCtl, keyboardType: TextInputType.number,
                decoration: _deco('auto-computed')),
            ])),
          ]),
          const SizedBox(height: 10),
          _label('PRICE RECEIVED (₱/kg)'),
          const SizedBox(height: 6),
          TextFormField(controller: _priceCtl, keyboardType: TextInputType.number,
            decoration: _deco('e.g. 28.00'),
            onChanged: (_) => setState(() {})),
          const SizedBox(height: 10),
          _label('DISPOSAL METHOD FOR UNSOLD'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _disposalMethod,
            decoration: _deco(''),
            items: _disposalOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: (v) => setState(() => _disposalMethod = v!),
          ),
        ]),
        const SizedBox(height: 12),

        // Live indicator preview
        if (yield_ > 0) _indicatorPreview(mar, iur),
        const SizedBox(height: 12),

        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: const Icon(Icons.upload_rounded, size: 18),
          label: _submitting
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Submit Harvest Report', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kGreen, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        )),
      ]),
    );
  }

  Widget _indicatorPreview(double mar, double iur) {
    final marColor = mar >= 0.85 ? const Color(0xFF16A34A) : mar >= 0.70 ? const Color(0xFFF59E0B) : const Color(0xFFDC2626);
    final iurColor = iur < 0.15 ? const Color(0xFF16A34A) : iur <= 0.30 ? const Color(0xFFF59E0B) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Live Indicator Preview', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(children: [
          _indicatorTile('MAR', '${(mar * 100).toStringAsFixed(1)}%', marColor, 'Market Absorption'),
          const SizedBox(width: 10),
          _indicatorTile('IUR', '${(iur * 100).toStringAsFixed(1)}%', iurColor, 'Unsold Ratio'),
        ]),
      ]),
    );
  }

  Widget _indicatorTile(String label, String value, Color color, String sub) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withAlpha(60))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
      ]),
    ));
  }

  Widget _buildHistory() {
    if (_myReports.isEmpty) {
      return const Center(child: Text('No harvest reports yet.', style: TextStyle(color: Color(0xFF6B7280))));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _myReports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = _myReports[i];
        final marColor = r.mar >= 0.85 ? const Color(0xFF16A34A) : r.mar >= 0.70 ? const Color(0xFFF59E0B) : const Color(0xFFDC2626);
        final iurColor = r.iur < 0.15 ? const Color(0xFF16A34A) : r.iur <= 0.30 ? const Color(0xFFF59E0B) : const Color(0xFFDC2626);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.cropName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('${r.actualYieldKg.toStringAsFixed(0)} kg total · ₱${r.priceReceivedPerKg.toStringAsFixed(2)}/kg',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            Row(children: [
              _pill('MAR ${(r.mar * 100).toStringAsFixed(0)}%', marColor),
              const SizedBox(width: 8),
              _pill('IUR ${(r.iur * 100).toStringAsFixed(0)}%', iurColor),
              const SizedBox(width: 8),
              _pill(r.disposalMethod ?? '', const Color(0xFF6B7280)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );

  Widget _sectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: _kGreen, size: 16),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const Divider(height: 16),
        ...children,
      ]),
    );
  }

  Widget _dropdown<T>(String label, T? value, List<T> items, String Function(T) display, ValueChanged<T?> onChanged) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: _deco(''),
      hint: Text('Select $label', style: const TextStyle(color: Color(0xFF9CA3AF))),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(display(i), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _infoCard(String msg) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBFDBFE))),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF)))),
    ]),
  );

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151), letterSpacing: 0.4));

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint.isEmpty ? null : hint,
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kGreen, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    filled: true, fillColor: const Color(0xFFFAFAFA),
  );
}
