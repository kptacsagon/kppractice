import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/planting_record.dart';
import '../../services/market_service.dart';
import '../../services/harvest_calculator.dart';
import '../../providers/mao_provider.dart';

class HarvestDashboard extends ConsumerWidget {
  final String maoId;
  const HarvestDashboard({super.key, required this.maoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantingsAsync = ref.watch(upcomingPlantingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Harvest Dashboard')),
      body: plantingsAsync.when(
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('No upcoming harvests'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (c, i) {
              final p = list[i];
              final daysLeft = HarvestCalculator.daysUntilHarvest(p.expectedHarvestDate);
              Color tagColor = Colors.grey;
              if (daysLeft <= 14) tagColor = Colors.red;
              else if (daysLeft <= 30) tagColor = Colors.orange;

              return Card(
                child: ListTile(
                  title: Text('${p.cropName.name} — ${p.farmerId}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Expected: ${p.expectedHarvestDate.toLocal()}'.split(' ')[0]),
                      Text('Est. yield: ${p.estimatedYieldMt} MT'),
                      const SizedBox(height: 6),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(12)),
                          child: Text('$daysLeft days', style: const TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => _endorse(context, ref, p),
                          child: const Text('Endorse to Market'),
                        ),
                      ])
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _endorse(BuildContext context, WidgetRef ref, PlantingRecord record) async {
    final controller = TextEditingController(text: '50.00');
    final starting = await showDialog<double?>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Set starting bid price'),
        content: TextField(controller: controller, keyboardType: TextInputType.numberWithOptions(decimal: true)),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(null), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(c).pop(double.tryParse(controller.text)), child: const Text('Publish')),
        ],
      ),
    );

    if (starting == null) return;

    try {
      await MarketService.requestEndorsement(plantingRecordId: record.id, maoId: maoId, startingBid: starting);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Endorsement published')));
      ref.refresh(upcomingPlantingsProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
