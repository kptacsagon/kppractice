import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/crop_declaration_service.dart';
import '../../services/agri_financial_input_service.dart';
import '../auth/login_screen.dart';
import '../features/buyer_demand_board_screen.dart';
import '../farmer/agri_financial_input_screen.dart';
import '../farmer/farmer_crop_declaration_screen.dart';
import '../mao/crop_intelligence_screen.dart';
import '../mao/smart_crop_advisor_screen.dart';
import 'baw_validation_queue_screen.dart';

const _kGreen = Color(0xFF1B7737);

// PRD §3.3 — Agricultural Technician (AT) / BAW Dashboard
class BawDashboardScreen extends StatefulWidget {
  const BawDashboardScreen({super.key});

  @override
  State<BawDashboardScreen> createState() => _BawDashboardScreenState();
}

class _BawDashboardScreenState extends State<BawDashboardScreen> {
  final _svc = CropDeclarationService();
  int _pendingCount = 0;
  int _validatedCount = 0;
  int _upcomingHarvestCount = 0;
  int _pendingFarmCount = 0;
  int _pendingFinInputCount = 0;
  final _finSvc = AgriFinancialInputService();

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final pending = await _svc.getPendingDeclarations();
    final validated = await _svc.getValidatedDeclarations();
    final upcoming = validated.where((d) {
      final days = d.expectedHarvestDate.difference(DateTime.now()).inDays;
      return days >= 0 && days <= 30;
    }).length;
    int farmCount = 0;
    try {
      final res = await Supabase.instance.client
          .from('agrisense_farms')
          .select('id')
          .eq('verification_status', 'Pending Verification');
      farmCount = (res as List).length;
    } catch (_) {}
    int finInputCount = 0;
    try {
      final finInputs = await _finSvc.getPendingForBaw();
      finInputCount = finInputs.length;
    } catch (_) {}
    if (mounted) setState(() {
      _pendingCount = pending.length;
      _validatedCount = validated.length;
      _upcomingHarvestCount = upcoming;
      _pendingFarmCount = farmCount;
      _pendingFinInputCount = finInputCount;
    });
  }

  /// Shows a dialog to collect farmer name + RSBSA before launching an assisted-entry screen.
  /// Returns null if the BAW cancelled, otherwise returns the entered farmer info.
  Future<({String name, String rsbsa})?> _promptFarmer(String mode) async {
    final nameCtl = TextEditingController();
    final rsbsaCtl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          Icon(
            mode == 'journal' ? Icons.menu_book_rounded : Icons.eco_rounded,
            color: const Color(0xFF2563EB), size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(
            mode == 'journal' ? 'Assist: Crop Cycle Journal' : 'Assist: Declare Crop',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
        ]),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFCA8A04)),
                SizedBox(width: 6),
                Expanded(child: Text(
                  'Verify the farmer\'s identity (ID or RSBSA card) before entering data on their behalf.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF92400E)))),
              ]),
            ),
            TextFormField(
              controller: nameCtl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Farmer Full Name *',
                hintText: 'e.g. Juan dela Cruz',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Farmer name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: rsbsaCtl,
              decoration: InputDecoration(
                labelText: 'RSBSA No. / Farmer ID',
                hintText: 'e.g. 0600100001234',
                prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
            label: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
        ],
      ),
    );

    if (confirmed != true) return null;
    return (name: nameCtl.text.trim(), rsbsa: rsbsaCtl.text.trim());
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? user?.email ?? 'BAW';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: _kGreen, foregroundColor: Colors.white, elevation: 0,
        title: const Text('BAW / AT Dashboard'),
        actions: [
          IconButton(onPressed: _loadCounts, icon: const Icon(Icons.refresh_rounded)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout_rounded)),
        ],
      ),
      body: RefreshIndicator(onRefresh: _loadCounts, color: _kGreen, child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome, $name', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 2),
          const Text('Validate farmer declarations and submit barangay supply reports.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 18),

          // KPI strip
          Row(children: [
            _kpi('Pending', '$_pendingCount', const Color(0xFFF59E0B), Icons.pending_actions_rounded),
            const SizedBox(width: 10),
            _kpi('Validated', '$_validatedCount', _kGreen, Icons.check_circle_outline_rounded),
            const SizedBox(width: 10),
            _kpi('Harvest 30d', '$_upcomingHarvestCount', const Color(0xFF2563EB), Icons.event_rounded),
          ]),
          const SizedBox(height: 18),

          // Workflow cards (PRD §3.3.2)
          _card(
            icon: Icons.fact_check_rounded, color: _kGreen,
            title: 'Validation Queue',
            subtitle: '$_pendingCount declarations awaiting your review',
            badge: _pendingCount > 0 ? '$_pendingCount' : null,
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BawValidationQueueScreen()));
              _loadCounts();
            },
          ),
          const SizedBox(height: 10),
          _card(
            icon: Icons.agriculture_rounded, color: const Color(0xFF7C3AED),
            title: 'Farm Registry Review',
            subtitle: '$_pendingFarmCount farm registration${_pendingFarmCount == 1 ? '' : 's'} pending BAW review',
            badge: _pendingFarmCount > 0 ? '$_pendingFarmCount' : null,
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BawValidationQueueScreen()));
              _loadCounts();
            },
          ),
          const SizedBox(height: 10),
          _card(
            icon: Icons.calculate_rounded, color: const Color(0xFF2563EB),
            title: 'Financial Model Inputs',
            subtitle: '$_pendingFinInputCount farmer financial input${_pendingFinInputCount == 1 ? '' : 's'} pending verification',
            badge: _pendingFinInputCount > 0 ? '$_pendingFinInputCount' : null,
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BawValidationQueueScreen()));
              _loadCounts();
            },
          ),
          const SizedBox(height: 10),
          _card(
            icon: Icons.event_note_rounded, color: const Color(0xFF2563EB),
            title: 'Harvest Calendar',
            subtitle: 'Timeline of expected harvests in your barangay',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BawValidationQueueScreen())),
          ),
          const SizedBox(height: 10),
          _card(
            icon: Icons.summarize_rounded, color: const Color(0xFFEA8A1A),
            title: 'Barangay Supply Report',
            subtitle: 'Compile and submit monthly supply report to MAO',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supply Report Composer — coming in Phase 2'))),
          ),
          const SizedBox(height: 10),
          _card(
            icon: Icons.shopping_bag_rounded, color: const Color(0xFFEA8A1A),
            title: 'Buyer Demand Board',
            subtitle: 'View institutional buyer requests from MAO',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BuyerDemandBoardScreen())),
          ),
          const SizedBox(height: 10),
          _card(
            icon: Icons.people_outline_rounded, color: const Color(0xFF7C3AED),
            title: 'Farmer Directory',
            subtitle: 'Manage farmers in your assigned barangay',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Farmer Directory — coming in Phase 2'))),
          ),
          const SizedBox(height: 22),

          // ── Intelligence Tools section ────────────────────────────────────
          const Row(children: [
            Icon(Icons.analytics_rounded, size: 14, color: Color(0xFF6B7280)),
            SizedBox(width: 6),
            Text('Intelligence Tools',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280), letterSpacing: 0.4)),
          ]),
          const SizedBox(height: 4),
          const Text(
            'Crop supply analysis and smart planting recommendations for your barangay.',
            style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 10),
          _card(
            icon: Icons.analytics_outlined, color: const Color(0xFF7C3AED),
            title: 'Crop Intelligence',
            subtitle: 'Supply vs demand analysis, saturation levels, harvest forecast',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CropIntelligenceScreen())),
          ),
          const SizedBox(height: 10),
          _card(
            icon: Icons.tips_and_updates_rounded, color: const Color(0xFF7C3AED),
            title: 'Smart Crop Advisor',
            subtitle: 'Crop recommendations and oversupply risk analysis by barangay',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SmartCropAdvisorScreen())),
          ),
          const SizedBox(height: 22),

          // ── Farmer Assistance section ─────────────────────────────────────
          const Row(children: [
            Icon(Icons.support_agent_rounded, size: 14, color: Color(0xFF6B7280)),
            SizedBox(width: 6),
            Text('Farmer Assisted Entry',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280), letterSpacing: 0.4)),
          ]),
          const SizedBox(height: 4),
          const Text(
            'Use these when a farmer cannot submit on their own. Verify their RSBSA card or valid ID first.',
            style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 10),
          _card(
            icon: Icons.menu_book_rounded, color: const Color(0xFF0891B2),
            title: 'Assist: Crop Cycle Journal',
            subtitle: 'Record 6-stage crop cycle on behalf of a farmer',
            onTap: () async {
              final farmer = await _promptFarmer('journal');
              if (farmer == null || !mounted) return;
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AgriFinancialInputScreen(
                  assistedFarmerName: farmer.name,
                  assistedRsbsa: farmer.rsbsa,
                )));
            },
          ),
          const SizedBox(height: 10),
          _card(
            icon: Icons.eco_rounded, color: const Color(0xFF0891B2),
            title: 'Assist: Declare Crop',
            subtitle: 'Submit HVC crop declaration on behalf of a farmer',
            onTap: () async {
              final farmer = await _promptFarmer('declare');
              if (farmer == null || !mounted) return;
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FarmerCropDeclarationScreen(
                  assistedFarmerName: farmer.name,
                  assistedRsbsa: farmer.rsbsa,
                )));
            },
          ),
        ]),
      )),
    );
  }

  Widget _kpi(String label, String value, Color color, IconData icon) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ]),
    ));
  }

  Widget _card({required IconData icon, required Color color, required String title, required String subtitle, String? badge, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ])),
        if (badge != null) Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(12)),
          child: Text(badge, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
      ]),
    ));
  }
}
