import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/hvc_master_list.dart';
import '../../data/tubungan_barangays.dart';
import '../../data/agrisat_real_data.dart';
import '../../data/financial_model_assumptions.dart';
import '../../services/crop_declaration_service.dart';
import '../../services/agri_forecast_engine.dart';

final _phpFmt = NumberFormat('#,##0', 'en_PH');
final _phpFmtD = NumberFormat('#,##0.00', 'en_PH');

const _kGreen = Color(0xFF1B7737);
const _kGreenLight = Color(0xFFE7F1E8);

// ── Crop Intelligence data model ──────────────────────────────────────────────

class _CropInsight {
  final String status;       // 'oversupplied' | 'moderate' | 'high_demand'
  final int supplyPct;       // % of demand that is covered by current declarations
  final int farmersCount;
  final int declaredKg;
  final double forecastPrice;
  final String priceDir;     // 'up' | 'down' | 'stable'
  final List<String> alts;   // recommended alternative crops
  final String? congestion;  // harvest congestion warning (null = no warning)
  // Real-data fields (AgriSat verified 2025 dataset)
  final bool isReal;         // true = verified field data; false = demo placeholder
  final double? ppi;         // Price Performance Index (Jul–Dec 2025 baseline)
  final String? alertLabel;  // 'SEVERE' | 'SATURATION' | 'CAUTION' | 'STABLE' | 'HIGH_DEMAND'
  const _CropInsight({
    required this.status, required this.supplyPct,
    required this.farmersCount, required this.declaredKg,
    required this.forecastPrice, required this.priceDir,
    this.alts = const [], this.congestion,
    this.isReal = false, this.ppi, this.alertLabel,
  });
  Color get color {
    if (status == 'oversupplied') return const Color(0xFFDC2626);
    if (status == 'moderate') return const Color(0xFFF59E0B);
    return const Color(0xFF1B7737);
  }
  Color get bgColor {
    if (status == 'oversupplied') return const Color(0xFFFEF2F2);
    if (status == 'moderate') return const Color(0xFFFFFBEB);
    return const Color(0xFFF0FDF4);
  }
  String get emoji {
    if (status == 'oversupplied') return '🔴';
    if (status == 'moderate') return '🟡';
    return '🟢';
  }
  String get label {
    if (status == 'oversupplied') return 'Oversupply Risk';
    if (status == 'moderate') return 'Moderate Supply';
    return 'High Demand';
  }
}

// 🟢 = Verified 2025 field data (annual production, weekly retail prices, PPI computed from baselines)
// ⚪ = Demo data for crops not in the AgriSat real dataset

