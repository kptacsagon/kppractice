// ─────────────────────────────────────────────────────────────────────────────
// Crop Cycle Financial Journal — Farmer 6-stage wizard
//
// Stages: Pre-Planting → Planting → Maintenance → Harvest → Post-Harvest → Sales
// Pipeline: Farmer submits → BAW verifies (checklist) → MAO consumes analytics
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/agri_financial_input_service.dart';
import '../../data/tubungan_barangays.dart';

const _kGreen = Color(0xFF1B7737);
const _kGreenDark = Color(0xFF154D26);
const _kBg = Color(0xFFF3F4F6);
const _kCard = Colors.white;
const _kBorder = Color(0xFFD1D5DB);
const _kMuted = Color(0xFF6B7280);
const _kText = Color(0xFF111827);
const _kRed = Color(0xFFDC2626);

const _kStages = [
  ('Pre-Planting',  Icons.grass_rounded),
  ('Planting',      Icons.spa_rounded),
  ('Maintenance',   Icons.healing_rounded),
  ('Harvest',       Icons.agriculture_rounded),
  ('Post-Harvest',  Icons.warehouse_rounded),
  ('Sales',         Icons.storefront_rounded),
];

class AgriFinancialInputScreen extends StatefulWidget {
  const AgriFinancialInputScreen({super.key});
  @override
  State<AgriFinancialInputScreen> createState() => _AgriFinancialInputScreenState();
}

