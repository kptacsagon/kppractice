import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

/// Admin screen for managing market prices for all crop types.
/// Only accessible to users with 'admin' or 'mao' roles.
class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  List<Map<String, dynamic>> _prices = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('market_prices')
          .select()
          .order('crop_type', ascending: true);

      setState(() {
        _prices = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.adminColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.price_change_rounded,
                color: AppTheme.adminColor, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Market Prices',
              style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.primary),
            onPressed: () => _showPriceDialog(null),
            tooltip: 'Add Crop Price',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: 16),
            Text('Error loading prices',
                style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPrices,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ]),
        ),
      );
    }

    if (_prices.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.price_check_rounded,
              color: AppTheme.textLight.withAlpha(100), size: 64),
          const SizedBox(height: 16),
          const Text('No market prices yet',
              style: TextStyle(color: AppTheme.textMedium, fontSize: 16)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _showPriceDialog(null),
            icon: const Icon(Icons.add),
            label: const Text('Add First Price'),
          ),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPrices,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _prices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildPriceCard(_prices[index]),
      ),
    );
  }

  Widget _buildPriceCard(Map<String, dynamic> price) {
    final cropType = price['crop_type'] as String? ?? 'Unknown';
    final pricePerKg = (price['price_per_kg'] as num?)?.toDouble() ?? 0.0;
    final priceDate = price['price_date'] as String? ?? '';
    final trend = (price['trend'] as String?) ?? 'stable';
    final source = price['source'] as String? ?? '';
    final id = price['id'] as String;

    IconData trendIcon;
    Color trendColor;
    switch (trend.toLowerCase()) {
      case 'rising':
        trendIcon = Icons.trending_up_rounded;
        trendColor = AppTheme.success;
        break;
      case 'falling':
        trendIcon = Icons.trending_down_rounded;
        trendColor = AppTheme.error;
        break;
      default:
        trendIcon = Icons.trending_flat_rounded;
        trendColor = AppTheme.textMedium;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Row(children: [
        // Trend indicator
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: trendColor.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(trendIcon, color: trendColor, size: 22),
        ),
        const SizedBox(width: 14),

        // Crop info
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cropType,
                style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(children: [
              Text('₱${pricePerKg.toStringAsFixed(2)}/kg',
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: trendColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(trend.toUpperCase(),
                    style: TextStyle(
                        color: trendColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            if (priceDate.isNotEmpty || source.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${priceDate.isNotEmpty ? priceDate : ''}'
                  '${source.isNotEmpty ? ' • $source' : ''}',
                  style:
                      const TextStyle(color: AppTheme.textLight, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ]),
        ),

        // Actions
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.textMedium),
          onSelected: (action) {
            if (action == 'edit') {
              _showPriceDialog(price);
            } else if (action == 'delete') {
              _confirmDelete(id, cropType);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ]),
    );
  }

  void _showPriceDialog(Map<String, dynamic>? existing) {
    final isEditing = existing != null;
    final cropController =
        TextEditingController(text: existing?['crop_type'] ?? '');
    final priceController = TextEditingController(
        text: existing != null
            ? (existing['price_per_kg'] as num).toString()
            : '');
    final sourceController =
        TextEditingController(text: existing?['source'] ?? 'Manual Entry');
    String selectedTrend = (existing?['trend'] as String?) ?? 'stable';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(isEditing ? 'Edit Price' : 'Add Crop Price',
                style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: cropController,
                  decoration: InputDecoration(
                    labelText: 'Crop Type',
                    hintText: 'e.g., Rice (Palay)',
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                  enabled: !isEditing,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Price per kg (₱)',
                    hintText: '0.00',
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedTrend,
                  decoration: InputDecoration(
                    labelText: 'Price Trend',
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'rising', child: Text('📈 Rising')),
                    DropdownMenuItem(value: 'stable', child: Text('➡️ Stable')),
                    DropdownMenuItem(value: 'falling', child: Text('📉 Falling')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedTrend = v);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: sourceController,
                  decoration: InputDecoration(
                    labelText: 'Data Source',
                    hintText: 'e.g., PSA, DA-BAS',
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                ),
              ]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final crop = cropController.text.trim();
                  final price =
                      double.tryParse(priceController.text.trim()) ?? 0;
                  final source = sourceController.text.trim();

                  if (crop.isEmpty || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Crop type and valid price are required')),
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  try {
                    if (isEditing) {
                      await Supabase.instance.client
                          .from('market_prices')
                          .update({
                            'price_per_kg': price,
                            'trend': selectedTrend,
                            'source': source,
                            'price_date': DateTime.now()
                                .toIso8601String()
                                .substring(0, 10),
                          })
                          .eq('id', existing['id']);
                    } else {
                      await Supabase.instance.client
                          .from('market_prices')
                          .insert({
                        'crop_type': crop,
                        'price_per_kg': price,
                        'trend': selectedTrend,
                        'source': source,
                        'price_date':
                            DateTime.now().toIso8601String().substring(0, 10),
                      });
                    }
                    await _loadPrices();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(isEditing
                                ? 'Price updated'
                                : 'Price added')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: Text(isEditing ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(String id, String cropType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Price',
            style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        content: Text(
            'Are you sure you want to delete the price for "$cropType"?',
            style: const TextStyle(color: AppTheme.textMedium)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client
                    .from('market_prices')
                    .delete()
                    .eq('id', id);
                await _loadPrices();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Price deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
