import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../mock/agrisense_mock_data.dart';
import '../../models/agrisense_alert.dart';
import '../../models/agrisense_farmer_profile.dart';
import '../../repositories/agrisense_repository.dart';
import 'agrisense_csi_screen.dart' show AgrisenseModuleHeader, AgrisenseModuleCard;

const _kGreen = Color(0xFF1B7737);

class AgrisensePhmlScreen extends StatefulWidget {
  const AgrisensePhmlScreen({super.key});

  @override
  State<AgrisensePhmlScreen> createState() => _AgrisensePhmlScreenState();
}

class _AgrisensePhmlScreenState extends State<AgrisensePhmlScreen> {
  AgrisenseFarmerProfile? _profile;
  bool _loading = true;
  String? _error;
  final Map<String, bool> _checklist = {
    '80–85% of panicles are yellow/golden': false,
    'Grain moisture is between 20–22%': false,
    'No wet/rainy weather in next 3 days': false,
    'Harvesting equipment confirmed available': false,
    'Palay sacks and tarpaulins prepared': false,
    'Drying area / flatbed dryer reserved': false,
  };

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
          AgrisenseModuleHeader(title: 'Post-Harvest & Market Linkage', subtitle: 'Sub-Module 07 — PHML', icon: Icons.agriculture_rounded),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kGreen))
            : _error != null
              ? Center(child: Text('Unable to load PHML data.\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280))))
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
          _buildReadinessStatus(),
          const SizedBox(height: 14),
          _buildChecklist(),
          const SizedBox(height: 14),
          _buildStorageGuide(),
          const SizedBox(height: 14),
          _buildMoisturePriceCalc(),
          const SizedBox(height: 14),
          _buildDryingCalendar(),
          const SizedBox(height: 14),
          _buildBuyerMatching(),
          const SizedBox(height: 14),
          _buildPhilMechDirectory(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReadinessStatus() {
    final checked = _checklist.values.where((v) => v).length;
    final total = _checklist.length;
    final ready = checked == total;
    final color = ready ? const Color(0xFF16A34A) : checked >= 4 ? const Color(0xFFF59E0B) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(ready ? Icons.check_circle_rounded : Icons.pending_rounded, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ready ? 'Ready to Harvest!' : checked >= 4 ? 'Almost Ready' : 'Not Yet Ready', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
                const SizedBox(height: 2),
                Text('$checked of $total readiness criteria met', style: TextStyle(fontSize: 12, color: color.withAlpha(180))),
              ],
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withAlpha(20),
            child: Text('${(checked / total * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist_rounded, color: _kGreen, size: 18),
              SizedBox(width: 8),
              Text('Harvest Readiness Checklist', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Check off each criterion before harvesting.', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 10),
          for (final entry in _checklist.entries)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: entry.value,
              onChanged: (v) => setState(() => _checklist[entry.key] = v ?? false),
              activeColor: _kGreen,
              title: Text(entry.key, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildStorageGuide() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.warehouse_rounded, color: Color(0xFF6366F1), size: 18),
              SizedBox(width: 8),
              Text('Post-Harvest Storage Guide', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 12),
          _StorageRow(crop: 'Palay (Rice)', moisture: '14%', temp: '≤ 30°C', duration: 'Up to 3 months', note: 'Use sealed sacks; avoid ground contact'),
          Divider(height: 16),
          _StorageRow(crop: 'Corn (Grain)', moisture: '13%', temp: '≤ 28°C', duration: 'Up to 6 months', note: 'Hermetic bag recommended for aflatoxin control'),
          Divider(height: 16),
          _StorageRow(crop: 'Eggplant / Vegetables', moisture: '—', temp: '10–15°C', duration: '5–10 days', note: 'Refrigerate; do not stack — bruising reduces price'),
        ],
      ),
    );
  }

  Widget _buildMoisturePriceCalc() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop_rounded, color: Color(0xFF3B82F6), size: 18),
              SizedBox(width: 8),
              Text('Moisture-to-Price Deduction Table', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('NFA standard reference for palay grading', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(2)},
            children: const [
              TableRow(children: [
                _TCell('Moisture Content', header: true),
                _TCell('Grade', header: true),
                _TCell('Farm Gate Price', header: true),
              ]),
              TableRow(children: [_TCell('≤ 14%'), _TCell('Premium'), _TCell('₱22.00/kg')]),
              TableRow(children: [_TCell('15–18%'), _TCell('Grade A'), _TCell('₱20.00/kg')]),
              TableRow(children: [_TCell('19–21%'), _TCell('Grade B'), _TCell('₱18.50/kg')]),
              TableRow(children: [_TCell('22–25%'), _TCell('Grade C'), _TCell('₱16.00/kg')]),
              TableRow(children: [_TCell('> 25%'), _TCell('Rejected'), _TCell('Re-dry required')]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDryingCalendar() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.wb_sunny_rounded, color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 8),
              Text('Drying Calendar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 4),
          Text('Estimated sun-drying days to reach target moisture', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          SizedBox(height: 12),
          _DryRow(startMoisture: '25%', targetMoisture: '14%', days: '4–5 days', weather: 'Sunny'),
          Divider(height: 14),
          _DryRow(startMoisture: '22%', targetMoisture: '14%', days: '2–3 days', weather: 'Sunny'),
          Divider(height: 14),
          _DryRow(startMoisture: '20%', targetMoisture: '14%', days: '1–2 days', weather: 'Sunny'),
          Divider(height: 14),
          _DryRow(startMoisture: 'Any', targetMoisture: '14%', days: '4–6 hours', weather: 'Flatbed Dryer'),
        ],
      ),
    );
  }

  Widget _buildBuyerMatching() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.handshake_rounded, color: _kGreen, size: 18),
              SizedBox(width: 8),
              Text('Buyer Matching', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with verified buyers in ${_profile?.municipality ?? "your municipality"}. Requests are forwarded to your MAO.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: _profile == null ? null : _openBuyerDialog,
            icon: const Icon(Icons.search_rounded, size: 16),
            label: const Text('Request Buyer Match'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhilMechDirectory() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.precision_manufacturing_rounded, color: Color(0xFF6366F1), size: 18),
              SizedBox(width: 8),
              Text('PHilMech Equipment Directory', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 4),
          Text('Nearby mechanization services for rent', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          SizedBox(height: 12),
          _PhilMechRow(equipment: 'Combine Harvester', operator: 'Municipal AgriMech Pool', rate: '₱3,500/ha', availability: 'Available'),
          Divider(height: 14),
          _PhilMechRow(equipment: 'Flatbed Dryer', operator: 'LGU Multi-Purpose Center', rate: '₱1,200/batch', availability: 'Available'),
          Divider(height: 14),
          _PhilMechRow(equipment: 'Rice Thresher', operator: 'Cooperative Rental', rate: '₱800/day', availability: 'Booked Jun 20'),
          Divider(height: 14),
          _PhilMechRow(equipment: 'Corn Sheller', operator: 'DA Field Office', rate: '₱600/day', availability: 'Available'),
        ],
      ),
    );
  }

  Future<void> _openBuyerDialog() async {
    final cropCtrl = TextEditingController(text: _profile?.primaryCrops.isNotEmpty == true ? _profile!.primaryCrops.first : '');
    final volCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Request Buyer Match'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: cropCtrl, decoration: const InputDecoration(labelText: 'Crop *')),
              const SizedBox(height: 12),
              TextField(controller: volCtrl, decoration: const InputDecoration(labelText: 'Volume (kg) *'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Target Price (₱/kg)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen),
            onPressed: () {
              if (cropCtrl.text.trim().isEmpty || volCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Crop and volume are required.')));
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (result != true || _profile == null) return;
    final vol = double.tryParse(volCtrl.text.trim());
    if (vol == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid volume.'))); return; }
    try {
      final repo = AgrisenseRepository(Supabase.instance.client);
      final msg = '${cropCtrl.text.trim()}, ${vol.toStringAsFixed(0)} kg${priceCtrl.text.trim().isNotEmpty ? ", target ₱${priceCtrl.text.trim()}/kg" : ""}${notesCtrl.text.trim().isNotEmpty ? ". ${notesCtrl.text.trim()}" : ""}';
      await repo.saveAlert(AgrisenseAlert(farmerId: _profile!.id!, module: 'PHML', alertType: 'buyer_match', severity: 'info', title: 'PHML buyer match request', message: msg, ctaLabel: 'View PHML', ctaAction: 'open_phml', triggeredAt: DateTime.now()));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buyer request submitted.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}

class _StorageRow extends StatelessWidget {
  final String crop;
  final String moisture;
  final String temp;
  final String duration;
  final String note;
  const _StorageRow({required this.crop, required this.moisture, required this.temp, required this.duration, required this.note});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2_rounded, size: 14, color: Color(0xFF6366F1)),
            const SizedBox(width: 6),
            Text(crop, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            _Badge('Moisture: $moisture', const Color(0xFF3B82F6)),
            _Badge('Temp: $temp', const Color(0xFFF59E0B)),
            _Badge(duration, const Color(0xFF16A34A)),
          ],
        ),
        const SizedBox(height: 4),
        Text(note, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _TCell extends StatelessWidget {
  final String text;
  final bool header;
  const _TCell(this.text, {this.header = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: header ? FontWeight.w700 : FontWeight.normal, color: header ? const Color(0xFF374151) : const Color(0xFF6B7280))),
    );
  }
}

class _DryRow extends StatelessWidget {
  final String startMoisture;
  final String targetMoisture;
  final String days;
  final String weather;
  const _DryRow({required this.startMoisture, required this.targetMoisture, required this.days, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$startMoisture → $targetMoisture', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            Text(weather, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          ],
        )),
        Text(days, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B))),
      ],
    );
  }
}

class _PhilMechRow extends StatelessWidget {
  final String equipment;
  final String operator;
  final String rate;
  final String availability;
  const _PhilMechRow({required this.equipment, required this.operator, required this.rate, required this.availability});

  @override
  Widget build(BuildContext context) {
    final available = availability == 'Available';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(equipment, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              Text('$operator · $rate', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: available ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
          child: Text(availability, style: TextStyle(fontSize: 9, color: available ? const Color(0xFF16A34A) : const Color(0xFFD97706), fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