class _AgriFinancialInputScreenState extends State<AgriFinancialInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _svc = AgriFinancialInputService();
  int _stage = 0;
  bool _submitting = false;
  bool _submitted = false;

  // ── Crop metadata (header) ─────────────────────────────────────────────────
  String _cropType = 'Palay';
  final _varietyCtl = TextEditingController();
  final _areaCtl = TextEditingController();
  String? _barangay;
  DateTime? _plantingDate;
  DateTime? _harvestDate;

  // ── Stage 1: Pre-Planting ──────────────────────────────────────────────────
  final _landPrepCtl = TextEditingController();
  final _soilPrepCtl = TextEditingController();
  String _seedSource = 'certified';
  final _seedQtyCtl = TextEditingController();
  final _seedCostCtl = TextEditingController();

  // ── Stage 2: Planting ──────────────────────────────────────────────────────
  final _laborPlantCtl = TextEditingController();
  final _fertBasalCtl = TextEditingController();
  final _irrigCtl = TextEditingController();
  final _pestPlantingCtl = TextEditingController();

  // ── Stage 3: Maintenance ───────────────────────────────────────────────────
  final _laborWeedCtl = TextEditingController();
  final _sprayingCtl = TextEditingController();
  final _fertTopCtl = TextEditingController();
  final _pestIncidentsCtl = TextEditingController();

  // ── Stage 4: Harvest ───────────────────────────────────────────────────────
  final _laborHarvestCtl = TextEditingController();
  final _grossHarvestCtl = TextEditingController();
  final _marketableCtl = TextEditingController();
  final _damagedCtl = TextEditingController();
  final _rejectedCtl = TextEditingController();

  // ── Stage 5: Post-Harvest ──────────────────────────────────────────────────
  final _storageLossCtl = TextEditingController();
  final _unsoldCtl = TextEditingController();
  final _transportCtl = TextEditingController();
  final _packagingCtl = TextEditingController();

  // ── Stage 6: Sales ─────────────────────────────────────────────────────────
  final _priceCtl = TextEditingController();
  String _buyerType = 'trader';
  final _qtySoldCtl = TextEditingController();

  // ── Overhead ───────────────────────────────────────────────────────────────
  final _landRentalCtl = TextEditingController();
  final _equipCtl = TextEditingController();

  static const _crops = [
    'Palay', 'Corn', 'Ampalaya', 'Eggplant', 'Tomato',
    'Cabbage', 'Pepper', 'Squash', 'Banana', 'Mango', 'Other',
  ];
  static const _avgHarvestDays = {
    'Palay': 120, 'Corn': 95, 'Ampalaya': 65, 'Eggplant': 75,
    'Tomato': 70, 'Cabbage': 80, 'Pepper': 90, 'Squash': 60,
    'Banana': 300, 'Mango': 120, 'Other': 90,
  };
  static const _seedSources = [
    ('certified', 'Certified Seed'),
    ('saved', 'Farmer-Saved Seed'),
    ('cooperative', 'Cooperative-Distributed'),
    ('other', 'Other Source'),
  ];
  static const _buyerTypes = [
    ('trader', 'Trader / Middleman'),
    ('cooperative', 'Cooperative'),
    ('institutional', 'Institutional Buyer'),
    ('market', 'Public Market'),
    ('direct', 'Direct Consumer'),
  ];

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata ?? {};
    _barangay = meta['barangay'] as String?;
  }

  @override
  void dispose() {
    for (final c in [
      _varietyCtl, _areaCtl, _landPrepCtl, _soilPrepCtl, _seedQtyCtl, _seedCostCtl,
      _laborPlantCtl, _fertBasalCtl, _irrigCtl, _pestPlantingCtl,
      _laborWeedCtl, _sprayingCtl, _fertTopCtl, _pestIncidentsCtl,
      _laborHarvestCtl, _grossHarvestCtl, _marketableCtl, _damagedCtl, _rejectedCtl,
      _storageLossCtl, _unsoldCtl, _transportCtl, _packagingCtl,
      _priceCtl, _qtySoldCtl, _landRentalCtl, _equipCtl,
    ]) { c.dispose(); }
    super.dispose();
  }

  double _d(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;

  void _onCropOrDateChanged() {
    if (_plantingDate != null) {
      final days = _avgHarvestDays[_cropType] ?? 90;
      setState(() => _harvestDate = _plantingDate!.add(Duration(days: days)));
    }
  }

  // ── Live preview computations ──────────────────────────────────────────────

  double get _liveRevenue => _d(_qtySoldCtl) * _d(_priceCtl);
  double get _liveTotalVariableCost =>
      _d(_landPrepCtl) + _d(_soilPrepCtl) + _d(_seedCostCtl) +
      _d(_fertBasalCtl) + _d(_fertTopCtl) +
      _d(_pestPlantingCtl) + _d(_sprayingCtl) +
      _d(_laborPlantCtl) + _d(_laborWeedCtl) + _d(_laborHarvestCtl) +
      _d(_irrigCtl) + _d(_transportCtl) + _d(_packagingCtl);
  double get _liveTotalFixedCost => _d(_landRentalCtl) + _d(_equipCtl);
  double get _liveNfi => _liveRevenue - _liveTotalVariableCost - _liveTotalFixedCost;
  double get _liveBep {
    final marketable = _d(_marketableCtl);
    if (marketable == 0) return 0;
    return (_liveTotalVariableCost + _liveTotalFixedCost) / marketable;
  }

  bool _canAdvance() {
    if (_stage == 0) {
      // Pre-planting requires header + seed cost
      return _areaCtl.text.trim().isNotEmpty
          && _barangay != null
          && _plantingDate != null
          && _seedCostCtl.text.trim().isNotEmpty;
    }
    return true; // Other stages all have optional fields
  }

  Future<void> _next() async {
    if (_stage < _kStages.length - 1) {
      // Validate header on stage 0 first
      if (_stage == 0 && !_formKey.currentState!.validate()) return;
      setState(() => _stage++);
    } else {
      await _submit();
    }
  }

  void _back() {
    if (_stage > 0) setState(() => _stage--);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _stage = 0);
      return;
    }
    if (_plantingDate == null || _harvestDate == null) return;
    setState(() => _submitting = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');
      final meta = user.userMetadata ?? {};
      final record = FinancialInputRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        farmerId: user.id,
        farmerName: (meta['full_name'] as String?) ?? user.email ?? '',
        barangay: _barangay ?? '',
        status: FinInputStatus.pendingBaw,
        submittedAt: DateTime.now(),
        cropType: _cropType,
        cropVariety: _varietyCtl.text.trim(),
        areaPlantedHa: _d(_areaCtl),
        plantingDate: _plantingDate!,
        expectedHarvestDate: _harvestDate!,
        landPrepCost: _d(_landPrepCtl), soilPrepCost: _d(_soilPrepCtl),
        seedSource: _seedSource,
        seedQtyKg: _d(_seedQtyCtl), seedCostPhp: _d(_seedCostCtl),
        laborPlantingPhp: _d(_laborPlantCtl),
        fertBasalPhp: _d(_fertBasalCtl),
        irrigationPhp: _d(_irrigCtl),
        pesticidePlantingPhp: _d(_pestPlantingCtl),
        laborWeedingPhp: _d(_laborWeedCtl),
        sprayingCostPhp: _d(_sprayingCtl),
        fertTopDressPhp: _d(_fertTopCtl),
        pestIncidents: _pestIncidentsCtl.text.trim(),
        laborHarvestingPhp: _d(_laborHarvestCtl),
        grossHarvestKg: _d(_grossHarvestCtl),
        marketableYieldKg: _d(_marketableCtl),
        damagedYieldKg: _d(_damagedCtl),
        rejectedYieldKg: _d(_rejectedCtl),
        storageLossKg: _d(_storageLossCtl),
        unsoldKg: _d(_unsoldCtl),
        transportPhp: _d(_transportCtl),
        packagingPhp: _d(_packagingCtl),
        sellingPricePhp: _d(_priceCtl),
        buyerType: _buyerType,
        quantitySoldKg: _d(_qtySoldCtl),
        landRentalPhp: _d(_landRentalCtl),
        equipmentDeprecPhp: _d(_equipCtl),
      );
      await _svc.submitInput(record);
      if (!mounted) return;
      setState(() { _submitting = false; _submitted = true; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e'), backgroundColor: _kRed));
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _SuccessView();
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: Column(children: [
        _buildHeader(),
        _buildStageProgress(),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildLivePreview(),
              const SizedBox(height: 12),
              _buildStageContent(),
              const SizedBox(height: 24),
            ]),
          ),
        )),
        _buildBottomBar(),
      ])),
    );
  }

  Widget _buildHeader() => Container(
    color: _kCard,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: const Icon(Icons.arrow_back_rounded, size: 22, color: _kText),
      ),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: _kGreen.withAlpha(20), borderRadius: BorderRadius.circular(6)),
        child: const Icon(Icons.menu_book_rounded, color: _kGreen, size: 18),
      ),
      const SizedBox(width: 10),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Crop Cycle Journal',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kText)),
        Text('Record your full cycle for BAW verification',
            style: TextStyle(fontSize: 11, color: _kMuted)),
      ])),
    ]),
  );

  Widget _buildStageProgress() => Container(
    color: _kCard,
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
    child: Column(children: [
      Row(children: List.generate(_kStages.length * 2 - 1, (i) {
        if (i.isOdd) {
          final connector = (i - 1) ~/ 2;
          final active = _stage > connector;
          return Expanded(child: Container(
            height: 2,
            color: active ? _kGreen : const Color(0xFFE5E7EB),
          ));
        }
        final stageIdx = i ~/ 2;
        final isCurrent = stageIdx == _stage;
        final isComplete = stageIdx < _stage;
        final color = isCurrent ? _kGreen : isComplete ? _kGreen : const Color(0xFFE5E7EB);
        final textColor = (isCurrent || isComplete) ? Colors.white : _kMuted;
        return Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(color: _kGreenDark, width: 2.5)
                : null),
          alignment: Alignment.center,
          child: isComplete
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
              : Text('${stageIdx + 1}', style: TextStyle(
                  color: textColor, fontSize: 11, fontWeight: FontWeight.w800)),
        );
      })),
      const SizedBox(height: 8),
      Row(children: [
        Icon(_kStages[_stage].$2, color: _kGreen, size: 14),
        const SizedBox(width: 6),
        Text('Stage ${_stage + 1} of ${_kStages.length}: ${_kStages[_stage].$1}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _kGreenDark)),
      ]),
    ]),
  );

  Widget _buildLivePreview() {
    final nfi = _liveNfi;
    final bep = _liveBep;
    final revenue = _liveRevenue;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_kGreenDark, _kGreen]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.auto_graph_rounded, color: Colors.white, size: 12),
          SizedBox(width: 5),
          Text('Live Cycle Snapshot', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _previewKpi('Revenue', revenue, isCurrency: true),
          const SizedBox(width: 8),
          _previewKpi('NFI', nfi, isCurrency: true),
          const SizedBox(width: 8),
          _previewKpi('Break-Even',
              bep, isCurrency: true, suffix: '/kg'),
        ]),
      ]),
    );
  }

  Widget _previewKpi(String label, double value, {bool isCurrency = false, String? suffix}) {
    final fmt = NumberFormat('#,##0', 'en_PH');
    final s = value == 0 ? '—'
      : isCurrency ? 'PHP ${fmt.format(value)}${suffix ?? ''}' : value.toStringAsFixed(2);
    return Expanded(child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(6)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(0xFFB2D9B8), fontSize: 9.5)),
        const SizedBox(height: 2),
        Text(s, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
      ]),
    ));
  }

  Widget _buildStageContent() {
    switch (_stage) {
      case 0: return _stagePrePlanting();
      case 1: return _stagePlanting();
      case 2: return _stageMaintenance();
      case 3: return _stageHarvest();
      case 4: return _stagePostHarvest();
      case 5: return _stageSales();
      default: return const SizedBox.shrink();
    }
  }

  // ── Stage 1: Pre-Planting (required header + seed) ────────────────────────

  Widget _stagePrePlanting() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _stageBanner(
      'Tell us what you are about to plant',
      'Capture crop selection, area, and pre-planting expenses. These set the baseline for your cycle.',
      const Color(0xFFF0FDF4), _kGreen, Icons.grass_rounded),
    _card(
      title: 'Crop Information',
      child: Column(children: [
        Row(children: [
          Expanded(flex: 2, child: _dropdown('Crop Type *', _cropType, _crops, (v) {
            setState(() => _cropType = v!);
            _onCropOrDateChanged();
          })),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: _field('Variety (e.g. NSIC Rc 222)', _varietyCtl)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _field('Area Planted (ha) *', _areaCtl,
              required: true, type: TextInputType.number, hint: 'e.g. 1.25')),
          const SizedBox(width: 10),
          Expanded(child: _barangayDropdown()),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _datePicker('Planting Date *', _plantingDate, (d) {
            setState(() => _plantingDate = d);
            _onCropOrDateChanged();
          })),
          const SizedBox(width: 10),
          Expanded(child: _autoHarvestDateField()),
        ]),
      ]),
    ),
    _card(
      title: 'Land Preparation',
      subtitle: 'Land clearing, plowing, soil treatment costs',
      child: Row(children: [
        Expanded(child: _field('Land Prep Cost (PHP)', _landPrepCtl,
            type: TextInputType.number, hint: 'Plowing, leveling')),
        const SizedBox(width: 10),
        Expanded(child: _field('Soil Treatment (PHP)', _soilPrepCtl,
            type: TextInputType.number, hint: 'Amendments, lime')),
      ]),
    ),
    _card(
      title: 'Seeds & Planting Material',
      subtitle: 'Source affects MAO seed-subsidy eligibility',
      child: Column(children: [
        _dropdown('Seed Source', _seedSource,
            _seedSources.map((e) => e.$1).toList(),
            (v) => setState(() => _seedSource = v!),
            labelMapper: (v) => _seedSources.firstWhere((e) => e.$1 == v).$2),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _field('Seed Quantity (kg)', _seedQtyCtl,
              type: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: _field('Seed Cost (PHP) *', _seedCostCtl,
              required: true, type: TextInputType.number)),
        ]),
      ]),
    ),
    _card(
      title: 'Overhead (Optional)',
      subtitle: 'Land rental and equipment depreciation for this cycle',
      child: Row(children: [
        Expanded(child: _field('Land Rental (PHP)', _landRentalCtl,
            type: TextInputType.number, hint: 'Skip if owner-cultivator')),
        const SizedBox(width: 10),
        Expanded(child: _field('Equipment Depreciation (PHP)', _equipCtl,
            type: TextInputType.number, hint: 'Pro-rated this cycle')),
      ]),
    ),
  ]);

  // ── Stage 2: Planting ──────────────────────────────────────────────────────

  Widget _stagePlanting() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _stageBanner(
      'Recording planting operations',
      'Capture planting-day labor, basal fertilizer, irrigation hookup, and starter pesticide.',
      const Color(0xFFFEFCE8), const Color(0xFFCA8A04), Icons.spa_rounded),
    _card(
      title: 'Labor',
      child: _field('Planting Labor Cost (PHP)', _laborPlantCtl,
          type: TextInputType.number, hint: 'Hired labor for transplanting / sowing'),
    ),
    _card(
      title: 'Inputs at Planting',
      child: Column(children: [
        Row(children: [
          Expanded(child: _field('Basal Fertilizer (PHP)', _fertBasalCtl,
              type: TextInputType.number, hint: 'Applied at planting')),
          const SizedBox(width: 10),
          Expanded(child: _field('Irrigation Fees (PHP)', _irrigCtl,
              type: TextInputType.number, hint: 'Water district / pump')),
        ]),
        const SizedBox(height: 10),
        _field('Pesticide / Pre-emergence Herbicide (PHP)', _pestPlantingCtl,
            type: TextInputType.number, hint: 'Applied around planting'),
      ]),
    ),
  ]);

  // ── Stage 3: Maintenance ───────────────────────────────────────────────────

  Widget _stageMaintenance() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _stageBanner(
      'Mid-cycle care',
      'Track weeding, additional fertilizer, spraying, and any pest incidents observed.',
      const Color(0xFFFEF3C7), const Color(0xFF92400E), Icons.healing_rounded),
    _card(
      title: 'Labor & Spraying',
      child: Row(children: [
        Expanded(child: _field('Weeding Labor (PHP)', _laborWeedCtl,
            type: TextInputType.number)),
        const SizedBox(width: 10),
        Expanded(child: _field('Spraying Cost (PHP)', _sprayingCtl,
            type: TextInputType.number, hint: 'Pesticide + application')),
      ]),
    ),
    _card(
      title: 'Additional Inputs',
      child: _field('Top-Dress Fertilizer (PHP, Optional)', _fertTopCtl,
          type: TextInputType.number, hint: 'Side-dressing fertilizer applied mid-cycle'),
    ),
    _card(
      title: 'Pest / Disease Incidents',
      subtitle: 'Describe any pest outbreaks or disease symptoms — BAW will verify',
      child: TextFormField(
        controller: _pestIncidentsCtl, maxLines: 3,
        style: const TextStyle(fontSize: 13),
        decoration: _deco('Incident Notes',
            hint: 'e.g. Brown planthopper infestation week 6; sprayed with neem...'),
      ),
    ),
  ]);

  // ── Stage 4: Harvest ───────────────────────────────────────────────────────

  Widget _stageHarvest() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _stageBanner(
      'Recording your harvest',
      'Split your total yield into marketable, damaged, and rejected portions. Critical for loss tracking.',
      const Color(0xFFE7F1E8), _kGreen, Icons.agriculture_rounded),
    _card(
      title: 'Labor',
      child: _field('Harvesting Labor (PHP)', _laborHarvestCtl,
          type: TextInputType.number, hint: 'Hired labor for harvesting'),
    ),
    _card(
      title: 'Yield Breakdown',
      subtitle: 'All quantities in kilograms (kg)',
      child: Column(children: [
        _field('Gross Harvest (kg)', _grossHarvestCtl,
            type: TextInputType.number, hint: 'Total volume harvested'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _field('Marketable Yield', _marketableCtl,
              type: TextInputType.number, hint: 'Sellable quality')),
          const SizedBox(width: 8),
          Expanded(child: _field('Damaged', _damagedCtl,
              type: TextInputType.number, hint: 'Field damage')),
          const SizedBox(width: 8),
          Expanded(child: _field('Rejected', _rejectedCtl,
              type: TextInputType.number, hint: 'Below grade')),
        ]),
        const SizedBox(height: 8),
        _balanceCheck(),
      ]),
    ),
  ]);

  Widget _balanceCheck() {
    final gross = _d(_grossHarvestCtl);
    final sum = _d(_marketableCtl) + _d(_damagedCtl) + _d(_rejectedCtl);
    if (gross == 0) return const SizedBox();
    final diff = gross - sum;
    final balanced = diff.abs() < 1;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: balanced ? const Color(0xFFE7F1E8) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6)),
      child: Row(children: [
        Icon(balanced ? Icons.check_circle_rounded : Icons.warning_rounded,
            size: 14, color: balanced ? _kGreen : const Color(0xFFCA8A04)),
        const SizedBox(width: 6),
        Expanded(child: Text(
          balanced
              ? 'Yield breakdown balances with gross harvest'
              : 'Marketable + Damaged + Rejected = ${sum.toStringAsFixed(0)} kg (off by ${diff.abs().toStringAsFixed(0)} kg)',
          style: TextStyle(fontSize: 11,
              color: balanced ? _kGreenDark : const Color(0xFF92400E)),
        )),
      ]),
    );
  }

  // ── Stage 5: Post-Harvest ──────────────────────────────────────────────────

  Widget _stagePostHarvest() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _stageBanner(
      'After the harvest',
      'Storage losses, transport, packaging, and unsold inventory tracking.',
      const Color(0xFFF5F3FF), const Color(0xFF7C3AED), Icons.warehouse_rounded),
    _card(
      title: 'Storage Losses & Unsold Inventory',
      subtitle: 'In kilograms (kg) — used to compute IUR for MAO oversupply analytics',
      child: Row(children: [
        Expanded(child: _field('Storage Loss (kg)', _storageLossCtl,
            type: TextInputType.number, hint: 'Spoilage, pests, moisture')),
        const SizedBox(width: 10),
        Expanded(child: _field('Unsold (kg)', _unsoldCtl,
            type: TextInputType.number, hint: 'No buyer found')),
      ]),
    ),
    _card(
      title: 'Post-Harvest Costs',
      child: Row(children: [
        Expanded(child: _field('Transport to Market (PHP)', _transportCtl,
            type: TextInputType.number)),
        const SizedBox(width: 10),
        Expanded(child: _field('Packaging (PHP)', _packagingCtl,
            type: TextInputType.number, hint: 'Sacks, crates, labels')),
      ]),
    ),
  ]);

  // ── Stage 6: Sales ─────────────────────────────────────────────────────────

  Widget _stageSales() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _stageBanner(
      'Sales results',
      'Final selling price, buyer relationship, and quantity sold. Locks in your realized revenue.',
      const Color(0xFFFFFBEB), const Color(0xFFCA8A04), Icons.storefront_rounded),
    _card(
      title: 'Selling Information',
      child: Column(children: [
        Row(children: [
          Expanded(child: _field('Selling Price (PHP/kg)', _priceCtl,
              type: TextInputType.number, hint: 'e.g. 21.50')),
          const SizedBox(width: 10),
          Expanded(child: _field('Quantity Sold (kg)', _qtySoldCtl,
              type: TextInputType.number, hint: 'Total actually sold')),
        ]),
        const SizedBox(height: 10),
        _dropdown('Buyer Type', _buyerType,
            _buyerTypes.map((e) => e.$1).toList(),
            (v) => setState(() => _buyerType = v!),
            labelMapper: (v) => _buyerTypes.firstWhere((e) => e.$1 == v).$2),
      ]),
    ),
    _card(
      title: 'Cycle Summary',
      subtitle: 'Review before submitting to BAW',
      child: _summary(),
    ),
  ]);

  Widget _summary() {
    final r = _liveRevenue;
    final cost = _liveTotalVariableCost + _liveTotalFixedCost;
    final nfi = _liveNfi;
    return Column(children: [
      _summaryRow('Crop', '$_cropType (${_varietyCtl.text})'),
      _summaryRow('Area', '${_areaCtl.text} ha · $_barangay'),
      _summaryRow('Gross Harvest', '${_grossHarvestCtl.text} kg'),
      _summaryRow('Marketable Yield', '${_marketableCtl.text} kg'),
      _summaryRow('Quantity Sold', '${_qtySoldCtl.text} kg'),
      _summaryRow('Realized Revenue', 'PHP ${NumberFormat('#,##0', 'en_PH').format(r)}'),
      _summaryRow('Total Cost', 'PHP ${NumberFormat('#,##0', 'en_PH').format(cost)}'),
      const Divider(height: 14),
      _summaryRow('Net Farm Income',
          'PHP ${NumberFormat('#,##0', 'en_PH').format(nfi)}',
          color: nfi >= 0 ? _kGreen : _kRed, bold: true),
    ]);
  }

  Widget _summaryRow(String k, String v, {Color? color, bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(k, style: const TextStyle(fontSize: 11.5, color: _kMuted)),
      Text(v, style: TextStyle(
          fontSize: 11.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: color ?? _kText)),
    ]),
  );

  // ── Bottom action bar ──────────────────────────────────────────────────────

  Widget _buildBottomBar() => Container(
    color: _kCard,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Row(children: [
      if (_stage > 0)
        OutlinedButton.icon(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back_rounded, size: 14, color: _kMuted),
          label: const Text('Back', style: TextStyle(fontSize: 12.5, color: _kText)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _kBorder),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      const SizedBox(width: 10),
      Expanded(child: ElevatedButton.icon(
        onPressed: _submitting ? null : (_canAdvance() ? _next : null),
        icon: _submitting
            ? const SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(_stage == _kStages.length - 1
                ? Icons.send_rounded : Icons.arrow_forward_rounded, size: 15),
        label: Text(_stage == _kStages.length - 1
            ? 'Submit to BAW for Verification' : 'Continue to ${_kStages[_stage + 1].$1}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kGreen, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      )),
    ]),
  );

  // ── Reusable widgets ───────────────────────────────────────────────────────

  Widget _card({required String title, String? subtitle, required Widget child}) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(7), blurRadius: 6, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: EdgeInsets.fromLTRB(14, 12, 14, subtitle == null ? 4 : 0),
        child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kText)),
      ),
      if (subtitle != null) Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        child: Text(subtitle, style: const TextStyle(fontSize: 11, color: _kMuted)),
      ),
      Padding(padding: const EdgeInsets.fromLTRB(14, 6, 14, 14), child: child),
    ]),
  );

  Widget _stageBanner(String title, String desc, Color bg, Color accent, IconData icon) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: accent.withAlpha(70))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: accent, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: accent)),
        const SizedBox(height: 3),
        Text(desc, style: const TextStyle(fontSize: 11.5, color: _kText, height: 1.4)),
      ])),
    ]),
  );

  Widget _field(String label, TextEditingController ctl, {
    bool required = false, TextInputType? type, String? hint,
  }) => TextFormField(
    controller: ctl, keyboardType: type,
    style: const TextStyle(fontSize: 13),
    decoration: _deco(label, hint: hint),
    validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
  );

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, {
    String Function(String)? labelMapper,
  }) => DropdownButtonFormField<String>(
    value: items.contains(value) ? value : null,
    isExpanded: true, style: const TextStyle(fontSize: 13, color: _kText),
    decoration: _deco(label),
    items: items.map((e) => DropdownMenuItem(value: e,
        child: Text(labelMapper == null ? e : labelMapper(e)))).toList(),
    onChanged: onChanged,
  );

  Widget _barangayDropdown() => DropdownButtonFormField<String>(
    value: kTubunganBarangays.contains(_barangay) ? _barangay : null,
    isExpanded: true, style: const TextStyle(fontSize: 13, color: _kText),
    decoration: _deco('Barangay *'),
    items: [
      const DropdownMenuItem(value: null, child: Text('— Select —',
          style: TextStyle(color: Color(0xFF9CA3AF)))),
      ...kTubunganBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))),
    ],
    onChanged: (v) => setState(() => _barangay = v),
    validator: (v) => v == null ? 'Required' : null,
  );

  Widget _datePicker(String label, DateTime? value, ValueChanged<DateTime> onPick) =>
    GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020), lastDate: DateTime(2030),
          builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _kGreen)), child: child!),
        );
        if (d != null) onPick(d);
      },
      child: AbsorbPointer(child: TextFormField(
        style: const TextStyle(fontSize: 13),
        decoration: _deco(label).copyWith(
          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16, color: _kMuted),
          hintText: value == null ? 'MM/DD/YYYY' : null,
        ),
        controller: TextEditingController(text: value == null ? ''
          : '${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}/${value.year}'),
        validator: (_) => value == null ? 'Required' : null,
      )),
    );

  Widget _autoHarvestDateField() {
    final days = _avgHarvestDays[_cropType] ?? 90;
    final dateStr = _harvestDate == null
        ? 'Set planting date first'
        : '${_harvestDate!.month.toString().padLeft(2,'0')}/${_harvestDate!.day.toString().padLeft(2,'0')}/${_harvestDate!.year}';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextFormField(
        readOnly: true,
        style: const TextStyle(fontSize: 13),
        decoration: _deco('Expected Harvest').copyWith(
          hintText: dateStr,
          hintStyle: TextStyle(fontSize: 13, color: _harvestDate != null ? _kText : _kMuted),
          suffixIcon: const Icon(Icons.auto_awesome_rounded, size: 16, color: _kGreen),
          fillColor: const Color(0xFFF0FDF4),
        ),
        controller: TextEditingController(text: _harvestDate == null ? '' : dateStr),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 3, left: 2),
        child: Text('Auto · avg $days days for $_cropType',
            style: const TextStyle(fontSize: 10, color: _kMuted)),
      ),
    ]);
  }

  InputDecoration _deco(String label, {String? hint}) => InputDecoration(
    labelText: label, hintText: hint,
    labelStyle: const TextStyle(fontSize: 12, color: _kMuted),
    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kGreen, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kRed)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kRed)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true, fillColor: const Color(0xFFFAFAFA), isDense: true,
  );
}