const _kCropInsightData = <String, _CropInsight>{
  // ── VERIFIED FIELD DATA: 5 pakbet crops from AgriSat 2025 monitoring ──────
  // Source: lib/data/agrisat_real_data.dart (kAnnualTotals, kPpiResults, kHarvestData)

  // Squash: SEVERE. PPI -34%, price ₱33/kg (vs ₱50 baseline). 97.30 MT/yr. 1,585 farmers.
  // Aug-Dec saturation window confirmed. 64% price collapse.
  'Squash': _CropInsight(
    status: 'oversupplied', supplyPct: 95, farmersCount: 1585,
    declaredKg: 97300, forecastPrice: 33.0, priceDir: 'down', isReal: true,
    ppi: -34.0, alertLabel: 'SEVERE',
    alts: ['Eggplant', 'Okra', 'Ampalaya'],
    congestion: 'CRITICAL — Aug–Dec saturation confirmed. Production sustained 17.50 MT/month while prices dropped 64% (₱70→₱25/kg).',
  ),

  // String Beans: WARNING. PPI +7.8% currently but 11x production spike in Aug.
  // 49.58 MT/yr. 1,255 farmers.
  'String Beans': _CropInsight(
    status: 'moderate', supplyPct: 72, farmersCount: 1255,
    declaredKg: 49580, forecastPrice: 110.0, priceDir: 'down', isReal: true,
    ppi: 7.8, alertLabel: 'STABLE',
    alts: ['Eggplant', 'Okra'],
    congestion: 'WARNING — August production spikes 11x (1.25→13.75 MT). Stagger planting to avoid Aug–Nov harvest pileup.',
  ),

  // Ampalaya: CAUTION. PPI +6.4% but volatile (worst week -46.8%). 52.50 MT/yr.
  'Ampalaya': _CropInsight(
    status: 'moderate', supplyPct: 58, farmersCount: 1425,
    declaredKg: 52500, forecastPrice: 100.0, priceDir: 'stable', isReal: true,
    ppi: 6.4, alertLabel: 'CAUTION',
    alts: ['Eggplant', 'Okra'],
    congestion: 'November peak: 9.00 MT. Single-week ₱50/kg dip (−46.8% PPI) shows market vulnerability.',
  ),

  // Eggplant: OPPORTUNITY. PPI +27.9%, price ₱110/kg. 86.93 MT/yr. 1,725 farmers.
  'Eggplant': _CropInsight(
    status: 'high_demand', supplyPct: 35, farmersCount: 1725,
    declaredKg: 86930, forecastPrice: 110.0, priceDir: 'up', isReal: true,
    ppi: 27.9, alertLabel: 'HIGH_DEMAND',
  ),

  // Okra: OPPORTUNITY. PPI +28.3%, price ₱145/kg. 29.90 MT/yr. 1,350 farmers.
  'Okra': _CropInsight(
    status: 'high_demand', supplyPct: 28, farmersCount: 1350,
    declaredKg: 29900, forecastPrice: 145.0, priceDir: 'up', isReal: true,
    ppi: 28.3, alertLabel: 'HIGH_DEMAND',
  ),

  // ── DEMO DATA: other crops (estimates, pending field collection) ──────────
  'Tomato': _CropInsight(
    status: 'oversupplied', supplyPct: 92, farmersCount: 58,
    declaredKg: 42000, forecastPrice: 15.0, priceDir: 'down',
    alts: ['Onion', 'Eggplant', 'Ampalaya'],
    congestion: 'September 2026 — excess tomato harvest expected. High price crash risk.',
  ),
  'Pechay': _CropInsight(
    status: 'oversupplied', supplyPct: 78, farmersCount: 42,
    declaredKg: 28000, forecastPrice: 12.0, priceDir: 'down',
    alts: ['Eggplant', 'Okra', 'Ampalaya'],
  ),
  'Cabbage': _CropInsight(
    status: 'moderate', supplyPct: 58, farmersCount: 35,
    declaredKg: 21000, forecastPrice: 22.0, priceDir: 'stable',
    alts: ['Ampalaya', 'Squash', 'Pepper'],
    congestion: 'August 2026 — moderate harvest overlap expected in Agboy-o area.',
  ),
  'Onion': _CropInsight(
    status: 'high_demand', supplyPct: 23, farmersCount: 8,
    declaredKg: 3500, forecastPrice: 95.0, priceDir: 'up',
  ),
  'Pepper': _CropInsight(
    status: 'moderate', supplyPct: 48, farmersCount: 19,
    declaredKg: 14000, forecastPrice: 45.0, priceDir: 'up',
  ),
  'Corn': _CropInsight(
    status: 'high_demand', supplyPct: 40, farmersCount: 12,
    declaredKg: 8000, forecastPrice: 18.0, priceDir: 'up',
  ),
  'Banana': _CropInsight(
    status: 'moderate', supplyPct: 55, farmersCount: 28,
    declaredKg: 32000, forecastPrice: 25.0, priceDir: 'stable',
    alts: ['Papaya', 'Ginger'],
  ),
  'Mango': _CropInsight(
    status: 'high_demand', supplyPct: 30, farmersCount: 16,
    declaredKg: 12000, forecastPrice: 55.0, priceDir: 'up',
  ),
};

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
  bool _insightsExpanded = false;
  int _tab = 0;
  List<CropDeclaration> _myDeclarations = [];

  final _svc = CropDeclarationService();

  @override
  void initState() {
    super.initState();
    _loadMyDeclarations();
    _prefillFromProfile();
  }

  Future<void> _prefillFromProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    // 1. Try user metadata (fastest — set when profile is saved)
    final meta = user.userMetadata ?? {};
    final brgyFromMeta = meta['barangay'] as String?;
    if (brgyFromMeta != null && brgyFromMeta.isNotEmpty) {
      if (mounted) setState(() => _selectedBarangay = brgyFromMeta);
      return;
    }
    // 2. Fall back to agrisense_farmer_profiles table
    try {
      final res = await Supabase.instance.client
          .from('agrisense_farmer_profiles')
          .select('barangay')
          .eq('user_id', user.id)
          .maybeSingle();
      if (mounted && res != null && (res['barangay'] as String?)?.isNotEmpty == true) {
        setState(() => _selectedBarangay = res['barangay'] as String);
        return;
      }
    } catch (_) {}
    // 3. Fall back to profiles.address (barangay is stored there as "Brgy, Tubungan, Iloilo")
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('address')
          .eq('id', user.id)
          .maybeSingle();
      if (mounted && res != null) {
        final addr = (res['address'] as String?) ?? '';
        // Extract barangay from "Barangay, Tubungan, Iloilo" format
        final parts = addr.split(',');
        if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
          setState(() => _selectedBarangay = parts[0].trim());
        }
      }
    } catch (_) {}
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
    return LayoutBuilder(builder: (ctx, box) {
      final wide = box.maxWidth >= 800;
      if (wide) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 7, child: _buildFormScrollable()),
          Container(width: 1, color: const Color(0xFFE5E7EB)),
          Expanded(flex: 3, child: _buildInsightsSidebar()),
        ]);
      }
      return _buildFormScrollable(showAccordion: true);
    });
  }

  Widget _buildFormScrollable({bool showAccordion = false}) {
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
            const SizedBox(height: 8),
            _buildInlineCropStatus(_selectedCrop!.nameEnglish),
          ],
        ]),
        const SizedBox(height: 12),
        if (showAccordion && _selectedCrop != null) ...[
          _buildMobileInsightsAccordion(),
          const SizedBox(height: 12),
        ],

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

  // ── Smart Crop Insights panel (wide: sidebar | mobile: accordion) ─────────

  Widget _buildInsightsSidebar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.tips_and_updates_rounded, color: Color(0xFF2563EB), size: 16),
          SizedBox(width: 6),
          Text('Smart Crop Insights',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        ]),
        const SizedBox(height: 3),
        const Text('Live market intelligence for your selection',
            style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
        const SizedBox(height: 14),
        _selectedCrop == null
            ? _buildInsightsPlaceholder()
            : _buildInsightsContent(_selectedCrop!.nameEnglish),
        // ── FR02: Financial Forecast Preview ────────────────────────────────
        if (_selectedCrop != null) ...[
          const SizedBox(height: 14),
          _buildFinancialPreview(),
        ],
      ]),
    );
  }

  Widget _buildInsightsPlaceholder() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
    child: const Column(children: [
      Icon(Icons.search_rounded, color: Color(0xFFCBD5E1), size: 40),
      SizedBox(height: 12),
      Text('Select a crop to see market intelligence',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
      SizedBox(height: 6),
      Text('Supply levels, price forecasts, and recommendations will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10.5, color: Color(0xFFB0BEC5), height: 1.4)),
    ]),
  );

  Widget _buildInsightsContent(String cropName) {
    final insight = _kCropInsightData[cropName];
    if (insight == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
        child: const Text('No market data available for this crop yet.',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Status + supply meter card
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: insight.bgColor, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: insight.color.withAlpha(80))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${insight.emoji} ${insight.label}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: insight.color)),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Supply Level', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
            const Spacer(),
            Text('${insight.supplyPct}% of demand',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: insight.color)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: insight.supplyPct / 100,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(insight.color), minHeight: 8)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _statTile(Icons.people_rounded, '${insight.farmersCount}', 'Farmers')),
            const SizedBox(width: 6),
            Expanded(child: _statTile(Icons.inventory_2_rounded,
                NumberFormat('#,##0', 'en_PH').format(insight.declaredKg), 'kg declared')),
          ]),
        ]),
      ),
      const SizedBox(height: 10),
      // Price forecast
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Row(children: [
          const Icon(Icons.price_change_rounded, color: Color(0xFF64748B), size: 16),
          const SizedBox(width: 8),
          const Text('Forecast Price', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('₱${insight.forecastPrice.toStringAsFixed(0)}/kg',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(width: 4),
          Icon(
            insight.priceDir == 'up' ? Icons.arrow_upward_rounded
                : insight.priceDir == 'down' ? Icons.arrow_downward_rounded
                : Icons.remove_rounded,
            size: 14,
            color: insight.priceDir == 'up' ? const Color(0xFF1B7737)
                : insight.priceDir == 'down' ? const Color(0xFFDC2626)
                : const Color(0xFF6B7280),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      // Harvest congestion warning (only when risk exists)
      if (insight.congestion != null) ...[
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCD34D))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 16),
            const SizedBox(width: 6),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Harvest Congestion Expected',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
              const SizedBox(height: 2),
              Text(insight.congestion!,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF92400E), height: 1.4)),
            ])),
          ]),
        ),
        const SizedBox(height: 10),
      ],
      // Clickable alternative crops
      if (insight.alts.isNotEmpty) ...[
        const Text('Recommended Alternatives',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF374151))),
        const SizedBox(height: 3),
        const Text('Tap to auto-select',
            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: insight.alts.map((alt) {
          final altInsight = _kCropInsightData[alt];
          final altColor = altInsight?.color ?? const Color(0xFF1B7737);
          return InkWell(
            onTap: () => _selectAlternative(alt),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: altColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: altColor.withAlpha(60))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(altInsight?.emoji ?? '🟢', style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Text(alt, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: altColor)),
              ]),
            ),
          );
        }).toList()),
      ],
    ]);
  }

  Widget _statTile(IconData icon, String value, String label) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: Colors.white.withAlpha(150), borderRadius: BorderRadius.circular(6)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 12, color: const Color(0xFF6B7280)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
      Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF6B7280))),
    ]),
  );

  Widget _buildMobileInsightsAccordion() => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(children: [
      InkWell(
        onTap: () => setState(() => _insightsExpanded = !_insightsExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withAlpha(20),
                borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF2563EB), size: 15)),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Smart Crop Insights',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            Text('Tap to see market intelligence',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF6B7280))),
          ])),
          Icon(_insightsExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: const Color(0xFF6B7280), size: 20),
        ])),
      ),
      if (_insightsExpanded) Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: _buildInsightsContent(_selectedCrop?.nameEnglish ?? ''),
      ),
    ]),
  );

  // ── FR02: Farmer Financial Preview ───────────────────────────────────────────
  // Shows projected EGP, NSQ, Forecasted Price, NFI, ROI before submission
  Widget _buildFinancialPreview() {
    final cropKey = kCropNameToKey[_selectedCrop!.nameEnglish];
    if (cropKey == null) return const SizedBox.shrink();

    final areaHa = double.tryParse(_areaController.text) ?? 1.0;
    final monthlyDemand = kMonthlyDemand[cropKey] ?? 50000.0;
    final forecast = AgriForecastEngine.computeFarmerForecast(
      cropKey: cropKey,
      farmSizeHa: areaHa,
      municipalSupplyKg: monthlyDemand, // use demand as proxy supply for new declaration
    );

    final nfiPositive = forecast.nfi >= 0;
    final msiColor = Color(forecast.msiStatus.colorValue);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          const Icon(Icons.calculate_rounded, color: Color(0xFF16A34A), size: 15),
          const SizedBox(width: 6),
          const Expanded(child: Text('Financial Forecast',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF166534)))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
            child: const Text('PRE-PLANTING', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
          ),
        ]),
        const SizedBox(height: 2),
        Text('${areaHa.toStringAsFixed(1)} ha · ${_selectedCrop!.nameEnglish}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF4B5563))),
        const Divider(height: 14, color: Color(0xFFBBF7D0)),

        // Production section
        _fRow('Expected Production (EGP)', '${_phpFmt.format(forecast.egpKg)} kg', const Color(0xFF374151)),
        _fRow('(−) Pre-Harvest Loss', '${_phpFmt.format(forecast.preHarvestLossKg)} kg', const Color(0xFFDC2626)),
        _fRow('(−) Post-Harvest Loss', '${_phpFmt.format(forecast.postHarvestLossKg)} kg', const Color(0xFFDC2626)),
        _fRowBold('Net Sellable Qty (NSQ)', '${_phpFmt.format(forecast.nsqKg)} kg', const Color(0xFF1B7737)),
        const Divider(height: 12, color: Color(0xFFBBF7D0)),

        // Revenue section
        _fRow('Forecasted Price', '₱${_phpFmtD.format(forecast.forecastedPrice)}/kg', const Color(0xFF374151)),
        _fRowBold('Gross Revenue', '₱${_phpFmt.format(forecast.grossRevenue)}', const Color(0xFF1B7737)),
        const Divider(height: 12, color: Color(0xFFBBF7D0)),

        // Cost section
        _fRow('Est. Production Cost', '₱${_phpFmt.format(forecast.totalProductionCost)}', const Color(0xFFDC2626)),
        _fRow('Cost per kg', '₱${_phpFmtD.format(forecast.costPerKg)}/kg', const Color(0xFF6B7280)),
        _fRow('Loss Value', '₱${_phpFmt.format(forecast.lossValue)}', const Color(0xFFF59E0B)),
        const Divider(height: 12, color: Color(0xFFBBF7D0)),

        // NFI + ROI — highlighted
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: nfiPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(children: [
            Row(children: [
              const Expanded(child: Text('NET FARM INCOME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF111827)))),
              Text('₱${_phpFmt.format(forecast.nfi)}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                      color: nfiPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Expanded(child: Text('ROI', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)))),
              Text('${forecast.roi.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: nfiPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
            ]),
          ]),
        ),
        const SizedBox(height: 10),

        // MSI warning — FR03
        _buildDiversificationNudge(forecast.msi, forecast.msiStatus, msiColor, cropKey),

        const SizedBox(height: 6),
        const Text('* Based on DA/MAO reference yields and default cost assumptions. '
            'Actual results vary by season, inputs, and market conditions.',
            style: TextStyle(fontSize: 9, color: Color(0xFF9CA3AF), height: 1.4)),
      ]),
    );
  }

  // ── FR03: Diversification Nudge ───────────────────────────────────────────────
  Widget _buildDiversificationNudge(double msi, MsiStatus msiStatus, Color msiColor, String cropKey) {
    final insight = _kCropInsightData[_selectedCrop?.nameEnglish ?? ''];
    final alts = insight?.alts ?? [];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // MSI bar
      Row(children: [
        const Text('Market Saturation Index:', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: msiColor.withAlpha(25), borderRadius: BorderRadius.circular(4)),
          child: Text(msi.toStringAsFixed(2),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: msiColor)),
        ),
        const SizedBox(width: 6),
        Text(msiStatus.label, style: TextStyle(fontSize: 9.5, color: msiColor, fontWeight: FontWeight.w600)),
      ]),
      // Nudge warning if saturated
      if (msi > 1.10) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: msi > 1.30 ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: msiColor.withAlpha(80)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(msi > 1.30 ? Icons.warning_rounded : Icons.info_rounded, size: 13, color: msiColor),
              const SizedBox(width: 4),
              Expanded(child: Text(
                msi > 1.30
                  ? 'CRITICAL: This crop is oversupplied. Price collapse risk is HIGH.'
                  : 'WARNING: Moderate oversupply risk for this crop.',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: msiColor, height: 1.3),
              )),
            ]),
            if (alts.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text('Consider these lower-saturation alternatives:',
                  style: TextStyle(fontSize: 9.5, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              Wrap(spacing: 4, runSpacing: 4, children: alts.map((alt) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFE7F1E8), borderRadius: BorderRadius.circular(4)),
                child: Text(alt, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF1B7737))),
              )).toList()),
            ],
          ]),
        ),
      ],
    ]);
  }

  Widget _fRow(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)))),
      Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    ]),
  );

  Widget _fRowBold(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151)))),
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    ]),
  );

  Widget _buildInlineCropStatus(String cropName) {
    final insight = _kCropInsightData[cropName];
    if (insight == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: insight.bgColor, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: insight.color.withAlpha(60))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${insight.emoji} ${insight.label}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: insight.color)),
          if (insight.isReal) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: const Color(0xFF1B7737),
                  borderRadius: BorderRadius.circular(3)),
              child: const Text('VERIFIED',
                  style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
            ),
          ],
          const Spacer(),
          Text(
            '₱${insight.forecastPrice.toStringAsFixed(0)}/kg '
            '${insight.priceDir == 'up' ? '↑' : insight.priceDir == 'down' ? '↓' : '→'}',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: insight.priceDir == 'up' ? const Color(0xFF1B7737)
                  : insight.priceDir == 'down' ? const Color(0xFFDC2626)
                  : const Color(0xFF6B7280)),
          ),
        ]),
        if (insight.ppi != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Text('PPI', style: TextStyle(fontSize: 9.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Text(
              '${insight.ppi! >= 0 ? '+' : ''}${insight.ppi!.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: insight.color),
            ),
            const SizedBox(width: 6),
            Text('vs ₱${kPriceBaselines[AgriSatData.cropKeyFromName(cropName) ?? ''] ?? 0}/kg baseline',
                style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
          ]),
        ],
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: insight.supplyPct / 100,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(insight.color), minHeight: 6))),
          const SizedBox(width: 8),
          Text('${insight.supplyPct}%',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: insight.color)),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 6, children: [
          _infoChip('👨‍🌾 ${insight.farmersCount} Farmers'),
          _infoChip('📦 ${NumberFormat('#,##0', 'en_PH').format(insight.declaredKg)} kg declared'),
        ]),
      ]),
    );
  }

  Widget _infoChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
  );

  void _selectAlternative(String cropName) {
    HvcCrop? found;
    try {
      found = kHvcMasterList.firstWhere(
          (c) => c.nameEnglish.toLowerCase() == cropName.toLowerCase());
    } catch (_) {}
    if (found != null) {
      setState(() => _selectedCrop = found);
      _recalcHarvestDate();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Switched to $cropName — recommended for this season'),
        backgroundColor: const Color(0xFF1B7737),
        duration: const Duration(seconds: 2)));
    }
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
