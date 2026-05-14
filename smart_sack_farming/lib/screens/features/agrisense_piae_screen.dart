import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/agrisense_alert.dart';
import '../../repositories/agrisense_repository.dart';
import 'agrisense_csi_screen.dart' show AgrisenseModuleHeader, AgrisenseModuleCard;

const _kGreen = Color(0xFF1B7737);

class AgrisensePiaeScreen extends StatelessWidget {
  const AgrisensePiaeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5F1),
      body: Column(
        children: [
          AgrisenseModuleHeader(
            title: 'Planting Input & Advisory',
            subtitle: 'Sub-Module 02 — PIAE',
            icon: Icons.grass_rounded,
          ),
          const Expanded(child: _PiaeBody()),
        ],
      ),
    );
  }
}

class _PiaeBody extends StatefulWidget {
  const _PiaeBody();

  @override
  State<_PiaeBody> createState() => _PiaeBodyState();
}

class _PiaeBodyState extends State<_PiaeBody> {
  int? _expandedIndex;

  static const _recommendations = [
    _CropRec(
      crop: 'Sweet Corn',
      score: 87,
      demand: 'High',
      saturation: 'Low',
      climate: 'Excellent',
      soilMatch: 'Good',
      expectedYield: '4.5 MT/ha',
      grossIncome: '₱54,000/ha',
      roi: '62%',
      inputSched: [
        _InputStep('Land Prep', 'Plow and harrow 2–3 times. Apply 2 t/ha compost.'),
        _InputStep('Seeding', 'NSIC Ct12 variety, 20 kg/ha seed rate. Direct seed.'),
        _InputStep('Fertilization', '14-14-14 at 200 kg/ha basal; Urea 100 kg/ha at knee-high.'),
        _InputStep('Irrigation', 'Critical stages: germination, tasseling, grain fill.'),
        _InputStep('Pest Watch', 'Monitor for FAW weekly from V3 stage. Apply Lambda-cyhalothrin if needed.'),
        _InputStep('Harvest', '75–80 days after planting. Harvest at milk to dough stage for fresh market.'),
      ],
    ),
    _CropRec(
      crop: 'Eggplant',
      score: 81,
      demand: 'High',
      saturation: 'Moderate',
      climate: 'Good',
      soilMatch: 'Excellent',
      expectedYield: '25 MT/ha',
      grossIncome: '₱75,000/ha',
      roi: '48%',
      inputSched: [
        _InputStep('Seedbed', 'Raise seedlings in seedbed 25–30 days before transplanting.'),
        _InputStep('Transplanting', 'Space at 75 cm × 60 cm. Water immediately after.'),
        _InputStep('Fertilization', 'Complete fertilizer 14-14-14 at 400 kg/ha; side-dress with Urea every 2 weeks.'),
        _InputStep('Staking', 'Stake plants at 30 cm height to support heavy fruiting.'),
        _InputStep('Pest Watch', 'Monitor for fruit borer and aphids weekly.'),
        _InputStep('Harvest', 'Start 60–70 DAT. Harvest every 3–5 days for continuous yield.'),
      ],
    ),
    _CropRec(
      crop: 'Chili (Siling Labuyo)',
      score: 77,
      demand: 'Moderate',
      saturation: 'Low',
      climate: 'Good',
      soilMatch: 'Good',
      expectedYield: '5 MT/ha',
      grossIncome: '₱60,000/ha',
      roi: '40%',
      inputSched: [
        _InputStep('Seedbed', 'Sow in seedbed 30 days before transplanting at 200g/ha.'),
        _InputStep('Transplanting', 'Space at 50 cm × 50 cm on raised beds. Apply rooting solution.'),
        _InputStep('Fertilization', '14-14-14 basal at 200 kg/ha; foliar feed every 2 weeks.'),
        _InputStep('Mulching', 'Apply plastic or organic mulch to conserve moisture.'),
        _InputStep('Pest Watch', 'Monitor for thrips, aphids, and bacterial wilt.'),
        _InputStep('Harvest', 'Green stage: 60–70 DAT. Red (mature): 80–90 DAT.'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgrisenseModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recommendation Scoring', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(
                  'Crops are ranked by a composite score: Saturation Risk (30%), Market Demand (25%), '
                  'Soil Match (20%), Climate Suitability (15%), Crop History (10%).',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Top 3 Crop Recommendations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 10),
          for (int i = 0; i < _recommendations.length; i++) ...[
            _CropCard(
              rec: _recommendations[i],
              rank: i + 1,
              isExpanded: _expandedIndex == i,
              onToggle: () => setState(() => _expandedIndex = _expandedIndex == i ? null : i),
              onAccept: () => _acceptRecommendation(context, _recommendations[i]),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          _buildRequestPlanCard(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRequestPlanCard(BuildContext context) {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pending_actions_rounded, color: _kGreen, size: 18),
              SizedBox(width: 8),
              Text('Need a DA Technician Visit?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Some recommendations require a farm visit before planting. Request a DA technician for personalized advisory.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _requestVisit(context),
            icon: const Icon(Icons.person_pin_rounded, size: 16),
            label: const Text('Request Visit'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRecommendation(BuildContext context, _CropRec rec) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Accept ${rec.crop}?'),
        content: Text('This will pre-fill a new Planting Intention submission for ${rec.crop}. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Accept & Submit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${rec.crop} accepted. Redirecting to planting submission...')),
    );
  }

  Future<void> _requestVisit(BuildContext context) async {
    final dateController = TextEditingController();
    final noteController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Request DA Visit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Preferred Date (YYYY-MM-DD)')),
            const SizedBox(height: 12),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
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
    );
    if (result != true || !context.mounted) return;

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');
      final repo = AgrisenseRepository(client);
      final profile = await repo.getFarmerProfile(userId);
      if (profile?.id == null) throw Exception('Profile not found');
      await repo.saveAlert(AgrisenseAlert(
        farmerId: profile!.id!,
        module: 'PIAE',
        alertType: 'visit_request',
        severity: 'info',
        title: 'DA Visit Request',
        message: 'Preferred date: ${dateController.text.trim()}. ${noteController.text.trim()}',
        ctaLabel: 'View PIAE',
        ctaAction: 'open_piae',
        triggeredAt: DateTime.now(),
      ));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit request submitted.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}

class _CropRec {
  final String crop;
  final int score;
  final String demand;
  final String saturation;
  final String climate;
  final String soilMatch;
  final String expectedYield;
  final String grossIncome;
  final String roi;
  final List<_InputStep> inputSched;
  const _CropRec({
    required this.crop, required this.score, required this.demand,
    required this.saturation, required this.climate, required this.soilMatch,
    required this.expectedYield, required this.grossIncome, required this.roi,
    required this.inputSched,
  });
}

class _InputStep {
  final String stage;
  final String detail;
  const _InputStep(this.stage, this.detail);
}

class _CropCard extends StatelessWidget {
  final _CropRec rec;
  final int rank;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onAccept;

  const _CropCard({required this.rec, required this.rank, required this.isExpanded, required this.onToggle, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final scoreColor = rec.score >= 85 ? const Color(0xFF16A34A) : rec.score >= 75 ? const Color(0xFFF59E0B) : const Color(0xFF6B7280);
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(rec.crop, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: scoreColor.withAlpha(20), borderRadius: BorderRadius.circular(20)),
                child: Text('${rec.score}/100', style: TextStyle(color: scoreColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rec.score / 100,
              backgroundColor: const Color(0xFFE5E7EB),
              color: scoreColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              _Badge('Demand: ${rec.demand}', const Color(0xFF3B82F6)),
              _Badge('Saturation: ${rec.saturation}', const Color(0xFF16A34A)),
              _Badge('Climate: ${rec.climate}', const Color(0xFF8B5CF6)),
              _Badge('Soil: ${rec.soilMatch}', const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatMini(label: 'Yield', value: rec.expectedYield)),
              const SizedBox(width: 10),
              Expanded(child: _StatMini(label: 'Gross Income', value: rec.grossIncome)),
              const SizedBox(width: 10),
              Expanded(child: _StatMini(label: 'ROI', value: rec.roi)),
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            const Text('Full Input Schedule', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (int i = 0; i < rec.inputSched.length; i++)
              _StepTile(step: rec.inputSched[i], index: i + 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kGreen,
                      side: const BorderSide(color: _kGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onToggle,
                    child: const Text('Collapse'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onAccept,
                    child: const Text('Accept Plan'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onToggle,
              child: Row(
                children: [
                  Text('View Input Schedule', style: TextStyle(color: _kGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: _kGreen, size: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  const _StatMini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final _InputStep step;
  final int index;
  const _StepTile({required this.step, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(color: _kGreen.withAlpha(20), shape: BoxShape.circle),
            child: Center(child: Text('$index', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kGreen))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.stage, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 2),
                Text(step.detail, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
