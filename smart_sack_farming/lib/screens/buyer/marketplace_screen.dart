import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/endorsement_provider.dart';
import '../../models/market_endorsement.dart';
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
                  title: Text(_productTitle(e)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start: \u20B1${e.startingBidPrice.toStringAsFixed(2)}'),
                      Text('Current: \u20B1${_currentBid(e).toStringAsFixed(2)}'),
                      if (e.expectedHarvestDate != null)
                        Text('Harvest: ${_formatDate(e.expectedHarvestDate)}'),
                      if (e.farmerName != null && e.farmerName!.isNotEmpty)
                        Text('Farmer: ${e.farmerName}'),
                    ],
                  ),
                  trailing: FilledButton(
                    onPressed: () => _openPlaceBid(context, e),
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

  void _openPlaceBid(BuildContext context, MarketEndorsement endorsement) {
    showModalBottomSheet<void>(
      context: context,
      builder: (c) {
        final minimumBid = _currentBid(endorsement) + 0.01;
        final controller = TextEditingController(
          text: minimumBid.toStringAsFixed(2),
        );
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Place your bid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: controller, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Bid amount')),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Minimum bid: ₱${minimumBid.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: FilledButton(onPressed: () async {
                final v = double.tryParse(controller.text);
                if (v == null || v < minimumBid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Bid must be at least ₱${minimumBid.toStringAsFixed(2)}')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                try {
                  await MarketService.placeBid(endorsementId: endorsement.id, buyerId: buyerId, amount: v);
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

  String _productTitle(MarketEndorsement endorsement) {
    final crop = endorsement.cropName;
    if (crop != null && crop.trim().isNotEmpty) {
      return crop;
    }
    return 'Product ${endorsement.plantingRecordId.substring(0, 8)}';
  }

  double _currentBid(MarketEndorsement endorsement) {
    return endorsement.currentHighestBid ?? endorsement.startingBidPrice;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
