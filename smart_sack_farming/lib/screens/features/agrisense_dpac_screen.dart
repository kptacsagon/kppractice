import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../mock/agrisense_mock_data.dart';
import '../../models/agrisense_farmer_profile.dart';
import '../../models/agrisense_program_enrollment.dart';
import '../../repositories/agrisense_repository.dart';
import 'agrisense_csi_screen.dart' show AgrisenseModuleHeader, AgrisenseModuleCard;

const _kGreen = Color(0xFF1B7737);

class AgrisenseDpacScreen extends StatefulWidget {
  const AgrisenseDpacScreen({super.key});

  @override
  State<AgrisenseDpacScreen> createState() => _AgrisenseDpacScreenState();
}

class _AgrisenseDpacScreenState extends State<AgrisenseDpacScreen> {
  AgrisenseFarmerProfile? _profile;
  List<AgrisenseProgramEnrollment> _enrollments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      final repo = AgrisenseRepository(client);
      final profile = userId == null ? null : await repo.getFarmerProfile(userId);
      final resolvedProfile = profile ?? AgrisenseMockData.profile;
      List<AgrisenseProgramEnrollment> enrollments = [];
      if (profile?.id != null) {
        enrollments = await repo.getProgramEnrollments(profile!.id!);
      }
      if (!mounted) return;
      setState(() {
        _profile = resolvedProfile;
        _enrollments = enrollments.isNotEmpty ? enrollments : AgrisenseMockData.programEnrollments;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = AgrisenseMockData.profile;
        _enrollments = AgrisenseMockData.programEnrollments;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5F1),
      body: Column(
        children: [
          AgrisenseModuleHeader(title: 'DA Program Access & Compliance', subtitle: 'Sub-Module 08 — DPAC', icon: Icons.account_balance_rounded),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kGreen))
            : _error != null
              ? Center(child: Text('Unable to load DPAC data.\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280))))
              : _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEligibilitySummary(),
          const SizedBox(height: 14),
          _buildMyEnrollments(),
          const SizedBox(height: 14),
          _buildProgramDirectory(),
          const SizedBox(height: 14),
          _buildDeadlineTracker(),
          const SizedBox(height: 14),
          _buildTechnicianScheduler(),
          const SizedBox(height: 14),
          _buildPcicInsurance(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEligibilitySummary() {
    final hasRsbsa = _profile != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1B7737), Color(0xFF2D9E4E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Eligibility Profile', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Text(_profile?.fullName ?? 'Farmer', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('${_profile?.municipality ?? "Municipality"}, ${_profile?.province ?? "Province"}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              _EligBadge('RSBSA', hasRsbsa),
              const SizedBox(width: 8),
              _EligBadge('ARB', false),
              const SizedBox(width: 8),
              _EligBadge('4Ps', false),
              const SizedBox(width: 8),
              _EligBadge('PWD', false),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasRsbsa ? 'Auto-eligible for RCEF, PUNLA & SURE Aid based on your RSBSA registration.' : 'Complete your RSBSA registration to unlock program eligibility.',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyEnrollments() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_membership_rounded, color: _kGreen, size: 18),
              const SizedBox(width: 8),
              const Text('My Program Enrollments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: _profile == null ? null : _openEnrollmentDialog,
                icon: const Icon(Icons.add_rounded, size: 14, color: _kGreen),
                label: const Text('Add', style: TextStyle(fontSize: 12, color: _kGreen)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_enrollments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No enrollments recorded yet. Tap Add to register a program.', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            )
          else
            for (final e in _enrollments.take(5)) ...[
              _EnrollmentTile(enrollment: e),
              if (e != _enrollments.take(5).last) const Divider(height: 14),
            ],
        ],
      ),
    );
  }

  Widget _buildProgramDirectory() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.library_books_rounded, color: Color(0xFF6366F1), size: 18),
              SizedBox(width: 8),
              Text('DA Program Directory', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 12),
          _ProgramTile(
            name: 'RCEF — Rice Competitiveness Enhancement Fund',
            agency: 'DA / PhilRice',
            benefit: 'Free inbred seeds, fertilizers, farm machinery access',
            eligibility: 'Rice farmers, RSBSA-registered, ≤ 2 ha',
            status: 'Open',
            statusColor: Color(0xFF16A34A),
          ),
          Divider(height: 16),
          _ProgramTile(
            name: 'SURE Aid — Survival & Recovery Assistance',
            agency: 'DA / LANDBANK',
            benefit: '₱5,000 cash assistance + ₱25,000 loan at 0% interest',
            eligibility: 'Farmers affected by calamity or El Niño',
            status: 'Open',
            statusColor: Color(0xFF16A34A),
          ),
          Divider(height: 16),
          _ProgramTile(
            name: 'PUNLA — Puno ng Pagkain at Kabuhayan',
            agency: 'DA',
            benefit: 'Vegetable seeds, seedling kits, technical assistance',
            eligibility: 'Household gardeners, backyard farmers, RSBSA-registered',
            status: 'Open',
            statusColor: Color(0xFF16A34A),
          ),
          Divider(height: 16),
          _ProgramTile(
            name: 'HUWAD — High Value Crops Dev. Program',
            agency: 'DA-HVCDP',
            benefit: 'Planting materials, fertilizer vouchers, market linkage',
            eligibility: 'HVC farmers with ≥ 0.5 ha, registered with HVCDP',
            status: 'Seasonal',
            statusColor: Color(0xFFF59E0B),
          ),
          Divider(height: 16),
          _ProgramTile(
            name: 'PCFC Micro-Agri Loan',
            agency: 'PCFC',
            benefit: 'Up to ₱50,000 production loan at low interest',
            eligibility: 'RSBSA-registered, no delinquent loans, with agri plan',
            status: 'Open',
            statusColor: Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineTracker() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.alarm_rounded, color: Color(0xFFDC2626), size: 18),
              SizedBox(width: 8),
              Text('Program Deadline Tracker', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 12),
          _DeadlineRow(program: 'RCEF Seed Subsidy Application', deadline: 'Jun 30, 2026', daysLeft: 16, urgent: true),
          Divider(height: 14),
          _DeadlineRow(program: 'SURE Aid Calamity Application', deadline: 'Jul 15, 2026', daysLeft: 31, urgent: false),
          Divider(height: 14),
          _DeadlineRow(program: 'HUWAD Fertilizer Voucher Claim', deadline: 'Jul 20, 2026', daysLeft: 36, urgent: false),
          Divider(height: 14),
          _DeadlineRow(program: 'PCIC Crop Insurance Enrollment', deadline: 'Jun 25, 2026', daysLeft: 11, urgent: true),
        ],
      ),
    );
  }

  Widget _buildTechnicianScheduler() {
    final municipality = _profile?.municipality ?? 'your municipality';
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_pin_circle_rounded, color: _kGreen, size: 18),
              SizedBox(width: 8),
              Text('DA Technician Scheduler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Request an Agricultural Technologist (ATO) or Municipal Agriculturist visit for $municipality.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 10),
          const _TechnicianRow(name: 'Maria Santos', title: 'Municipal Agriculturist', contact: '0917-543-2100', available: true),
          const Divider(height: 14),
          const _TechnicianRow(name: 'Jose Reyes', title: 'Agricultural Technologist', contact: '0928-111-2233', available: true),
          const Divider(height: 14),
          const _TechnicianRow(name: 'Ana Cruz', title: 'Agricultural Technologist', contact: '0905-987-0011', available: false),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: _profile == null ? null : _openTechnicianDialog,
            icon: const Icon(Icons.calendar_today_rounded, size: 16),
            label: const Text('Schedule a Visit'),
          ),
        ],
      ),
    );
  }

  Widget _buildPcicInsurance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security_rounded, color: Color(0xFF3B82F6), size: 18),
              SizedBox(width: 8),
              Text('PCIC Crop Insurance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E3A8A))),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Insure your crops against typhoon, drought, pest, and disease losses. '
            'Premium starts at ₱420/ha/season. Claim up to ₱25,000/ha.',
            style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _InsuranceRow(label: 'Coverage', value: 'Rice, Corn, HVCs'),
                    _InsuranceRow(label: 'Premium', value: '₱420–₱2,200/ha'),
                    _InsuranceRow(label: 'Indemnity', value: 'Up to ₱25,000/ha'),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {},
                child: const Text('Enroll Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openEnrollmentDialog() async {
    final programCtrl = TextEditingController();
    String status = 'Active';
    final expiryCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Program Enrollment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: programCtrl, decoration: const InputDecoration(labelText: 'Program Name *')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                ],
                onChanged: (v) => setLS(() => status = v ?? 'Active'),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 12),
              TextField(controller: expiryCtrl, decoration: const InputDecoration(labelText: 'Expiry Date (YYYY-MM-DD)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kGreen),
              onPressed: () {
                if (programCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Program name is required.'))); return; }
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result != true || _profile == null || !mounted) return;
    DateTime? expiry;
    if (expiryCtrl.text.trim().isNotEmpty) {
      expiry = DateTime.tryParse(expiryCtrl.text.trim());
      if (expiry == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid expiry date.'))); return; }
    }
    try {
      final repo = AgrisenseRepository(Supabase.instance.client);
      await repo.saveProgramEnrollment(AgrisenseProgramEnrollment(farmerId: _profile!.id!, programName: programCtrl.text.trim(), status: status, enrolledDate: DateTime.now(), expiryDate: expiry));
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enrollment saved.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _openTechnicianDialog() async {
    String? visitType = 'Farm Visit';
    final dateCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Request Technician Visit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: visitType,
                items: const [
                  DropdownMenuItem(value: 'Farm Visit', child: Text('Farm Visit')),
                  DropdownMenuItem(value: 'Soil Test', child: Text('Soil Test')),
                  DropdownMenuItem(value: 'Pest Diagnosis', child: Text('Pest Diagnosis')),
                  DropdownMenuItem(value: 'Loan / Subsidy Assistance', child: Text('Loan / Subsidy Assistance')),
                ],
                onChanged: (v) => setLS(() => visitType = v),
                decoration: const InputDecoration(labelText: 'Visit Type'),
              ),
              const SizedBox(height: 12),
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Preferred Date (YYYY-MM-DD)')),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes / Concerns'), maxLines: 2),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kGreen),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Request'),
            ),
          ],
        ),
      ),
    );
    if (result != true) return;
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Technician visit request submitted. MAO will confirm within 2 business days.')));
  }
}

