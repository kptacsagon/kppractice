import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/endorsement_provider.dart';

class MyMarketScreen extends ConsumerWidget {
  final String farmerId;
  const MyMarketScreen({super.key, required this.farmerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final endorsementsAsync = ref.watch(farmerEndorsementsProvider(farmerId));

    return Scaffold(
      appBar: AppBar(title: const Text('My Market')),
      body: endorsementsAsync.when(
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('No market endorsements yet'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (c, i) {
              final e = list[i];
              return Card(
                child: ListTile(
                  title: Text('Planting: ${e.plantingRecordId}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start: \u20B1${e.startingBidPrice.toStringAsFixed(2)}'),
                      if (e.currentHighestBid != null) Text('Current: \u20B1${e.currentHighestBid!.toStringAsFixed(2)}'),
                    ],
                  ),
                  trailing: Text(e.status),
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
}
