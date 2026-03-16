import 'package:flutter/material.dart';
import '../../services/marketplace_service.dart';
import '../../theme/app_theme.dart';

class BuyerMessagesScreen extends StatefulWidget {
  const BuyerMessagesScreen({super.key});

  @override
  State<BuyerMessagesScreen> createState() => _BuyerMessagesScreenState();
}

class _BuyerMessagesScreenState extends State<BuyerMessagesScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final TextEditingController _cropController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  DateTime? _preferredCollectionDate;

  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _cropController.dispose();
    _quantityController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messages = await _marketplaceService.getCurrentBuyerCropRequests();
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load messages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final crop = _cropController.text.trim();
    final qty = double.tryParse(_quantityController.text.trim());

    if (crop.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter crop name.')),
      );
      return;
    }
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity.')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await _marketplaceService.submitCropRequestToAdmin(
        cropName: crop,
        requestedQuantityKg: qty,
        preferredCollectionDate: _preferredCollectionDate,
        notes: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );

      if (!mounted) return;
      _cropController.clear();
      _quantityController.clear();
      _messageController.clear();
      setState(() => _preferredCollectionDate = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent to admin.'),
          backgroundColor: AppTheme.success,
        ),
      );
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      final errorText = e.toString();
      if (errorText.toLowerCase().contains('not set up in the database')) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Database Setup Required'),
            content: const Text(
              'Buyer messaging table is not created yet in Supabase.\n\n'
              'Run the SQL in supabase_migration_v1_to_v2.sql using Supabase SQL Editor, then try again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Message Admin'),
        backgroundColor: AppTheme.primary,
        actions: [
          IconButton(
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [AppTheme.cardShadow],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _cropController,
                  decoration: const InputDecoration(
                    labelText: 'Crop/Product',
                    hintText: 'e.g. Rice',
                    prefixIcon: Icon(Icons.grass_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Quantity (kg)',
                    hintText: 'e.g. 200',
                    prefixIcon: Icon(Icons.scale_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _messageController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Tell admin what you want to buy...',
                    prefixIcon: Icon(Icons.message_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month_rounded,
                      color: AppTheme.primary),
                  title: Text(
                    _preferredCollectionDate == null
                        ? 'Preferred Collection Date (Optional)'
                        : 'Collect on: ${_preferredCollectionDate!.toIso8601String().split('T')[0]}',
                    style: TextStyle(
                      color: _preferredCollectionDate == null
                          ? AppTheme.textLight
                          : AppTheme.textDark,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_drop_down_rounded),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _preferredCollectionDate ?? now,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _preferredCollectionDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_isSending) return;
                      _sendMessage();
                    },
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_isSending ? 'Sending...' : 'Send to Admin'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildMessageList()),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(_error!, style: const TextStyle(color: AppTheme.error)),
        ),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet. Send your first crop request to admin.',
          style: TextStyle(color: AppTheme.textMedium),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: _messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final qty = (msg['requested_quantity_kg'] as num?)?.toDouble();
        final preferredDate = (msg['preferred_collection_date'] ?? '').toString();

        return Card(
          child: ListTile(
            title: Text((msg['crop_name'] ?? 'Unknown crop').toString()),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quantity: ${qty?.toStringAsFixed(2) ?? 'N/A'} kg'),
                Text('Status: ${(msg['status'] ?? 'pending').toString()}'),
                if (preferredDate.isNotEmpty)
                  Text('Collection Date: $preferredDate'),
                if ((msg['notes'] ?? '').toString().trim().isNotEmpty)
                  Text('Message: ${msg['notes']}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
