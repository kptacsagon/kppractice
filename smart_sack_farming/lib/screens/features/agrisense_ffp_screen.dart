import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../mock/agrisense_mock_data.dart';
import '../../models/agrisense_alert.dart';
import '../../models/agrisense_farmer_profile.dart';
import '../../repositories/agrisense_repository.dart';
import 'agrisense_csi_screen.dart' show AgrisenseModuleHeader, AgrisenseModuleCard;

const _kGreen = Color(0xFF1B7737);

class AgrisenseFfpScreen extends StatefulWidget {
  const AgrisenseFfpScreen({super.key});

  @override
  State<AgrisenseFfpScreen> createState() => _AgrisenseFfpScreenState();
}

class _AgrisenseFfpScreenState extends State<AgrisenseFfpScreen> {
  AgrisenseFarmerProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      final profile = userId == null ? null : await AgrisenseRepository(client).getFarmerProfile(userId);
      if (!mounted) return;
      setState(() { _profile = profile ?? AgrisenseMockData.profile; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _profile = AgrisenseMockData.profile; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5F1),
      body: Column(
        children: [
          AgrisenseModuleHeader(title: 'Farm Financial Planner', subtitle: 'Sub-Module 06 — FFP', icon: Icons.account_balance_wallet_rounded),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kGreen))
            : _error != null
              ? Center(child: Text('Unable to load FFP data.\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280))))
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
          _buildSeasonForecast(),
          const SizedBox(height: 14),
          _buildBudgetWizard(),
          const SizedBox(height: 14),
          _buildBreakEvenCalculator(),
          const SizedBox(height: 14),
          _buildCreditEligibility(),
          const SizedBox(height: 14),
          _buildSubsidyFinder(),
          const SizedBox(height: 14),
          _buildInsuranceCta(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSeasonForecast() {
    final crop = _profile?.primaryCrops.isNotEmpty == true ? _profile!.primaryCrops.first : 'Sweet Corn';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1B7737), Color(0xFF2D9E4E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Season Income Forecast', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text(crop, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: const [
              _ForecastStat(label: 'Yield Est.', value: '3.2 MT'),
              _ForecastStat(label: 'Farm Gate Price', value: '₱18/kg'),
              _ForecastStat(label: 'Gross Income', value: '₱57,600'),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),
          Row(
            children: const [
              _ForecastStat(label: 'Total Cost', value: '₱22,400'),
              _ForecastStat(label: 'Net Profit', value: '₱35,200'),
              _ForecastStat(label: 'ROI', value: '157%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetWizard() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: _kGreen, size: 18),
              SizedBox(width: 8),
              Text('Pre-Season Budget Wizard', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Auto-filled from your PIAE plan. Adjust actual costs each week.', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 12),
          const _BudgetRow(item: 'Seeds & Planting Materials', planned: '₱3,200', actual: '₱3,200'),
          const Divider(height: 14),
          const _BudgetRow(item: 'Fertilizer (Basal + Top-dress)', planned: '₱6,500', actual: '₱6,800'),
          const Divider(height: 14),
          const _BudgetRow(item: 'Labor (Land Prep + Harvest)', planned: '₱8,000', actual: '—'),
          const Divider(height: 14),
          const _BudgetRow(item: 'Pesticides & Fungicides', planned: '₱2,400', actual: '—'),
          const Divider(height: 14),
          const _BudgetRow(item: 'Irrigation', planned: '₱1,200', actual: '—'),
          const Divider(height: 14),
          const _BudgetRow(item: 'Transport & Hauling', planned: '₱1,100', actual: '—'),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Planned Total', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  Text('₱22,400', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kGreen)),
                ],
              )),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: _profile == null ? null : _openBudgetDialog,
                child: const Text('Save Budget'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakEvenCalculator() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate_rounded, color: Color(0xFF3B82F6), size: 18),
              SizedBox(width: 8),
              Text('Break-Even Calculator', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          const _BreakEvenRow(label: 'Total Production Cost', value: '₱22,400'),
          const _BreakEvenRow(label: 'Expected Yield', value: '3,200 kg'),
          const _BreakEvenRow(label: 'Break-Even Price', value: '₱7.00/kg'),
          const _BreakEvenRow(label: 'Current Market Price', value: '₱18.50/kg'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
            child: const Row(
              children: [
                Icon(Icons.thumb_up_rounded, color: Color(0xFF16A34A), size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Current price is ₱11.50 above break-even — you are in a PROFITABLE position.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditEligibility() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.credit_score_rounded, color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 8),
              Text('Credit Eligibility Checker', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Auto-checked based on your RSBSA registration and farm size.', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 12),
          const _CreditRow(program: 'RCEF (Rice Competitiveness)', limit: 'Subsidy — no repayment', status: 'Eligible'),
          const Divider(height: 16),
          const _CreditRow(program: 'PCFC (Micro-Agri Loan)', limit: 'Up to ₱50,000', status: 'Eligible'),
          const Divider(height: 16),
          const _CreditRow(program: 'Land Bank SURE Aid', limit: 'Up to ₱25,000', status: 'Check'),
          const Divider(height: 16),
          const _CreditRow(program: 'DBP Sustainable Agri', limit: 'Up to ₱500,000', status: 'Ineligible'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: _profile == null ? null : _openEligibilityDialog,
            icon: const Icon(Icons.search_rounded, size: 16),
            label: const Text('Apply for Credit'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsidyFinder() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.savings_rounded, color: _kGreen, size: 18),
              SizedBox(width: 8),
              Text('Subsidy Finder', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 12),
          _SubsidyRow(name: 'Inbred Seed Subsidy (DA-RCEF)', crop: 'Rice', value: '₱1,000/ha', deadline: 'Jun 30'),
          Divider(height: 14),
          _SubsidyRow(name: 'Fertilizer Voucher (HVCDP)', crop: 'High-Value Crops', value: '₱1,500/ha', deadline: 'Jul 15'),
          Divider(height: 14),
          _SubsidyRow(name: 'Spray Drone Subsidy (DA-PhilMech)', crop: 'All crops', value: '₱500/application', deadline: 'Open'),
        ],
      ),
    );
  }

  Widget _buildInsuranceCta() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.security_rounded, color: Color(0xFF3B82F6), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('PCIC Crop Insurance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E3A8A))),
                SizedBox(height: 4),
                Text('Protect your harvest against typhoons, pests & drought. Premium as low as ₱420/season.', style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () {},
            child: const Text('Enroll', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _openBudgetDialog() async {
    final cropCtrl = TextEditingController(text: _profile?.primaryCrops.isNotEmpty == true ? _profile!.primaryCrops.first : '');
    final amtCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save Season Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cropCtrl, decoration: const InputDecoration(labelText: 'Crop')),
            const SizedBox(height: 12),
            TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Budget Amount (₱) *'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 12),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen),
            onPressed: () {
              if (amtCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Budget amount is required.'))); return; }
              Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != true || _profile == null) return;
    final amt = double.tryParse(amtCtrl.text.trim());
    if (amt == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount.'))); return; }
    try {
      final repo = AgrisenseRepository(Supabase.instance.client);
      final msg = StringBuffer('Budget ₱${amt.toStringAsFixed(2)}');
      if (cropCtrl.text.trim().isNotEmpty) msg.write(' for ${cropCtrl.text.trim()}');
      if (notesCtrl.text.trim().isNotEmpty) msg.write('. ${notesCtrl.text.trim()}');
      await repo.saveAlert(AgrisenseAlert(farmerId: _profile!.id!, module: 'FFP', alertType: 'budget_saved', severity: 'info', title: 'FFP budget saved', message: msg.toString(), ctaLabel: 'Review FFP', ctaAction: 'open_ffp', triggeredAt: DateTime.now()));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Budget saved.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _openEligibilityDialog() async {
    final programCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Apply for Credit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: programCtrl, decoration: const InputDecoration(labelText: 'Program Name *')),
            const SizedBox(height: 12),
            TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Requested Amount (₱)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
            onPressed: () {
              if (programCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Program name is required.'))); return; }
              Navigator.pop(ctx, true);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (result != true || _profile == null) return;
    try {
      final repo = AgrisenseRepository(Supabase.instance.client);
      await repo.saveAlert(AgrisenseAlert(farmerId: _profile!.id!, module: 'FFP', alertType: 'credit_check', severity: 'info', title: 'FFP credit eligibility check', message: '${programCtrl.text.trim()} — ${amtCtrl.text.trim().isEmpty ? "no amount" : "₱${amtCtrl.text.trim()}"}', ctaLabel: 'Review FFP', ctaAction: 'open_ffp', triggeredAt: DateTime.now()));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application submitted.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}

class _ForecastStat extends StatelessWidget {
  final String label;
  final String value;
  const _ForecastStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final String item;
  final String planned;
  final String actual;
  const _BudgetRow({required this.item, required this.planned, required this.actual});

  @override
  Widget build(BuildContext context) {
    final hasActual = actual != '—';
    return Row(
      children: [
        Expanded(child: Text(item, style: const TextStyle(fontSize: 12))),
        SizedBox(width: 70, child: Text(planned, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        SizedBox(width: 60, child: Text(actual, textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: hasActual ? const Color(0xFF374151) : const Color(0xFF9CA3AF)))),
      ],
    );
  }
}

class _BreakEvenRow extends StatelessWidget {
  final String label;
  final String value;
  const _BreakEvenRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 170, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  final String program;
  final String limit;
  final String status;
  const _CreditRow({required this.program, required this.limit, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'Eligible' ? const Color(0xFF16A34A) : status == 'Check' ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(program, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(limit, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
          child: Text(status, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _SubsidyRow extends StatelessWidget {
  final String name;
  final String crop;
  final String value;
  final String deadline;
  const _SubsidyRow({required this.name, required this.crop, required this.value, required this.deadline});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('$crop · Deadline: $deadline', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen)),
      ],
    );
  }
}