class _EligBadge extends StatelessWidget {
  final String label;
  final bool active;
  const _EligBadge(this.label, this.active);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.white.withAlpha(30) : Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: active ? Colors.white54 : Colors.white24),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: active ? Colors.white : Colors.white38, fontWeight: FontWeight.w700)),
    );
  }
}

class _EnrollmentTile extends StatelessWidget {
  final AgrisenseProgramEnrollment enrollment;
  const _EnrollmentTile({required this.enrollment});

  @override
  Widget build(BuildContext context) {
    final statusColor = enrollment.status == 'Active' ? const Color(0xFF16A34A) : enrollment.status == 'Pending' ? const Color(0xFFF59E0B) : const Color(0xFF6B7280);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(enrollment.programName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('Enrolled: ${enrollment.enrolledDate?.toIso8601String().split('T')[0] ?? '—'}', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(6)),
          child: Text(enrollment.status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _ProgramTile extends StatelessWidget {
  final String name;
  final String agency;
  final String benefit;
  final String eligibility;
  final String status;
  final Color statusColor;
  const _ProgramTile({required this.name, required this.agency, required this.benefit, required this.eligibility, required this.status, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(6)),
              child: Text(status, style: TextStyle(fontSize: 9, color: statusColor, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('Agency: $agency', style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.star_rounded, size: 11, color: Color(0xFF16A34A)),
            const SizedBox(width: 4),
            Expanded(child: Text(benefit, style: const TextStyle(fontSize: 11, color: Color(0xFF374151)))),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.person_rounded, size: 11, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 4),
            Expanded(child: Text(eligibility, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)))),
          ],
        ),
      ],
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  final String program;
  final String deadline;
  final int daysLeft;
  final bool urgent;
  const _DeadlineRow({required this.program, required this.deadline, required this.daysLeft, required this.urgent});

  @override
  Widget build(BuildContext context) {
    final color = urgent ? const Color(0xFFDC2626) : const Color(0xFF6B7280);
    return Row(
      children: [
        Icon(urgent ? Icons.warning_amber_rounded : Icons.event_rounded, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(program, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(deadline, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(6)),
          child: Text('$daysLeft days', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _TechnicianRow extends StatelessWidget {
  final String name;
  final String title;
  final String contact;
  final bool available;
  const _TechnicianRow({required this.name, required this.title, required this.contact, required this.available});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 18, backgroundColor: const Color(0xFFF0F5F1), child: Text(name[0], style: const TextStyle(color: _kGreen, fontWeight: FontWeight.w700))),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              Text('$title · $contact', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(color: available ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
          child: Text(available ? 'Available' : 'Busy', style: TextStyle(fontSize: 9, color: available ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF), fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _InsuranceRow extends StatelessWidget {
  final String label;
  final String value;
  const _InsuranceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)))),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
        ],
      ),
    );
  }
}