// ─── Success view ─────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: Center(child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12)]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _kGreen.withAlpha(20), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: _kGreen, size: 56),
          ),
          const SizedBox(height: 18),
          const Text('Cycle Journal Submitted!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kText)),
          const SizedBox(height: 10),
          const Text(
            'Your full 6-stage crop cycle data has been sent to the BAW for field verification.\n\nThe BAW will check area, crop, yield, losses, and market conditions before forwarding to MAO.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: _kMuted, height: 1.5)),
          const SizedBox(height: 22),
          _step('✓', 'Farmer', 'Cycle journal submitted', _kGreen, true),
          _step('⏳', 'BAW', 'Pending field verification', _kMuted, false),
          _step('◦', 'MAO', 'Awaiting BAW approval', _kMuted, false),
          const SizedBox(height: 22),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
          )),
        ]),
      ))),
    );
  }

  Widget _step(String icon, String role, String status, Color color, bool active) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(width: 28, height: 28, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? _kGreen : const Color(0xFFE5E7EB), shape: BoxShape.circle),
          child: Text(icon, style: TextStyle(fontSize: 11, color: active ? Colors.white : _kMuted))),
        const SizedBox(width: 10),
        Text('$role — ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        Text(status, style: TextStyle(fontSize: 12, color: color)),
      ]),
    );
}
