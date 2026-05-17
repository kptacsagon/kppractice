import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/agrisense_farm.dart';
import '../../models/agrisense_farmer_profile.dart';
import '../../repositories/agrisense_repository.dart';

// PostgrestException is exported by supabase_flutter — explicit import for catch clause
// ignore: implementation_imports
import 'package:postgrest/postgrest.dart' show PostgrestException;

const _kGreen = Color(0xFF1B7737);
const _kBg = Color(0xFFF0F5F1);

// Tubungan, Iloilo — corrected geographic center
const _kTubunganLat = 10.7654;
const _kTubunganLng = 122.3181;

// ─── 48 official barangays of Tubungan, Iloilo ───────────────────────────────
const _kBarangays = [
  'Adgao', 'Ago', 'Ambarihon', 'Ayubo', 'Bacan', 'Badiang',
  'Bagunanay', 'Balicua', 'Bantayanan', 'Batga', 'Bato', 'Bikil',
  'Boloc', 'Bondoc (Sto. Niño)', 'Borong', 'Buenavista', 'Cadabdab',
  'Daga-ay', 'Desposorio', 'Igdampog Norte', 'Igdampog Sur', 'Igpaho',
  'Igtuble', 'Ingay', 'Isauan', 'Jolason', 'Jona', 'La-ag (San Vicente)',
  'Lanag Norte', 'Lanag Sur', 'Male', 'Mayang', 'Molina', 'Morcillas',
  'Nagba', 'Navillan', 'Pinamacalan', 'San Jose', 'Sibucauan', 'Singon',
  'Tabat', 'Tagpu-an', 'Talento', 'Teniente Benito', 'Victoria',
  'Zone I', 'Zone II', 'Zone III',
];

// ─── Appendix B — Predefined crop list ──────────────────────────────────────
const _kCrops = [
  'Palay (Rice)', 'Corn (White)', 'Corn (Yellow)', 'Sorghum',
  'Cassava', 'Sweet Potato (Kamote)', 'Gabi', 'Ube', 'Singkamas',
  'Eggplant', 'Tomato', 'Ampalaya (Bitter Gourd)', 'Squash', 'Upo', 'Patola', 'Okra',
  'Pechay', 'Kangkong', 'Sitaw (String Beans)',
  'Munggo', 'Kadyos', 'Bataw', 'Peanut',
  'Banana', 'Jackfruit', 'Mango', 'Cacao', 'Coconut', 'Avocado',
  'Lanzones', 'Rambutan',
  'Sugarcane', 'Coffee', 'Rubber',
  'Lemongrass', 'Turmeric', 'Ginger', 'Lagundi',
  'Other (Custom)',
];

const _kOwnershipTypes = [
  'Owner', 'Tenant', 'Lessee', 'CLOA Holder', 'Ancestral Land Holder',
];
const _kTerrainTypes = ['Lowland', 'Upland', 'Mountainous', 'Sloping'];
const _kSoilTypes = ['Clay', 'Sandy', 'Loam', 'Silt', 'Volcanic'];
const _kIrrigationTypes = ['Rainfed', 'Irrigated', 'Drip Irrigation', 'Deep Well'];
const _kWaterSources = ['River', 'Spring', 'Rainwater', 'Communal Irrigation System', 'Deep Well'];
const _kFarmingMethods = ['Organic', 'Conventional', 'Mixed'];
const _kTransportation = ['Motorized Vehicle', 'Motorcycle Only', 'Foot Path Only', 'Boat Access'];
const _kRoadTypes = ['Concrete', 'Gravel', 'Rough Road', 'Mountain Trail'];
const _kSeasonality = ['Wet Season', 'Dry Season', 'Year-round'];
const _kRiskOptions = ['Yes', 'No', 'Unknown'];

const _kStatusColors = {
  'Draft': Color(0xFF6B7280),
  'Pending Verification': Color(0xFFF59E0B),
  'Needs Correction': Color(0xFFDC2626),
  'Verified': Color(0xFF16A34A),
  'Flagged': Color(0xFFEF4444),
  'Archived': Color(0xFF9CA3AF),
};

