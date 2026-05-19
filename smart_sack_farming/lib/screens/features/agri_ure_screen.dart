import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/agri_ure_service.dart';

const _kGreen = Color(0xFF1B7737);
const _kBg = Color(0xFFF3F4F6);
const _kCard = Colors.white;
const _kBorder = Color(0xFFD1D5DB);
const _kMuted = Color(0xFF6B7280);
const _kText = Color(0xFF111827);

class AgriUreScreen extends StatefulWidget {
  const AgriUreScreen({super.key});
  @override
  State<AgriUreScreen> createState() => _AgriUreScreenState();
}

class _AgriUreScreenState extends State<AgriUreScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _submitted = false;
  bool _savingDraft = false;

  // Section 1 — Farmer Info
  final _farmerNameCtl = TextEditingController();
  final _farmerIdCtl = TextEditingController();
  final _contactCtl = TextEditingController();
  final _assocCtl = TextEditingController();

  // Section 2 — Location
  final _sitioCtl = TextEditingController();
  final _farmLocCtl = TextEditingController();
  final _gpsCtl = TextEditingController();
  String? _province;
  String? _municipality;
  String? _barangay;

  // Section 3 — Tenure
  String _tenureType = 'Tenant';
  final _landOwnerCtl = TextEditingController();

  // Section 4 — Farm Details
  String _crop = 'Ampalaya';
  final _cropVarietyCtl = TextEditingController();
  final _totalAreaCtl = TextEditingController();
  final _areaDamagedCtl = TextEditingController();
  String _areaDamagePct = '50% (1/2)';
  String? _irrigationType;

  // Section 5 — Incident
  String _disasterType = 'Typhoon';
  DateTime? _incidentDate;
  TimeOfDay? _incidentTime;
  final _descCtl = TextEditingController();

  // Section 6 — Damage Assessment
  String _cropDamagePct = '50% (1/2)';
  String _landDamagePct = '50% (1/2)';
  final _yieldLossCtl = TextEditingController();
  final _financialLossCtl = TextEditingController();

  // Evidence (simulated)
  int _photoCount = 4; // simulated uploaded photos

  static const _crops = [
    'Ampalaya','Eggplant','Tomato','Cabbage','Pepper','Squash',
    'Rice','Corn','Banana','Mango','Other',
  ];
  static const _disasterTypes = [
    'Typhoon','Flooding','Drought','Pest Infestation',
    'Disease Outbreak','Landslide','Fire','Strong Winds',
    'Hailstorm','Other',
  ];
  static const _tenureTypes = [
    'Land Owner','Tenant','Lessee','Farm Worker',
    'Caretaker','Cooperative Managed','Shared Farming','Other',
  ];
  static const _damagePcts = [
    '25% (1/4)','33% (1/3)','50% (1/2)','75% (3/4)','100% (Total Loss)',
  ];
  static const _irrigationTypes = ['Rainfed','Irrigated','Supplemental Irrigation'];
  static const _areaDamagePcts = ['25% (1/4)','33% (1/3)','50% (1/2)','75% (3/4)','100% (Total Loss)'];
  static const _provinces = ['Iloilo','Cebu','Nueva Ecija','Batangas','Other'];
  static const _municipalities = ['Tubungan','Cabanatuan City','Other'];
  static const _barangays = [
    'Alegria','Anilao','Bagumbayan','Buenavista','Cabilauan',
    'Calumpang','Canabuan','San Isidro','Other',
  ];

  @override
  void initState() {
    super.initState();
    _prefillFarmerInfo();
  }

  void _prefillFarmerInfo() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final meta = user.userMetadata ?? {};
    _farmerNameCtl.text = (meta['full_name'] as String?) ?? '';
    _contactCtl.text   = (meta['contact_number'] as String?) ?? '';
    _farmerIdCtl.text  = (meta['rsbsa_number'] as String?) ?? 'FMR-2025-000001';
    _assocCtl.text     = (meta['association'] as String?) ?? '';
    _province     = meta['province'] as String?;
    _municipality = meta['municipality'] as String?;
    _barangay     = meta['barangay'] as String?;
  }

  @override
  void dispose() {
    for (final c in [
      _farmerNameCtl,_farmerIdCtl,_contactCtl,_assocCtl,
      _sitioCtl,_farmLocCtl,_gpsCtl,_landOwnerCtl,
      _cropVarietyCtl,_totalAreaCtl,_areaDamagedCtl,
      _descCtl,_yieldLossCtl,_financialLossCtl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');
      await AgriUreService().submitUreEvent(
        farmerId: user.id,
        cropType: _crop,
        eventType: _disasterType,
        description: _descCtl.text.trim(),
        financialImpact: double.tryParse(
            _financialLossCtl.text.replaceAll(',', '').trim()),
      );
      if (!mounted) return;
      setState(() { _submitting = false; _submitted = true; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _SuccessView(onAgain: () => setState(() { _submitted = false; }));
    final wide = MediaQuery.of(context).size.width > 860;
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: Column(children: [
        _buildTopBar(),
        Expanded(
          child: wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 7, child: _buildScrollableForm()),
                  SizedBox(
                    width: 280,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(0, 16, 16, 32),
                      child: _buildSidebar(),
                    ),
                  ),
                ])
              : _buildScrollableForm(),
        ),
      ])),
    );
  }

  Widget _buildTopBar() => Container(
    color: _kCard,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: const Icon(Icons.arrow_back_rounded, size: 22, color: _kText),
      ),
      const SizedBox(width: 12),
      const Text('Report Uncontrolled Risk Event',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kText)),
    ]),
  );

  Widget _buildScrollableForm() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _infoBanner(),
        const SizedBox(height: 16),
        _s(1, 'Farmer Information', _farmerInfoFields()),
        const SizedBox(height: 14),
        _s(2, 'Location Information', _locationFields()),
        const SizedBox(height: 14),
        _s(3, 'Farm Ownership / Tenure Information', _tenureFields()),
        const SizedBox(height: 14),
        _s(4, 'Farm Details', _farmDetailFields()),
        const SizedBox(height: 14),
        _s(5, 'Incident / Disaster Information', _incidentFields()),
        const SizedBox(height: 14),
        _s(6, 'Damage Assessment', _damageAssessmentFields()),
        const SizedBox(height: 14),
        _s(7, 'Evidence Upload', _evidenceUploadFields()),
        const SizedBox(height: 24),
        _buildBottomActions(),
        const SizedBox(height: 32),
      ]),
    ),
  );

  // ─── Info banner ──────────────────────────────────────────────────────────

  Widget _infoBanner() => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFBFDBFE)),
    ),
    child: const Row(children: [
      Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 18),
      SizedBox(width: 10),
      Expanded(child: Text(
        'Uncontrolled Risk Events (UREs) are sudden events affecting your crops. '
        'Reports are reviewed by the BAW office and verified before being forwarded to the MAO office.',
        style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.45),
      )),
    ]),
  );

  // ─── Section wrapper ──────────────────────────────────────────────────────

  Widget _s(int num, String title, Widget content) => Container(
    decoration: BoxDecoration(
      color: _kCard, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0,2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(children: [
          Container(
            width: 26, height: 26,
            decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('$num', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kText)),
        ]),
      ),
      const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
      Padding(padding: const EdgeInsets.all(16), child: content),
    ]),
  );

  // ─── Section 1: Farmer Info ───────────────────────────────────────────────

  Widget _farmerInfoFields() => Column(children: [
    Row(children: [
      Expanded(child: _field('Farmer Name', controller: _farmerNameCtl, required: true)),
      const SizedBox(width: 12),
      Expanded(child: _field('Farmer ID / Registry No.', controller: _farmerIdCtl)),
      const SizedBox(width: 12),
      Expanded(child: _field('Contact Number', controller: _contactCtl, required: true,
          keyboardType: TextInputType.phone)),
    ]),
    const SizedBox(height: 12),
    _field('Association / Cooperative (Optional)', controller: _assocCtl),
  ]);

  // ─── Section 2: Location ──────────────────────────────────────────────────

  Widget _locationFields() => Column(children: [
    Row(children: [
      Expanded(child: _dropdown('Province', _province, _provinces, (v) => setState(() => _province = v))),
      const SizedBox(width: 12),
      Expanded(child: _dropdown('Municipality', _municipality, _municipalities, (v) => setState(() => _municipality = v))),
      const SizedBox(width: 12),
      Expanded(child: _dropdown('Barangay *', _barangay, _barangays,
          (v) => setState(() => _barangay = v), required: true)),
    ]),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _field('Sitio / Purok (Optional)', controller: _sitioCtl)),
      const SizedBox(width: 12),
      Expanded(child: _fieldWithSuffix('Farm Location (Optional)', _farmLocCtl,
          Icons.gps_fixed_rounded)),
      const SizedBox(width: 12),
      Expanded(child: _field('GPS Coordinates (Optional)', controller: _gpsCtl,
          hint: 'e.g. 10.7654, 122.3181')),
    ]),
  ]);

  // ─── Section 3: Tenure ───────────────────────────────────────────────────

  Widget _tenureFields() => Column(children: [
    Row(children: [
      Expanded(child: _dropdown('Farm Relationship / Tenure Type *', _tenureType, _tenureTypes,
          (v) => setState(() => _tenureType = v!), required: true, nullable: false)),
      const SizedBox(width: 12),
      Expanded(child: _field('Land Owner Name *', controller: _landOwnerCtl, required: true)),
      const SizedBox(width: 12),
      Expanded(child: _uploadButton('Land Tenure Document (Optional)',
          'Accepted: PDF, JPG, PNG (Max. 5MB)')),
    ]),
  ]);

  // ─── Section 4: Farm Details ──────────────────────────────────────────────

  Widget _farmDetailFields() => Column(children: [
    Row(children: [
      Expanded(child: _dropdown('Affected Crop *', _crop, _crops,
          (v) => setState(() => _crop = v!), required: true, nullable: false)),
      const SizedBox(width: 12),
      Expanded(child: _field('Crop Variety (Optional)', controller: _cropVarietyCtl)),
      const SizedBox(width: 12),
      Expanded(child: _field('Total Farm Land Area (Hectares) *',
          controller: _totalAreaCtl, required: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true))),
    ]),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _field('Area Affected / Damaged (Hectares) *',
          controller: _areaDamagedCtl, required: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true))),
      const SizedBox(width: 12),
      Expanded(child: _dropdown('Percentage of Land Area Affected *',
          _areaDamagePct, _areaDamagePcts,
          (v) => setState(() => _areaDamagePct = v!), required: true, nullable: false)),
      const SizedBox(width: 12),
      Expanded(child: _dropdown('Farm Irrigation Type (Optional)',
          _irrigationType, _irrigationTypes,
          (v) => setState(() => _irrigationType = v))),
    ]),
  ]);

  // ─── Section 5: Incident ──────────────────────────────────────────────────

  Widget _incidentFields() => Column(children: [
    Row(children: [
      Expanded(child: _dropdown('Type of Disaster / Incident *',
          _disasterType, _disasterTypes,
          (v) => setState(() => _disasterType = v!), required: true, nullable: false)),
      const SizedBox(width: 12),
      Expanded(child: _datePicker()),
      const SizedBox(width: 12),
      Expanded(child: _timePicker()),
    ]),
    const SizedBox(height: 12),
    _field('Description of Incident / Damage *', controller: _descCtl,
        required: true, maxLines: 3,
        hint: 'Describe how the incident affected your crops and farm...'),
  ]);

  // ─── Section 6: Damage Assessment ────────────────────────────────────────

  Widget _damageAssessmentFields() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _fieldLabel('Crop Damage Level (by percentage of yield lost) *'),
        const SizedBox(height: 8),
        ..._damagePcts.map((p) => _radioRow(p, _cropDamagePct, (v) => setState(() => _cropDamagePct = v!))),
      ])),
      const SizedBox(width: 24),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _fieldLabel('Land Area Damage Level *'),
        const SizedBox(height: 8),
        ..._damagePcts.map((p) => _radioRow(p, _landDamagePct, (v) => setState(() => _landDamagePct = v!))),
      ])),
      const SizedBox(width: 24),
      Expanded(child: Column(children: [
        _field('Estimated Yield Loss (kg) Optional', controller: _yieldLossCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 12),
        _field('Estimated Financial Loss (₱) *', controller: _financialLossCtl,
            required: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true)),
      ])),
    ]),
  ]);

  Widget _radioRow(String label, String groupValue, ValueChanged<String?> onChanged) =>
    GestureDetector(
      onTap: () => onChanged(label),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Radio<String>(
            value: label, groupValue: groupValue, onChanged: onChanged,
            activeColor: _kGreen,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: _kText)),
        ]),
      ),
    );

  // ─── Section 7: Evidence Upload ───────────────────────────────────────────

  Widget _evidenceUploadFields() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _fieldLabel('Photos of Damage *'),
    const SizedBox(height: 10),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Existing photos
      Expanded(
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          ...List.generate(_photoCount, (i) => _photoThumb(i)),
        ]),
      ),
      const SizedBox(width: 12),
      // Upload zone
      Container(
        width: 180,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: _kBorder, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFF9FAFB),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _photoCount = (_photoCount + 1).clamp(0, 10)),
          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.cloud_upload_outlined, size: 26, color: _kMuted),
            SizedBox(height: 6),
            Text('Upload More Photos / Videos', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kText)),
            SizedBox(height: 2),
            Text('Click or drag files here',
                style: TextStyle(fontSize: 10, color: _kMuted)),
            SizedBox(height: 2),
            Text('Accepted: JPG, PNG, MP4 (Max. 20MB)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: _kMuted)),
          ]),
        ),
      ),
    ]),
  ]);

  Widget _photoThumb(int i) {
    final colors = [
      const Color(0xFF4CAF50), const Color(0xFF2196F3),
      const Color(0xFF795548), const Color(0xFF607D8B),
    ];
    return Stack(children: [
      Container(
        width: 70, height: 70,
        decoration: BoxDecoration(
          color: colors[i % colors.length].withAlpha(60),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: const Icon(Icons.image_rounded, color: _kMuted, size: 28),
      ),
      Positioned(top: 2, right: 2,
        child: GestureDetector(
          onTap: () => setState(() => _photoCount = (_photoCount - 1).clamp(0, 10)),
          child: Container(
            width: 18, height: 18,
            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, size: 11, color: Colors.white),
          ),
        ),
      ),
    ]);
  }

  // ─── Bottom actions ───────────────────────────────────────────────────────

  Widget _buildBottomActions() => Column(children: [
    Row(children: [
      OutlinedButton(
        onPressed: _savingDraft ? null : () async {
          setState(() => _savingDraft = true);
          await Future.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;
          setState(() => _savingDraft = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Draft saved.'), backgroundColor: _kGreen));
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _kBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _savingDraft
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Save as Draft', style: TextStyle(color: _kText, fontWeight: FontWeight.w600)),
      ),
      const SizedBox(width: 12),
      Expanded(child: ElevatedButton.icon(
        onPressed: _submitting ? null : _submit,
        icon: _submitting
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.send_rounded, size: 16),
        label: const Text('Submit Report to BAW',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kGreen, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      )),
    ]),
    const SizedBox(height: 6),
    const Text('Your report will be reviewed by the BAW office.',
        style: TextStyle(fontSize: 11, color: _kMuted)),
  ]);

  // ─── Sidebar ──────────────────────────────────────────────────────────────

  Widget _buildSidebar() => Column(children: [
    _sideCard('Report Status', _buildStatusWidget()),
    const SizedBox(height: 12),
    _sideCard('Reporting Workflow', _buildWorkflowWidget()),
    const SizedBox(height: 12),
    _notesCard(),
    const SizedBox(height: 12),
    _helpCard(),
  ]);

  Widget _sideCard(String title, Widget content) => Container(
    decoration: BoxDecoration(
      color: _kCard, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0,2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kText)),
      ),
      const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
      Padding(padding: const EdgeInsets.all(14), child: content),
    ]),
  );

  Widget _buildStatusWidget() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(20)),
      child: const Text('Draft',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
    ),
    const SizedBox(height: 8),
    const Text('Your report is not yet submitted.',
        style: TextStyle(fontSize: 12, color: _kMuted)),
  ]);

  Widget _buildWorkflowWidget() {
    const steps = [
      ('Submitted by Farmer', 'You submit the report.'),
      ('BAW Verification', 'Barangay Agriculture Worker (BAW) reviews and verifies the report.'),
      ('Forwarded to MAO', 'If verified, the report is forwarded to the Municipal Agriculture Office.'),
      ('MAO Review', 'MAO reviews the report and takes appropriate action.'),
      ('Assistance / Action', 'Intervention or assistance will be provided if eligible.'),
    ];
    return Column(children: steps.asMap().entries.map((e) {
      final i = e.key;
      final active = i == 0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: active ? _kGreen : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('${i+1}', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: active ? Colors.white : _kMuted)),
            ),
            if (i < steps.length - 1)
              Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
          ]),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.value.$1, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: active ? _kGreen : _kText)),
            const SizedBox(height: 2),
            Text(e.value.$2, style: const TextStyle(fontSize: 11, color: _kMuted, height: 1.4)),
          ])),
        ]),
      );
    }).toList());
  }

  Widget _notesCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFBBF7D0)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Notes for Farmer',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen)),
      const SizedBox(height: 8),
      ...[
        'Provide accurate information.',
        'Attach clear photos as evidence.',
        'False reporting is subject to penalties.',
      ].map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('• ', style: TextStyle(fontSize: 12, color: _kGreen, fontWeight: FontWeight.w700)),
          Expanded(child: Text(t, style: const TextStyle(fontSize: 12, color: Color(0xFF166534)))),
        ]),
      )),
    ]),
  );

  Widget _helpCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFBBF7D0)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Need Help?',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen)),
      const SizedBox(height: 6),
      const Text('Contact your Barangay Agriculture Worker (BAW) for assistance.',
          style: TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.4)),
      const SizedBox(height: 8),
      Row(children: [
        const Icon(Icons.phone_rounded, size: 14, color: _kGreen),
        const SizedBox(width: 6),
        Text('(044) 123-4567',
            style: const TextStyle(fontSize: 12, color: _kGreen, fontWeight: FontWeight.w700)),
      ]),
    ]),
  );

  // ─── Reusable field widgets ───────────────────────────────────────────────

  Widget _field(String label, {
    TextEditingController? controller,
    bool required = false,
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    style: const TextStyle(fontSize: 13),
    decoration: _deco(label, hint: hint),
    validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
  );

  Widget _fieldWithSuffix(String label, TextEditingController ctl, IconData icon) =>
    TextFormField(
      controller: ctl,
      style: const TextStyle(fontSize: 13),
      decoration: _deco(label).copyWith(
        suffixIcon: Icon(icon, size: 16, color: _kMuted),
      ),
    );

  Widget _dropdown(String label, String? value, List<String> items,
      ValueChanged<String?> onChanged, {
        bool required = false,
        bool nullable = true,
      }) => DropdownButtonFormField<String>(
    value: (nullable && value == null) ? null : (items.contains(value) ? value : null),
    style: const TextStyle(fontSize: 13, color: _kText),
    isExpanded: true,
    decoration: _deco(label),
    items: [
      if (nullable) const DropdownMenuItem(value: null, child: Text('— Select —', style: TextStyle(color: Color(0xFF9CA3AF)))),
      ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
    ],
    onChanged: onChanged,
    validator: required ? (v) => v == null ? 'Required' : null : null,
  );

  Widget _uploadButton(String label, String hint) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel(label),
      const SizedBox(height: 6),
      OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.upload_rounded, size: 15, color: _kGreen),
        label: const Text('Upload Document', style: TextStyle(fontSize: 12, color: _kGreen)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _kGreen),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      const SizedBox(height: 4),
      Text(hint, style: const TextStyle(fontSize: 10, color: _kMuted)),
    ],
  );

  Widget _datePicker() => GestureDetector(
    onTap: () async {
      final d = await showDatePicker(
        context: context,
        initialDate: _incidentDate ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (d != null) setState(() => _incidentDate = d);
    },
    child: AbsorbPointer(child: TextFormField(
      style: const TextStyle(fontSize: 13),
      decoration: _deco('Date of Incident *').copyWith(
        suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16, color: _kMuted),
        hintText: _incidentDate == null ? 'MM/DD/YYYY' : null,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      ),
      controller: TextEditingController(
          text: _incidentDate == null ? '' :
          '${_incidentDate!.month.toString().padLeft(2,'0')}/'
          '${_incidentDate!.day.toString().padLeft(2,'0')}/'
          '${_incidentDate!.year}'),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    )),
  );

  Widget _timePicker() => GestureDetector(
    onTap: () async {
      final t = await showTimePicker(
        context: context,
        initialTime: _incidentTime ?? TimeOfDay.now(),
      );
      if (t != null) setState(() => _incidentTime = t);
    },
    child: AbsorbPointer(child: TextFormField(
      style: const TextStyle(fontSize: 13),
      decoration: _deco('Time Detected').copyWith(
        suffixIcon: const Icon(Icons.access_time_rounded, size: 16, color: _kMuted),
        hintText: _incidentTime == null ? 'e.g. 07:30 AM' : null,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      ),
      controller: TextEditingController(
          text: _incidentTime == null ? '' : _incidentTime!.format(context)),
    )),
  );

  Widget _fieldLabel(String label) => Text(label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted));

  InputDecoration _deco(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
    labelStyle: const TextStyle(fontSize: 12, color: _kMuted),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kGreen, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEF4444))),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEF4444))),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true, fillColor: const Color(0xFFFAFAFA),
    isDense: true,
  );
}

// ─── Success View ─────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final VoidCallback onAgain;
  const _SuccessView({required this.onAgain});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _kBg,
    body: Center(child: Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12)]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _kGreen.withAlpha(20), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded, color: _kGreen, size: 60),
        ),
        const SizedBox(height: 20),
        const Text('Report Submitted!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
        const SizedBox(height: 10),
        const Text(
          'Your URE report has been sent to the BAW office for verification.\n'
          'You will be notified once it has been reviewed.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: _kMuted, height: 1.5),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kBorder),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Back to Dashboard', style: TextStyle(color: _kText)),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: onAgain,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Submit Another', style: TextStyle(fontWeight: FontWeight.w700)),
          )),
        ]),
      ]),
    )),
  );
}
