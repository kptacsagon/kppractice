import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/hvc_master_list.dart';
import '../../services/buyer_demand_service.dart';

const _kGreen = Color(0xFF1B7737);
final _php = NumberFormat('#,##0.00', 'en_PH');

// PRD FR-F06 / FR-M05 — Buyer Demand Board (farmers view + MAO posts)
class BuyerDemandBoardScreen extends StatefulWidget {
  final bool maoMode; // true = MAO can post demands
  const BuyerDemandBoardScreen({super.key, this.maoMode = false});

  @override
  State<BuyerDemandBoardScreen> createState() => _BuyerDemandBoardScreenState();
}

class _BuyerDemandBoardScreenState extends State<BuyerDemandBoardScreen> {
  final _svc = BuyerDemandService();
  List<BuyerDemand> _demands = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _svc.getActiveDemands();
    if (mounted) setState(() { _demands = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: _kGreen, foregroundColor: Colors.white, elevation: 0,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Buyer Demand Board', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text('Institutional buyer requests from MAO', style: TextStyle(fontSize: 10, color: Colors.white70)),
        ]),
        actions: [
          if (widget.maoMode)
            TextButton.icon(
              onPressed: _showPostDialog,
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              label: const Text('Post Demand', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: _kGreen))
        : RefreshIndicator(
            onRefresh: _load, color: _kGreen,
            child: _demands.isEmpty
              ? const Center(child: Text('No active buyer requests.', style: TextStyle(color: Color(0xFF6B7280))))
              : Column(children: [
                  _headerBanner(),
                  Expanded(child: ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: _demands.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _demandCard(_demands[i]),
                  )),
                ]),
          ),
    );
  }

  Widget _headerBanner() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(children: [
      const Icon(Icons.storefront_rounded, color: _kGreen, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(
        '${_demands.length} active buyer request${_demands.length == 1 ? "" : "s"} — tap to express supply interest',
        style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
      )),
    ]),
  );

  Widget _demandCard(BuyerDemand d) {
    final urgent = d.daysLeft <= 5;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: urgent ? Border.all(color: const Color(0xFFF59E0B).withAlpha(120)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFE7F1E8), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.shopping_bag_rounded, color: _kGreen, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.cropName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text('Posted by ${d.postedBy}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ])),
          if (urgent) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
            child: const Text('URGENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _stat('Volume Needed', '${d.volumeNeededKg.toStringAsFixed(0)} kg', const Color(0xFF2563EB)),
          _stat('Price Offered', '₱${_php.format(d.priceOfferedPerKg)}/kg', _kGreen),
          _stat('Deadline', '${d.daysLeft}d left', urgent ? const Color(0xFFDC2626) : const Color(0xFF6B7280)),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Expanded(child: Text(d.terms, style: const TextStyle(fontSize: 11, color: Color(0xFF374151)))),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: ElevatedButton(
            onPressed: () => _expressInterest(d),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Express Supply Interest', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          )),
          if (widget.maoMode) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () async { await _svc.closeDemand(d.id); _load(); },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Close', style: TextStyle(fontSize: 12, color: Color(0xFF374151))),
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
  ]));

  void _expressInterest(BuyerDemand d) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Supply Interest Sent'),
      content: Text('Your interest in supplying ${d.cropName} has been recorded. Your BAW and the MAO will contact you with details.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ));
  }

  void _showPostDialog() {
    final cropCtl = TextEditingController();
    final volCtl = TextEditingController();
    final priceCtl = TextEditingController();
    final termsCtl = TextEditingController();
    DateTime deadline = DateTime.now().add(const Duration(days: 7));
    HvcCrop? selectedCrop;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Post Buyer Demand'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<HvcCrop>(
            value: selectedCrop,
            isExpanded: true,
            hint: const Text('Select Crop'),
            decoration: const InputDecoration(labelText: 'Crop', border: OutlineInputBorder()),
            items: kHvcMasterList.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) { setDialogState(() => selectedCrop = v); cropCtl.text = v?.displayName ?? ''; },
          ),
          const SizedBox(height: 10),
          TextField(controller: volCtl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Volume Needed (kg)', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: priceCtl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price Offered (₱/kg)', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: termsCtl,
            decoration: const InputDecoration(labelText: 'Terms (pickup, delivery, etc.)', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Deadline: ${deadline.day}/${deadline.month}/${deadline.year}'),
            trailing: const Icon(Icons.calendar_today_rounded, size: 18),
            onTap: () async {
              final picked = await showDatePicker(context: ctx,
                initialDate: deadline, firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)));
              if (picked != null) setDialogState(() => deadline = picked);
            },
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white),
            onPressed: () async {
              if (selectedCrop == null || volCtl.text.isEmpty || priceCtl.text.isEmpty) return;
              final user = Supabase.instance.client.auth.currentUser;
              await _svc.postDemand(BuyerDemand(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                cropName: selectedCrop!.displayName,
                volumeNeededKg: double.tryParse(volCtl.text) ?? 0,
                priceOfferedPerKg: double.tryParse(priceCtl.text) ?? 0,
                terms: termsCtl.text.trim(),
                deadline: deadline,
                postedBy: user?.userMetadata?['full_name'] as String? ?? 'MAO',
                status: 'active',
                createdAt: DateTime.now(),
              ));
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
            },
            child: const Text('Post'),
          ),
        ],
      ),
    ));
  }
}
