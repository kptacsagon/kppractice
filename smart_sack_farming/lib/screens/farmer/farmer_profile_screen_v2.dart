import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/agrisense_farmer_profile.dart';
import '../../repositories/agrisense_repository.dart';

// ─── 48 barangays of Tubungan, Iloilo ────────────────────────────────────────
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

const _kCrops = [
  'Palay (Rice)', 'Corn (White)', 'Corn (Yellow)', 'Sorghum',
  'Cassava', 'Sweet Potato (Kamote)', 'Gabi', 'Ube', 'Singkamas',
  'Eggplant', 'Tomato', 'Ampalaya (Bitter Gourd)', 'Squash', 'Upo', 'Patola',
  'Pechay', 'Kangkong', 'Sitaw (String Beans)', 'Okra',
  'Munggo', 'Kadyos', 'Bataw', 'Peanut',
  'Banana', 'Jackfruit', 'Mango', 'Cacao', 'Coconut', 'Avocado',
  'Lanzones', 'Rambutan', 'Sugarcane', 'Coffee', 'Rubber',
  'Lemongrass', 'Turmeric', 'Ginger', 'Lagundi',
];

// High-value crops only — for preferred crops selection
const _kHighValueCrops = [
  'Eggplant',
  'Ampalaya (Bitter Gourd)',
  'Okra',
  'Sitaw (String Beans)',
  'Squash',
];

const _kGreen = Color(0xFF285437);
const _kGreenDark = Color(0xFF0F2618);
const _kGold = Color(0xFFC49A50);

// ─────────────────────────────────────────────────────────────────────────────

class FarmerProfileScreenV2 extends StatefulWidget {
  const FarmerProfileScreenV2({super.key});

  @override
  State<FarmerProfileScreenV2> createState() => _FarmerProfileScreenV2State();
}

