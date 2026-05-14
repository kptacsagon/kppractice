import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../mock/agrisense_mock_data.dart';
import '../../models/agrisense_farmer_profile.dart';
import '../../models/agrisense_pest_report.dart';
import '../../repositories/agrisense_repository.dart';
import 'agrisense_csi_screen.dart' show AgrisenseModuleHeader, AgrisenseModuleCard;

const _kGreen = Color(0xFF1B7737);

class AgrisensePdewScreen extends StatefulWidget {
  const AgrisensePdewScreen({super.key});

  @override
  State<AgrisensePdewScreen> createState() => _AgrisensePdewScreenState();
}

class _AgrisensePdewScreenState extends State<AgrisensePdewScreen> {
  AgrisenseFarmerProfile? _profile;
  List<AgrisensePestReport> _reports = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() { _loading = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      final profile = userId == null ? null : await AgrisenseRepository(client).getFarmerProfile(userId);
      final resolvedProfile = profile ?? AgrisenseMockData.profile;
      List<AgrisensePestReport> reports = [];
      if (profile != null) {
        reports = await AgrisenseRepository(client).getPestReports(resolvedProfile.municipality);
      }
      if (!mounted) return;
      setState(() {
        _profile = resolvedProfile;
        _reports = reports.isNotEmpty ? reports : AgrisenseMockData.pestReports;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = AgrisenseMockData.profile;
        _reports = AgrisenseMockData.pestReports;
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
          AgrisenseModuleHeader(title: 'Pest & Disease Early Warning', subtitle: 'Sub-Module 04 — PDEW', icon: Icons.bug_report_rounded),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kGreen))
            : _error != null
              ? Center(child: Text('Unable to load PDEW data.\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280))))
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
          _buildTierLegend(),
          const SizedBox(height: 14),
          _buildActiveAlerts(),
          const SizedBox(height: 14),
          _buildIpmGuide(),
          const SizedBox(height: 14),
          _buildSeasonalCalendar(),
          const SizedBox(height: 14),
          _buildReportCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTierLegend() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alert Tier Classification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const _TierRow(tier: 'Tier 1 — Isolated', desc: '1–2 reports, same barangay', color: Color(0xFF6B7280)),
          const _TierRow(tier: 'Tier 2 — Emerging', desc: '3–5 reports, cross-barangay', color: Color(0xFFF59E0B)),
          const _TierRow(tier: 'Tier 3 — Outbreak', desc: '6+ reports or BPI-confirmed', color: Color(0xFFDC2626)),
        ],
      ),
    );
  }

  Widget _buildActiveAlerts() {
    if (_reports.isEmpty) {
      return AgrisenseModuleCard(
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 36),
            const SizedBox(height: 8),
            const Text('No active pest alerts in your area.', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Stay vigilant and report any sightings immediately.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Active Alerts Near You', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final report in _reports.take(4)) ...[
            _AlertReportTile(report: report),
            if (report != _reports.take(4).last) const Divider(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildIpmGuide() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('IPM Action Guide', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Integrated Pest Management — balance chemical and biological controls', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          SizedBox(height: 12),
          _IpmEntry(
            pest: 'Fall Armyworm (FAW)',
            crop: 'Corn',
            chemical: 'Lambda-cyhalothrin 2.5 EC — 1 L/ha at V3–V6 stage',
            biological: 'Releases of Trichogramma egg parasitoids; neem extract spray',
          ),
          Divider(height: 20),
          _IpmEntry(
            pest: 'Brown Planthopper (BPH)',
            crop: 'Rice',
            chemical: 'Imidacloprid 200 SL — 50 ml/ha. Avoid pyrethroid resistance.',
            biological: 'Preserve natural enemies (spiders, Cyrtorhinus bugs). Avoid over-fertilizing.',
          ),
          Divider(height: 20),
          _IpmEntry(
            pest: 'Fruit Borer',
            crop: 'Eggplant / Tomato',
            chemical: 'Spinosad 480 SC — 125 ml/ha at first sign of infestation',
            biological: 'Remove and destroy infected fruits. Install pheromone traps.',
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonalCalendar() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Seasonal Pest Calendar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Historically prevalent pests this month', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          SizedBox(height: 12),
          _SeasonalPestRow(pest: 'Fall Armyworm', risk: 'High', crop: 'Corn'),
          _SeasonalPestRow(pest: 'Brown Planthopper', risk: 'Moderate', crop: 'Rice'),
          _SeasonalPestRow(pest: 'Mites (Spider Mites)', risk: 'Low', crop: 'Eggplant'),
          _SeasonalPestRow(pest: 'Bacterial Wilt', risk: 'Moderate', crop: 'Chili/Tomato'),
        ],
      ),
    );
  }

  Widget _buildReportCard() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.report_problem_rounded, color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 8),
              Text('Report a Pest Sighting', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Submit a sighting for ${_profile?.municipality ?? "your municipality"} to help protect neighboring farms.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: _profile == null ? null : _openReportDialog,
            icon: const Icon(Icons.add_alert_rounded, size: 16),
            label: const Text('Report Sighting'),
          ),
        ],
      ),
    );
  }

  Future<void> _openReportDialog() async {
    final pestController = TextEditingController();
    final cropController = TextEditingController();
    final photoController = TextEditingController();
    String severity = 'Moderate';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Report Pest / Disease'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: pestController, decoration: const InputDecoration(labelText: 'Pest / Disease Type *')),
                const SizedBox(height: 12),
                TextField(controller: cropController, decoration: const InputDecoration(labelText: 'Affected Crop *')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: severity,
                  items: const [
                    DropdownMenuItem(value: 'Mild', child: Text('Mild')),
                    DropdownMenuItem(value: 'Moderate', child: Text('Moderate')),
                    DropdownMenuItem(value: 'Severe', child: Text('Severe')),
                  ],
                  onChanged: (v) => setLocalState(() => severity = v ?? 'Moderate'),
                  decoration: const InputDecoration(labelText: 'Severity'),
                ),
                const SizedBox(height: 12),
                TextField(controller: photoController, decoration: const InputDecoration(labelText: 'Photo URL (optional)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () {
                if (pestController.text.trim().isEmpty || cropController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Pest type and crop are required.')));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );

    if (result != true || _profile == null || !mounted) return;
    try {
      final repo = AgrisenseRepository(Supabase.instance.client);
      await repo.submitPestReport(AgrisensePestReport(
        farmerId: _profile!.id!,
        farmId: null,
        municipality: _profile!.municipality,
        cropType: cropController.text.trim(),
        pestType: pestController.text.trim(),
        severity: severity,
        photoUrl: photoController.text.trim().isEmpty ? null : photoController.text.trim(),
        reportedAt: DateTime.now(),
      ));
      await _loadReports();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pest report submitted.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

}

class _TierRow extends StatelessWidget {
  final String tier;
  final String desc;
  final Color color;
  const _TierRow({required this.tier, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(tier, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 6),
          Text('— $desc', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _AlertReportTile extends StatelessWidget {
  final AgrisensePestReport report;
  const _AlertReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    final sevColor = report.severity == 'Severe'
        ? const Color(0xFFDC2626)
        : report.severity == 'Moderate'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF6B7280);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: sevColor.withAlpha(20), borderRadius: BorderRadius.circular(6)),
          child: Text(report.severity, style: TextStyle(fontSize: 10, color: sevColor, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(report.pestType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${report.cropType} — ${report.municipality}', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
      ],
    );
  }
}

class _IpmEntry extends StatelessWidget {
  final String pest;
  final String crop;
  final String chemical;
  final String biological;
  const _IpmEntry({required this.pest, required this.crop, required this.chemical, required this.biological});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pest_control_rounded, size: 14, color: Color(0xFFDC2626)),
            const SizedBox(width: 6),
            Text(pest, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFF0F5F1), borderRadius: BorderRadius.circular(6)),
              child: Text(crop, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _IpmRow(label: 'Chemical', text: chemical, color: const Color(0xFFDC2626)),
        const SizedBox(height: 4),
        _IpmRow(label: 'Biological', text: biological, color: const Color(0xFF16A34A)),
      ],
    );
  }
}

class _IpmRow extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  const _IpmRow({required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(4)),
          child: Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF374151)))),
      ],
    );
  }
}

class _SeasonalPestRow extends StatelessWidget {
  final String pest;
  final String risk;
  final String crop;
  const _SeasonalPestRow({required this.pest, required this.risk, required this.crop});

  @override
  Widget build(BuildContext context) {
    final color = risk == 'High' ? const Color(0xFFDC2626) : risk == 'Moderate' ? const Color(0xFFF59E0B) : const Color(0xFF16A34A);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pest, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(crop, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
            child: Text(risk, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
