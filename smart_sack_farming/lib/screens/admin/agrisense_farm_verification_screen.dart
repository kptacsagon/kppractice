import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

const _kGreen = Color(0xFF1B7737);
const _kBg = Color(0xFFF0F5F1);

class AgrisenseFarmVerificationScreen extends StatefulWidget {
  const AgrisenseFarmVerificationScreen({super.key});

  @override
  State<AgrisenseFarmVerificationScreen> createState() =>
      _AgrisenseFarmVerificationScreenState();
}

class _AgrisenseFarmVerificationScreenState
    extends State<AgrisenseFarmVerificationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = true;

  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _verified = [];
  List<Map<String, dynamic>> _needsCorrection = [];
  List<Map<String, dynamic>> _rejected = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      // Join farms with farmer profiles to get farmer name & contact
      final rows = await client
          .from('agrisense_farms')
          .select('''
            *,
            agrisense_farmer_profiles (
              full_name,
              contact_number,
              barangay,
              rsbsa_number
            )
          ''')
          .order('submitted_at', ascending: false);

      final all = List<Map<String, dynamic>>.from(rows as List);
      setState(() {
        // MAO sees farms forwarded by BAW ('BAW Reviewed') — 'Pending Verification' means still with BAW
        _pending = all.where((r) => r['verification_status'] == 'BAW Reviewed').toList();
        _verified = all.where((r) => r['verification_status'] == 'Verified').toList();
        _needsCorrection = all.where((r) => r['verification_status'] == 'Needs Correction').toList();
        _rejected = all.where((r) => r['verification_status'] == 'Flagged' || r['verification_status'] == 'Rejected').toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('[FarmVerification] load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String farmId, String status, {String? note}) async {
    try {
      final payload = <String, dynamic>{'verification_status': status};
      if (note != null && note.isNotEmpty) {
        payload['rejection_note'] = note;
        payload['rejection_reason_code'] = status == 'Needs Correction' ? 'INCOMPLETE_DATA' : 'REJECTED_BY_BAO';
      }
      await Supabase.instance.client
          .from('agrisense_farms')
          .update(payload)
          .eq('id', farmId);
      _snack(status == 'Verified'
          ? 'Farm approved and verified.'
          : status == 'Needs Correction'
              ? 'Correction request sent to farmer.'
              : 'Farm rejected.');
      _load();
    } catch (e) {
      _snack('Failed to update: $e');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );

  void _showActionDialog(Map<String, dynamic> farm) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.rate_review_rounded, color: _kGreen),
          const SizedBox(width: 10),
          Expanded(child: Text(farm['farm_name'] ?? 'Unnamed Farm', style: const TextStyle(fontSize: 15))),
        ]),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogInfoRow('Farmer', _farmerName(farm)),
              _dialogInfoRow('Barangay', farm['barangay'] ?? '—'),
              _dialogInfoRow('Area', '${(farm['total_area_hectares'] ?? 0).toStringAsFixed(4)} ha'),
              _dialogInfoRow('Primary Crop', farm['primary_crop'] ?? '—'),
              _dialogInfoRow('Ownership', farm['ownership_type'] ?? '—'),
              _dialogInfoRow('Submitted', _formatDate(farm['submitted_at'])),
              const SizedBox(height: 16),
              const Text('Correction / Rejection Note (optional):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Explain what needs to be corrected…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF59E0B), side: const BorderSide(color: Color(0xFFF59E0B))),
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(farm['id'], 'Needs Correction', note: noteCtrl.text.trim());
            },
            icon: const Icon(Icons.edit_note_rounded, size: 16),
            label: const Text('Needs Correction'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626), side: const BorderSide(color: Color(0xFFDC2626))),
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(farm['id'], 'Flagged', note: noteCtrl.text.trim());
            },
            icon: const Icon(Icons.block_rounded, size: 16),
            label: const Text('Reject'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(farm['id'], 'Verified');
            },
            icon: const Icon(Icons.verified_rounded, size: 16),
            label: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Widget _dialogInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
      );

  String _farmerName(Map<String, dynamic> farm) {
    final profile = farm['agrisense_farmer_profiles'];
    if (profile is Map) return profile['full_name']?.toString() ?? '—';
    return '—';
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          Container(
            color: _kGreen,
            padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.fact_check_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Farm Verification', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('${_pending.length} pending review', style: const TextStyle(color: Color(0xFFB2D9B8), fontSize: 11)),
                    ]),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    tooltip: 'Refresh',
                  ),
                ]),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabs,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: 'Pending (${_pending.length})'),
                    Tab(text: 'Verified (${_verified.length})'),
                    Tab(text: 'Needs Correction (${_needsCorrection.length})'),
                    Tab(text: 'Rejected (${_rejected.length})'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kGreen))
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _buildList(_pending, showActions: true),
                      _buildList(_verified),
                      _buildList(_needsCorrection, showActions: true),
                      _buildList(_rejected),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> farms, {bool showActions = false}) {
    if (farms.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_outline_rounded, size: 56, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          const Text('No farms in this category.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _kGreen,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: farms.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _FarmReviewCard(
          farm: farms[i],
          farmerName: _farmerName(farms[i]),
          formatDate: _formatDate,
          showActions: showActions,
          onReview: () => _showActionDialog(farms[i]),
        ),
      ),
    );
  }
}