class _FarmerProfileScreenV2State extends State<FarmerProfileScreenV2>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _imagePicker = ImagePicker();

  // ── Personal profile state (profiles table) ──
  final _personalForm = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _landCtrl = TextEditingController();
  String? _selectedSex = 'Prefer not to say';
  String? _selectedPersonalBarangay; // barangay dropdown for personal tab
  DateTime? _dob;
  Map<String, dynamic> _profileData = {};
  String? _photoUrl;
  bool _isUploadingPhoto = false;

  // ── AgriSense profile state (agrisense_farmer_profiles table) ──
  final _agriForm = GlobalKey<FormState>();
  final _rsbsaCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  AgrisenseFarmerProfile? _agriProfile;
  String? _agriBarangay;
  String _agriIrrigation = 'Rainfed';
  String _agriFarmingMethod = 'Conventional';
  String? _agriOwnership;
  String? _agriMarketAccess;
  List<String> _primaryCrops = [];
  List<String> _preferredCrops = [];

  // ── UI state ──
  bool _loading = true;
  bool _isEditing = false;
  bool _isSavingPersonal = false;
  bool _isSavingAgri = false;
  String? _agriProfileId; // agrisense_farmer_profiles.id — used by Farm Registry

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _addressCtrl.dispose(); _ageCtrl.dispose(); _landCtrl.dispose();
    _rsbsaCtrl.dispose(); _expCtrl.dispose(); _contactCtrl.dispose();
    super.dispose();
  }

  // ── Load both profiles ────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) { setState(() => _loading = false); return; }

      // Load personal profile
      try {
        final res = await Supabase.instance.client
            .from('profiles').select().eq('id', user.id).single();
        _profileData = res;
      } on PostgrestException {
        _profileData = {
          'id': user.id, 'email': user.email ?? '',
          'full_name': user.userMetadata?['full_name'] ?? '',
          'phone': user.userMetadata?['phone'] ?? '',
        };
      }
      _populatePersonalControllers();

      // Load AgriSense profile
      final repo = AgrisenseRepository(Supabase.instance.client);
      final agri = await repo.getFarmerProfile(user.id);
      _agriProfile = agri;
      _agriProfileId = agri?.id;
      if (agri != null) _populateAgriControllers(agri);

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _populatePersonalControllers() {
    _nameCtrl.text = _profileData['full_name'] ?? '';
    _emailCtrl.text = _profileData['email'] ?? '';
    _phoneCtrl.text = _profileData['phone'] ?? '';
    _addressCtrl.text = _profileData['address'] ?? '';
    _ageCtrl.text = _profileData['age']?.toString() ?? '';
    _landCtrl.text = _profileData['land_size_ha']?.toString() ?? '';
    _photoUrl = _profileData['profile_photo_url'];
    final sex = _profileData['sex']?.toString().toLowerCase();
    _selectedSex = sex == 'male' ? 'Male' : sex == 'female' ? 'Female' : 'Prefer not to say';
    if (_profileData['date_of_birth'] != null) {
      try { _dob = DateTime.parse(_profileData['date_of_birth'].toString()); } catch (_) {}
    }
    // Barangay — extract from address field ("Barangay, Tubungan, Iloilo" format)
    final addr = (_profileData['address'] as String?) ?? '';
    final firstPart = addr.split(',').first.trim();
    _selectedPersonalBarangay = _kBarangays.contains(firstPart) ? firstPart : null;
  }

  void _populateAgriControllers(AgrisenseFarmerProfile p) {
    _rsbsaCtrl.text = p.rsbsaNumber ?? '';
    _expCtrl.text = p.farmingExperienceYears?.toString() ?? '';
    _contactCtrl.text = p.contactNumber ?? '';
    _agriBarangay = p.barangay.isEmpty ? null : p.barangay;
    _agriIrrigation = p.irrigationAccess ?? 'Rainfed';
    _agriFarmingMethod = p.farmingMethod ?? 'Conventional';
    _agriOwnership = p.farmOwnershipType;
    _agriMarketAccess = p.marketAccess;
    _primaryCrops = List<String>.from(p.primaryCrops);
    _preferredCrops = List<String>.from(p.preferredCrops);
  }

  // ── Save personal profile ─────────────────────────────────────────────────

  Future<void> _savePersonal() async {
    if (!_personalForm.currentState!.validate()) return;
    if (_selectedPersonalBarangay == null) {
      _snack('Please select your barangay.');
      return;
    }
    setState(() => _isSavingPersonal = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final landSizeHa = _landCtrl.text.trim().isNotEmpty ? double.tryParse(_landCtrl.text.trim()) : null;
      final data = {
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        // Store barangay in the address field (profiles table has no dedicated barangay column)
        'address': '$_selectedPersonalBarangay, Tubungan, Iloilo',
        'sex': _selectedSex,
        'age': _ageCtrl.text.trim().isNotEmpty ? int.tryParse(_ageCtrl.text.trim()) : null,
        'date_of_birth': _dob?.toIso8601String().split('T')[0],
        'land_size_ha': landSizeHa,
        'profile_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await Supabase.instance.client.from('profiles').update(data).eq('id', user.id);
      // Also push barangay + land area to user metadata so all feature screens can read
      // without a separate DB query
      try {
        await Supabase.instance.client.auth.updateUser(UserAttributes(data: {
          'barangay': _selectedPersonalBarangay,
          'land_size_ha': landSizeHa?.toString(),
          'full_name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
        }));
      } catch (_) {} // metadata update is best-effort
      _profileData.addAll(data);
      setState(() { _isSavingPersonal = false; _isEditing = false; });
      _snack('Personal profile updated. Barangay and land area saved.', ok: true);
    } catch (e) {
      setState(() => _isSavingPersonal = false);
      _snack('Failed to save: $e');
    }
  }

  // ── Save AgriSense profile ────────────────────────────────────────────────

  Future<void> _saveAgriProfile() async {
    if (!_agriForm.currentState!.validate()) return;
    if (_agriBarangay == null) { _snack('Please select your barangay.'); return; }
    if (_primaryCrops.isEmpty) { _snack('Please select at least one primary crop.'); return; }

    setState(() => _isSavingAgri = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final repo = AgrisenseRepository(Supabase.instance.client);

      final profile = AgrisenseFarmerProfile(
        id: _agriProfileId,
        userId: user.id,
        rsbsaNumber: _rsbsaCtrl.text.trim().isEmpty ? null : _rsbsaCtrl.text.trim(),
        fullName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : (_profileData['full_name'] ?? 'Farmer'),
        sex: (_selectedSex == null || _selectedSex == 'Prefer not to say') ? null : _selectedSex,
        age: _dob != null ? DateTime.now().year - _dob!.year : int.tryParse(_ageCtrl.text.trim()),
        contactNumber: _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
        barangay: _agriBarangay!,
        municipality: 'Tubungan',
        province: 'Iloilo',
        farmingExperienceYears: int.tryParse(_expCtrl.text.trim()),
        irrigationAccess: _agriIrrigation,
        farmingMethod: _agriFarmingMethod,
        primaryCrops: _primaryCrops,
        preferredCrops: _preferredCrops,
        farmOwnershipType: _agriOwnership,
        marketAccess: _agriMarketAccess,
        verificationStatus: _agriProfile?.verificationStatus ?? 'Pending',
      );

      await repo.saveFarmerProfile(profile);

      // Reload to get the DB-generated id (needed by Farm Registry as FK)
      final saved = await repo.getFarmerProfile(user.id);
      _agriProfile = saved;
      _agriProfileId = saved?.id;

      if (!mounted) return;
      setState(() => _isSavingAgri = false);
      _snack('AgriSense profile saved. You can now register farms.', ok: true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingAgri = false);
        _snack('Failed to save AgriSense profile: $e');
      }
    }
  }

  // ── Photo upload ──────────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final img = await _imagePicker.pickImage(source: source, imageQuality: 80, maxWidth: 512, maxHeight: 512);
      if (img == null) return;
      setState(() => _isUploadingPhoto = true);
      final user = Supabase.instance.client.auth.currentUser!;
      final path = 'profile-photos/${user.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await img.readAsBytes();
      await Supabase.instance.client.storage.from('profile-photos').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
      final url = Supabase.instance.client.storage.from('profile-photos').getPublicUrl(path);
      await Supabase.instance.client.from('profiles').update({'profile_photo_url': url}).eq('id', user.id);
      setState(() { _photoUrl = url; _isUploadingPhoto = false; });
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      _snack('Photo upload failed: $e');
    }
  }

  void _showPhotoMenu() => showModalBottomSheet(context: context, builder: (_) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(height: 8),
      ListTile(leading: const Icon(Icons.camera_alt, color: _kGreen), title: const Text('Take Photo'), onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.camera); }),
      ListTile(leading: const Icon(Icons.photo_library, color: _kGreen), title: const Text('Choose from Gallery'), onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.gallery); }),
      const SizedBox(height: 8),
    ],
  ));

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _snack(String msg, {bool ok = false}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), behavior: SnackBarBehavior.floating,
    backgroundColor: ok ? AppTheme.success : AppTheme.error,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    return name.trim().split(' ').where((w) => w.isNotEmpty).map((w) => w[0].toUpperCase()).join().substring(0, name.trim().split(' ').where((w) => w.isNotEmpty).length > 1 ? 2 : 1);
  }

  int _personalCompletion() {
    int c = 0;
    if (_profileData['full_name']?.toString().isNotEmpty ?? false) c++;
    if (_profileData['email']?.toString().isNotEmpty ?? false) c++;
    if (_profileData['phone']?.toString().isNotEmpty ?? false) c++;
    if (_profileData['address']?.toString().isNotEmpty ?? false) c++;
    if (_profileData['land_size_ha'] != null) c++;
    if (_profileData['sex']?.toString().isNotEmpty ?? false) c++;
    if (_profileData['date_of_birth'] != null) c++;
    return ((c / 7) * 100).toInt();
  }

  int _agriCompletion() {
    if (_agriProfile == null) return 0;
    int c = 0;
    if (_agriProfile!.rsbsaNumber?.isNotEmpty ?? false) c++;
    if (_agriProfile!.barangay.isNotEmpty) c++;
    if (_agriProfile!.primaryCrops.isNotEmpty) c++;
    if (_agriProfile!.farmingExperienceYears != null) c++;
    if (_agriProfile!.irrigationAccess != null) c++;
    if (_agriProfile!.farmingMethod != null) c++;
    return ((c / 6) * 100).toInt();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Color(0xFFF6F7F0), body: Center(child: CircularProgressIndicator(color: _kGreen)));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F0),
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _buildHeader()),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(child: TabBarView(controller: _tabs, children: [
              _buildPersonalTab(),
              _buildAgriTab(),
            ])),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_kGreenDark, Color(0xFF081C10)]),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleBtn(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
                  const Text('My Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  _circleBtn(_isEditing ? Icons.check : Icons.edit, () {
                    if (_tabs.index == 0) {
                      _isEditing ? _savePersonal() : setState(() => _isEditing = true);
                    } else {
                      _saveAgriProfile();
                    }
                  }, gold: _isEditing || _tabs.index == 1),
                ],
              ),
              const SizedBox(height: 20),
              // Avatar
              Stack(children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF235332), shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    image: _photoUrl != null ? DecorationImage(image: NetworkImage(_photoUrl!), fit: BoxFit.cover) : null,
                  ),
                  child: _photoUrl == null ? Center(child: Text(_initials(_profileData['full_name'] as String?), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold))) : null,
                ),
                Positioned(bottom: 0, right: 0, child: GestureDetector(
                  onTap: _isUploadingPhoto ? null : _showPhotoMenu,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _kGold, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: _isUploadingPhoto
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                )),
              ]),
              const SizedBox(height: 12),
              Text(_profileData['full_name'] ?? 'Farmer', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_profileData['email'] ?? '', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _badge('FARMER', _kGold),
                if (_agriProfile != null) ...[
                  const SizedBox(width: 8),
                  _badge(_agriProfile!.verificationStatus == 'Verified' ? '✓ AGRISENSE VERIFIED' : 'AGRISENSE ${_agriProfile!.verificationStatus.toUpperCase()}',
                    _agriProfile!.verificationStatus == 'Verified' ? const Color(0xFF16A34A) : const Color(0xFF6B7280)),
                ],
              ]),
              const SizedBox(height: 16),
              // Stats strip
              Container(
                decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _statItem((_profileData['age'] ?? 'N/A').toString(), 'AGE'),
                  _vDivider(),
                  _statItem(_profileData['land_size_ha'] != null ? '${double.parse(_profileData['land_size_ha'].toString()).toStringAsFixed(1)} ha' : 'N/A', 'LAND'),
                  _vDivider(),
                  _statItem(_agriProfile != null ? '${_agriCompletion()}%' : '0%', 'AGRI PROFILE'),
                  _vDivider(),
                  _statItem('${_personalCompletion()}%', 'PROFILE'),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() => Container(
    color: _kGreenDark,
    child: TabBar(
      controller: _tabs,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white54,
      indicatorColor: _kGold,
      indicatorWeight: 3,
      onTap: (_) => setState(() {}),
      tabs: [
        Tab(text: 'Personal Info (${_personalCompletion()}%)'),
        Tab(text: 'AgriSense Profile (${_agriCompletion()}%)'),
      ],
    ),
  );

  // ── Tab 1: Personal Info ──────────────────────────────────────────────────

  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _isEditing ? _buildPersonalEditForm() : _buildPersonalViewMode(),
    );
  }

  Widget _buildPersonalViewMode() {
    // Barangay: use in-memory selection or extract from saved address field
    String brgy = _selectedPersonalBarangay ?? '';
    if (brgy.isEmpty) {
      final addr = (_profileData['address'] as String?) ?? '';
      brgy = addr.split(',').first.trim();
    }
    return Column(children: [
      // Barangay + land area summary banner (pre-fill reference for other features)
      if (brgy.isNotEmpty || _profileData['land_size_ha'] != null)
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF86EFAC))),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded, color: _kGreen, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Profile data auto-fills your declarations',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
              const SizedBox(height: 2),
              Text(
                '${brgy.isNotEmpty ? '📍 $brgy' : '📍 Barangay not set'}'
                '${_profileData['land_size_ha'] != null ? ' · 🌾 ${_profileData['land_size_ha']} ha' : ' · 🌾 Land area not set'}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF166534))),
            ])),
          ]),
        ),
      _infoCard('PERSONAL INFORMATION', [
        _infoRow('FULL NAME', _profileData['full_name'] ?? 'Not set'),
        _infoRow('SEX', _profileData['sex'] ?? 'Not set'),
        _infoRow('DATE OF BIRTH', _dob != null ? DateFormat('MMM d, yyyy').format(_dob!) : 'Not set'),
        _infoRow('BARANGAY', brgy.isNotEmpty ? brgy : 'Not set'),
        _infoRow('MUNICIPALITY / PROVINCE', 'Tubungan, Iloilo'),
      ]),
      const SizedBox(height: 16),
      _infoCard('CONTACT', [
        _infoRow('EMAIL', _profileData['email'] ?? 'Not set'),
        _infoRow('PHONE', _profileData['phone'] ?? 'Not set'),
      ]),
      const SizedBox(height: 16),
      _infoCard('FARM DETAILS', [
        _infoRow('LAND SIZE', _profileData['land_size_ha'] != null ? '${_profileData['land_size_ha']} ha' : 'Not set'),
        _infoRow('AGE', _profileData['age']?.toString() ?? 'Not set'),
      ]),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: () => setState(() => _isEditing = true),
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: const Text('Edit Personal Info', style: TextStyle(fontWeight: FontWeight.w600)),
      )),
    ]);
  }

  Widget _buildPersonalEditForm() {
    return Form(
      key: _personalForm,
      child: Column(children: [
        _formCard('PERSONAL INFORMATION', [
          _formField('Full Name *', _nameCtrl, icon: Icons.person_outline, validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          _dropdownField('Sex', _selectedSex, ['Male', 'Female', 'Prefer not to say'], (v) => setState(() => _selectedSex = v), icon: Icons.wc_rounded),
          const SizedBox(height: 12),
          _dateField('Date of Birth', _dob),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _kBarangays.contains(_selectedPersonalBarangay) ? _selectedPersonalBarangay : null,
            decoration: _dec('Barangay *').copyWith(prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: _kGreen)),
            isExpanded: true,
            hint: const Text('Select your barangay', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
            items: _kBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _selectedPersonalBarangay = v),
            validator: (v) => v == null ? 'Please select your barangay' : null,
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('Municipality: Tubungan · Province: Iloilo', style: TextStyle(fontSize: 10.5, color: Color(0xFF6B7280))),
          ),
        ]),
        const SizedBox(height: 16),
        _formCard('CONTACT', [
          _formField('Email', _emailCtrl, readOnly: true, icon: Icons.email_outlined),
          const SizedBox(height: 12),
          _formField('Phone', _phoneCtrl, icon: Icons.phone_outlined, type: TextInputType.phone),
        ]),
        const SizedBox(height: 16),
        _formCard('FARM DETAILS', [
          _formField('Land Size (ha)', _landCtrl, icon: Icons.landscape_outlined, type: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 12),
          _formField('Age', _ageCtrl, icon: Icons.badge_outlined, type: TextInputType.number),
        ]),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => setState(() => _isEditing = false), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Cancel'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _isSavingPersonal ? null : _savePersonal,
            child: _isSavingPersonal ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          )),
        ]),
      ]),
    );
  }

  // ── Tab 2: AgriSense Profile ──────────────────────────────────────────────

  Widget _buildAgriTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _agriForm,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Status banner
          if (_agriProfile == null)
            _warningBanner(
              'Complete your AgriSense Profile to register farms and access DSS modules. '
              'Your profile must be saved before you can use the Farm Registry.',
            )
          else
            _successBanner('Profile ID: ${_agriProfileId ?? "—"}\nThis ID links your farms to your AgriSense account.'),

          _buildSyncedPersonalCard(),

          _agriSection('RSBSA & IDENTIFICATION', Icons.badge_rounded, [
            _formField('RSBSA Number', _rsbsaCtrl, hint: 'Leave blank if not yet registered', icon: Icons.numbers_rounded),
            const SizedBox(height: 12),
            _formField('Contact Number', _contactCtrl, icon: Icons.phone_rounded, type: TextInputType.phone),
          ]),

          _agriSection('LOCATION — Tubungan, Iloilo', Icons.location_on_rounded, [
            DropdownButtonFormField<String>(
              value: _agriBarangay,
              decoration: _dec('Barangay *'),
              isExpanded: true,
              items: _kBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _agriBarangay = v),
              validator: (v) => v == null ? 'Please select your barangay' : null,
            ),
            const SizedBox(height: 10),
            _readonlyRow('Municipality', 'Tubungan'),
            _readonlyRow('Province', 'Iloilo'),
          ]),

          _agriSection('FARMING PROFILE', Icons.agriculture_rounded, [
            _formField('Farming Experience (years)', _expCtrl, icon: Icons.access_time_rounded, type: TextInputType.number),
            const SizedBox(height: 12),
            _dropdownField('Farming Method *', _agriFarmingMethod, ['Organic', 'Conventional', 'Mixed'],
              (v) => setState(() => _agriFarmingMethod = v ?? 'Conventional'), icon: Icons.biotech_rounded),
            const SizedBox(height: 12),
            _dropdownField('Irrigation Access', _agriIrrigation, ['Rainfed', 'Irrigated', 'Drip Irrigation', 'Deep Well'],
              (v) => setState(() => _agriIrrigation = v ?? 'Rainfed'), icon: Icons.water_drop_rounded),
            const SizedBox(height: 12),
            _dropdownField('Farm Ownership Type', _agriOwnership, ['Owner', 'Tenant', 'Lessee', 'CLOA Holder', 'Ancestral Land Holder'],
              (v) => setState(() => _agriOwnership = v), icon: Icons.home_work_rounded, required: false),
            const SizedBox(height: 12),
            _dropdownField('Market Access', _agriMarketAccess, ['Local Market', 'Trader / Middleman', 'Direct to Consumer', 'Cooperative', 'NFA / Government'],
              (v) => setState(() => _agriMarketAccess = v), icon: Icons.storefront_rounded, required: false),
          ]),

          _agriSection('CROPS', Icons.grass_rounded, [
            const Text('Primary Crops *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5D846D))),
            const SizedBox(height: 4),
            const Text('Select from recommended high-value crops for Tubungan', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: _kHighValueCrops.map((crop) {
              final selected = _primaryCrops.contains(crop);
              return FilterChip(
                label: Text(crop, style: TextStyle(fontSize: 10, color: selected ? Colors.white : const Color(0xFF374151))),
                selected: selected,
                selectedColor: _kGreen,
                backgroundColor: const Color(0xFFF3F4F6),
                onSelected: (v) => setState(() => v ? _primaryCrops.add(crop) : _primaryCrops.remove(crop)),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList()),
            const SizedBox(height: 16),
            const Text('Preferred High-Value Crops (next season)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5D846D))),
            const SizedBox(height: 4),
            const Text('Select from recommended high-value crops for Tubungan', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: _kHighValueCrops.map((crop) {
              final selected = _preferredCrops.contains(crop);
              return FilterChip(
                label: Text(crop, style: TextStyle(fontSize: 10, color: selected ? Colors.white : const Color(0xFF374151))),
                selected: selected,
                selectedColor: const Color(0xFF6366F1),
                backgroundColor: const Color(0xFFF3F4F6),
                onSelected: (v) => setState(() => v ? _preferredCrops.add(crop) : _preferredCrops.remove(crop)),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList()),
          ]),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSavingAgri ? null : _saveAgriProfile,
              icon: _isSavingAgri
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(
                _agriProfile == null ? 'Save AgriSense Profile' : 'Update AgriSense Profile',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),

          if (_agriProfileId != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.link_rounded, color: Color(0xFF16A34A), size: 18),
                const SizedBox(width: 8),
                const Expanded(child: Text(
                  'Your AgriSense profile is linked. You can now register farms in the Farm Registry.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w500),
                )),
              ]),
            ),
          ],
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  // ── Shared UI helpers ─────────────────────────────────────────────────────

  Widget _agriSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(color: Color(0xFFF0F5F1), borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
          child: Row(children: [
            Icon(icon, size: 16, color: _kGreen),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen, letterSpacing: 0.5)),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
      ]),
    );
  }

  Widget _warningBanner(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF59E0B))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.4))),
    ]),
  );

  Widget _successBanner(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF86EFAC))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 11, color: Color(0xFF166534), height: 1.4))),
    ]),
  );

  Widget _readonlyRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
        child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      const SizedBox(width: 6),
      const Text('(fixed)', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
    ]),
  );

  Widget _buildSyncedPersonalCard() {
    final name = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : (_profileData['full_name']?.toString() ?? '—');
    final sex = (_selectedSex == null || _selectedSex == 'Prefer not to say') ? 'Not specified' : _selectedSex!;
    final dob = _dob != null ? DateFormat('MMM d, yyyy').format(_dob!) : 'Not set';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.sync_rounded, color: Color(0xFF2563EB), size: 16),
          SizedBox(width: 8),
          Text('Synced from Personal Info', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
        ]),
        const SizedBox(height: 8),
        _syncRow(Icons.person_rounded, 'Full Name', name),
        _syncRow(Icons.wc_rounded, 'Sex', sex),
        _syncRow(Icons.cake_rounded, 'Date of Birth', dob),
        const SizedBox(height: 4),
        const Text(
          'These fields are inherited from your Personal Info tab and saved together with your AgriSense profile.',
          style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6), height: 1.4),
        ),
      ]),
    );
  }

  Widget _syncRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Icon(icon, size: 13, color: const Color(0xFF60A5FA)),
      const SizedBox(width: 6),
      SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E3A5F)))),
    ]),
  );

  Widget _circleBtn(IconData icon, VoidCallback onTap, {bool gold = false}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: gold ? _kGold.withAlpha(200) : Colors.white.withAlpha(90), shape: BoxShape.circle),
      child: Icon(icon, size: 18, color: gold ? Colors.white : _kGreen),
    ),
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
  );

  Widget _statItem(String val, String lbl) => Expanded(child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(children: [
      Text(val, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(lbl, style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    ]),
  ));

  Widget _vDivider() => Container(width: 1, height: 30, color: Colors.white.withAlpha(40));

  Widget _infoCard(String title, List<Widget> rows) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(color: Color(0xFF5D846D), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1))),
    Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 4, offset: const Offset(0, 1))]),
      child: ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: rows.length, separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (_, i) => Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), child: rows[i])),
    ),
  ]);

  Widget _infoRow(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Color(0xFF8F9F94), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(color: Color(0xFF2A5239), fontSize: 15, fontWeight: FontWeight.w500)),
  ]);

  Widget _formCard(String title, List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(color: Color(0xFF5D846D), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1))),
    Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 4, offset: const Offset(0, 1))]),
      padding: const EdgeInsets.all(16),
      child: Column(children: children),
    ),
  ]);

  Widget _formField(String label, TextEditingController ctrl, {String? hint, bool readOnly = false, TextInputType type = TextInputType.text, IconData? icon, String? Function(String?)? validator}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(0xFF5D846D), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl, readOnly: readOnly, keyboardType: type,
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: Color(0xFFC0CEC3)),
          prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF5D846D), size: 18) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E9E0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E9E0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kGreen, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        validator: validator,
      ),
    ]);
  }

  Widget _dropdownField(String label, String? value, List<String> items, void Function(String?) onChanged, {IconData? icon, bool required = true}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(0xFF5D846D), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: value,
        items: [if (!required) const DropdownMenuItem(value: null, child: Text('— None —', style: TextStyle(color: Color(0xFF9CA3AF)))),
          ...items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13))))],
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF5D846D), size: 18) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E9E0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E9E0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kGreen, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    ]);
  }

  Widget _dateField(String label, DateTime? value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Color(0xFF5D846D), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    const SizedBox(height: 6),
    GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: _dob ?? DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now());
        if (picked != null) setState(() => _dob = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E9E0)), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(value != null ? DateFormat('MMM d, yyyy').format(value) : 'Select date', style: TextStyle(color: value != null ? const Color(0xFF2A5239) : const Color(0xFFC0CEC3), fontSize: 14)),
          const Icon(Icons.calendar_today, size: 16, color: _kGreen),
        ]),
      ),
    ),
  ]);

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E9E0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E9E0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kGreen, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    isDense: true,
  );
}