// ─── Main Screen ─────────────────────────────────────────────────────────────

class AgrisenseFarmRegistryScreen extends StatefulWidget {
  const AgrisenseFarmRegistryScreen({super.key});

  @override
  State<AgrisenseFarmRegistryScreen> createState() => _AgrisenseFarmRegistryScreenState();
}

class _AgrisenseFarmRegistryScreenState extends State<AgrisenseFarmRegistryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<AgrisenseFarm> _myFarms = [];
  bool _loadingFarms = true;

  // The agrisense_farmer_profiles.id (DB UUID) — NOT the auth user ID.
  // This is the value that satisfies agrisense_farms.farmer_id FK constraint.
  // Remains null when the user has no profile row yet.
  String? _farmerProfileId;
  AgrisenseFarmerProfile? _farmerProfile;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadMyFarms();
  }

  Future<void> _loadMyFarms() async {
    if (!mounted) return;
    setState(() => _loadingFarms = true);
    try {
      final client = Supabase.instance.client;
      final authUserId = client.auth.currentUser?.id;
      if (authUserId == null) {
        setState(() => _loadingFarms = false);
        return;
      }

      final repo = AgrisenseRepository(client);

      // Resolve the DB profile UUID — critical: this is NOT the auth UID.
      // agrisense_farms.farmer_id must reference agrisense_farmer_profiles.id.
      final profileId = await repo.getFarmerProfileId(authUserId);

      if (!mounted) return;
      _farmerProfileId = profileId; // null if no profile exists yet
      try {
        _farmerProfile = await repo.getFarmerProfile(authUserId);
      } catch (_) {}

      List<AgrisenseFarm> farms = [];
      if (profileId != null) {
        farms = await repo.getFarmsByFarmer(profileId);
      }

      if (!mounted) return;
      setState(() { _myFarms = farms; _loadingFarms = false; });
    } catch (e) {
      debugPrint('[FarmRegistry] _loadMyFarms error: $e');
      if (mounted) setState(() => _loadingFarms = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Header ──
          Container(
            color: _kGreen,
            padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.landscape_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GIS Farm Registry', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                        Text('Tubungan, Iloilo — Farm Registry Module', style: TextStyle(color: Color(0xFFB2D9B8), fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabs,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'My Farms'),
                    Tab(text: 'Register New Farm'),
                  ],
                ),
              ],
            ),
          ),
          // ── Body ──
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _MyFarmsTab(farms: _myFarms, loading: _loadingFarms, onRefresh: _loadMyFarms),
                _RegisterFarmTab(farmerProfileId: _farmerProfileId, farmerProfile: _farmerProfile, onSaved: () { _loadMyFarms(); _tabs.animateTo(0); }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── My Farms Tab ────────────────────────────────────────────────────────────

class _MyFarmsTab extends StatelessWidget {
  final List<AgrisenseFarm> farms;
  final bool loading;
  final VoidCallback onRefresh;
  const _MyFarmsTab({required this.farms, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: _kGreen));
    if (farms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.landscape_outlined, size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            const Text('No farms registered yet.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Tap "Register New Farm" to add your first farm.', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: _kGreen,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: farms.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _FarmCard(farm: farms[i]),
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  final AgrisenseFarm farm;
  const _FarmCard({required this.farm});

  @override
  Widget build(BuildContext context) {
    final color = _kStatusColors[farm.verificationStatus] ?? const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: _kGreen, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(farm.farmName ?? 'Unnamed Farm', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                child: Text(farm.verificationStatus, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${farm.barangay}${farm.sitio != null ? ", ${farm.sitio}" : ""} — ${farm.totalAreaHectares.toStringAsFixed(4)} ha',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: [
              _Chip(farm.primaryCrop, _kGreen),
              _Chip(farm.terrainType, const Color(0xFF6366F1)),
              _Chip(farm.irrigationType, const Color(0xFF3B82F6)),
              if (farm.floodProne == 'Yes') _Chip('Flood Prone', const Color(0xFFDC2626)),
              if (farm.landslideRisk == 'Yes') _Chip('Landslide Risk', const Color(0xFFDC2626)),
            ],
          ),
          if (farm.rejectionNote != null && farm.rejectionNote!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text(farm.rejectionNote!, style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
  );
}

// ─── Register Farm Tab ────────────────────────────────────────────────────────

class _RegisterFarmTab extends StatefulWidget {
  /// The agrisense_farmer_profiles.id (DB UUID) — NOT the auth user ID.
  /// Null means no profile exists yet; farm saves will be blocked.
  final String? farmerProfileId;
  final AgrisenseFarmerProfile? farmerProfile;
  final VoidCallback onSaved;
  const _RegisterFarmTab({this.farmerProfileId, this.farmerProfile, required this.onSaved});

  @override
  State<_RegisterFarmTab> createState() => _RegisterFarmTabState();
}

class _RegisterFarmTabState extends State<_RegisterFarmTab> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _showMapPicker = false;

  // Form state
  final _farmNameCtrl = TextEditingController();
  final _sitioCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _soilNotesCtrl = TextEditingController();
  final _irrigationNotesCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController();
  final _travelTimeCtrl = TextEditingController();
  final _yieldCtrl = TextEditingController();
  final _vulnNotesCtrl = TextEditingController();

  String? _barangay;
  String _ownershipType = 'Owner';
  String? _primaryCrop;
  String? _secondaryCrop;
  String _farmingMethod = 'Conventional';
  List<String> _seasonality = [];
  int? _harvestsPerYear;
  String _terrainType = 'Lowland';
  String? _soilClass;
  String _irrigationType = 'Rainfed';
  List<String> _waterSources = [];
  String? _transportation;
  String? _roadType;
  String _floodProne = 'Unknown';
  String _landslideRisk = 'Unknown';
  String _droughtRisk = 'Unknown';
  bool _consentGiven = false;
  double _markerLat = _kTubunganLat;
  double _markerLng = _kTubunganLng;
  bool _markerPlaced = false;

  bool get _needsBarangayCert => _ownershipType == 'Tenant' || _ownershipType == 'Lessee';
  bool get _needsLandTitle => _ownershipType == 'Owner' || _ownershipType == 'CLOA Holder';

  @override
  void initState() {
    super.initState();
    final p = widget.farmerProfile;
    if (p != null) {
      if (p.barangay.isNotEmpty) _barangay = p.barangay;
      if (p.farmOwnershipType != null) _ownershipType = p.farmOwnershipType!;
      if (p.irrigationAccess != null) _irrigationType = p.irrigationAccess!;
      if (p.primaryCrops.isNotEmpty) _primaryCrop = p.primaryCrops.first;
      if (p.farmingMethod != null) _farmingMethod = p.farmingMethod!;
    }
  }

  @override
  void dispose() {
    _farmNameCtrl.dispose(); _sitioCtrl.dispose(); _areaCtrl.dispose();
    _soilNotesCtrl.dispose(); _irrigationNotesCtrl.dispose();
    _distanceCtrl.dispose(); _travelTimeCtrl.dispose();
    _yieldCtrl.dispose(); _vulnNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(String status) async {
    // ── Guard 1: Farmer profile must exist ──────────────────────────────────
    // agrisense_farms.farmer_id is a FK to agrisense_farmer_profiles.id.
    // Using auth.uid() here would violate the constraint.
    String? resolvedProfileId = widget.farmerProfileId;

    if (resolvedProfileId == null) {
      // Attempt to auto-resolve: check if the profile was created since page load.
      final authUserId = Supabase.instance.client.auth.currentUser?.id;
      if (authUserId != null) {
        try {
          final repo = AgrisenseRepository(Supabase.instance.client);
          resolvedProfileId = await repo.ensureFarmerProfileAndGetId(authUserId);
          debugPrint('[FarmRegistry] Resolved profile ID: $resolvedProfileId');
        } catch (e) {
          debugPrint('[FarmRegistry] Profile resolution failed: $e');
        }
      }

      if (resolvedProfileId == null) {
        _showProfileRequiredDialog();
        return;
      }
    }

    // ── Guard 2: Form validation ─────────────────────────────────────────────
    if (!_formKey.currentState!.validate()) return;

    if (!_consentGiven && status != 'Draft') {
      _snack('Kailangan ang pahintulot sa privacy. / Privacy consent is required.');
      return;
    }

    final area = double.tryParse(_areaCtrl.text.trim());
    if (area == null || area <= 0) {
      _snack('Ang lawak ng bukid ay dapat higit sa 0. / Farm area must be greater than 0.');
      return;
    }
    if (_primaryCrop != null && _primaryCrop == _secondaryCrop) {
      _snack('Hindi pwedeng pareho ang primary at secondary na pananim. / Primary and Secondary Crop must be different.');
      return;
    }
    final dist = double.tryParse(_distanceCtrl.text.trim());
    if (_distanceCtrl.text.trim().isNotEmpty && (dist == null || dist < 0)) {
      _snack('Ang distansya ay dapat 0 o higit pa. / Distance must be 0 or greater.');
      return;
    }

    setState(() => _saving = true);
    try {
      debugPrint('[FarmRegistry] Saving farm with profile ID: $resolvedProfileId');
      final farm = AgrisenseFarm(
        farmerId: resolvedProfileId,
        farmName: _farmNameCtrl.text.trim().isEmpty ? null : _farmNameCtrl.text.trim(),
        province: 'Iloilo',
        municipality: 'Tubungan',
        barangay: _barangay ?? '',
        sitio: _sitioCtrl.text.trim().isEmpty ? null : _sitioCtrl.text.trim(),
        totalAreaHectares: area,
        ownershipType: _ownershipType,
        primaryCrop: _primaryCrop ?? '',
        secondaryCrop: _secondaryCrop,
        farmingMethod: _farmingMethod,
        cropSeasonality: _seasonality,
        expectedYieldKg: double.tryParse(_yieldCtrl.text.trim()),
        harvestsPerYear: _harvestsPerYear,
        terrainType: _terrainType,
        soilClassification: _soilClass,
        soilNotes: _soilNotesCtrl.text.trim().isEmpty ? null : _soilNotesCtrl.text.trim(),
        irrigationType: _irrigationType,
        waterSources: _waterSources,
        irrigationNotes: _irrigationNotesCtrl.text.trim().isEmpty ? null : _irrigationNotesCtrl.text.trim(),
        distanceToMarketKm: dist,
        transportationAccess: _transportation,
        roadType: _roadType,
        travelTimeToMarketMin: int.tryParse(_travelTimeCtrl.text.trim()),
        floodProne: _floodProne,
        landslideRisk: _landslideRisk,
        droughtRisk: _droughtRisk,
        vulnerabilityNotes: _vulnNotesCtrl.text.trim().isEmpty ? null : _vulnNotesCtrl.text.trim(),
        centroidLat: _markerPlaced ? _markerLat : null,
        centroidLng: _markerPlaced ? _markerLng : null,
        verificationStatus: status,
        privacyConsentGiven: _consentGiven,
        submittedAt: status == 'Pending Verification' ? DateTime.now() : null,
      );

      await AgrisenseRepository(Supabase.instance.client).saveFarm(farm);
      debugPrint('[FarmRegistry] Farm saved successfully. Status: $status');
      if (!mounted) return;
      _snack(status == 'Draft' ? 'Draft saved successfully.' : 'Farm submitted for BAO verification.');
      widget.onSaved();
    } on PostgrestException catch (e) {
      debugPrint('[FarmRegistry] PostgrestException code=${e.code} msg=${e.message}');
      if (!mounted) return;
      if (e.code == '23503') {
        _showProfileRequiredDialog();
      } else if (e.code == '42501') {
        _snack('Permission denied. Contact your system administrator to enable farm registration.');
      } else {
        _snack('Database error (${e.code}): ${e.message}');
      }
    } catch (e) {
      debugPrint('[FarmRegistry] Save error: $e');
      if (mounted) _snack('Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showProfileRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.person_off_rounded, color: Color(0xFFF59E0B)),
          SizedBox(width: 10),
          Text('Profile Required'),
        ]),
        content: const Text(
          'You need to complete your AgriSense Farmer Registration before registering a farm.\n\n'
          'Go to: Farmer Dashboard → AgriSense Registration → Save Profile\n\n'
          'Once your profile is saved, return here to register your farm.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK, I\'ll register first'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.farmerProfileId == null) _buildProfileWarningBanner(),
            if (widget.farmerProfile != null) _buildProfileInheritanceBanner(widget.farmerProfile!),
            _section('1. Farm Basic Information', Icons.info_outline_rounded, _buildBasicInfo()),
            _section('2. Ownership & Tenurial Status', Icons.gavel_rounded, _buildOwnership()),
            _section('3. Agricultural Production Profile', Icons.grass_rounded, _buildProduction()),
            _section('4. Soil & Terrain Classification', Icons.terrain_rounded, _buildSoilTerrain()),
            _section('5. Irrigation & Water Source', Icons.water_drop_rounded, _buildIrrigation()),
            _section('6. Accessibility & Logistics', Icons.directions_rounded, _buildAccessibility()),
            _section('7. Disaster Vulnerability', Icons.warning_amber_rounded, _buildVulnerability()),
            _section('8. GIS Location', Icons.map_rounded, _buildGisMap()),
            _buildPrivacyConsent(),
            const SizedBox(height: 20),
            _buildButtons(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F5F1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: _kGreen),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1B7737))),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: content),
        ],
      ),
    );
  }

  // ── Section 1 ──
  Widget _buildBasicInfo() {
    return Column(children: [
      _field(controller: _farmNameCtrl, label: 'Farm Name', hint: '3–100 characters',
        validator: (v) { if (v != null && v.isNotEmpty && (v.length < 3 || v.length > 100)) return 'Farm name must be 3–100 characters.'; return null; }),
      _readonlyRow('Province', 'Iloilo'),
      _readonlyRow('Municipality', 'Tubungan'),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _barangay,
        decoration: _dec('Barangay *'),
        items: _kBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => _barangay = v),
        validator: (v) => v == null ? 'Pumili ng wastong barangay. / Please select a barangay.' : null,
      ),
      const SizedBox(height: 10),
      _field(controller: _sitioCtrl, label: 'Sitio / Purok (optional)', maxLength: 100),
      const SizedBox(height: 10),
      TextFormField(
        controller: _areaCtrl,
        decoration: _dec('Total Farm Area (hectares) *'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Kailangan ang field na ito. / This field is required.';
          final n = double.tryParse(v.trim());
          if (n == null || n <= 0) return 'Ang lawak ng bukid ay dapat higit sa 0. / Farm area must be greater than 0.';
          return null;
        },
      ),
    ]);
  }

  // ── Section 2 ──
  Widget _buildOwnership() {
    return Column(children: [
      DropdownButtonFormField<String>(
        value: _ownershipType,
        decoration: _dec('Ownership Type *'),
        items: _kOwnershipTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => _ownershipType = v ?? 'Owner'),
      ),
      const SizedBox(height: 12),
      _uploadTile('Government ID', required: true, hint: 'JPG, PNG, PDF — max 5 MB'),
      if (_needsBarangayCert) _uploadTile('Barangay Certification', required: true, hint: 'Required for Tenant / Lessee'),
      if (_needsLandTitle) _uploadTile('Land Title / CLOA Document', required: true, hint: 'Required for Owner / CLOA Holder'),
    ]);
  }

  // ── Section 3 ──
  Widget _buildProduction() {
    return Column(children: [
      DropdownButtonFormField<String>(
        value: _primaryCrop,
        decoration: _dec('Primary Crop *'),
        isExpanded: true,
        items: _kCrops.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => _primaryCrop = v),
        validator: (v) => v == null ? 'Kailangan ang field na ito. / This field is required.' : null,
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _secondaryCrop,
        decoration: _dec('Secondary Crop (optional)'),
        isExpanded: true,
        items: [const DropdownMenuItem(value: null, child: Text('None', style: TextStyle(fontSize: 13))),
          ..._kCrops.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))),
        ],
        onChanged: (v) => setState(() => _secondaryCrop = v),
      ),
      const SizedBox(height: 12),
      const Text('Farming Method *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      Row(children: _kFarmingMethods.map((m) => Expanded(child: RadioListTile<String>(
        dense: true, contentPadding: EdgeInsets.zero,
        title: Text(m, style: const TextStyle(fontSize: 12)),
        value: m, groupValue: _farmingMethod,
        activeColor: _kGreen,
        onChanged: (v) => setState(() => _farmingMethod = v ?? 'Conventional'),
      ))).toList()),
      const SizedBox(height: 8),
      const Text('Crop Seasonality *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      const SizedBox(height: 4),
      Wrap(spacing: 8, children: _kSeasonality.map((s) {
        final selected = _seasonality.contains(s);
        return FilterChip(
          label: Text(s, style: TextStyle(fontSize: 11, color: selected ? Colors.white : const Color(0xFF374151))),
          selected: selected,
          selectedColor: _kGreen,
          backgroundColor: const Color(0xFFF3F4F6),
          onSelected: (v) => setState(() => v ? _seasonality.add(s) : _seasonality.remove(s)),
          showCheckmark: false,
        );
      }).toList()),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _field(controller: _yieldCtrl, label: 'Expected Yield/Harvest (kg)', keyboardType: TextInputType.number)),
        const SizedBox(width: 10),
        Expanded(child: DropdownButtonFormField<int>(
          value: _harvestsPerYear,
          decoration: _dec('Harvests/Year'),
          items: [1,2,3,4].map((n) => DropdownMenuItem(value: n, child: Text('$n', style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _harvestsPerYear = v),
        )),
      ]),
    ]);
  }

  // ── Section 4 ──
  Widget _buildSoilTerrain() {
    return Column(children: [
      DropdownButtonFormField<String>(
        value: _terrainType,
        decoration: _dec('Terrain Type *'),
        items: _kTerrainTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => _terrainType = v ?? 'Lowland'),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _soilClass,
        decoration: _dec('Soil Classification *'),
        items: _kSoilTypes.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => _soilClass = v),
        validator: (v) => v == null ? 'Kailangan ang field na ito. / This field is required.' : null,
      ),
      const SizedBox(height: 10),
      _field(controller: _soilNotesCtrl, label: 'Soil Notes (optional)', maxLines: 2, maxLength: 500),
    ]);
  }

  // ── Section 5 ──
  Widget _buildIrrigation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _irrigationType,
          decoration: _dec('Irrigation Type *'),
          items: _kIrrigationTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) {
            setState(() {
              _irrigationType = v ?? 'Rainfed';
              if (_irrigationType == 'Rainfed') _waterSources = ['Rainwater'];
              else _waterSources.remove('Rainwater');
            });
            if (_irrigationType == 'Mountainous' || _terrainType == 'Mountainous') {
              _snack('Mountainous terrain with full irrigation is uncommon. Please confirm this is correct.');
            }
          },
        ),
        const SizedBox(height: 12),
        const Text('Water Source *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        ..._kWaterSources.map((src) {
          final isRainfed = _irrigationType == 'Rainfed';
          final enabled = !isRainfed || src == 'Rainwater';
          return CheckboxListTile(
            dense: true, contentPadding: EdgeInsets.zero,
            title: Text(src, style: TextStyle(fontSize: 12, color: enabled ? const Color(0xFF374151) : const Color(0xFF9CA3AF))),
            value: _waterSources.contains(src),
            activeColor: _kGreen,
            onChanged: enabled ? (v) => setState(() => v == true ? _waterSources.add(src) : _waterSources.remove(src)) : null,
          );
        }),
        const SizedBox(height: 8),
        _field(controller: _irrigationNotesCtrl, label: 'Irrigation Notes (optional)', maxLines: 2, maxLength: 500),
      ],
    );
  }

  // ── Section 6 ──
  Widget _buildAccessibility() {
    return Column(children: [
      TextFormField(
        controller: _distanceCtrl,
        decoration: _dec('Distance to Nearest Market (km) *'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Kailangan ang field na ito. / This field is required.';
          final n = double.tryParse(v.trim());
          if (n == null || n < 0) return 'Ang distansya ay dapat 0 o higit pa. / Distance must be 0 or greater.';
          return null;
        },
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _transportation,
        decoration: _dec('Transportation Access *'),
        isExpanded: true,
        items: _kTransportation.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => _transportation = v),
        validator: (v) => v == null ? 'Kailangan ang field na ito. / This field is required.' : null,
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _roadType,
        decoration: _dec('Road Type *'),
        items: _kRoadTypes.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => _roadType = v),
        validator: (v) => v == null ? 'Kailangan ang field na ito. / This field is required.' : null,
      ),
      const SizedBox(height: 10),
      _field(controller: _travelTimeCtrl, label: 'Est. Travel Time to Market (min)', keyboardType: TextInputType.number),
    ]);
  }

  // ── Section 7 ──
  Widget _buildVulnerability() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _riskRow('Flood Prone', _floodProne, (v) => setState(() => _floodProne = v)),
      const SizedBox(height: 4),
      _riskRow('Landslide Risk', _landslideRisk, (v) => setState(() => _landslideRisk = v)),
      const SizedBox(height: 4),
      _riskRow('Drought Risk', _droughtRisk, (v) => setState(() => _droughtRisk = v)),
      const SizedBox(height: 10),
      _field(controller: _vulnNotesCtrl, label: 'Vulnerability Notes (optional)', maxLines: 2, maxLength: 500),
      if (_floodProne == 'Yes' || (_landslideRisk == 'Yes' && _terrainType == 'Mountainous')) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 16),
            const SizedBox(width: 8),
            const Expanded(child: Text('This farm will be tagged in the priority intervention report.', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626)))),
          ]),
        ),
      ],
    ]);
  }

  Widget _riskRow(String label, String value, void Function(String) onChanged) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ..._kRiskOptions.map((opt) => Expanded(child: RadioListTile<String>(
          dense: true, contentPadding: EdgeInsets.zero,
          title: Text(opt, style: const TextStyle(fontSize: 11)),
          value: opt, groupValue: value,
          activeColor: _kGreen,
          onChanged: (v) => onChanged(v ?? 'Unknown'),
        ))),
      ],
    );
  }

  // ── Section 8 — GIS Map ──
  Widget _buildGisMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tap on the map to place a marker at your farm\'s location. Map is centered on Tubungan, Iloilo.',
          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 280,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(_kTubunganLat, _kTubunganLng),
                initialZoom: 13.5,
                onTap: (_, point) => setState(() {
                  _markerLat = point.latitude;
                  _markerLng = point.longitude;
                  _markerPlaced = true;
                }),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.smartsackfarming.app',
                ),
                if (_markerPlaced)
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(_markerLat, _markerLng),
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.location_pin, color: Color(0xFFDC2626), size: 36),
                    ),
                  ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_markerPlaced)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded, color: _kGreen, size: 14),
              const SizedBox(width: 6),
              Text(
                'Location set: ${_markerLat.toStringAsFixed(4)}°N, ${_markerLng.toStringAsFixed(4)}°E',
                style: const TextStyle(fontSize: 11, color: _kGreen, fontWeight: FontWeight.w600),
              ),
            ]),
          )
        else
          const Text('No location set. Tap the map to pin your farm.', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
      ],
    );
  }

  // ── Privacy Consent ──
  Widget _buildPrivacyConsent() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _consentGiven ? _kGreen : const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.privacy_tip_rounded, color: _kGreen, size: 16),
            SizedBox(width: 8),
            Text('Privacy Notice (RA 10173)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kGreen)),
          ]),
          const SizedBox(height: 8),
          const Text(
            'Ang iyong personal na impormasyon ay kokolektahin at itatago para sa layunin ng pagpaparehistro ng bukid at pagtulong ng Municipal Agriculture Office (MAO). '
            'Maaari mong hilingin na tingnan, baguhin, o burahin ang iyong datos anumang oras.\n\n'
            'Your personal data is collected and stored for farm registration and MAO agricultural assistance purposes only. '
            'You may request to view, correct, or delete your data at any time.',
            style: TextStyle(fontSize: 11, color: Color(0xFF374151), height: 1.5),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            dense: true, contentPadding: EdgeInsets.zero,
            value: _consentGiven,
            activeColor: _kGreen,
            onChanged: (v) => setState(() => _consentGiven = v ?? false),
            title: const Text(
              'Sumasang-ayon ako / I consent to the collection and use of my personal data as described above.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInheritanceBanner(AgrisenseFarmerProfile p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB), size: 15),
          SizedBox(width: 8),
          Text('Pre-filled from Your AgriSense Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
        ]),
        const SizedBox(height: 6),
        _inheritRow(Icons.location_on_rounded, 'Barangay', p.barangay.isNotEmpty ? p.barangay : '—'),
        _inheritRow(Icons.gavel_rounded, 'Ownership', p.farmOwnershipType ?? '—'),
        _inheritRow(Icons.water_drop_rounded, 'Irrigation', p.irrigationAccess ?? '—'),
        if (p.primaryCrops.isNotEmpty) _inheritRow(Icons.grass_rounded, 'Primary Crop', p.primaryCrops.first),
        const SizedBox(height: 4),
        const Text(
          'You can change any of these values in the form below. Fields were pre-filled to save you time.',
          style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6), height: 1.4),
        ),
      ]),
    );
  }

  Widget _inheritRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(children: [
      Icon(icon, size: 12, color: const Color(0xFF60A5FA)),
      const SizedBox(width: 6),
      SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E3A5F)))),
    ]),
  );

  // ── Action Buttons ──
  Widget _buildProfileWarningBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Farmer Profile Required', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF92400E))),
                SizedBox(height: 4),
                Text(
                  'You do not have an AgriSense Farmer Profile yet. '
                  'You can still fill out this form, but saving will automatically create your profile first.\n\n'
                  'For a complete profile, go to Farmer Dashboard → AgriSense Registration.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    final bool blocked = _saving;
    return Column(children: [
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _kGreen),
            foregroundColor: _kGreen,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: blocked ? null : () => _save('Draft'),
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('I-save bilang Draft / Save as Draft', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _saving ? null : () => _save('Pending Verification'),
          icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, size: 18),
          label: const Text('Isumite para sa Verification / Submit for Verification', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }

  // ── Helpers ──
  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: TextFormField(
      controller: controller,
      decoration: _dec(label, hint: hint, maxLength: maxLength),
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
    ),
  );

  Widget _readonlyRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
        child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      ),
      const SizedBox(width: 6),
      const Text('(read-only)', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
    ]),
  );

  Widget _uploadTile(String label, {bool required = false, String? hint}) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Row(children: [
      const Icon(Icons.upload_file_rounded, size: 20, color: Color(0xFF6B7280)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label${required ? ' *' : ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        if (hint != null) Text(hint, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
      ])),
      TextButton(
        onPressed: () => _snack('Document upload coming in Phase 2.'),
        child: const Text('Upload', style: TextStyle(fontSize: 12, color: _kGreen)),
      ),
    ]),
  );

  InputDecoration _dec(String label, {String? hint, int? maxLength}) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    counterText: '',
    isDense: true,
  );
}
