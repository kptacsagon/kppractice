import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/crop_declaration_service.dart';
import '../auth/login_screen.dart';
import '../features/buyer_demand_board_screen.dart';
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
    if (mounted) setState(() {
      _pendingCount = pending.length;
      _validatedCount = validated.length;
      _upcomingHarvestCount = upcoming;
      _pendingFarmCount = farmCount;
    });
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
