import 'package:flutter/material.dart';
import '../../services/marketplace_service.dart';
import '../../theme/app_theme.dart';

class BuyerCropRequestsScreen extends StatefulWidget {
  const BuyerCropRequestsScreen({super.key});

  @override
  State<BuyerCropRequestsScreen> createState() => _BuyerCropRequestsScreenState();
}

class _BuyerCropRequestsScreenState extends State<BuyerCropRequestsScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final requests = await _marketplaceService.getBuyerCropRequestsForAdmin();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load crop requests: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Buyer Crop Requests'),
        backgroundColor: AppTheme.primary,
        actions: [
          IconButton(
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _error!,
            style: const TextStyle(color: AppTheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return const Center(
        child: Text(
          'No buyer crop requests yet.',
          style: TextStyle(color: AppTheme.textMedium),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final req = _requests[index];
        final quantity = (req['requested_quantity_kg'] as num?)?.toDouble();
        final createdAt = (req['created_at'] ?? '').toString();

        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (req['crop_name'] ?? 'Unknown crop').toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Buyer: ${(req['buyer_name'] ?? 'Unknown').toString()}'),
                Text('Quantity: ${quantity?.toStringAsFixed(2) ?? 'N/A'} kg'),
                Text('Status: ${(req['status'] ?? 'pending').toString()}'),
                if ((req['listing_id'] ?? '').toString().isNotEmpty)
                  Text('Listing ID: ${req['listing_id']}'),
                if ((req['farmer_id'] ?? '').toString().isNotEmpty)
                  Text('Farmer ID: ${req['farmer_id']}'),
                if ((req['notes'] ?? '').toString().trim().isNotEmpty)
                  Text('Notes: ${req['notes']}'),
                if (createdAt.isNotEmpty) Text('Created: $createdAt'),
              ],
            ),
          ),
        );
      },
    );
  }
}