// ─── Farm Review Card ─────────────────────────────────────────────────────────

class _FarmReviewCard extends StatelessWidget {
  final Map<String, dynamic> farm;
  final String farmerName;
  final String Function(dynamic) formatDate;
  final bool showActions;
  final VoidCallback onReview;

  const _FarmReviewCard({
    required this.farm,
    required this.farmerName,
    required this.formatDate,
    required this.showActions,
    required this.onReview,
  });

  static const _statusColors = {
    'Draft': Color(0xFF6B7280),
    'Pending Verification': Color(0xFFF59E0B),
    'Needs Correction': Color(0xFFDC2626),
    'Verified': Color(0xFF16A34A),
    'Flagged': Color(0xFFEF4444),
    'Rejected': Color(0xFFEF4444),
  };

  @override
  Widget build(BuildContext context) {
    final status = farm['verification_status'] ?? 'Draft';
    final color = _statusColors[status] ?? const Color(0xFF6B7280);
    final area = (farm['total_area_hectares'] as num?)?.toStringAsFixed(4) ?? '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
        border: showActions ? Border.all(color: color.withAlpha(60)) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.eco_rounded, color: _kGreen, size: 15),
          const SizedBox(width: 6),
          Expanded(child: Text(farm['farm_name'] ?? 'Unnamed Farm', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        _row(Icons.person_rounded, farmerName),
        _row(Icons.location_on_rounded, '${farm['barangay'] ?? '—'}, Tubungan, Iloilo'),
        _row(Icons.straighten_rounded, '$area ha · ${farm['ownership_type'] ?? '—'}'),
        _row(Icons.grass_rounded, '${farm['primary_crop'] ?? '—'}  ${farm['farming_method'] != null ? "· ${farm['farming_method']}" : ""}'),
        _row(Icons.water_drop_rounded, farm['irrigation_type'] ?? '—'),
        if (farm['submitted_at'] != null)
          _row(Icons.calendar_today_rounded, 'Submitted: ${formatDate(farm['submitted_at'])}'),
        if (farm['rejection_note'] != null && (farm['rejection_note'] as String).isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 13),
              const SizedBox(width: 6),
              Expanded(child: Text(farm['rejection_note'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)))),
            ]),
          ),
        ],
        if (showActions) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onReview,
              icon: const Icon(Icons.rate_review_rounded, size: 16),
              label: const Text('Review Farm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(children: [
      Icon(icon, size: 12, color: const Color(0xFF9CA3AF)),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
    ]),
  );
}
