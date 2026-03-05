import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/logbook_model.dart';
import '../../theme/app_theme.dart';

/// Comprehensive digital logbook for recording agronomic events such as
/// fertilizer application, irrigation, weeding, and other farm activities.
class AgronomicLogbookScreen extends StatefulWidget {
  const AgronomicLogbookScreen({super.key});

  @override
  State<AgronomicLogbookScreen> createState() =>
      _AgronomicLogbookScreenState();
}

class _AgronomicLogbookScreenState extends State<AgronomicLogbookScreen> {
  final _client = Supabase.instance.client;
  List<LogbookEntry> _entries = [];
  bool _isLoading = true;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      final data = await _client
          .from('agronomic_logbook')
          .select()
          .eq('farmer_id', userId)
          .order('event_date', ascending: false);
      setState(() {
        _entries = List<LogbookEntry>.from(data.map((e) => LogbookEntry.fromJson(e)));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<LogbookEntry> get _filteredEntries {
    if (_filterType == 'all') return _entries;
    return _entries.where((e) => e.eventType == _filterType).toList();
  }

  double get _totalCosts =>
      _entries.fold<double>(0, (sum, e) => sum + e.cost);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Agronomic Logbook'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadEntries,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEntryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Log Event'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSummaryStrip(),
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEntries.isEmpty
                    ? _buildEmptyState()
                    : _buildLogList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStrip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _summaryItem('${_entries.length}', 'Total Events', Icons.event_note),
          _divider(),
          _summaryItem('₱${_formatNum(_totalCosts)}', 'Total Cost',
              Icons.account_balance_wallet),
          _divider(),
          _summaryItem(
            _entries.isNotEmpty ? _entries.first.eventTypeEmoji : '—',
            'Latest',
            Icons.schedule,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withAlpha(200), size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style:
                  TextStyle(color: Colors.white.withAlpha(180), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
        width: 1, height: 36, color: Colors.white.withAlpha(50));
  }

  Widget _buildFilterBar() {
    final types = ['all', ...LogbookEntry.eventTypes];
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: types.map((t) {
          final selected = _filterType == t;
          final label = t == 'all'
              ? 'All'
              : LogbookEntry(
                      id: '',
                      farmerId: '',
                      eventType: t,
                      eventDate: DateTime.now(),
                      description: '')
                  .eventTypeLabel;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.white : AppTheme.textMedium,
                  )),
              selected: selected,
              selectedColor: AppTheme.primary,
              onSelected: (_) => setState(() => _filterType = t),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = _filteredEntries[index];
        return _buildEntryCard(entry);
      },
    );
  }

  Widget _buildEntryCard(LogbookEntry entry) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.error),
      ),
      confirmDismiss: (_) => _confirmDelete(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(entry.eventTypeEmoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.eventTypeLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        '${entry.eventDate.day}/${entry.eventDate.month}/${entry.eventDate.year}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(entry.description,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMedium,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (entry.cropAffected != null &&
                          entry.cropAffected!.isNotEmpty)
                        _buildTag('🌱 ${entry.cropAffected!}'),
                      if (entry.quantity != null) ...[
                        const SizedBox(width: 6),
                        _buildTag(
                            '${entry.quantity!.toStringAsFixed(1)} ${entry.quantityUnit ?? ""}'),
                      ],
                      if (entry.cost > 0) ...[
                        const SizedBox(width: 6),
                        _buildTag('₱${entry.cost.toStringAsFixed(0)}',
                            color: AppTheme.warning),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primary).withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              color: color ?? AppTheme.primary,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_outlined,
              size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          const Text('No logbook entries yet',
              style: TextStyle(color: AppTheme.textMedium, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Tap + to record your first farm event',
              style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(LogbookEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content:
            Text('Delete "${entry.eventTypeLabel}" from ${entry.eventDate.day}/${entry.eventDate.month}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _client
            .from('agronomic_logbook')
            .delete()
            .eq('id', entry.id);
        _loadEntries();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
    return confirmed ?? false;
  }

  void _showAddEntryDialog() {
    String eventType = 'fertilizer_application';
    final descController = TextEditingController();
    final quantityController = TextEditingController();
    final costController = TextEditingController();
    final cropController = TextEditingController();
    String? quantityUnit = 'kg';
    DateTime eventDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textLight.withAlpha(80),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Log Farm Event',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    // Event Type
                    DropdownButtonFormField<String>(
                      value: eventType,
                      decoration: const InputDecoration(
                        labelText: 'Event Type',
                        prefixIcon: Icon(Icons.category_rounded),
                        isDense: true,
                      ),
                      items: LogbookEntry.eventTypes.map((t) {
                        final e = LogbookEntry(
                            id: '',
                            farmerId: '',
                            eventType: t,
                            eventDate: DateTime.now(),
                            description: '');
                        return DropdownMenuItem(
                          value: t,
                          child: Text(
                              '${e.eventTypeEmoji} ${e.eventTypeLabel}',
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setSheetState(() => eventType = v ?? eventType),
                    ),
                    const SizedBox(height: 12),
                    // Description
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        prefixIcon: Icon(Icons.notes_rounded),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Crop affected
                    TextField(
                      controller: cropController,
                      decoration: const InputDecoration(
                        labelText: 'Crop Affected',
                        prefixIcon: Icon(Icons.eco_rounded),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Quantity + Unit
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              prefixIcon: Icon(Icons.straighten),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: quantityUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              isDense: true,
                            ),
                            items: ['kg', 'liters', 'bags', 'hours', 'units']
                                .map((u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u,
                                          style:
                                              const TextStyle(fontSize: 14)),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setSheetState(() => quantityUnit = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Cost + Date
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: costController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cost (₱)',
                              prefixIcon: Icon(Icons.attach_money),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: ctx,
                                initialDate: eventDate,
                                firstDate: DateTime(2024),
                                lastDate: DateTime.now(),
                              );
                              if (d != null) {
                                setSheetState(() => eventDate = d);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                prefixIcon: Icon(Icons.calendar_today),
                                isDense: true,
                              ),
                              child: Text(
                                '${eventDate.day}/${eventDate.month}/${eventDate.year}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (descController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Please enter a description')),
                            );
                            return;
                          }
                          await _saveEntry(
                            eventType: eventType,
                            description: descController.text.trim(),
                            eventDate: eventDate,
                            quantity:
                                double.tryParse(quantityController.text),
                            quantityUnit: quantityUnit,
                            cost:
                                double.tryParse(costController.text) ?? 0,
                            cropAffected: cropController.text.trim().isEmpty
                                ? null
                                : cropController.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Save Entry'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveEntry({
    required String eventType,
    required String description,
    required DateTime eventDate,
    double? quantity,
    String? quantityUnit,
    double cost = 0,
    String? cropAffected,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      final entry = LogbookEntry(
        id: '',
        farmerId: userId,
        eventType: eventType,
        eventDate: eventDate,
        description: description,
        quantity: quantity,
        quantityUnit: quantityUnit,
        cost: cost,
        cropAffected: cropAffected,
      );
      await _client.from('agronomic_logbook').insert(entry.toJson());
      _loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event logged successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatNum(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}
