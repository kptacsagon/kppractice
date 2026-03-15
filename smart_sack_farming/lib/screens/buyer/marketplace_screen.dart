import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/endorsement_provider.dart';
import '../../services/market_service.dart';

class MarketplaceScreen extends ConsumerWidget {
  final String buyerId;
  const MarketplaceScreen({super.key, required this.buyerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final endorsementsAsync = ref.watch(openEndorsementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      body: endorsementsAsync.when(
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('No active endorsements'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (c, i) {
              final e = list[i];
              return Card(
                child: ListTile(
                  title: Text('Crop: ${e.plantingRecordId}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Est. start: \u20B1${e.startingBidPrice.toStringAsFixed(2)}'),
                      if (e.currentHighestBid != null) Text('Current: \u20B1${e.currentHighestBid!.toStringAsFixed(2)}'),
                    ],
                  ),
                  trailing: FilledButton(
                    onPressed: () => _openPlaceBid(context, e.id),
                    child: const Text('Place Bid'),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: list.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _openPlaceBid(BuildContext context, String endorsementId) {
    showModalBottomSheet<void>(
      context: context,
      builder: (c) {
        final controller = TextEditingController();
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Place your bid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: controller, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Bid amount')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: FilledButton(onPressed: () async {
                final v = double.tryParse(controller.text);
                if (v == null) return;
                Navigator.of(context).pop();
                try {
                  await MarketService.placeBid(endorsementId: endorsementId, buyerId: buyerId, amount: v);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid placed')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error placing bid: $e')));
                }
              }, child: const Text('Submit')))
            ])
          ],),
        );
      }
    );
  }
}
