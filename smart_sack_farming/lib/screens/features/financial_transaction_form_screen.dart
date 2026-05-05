import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/financial_transaction.dart';
import '../../services/agri_financial_service.dart';
import '../../theme/app_theme.dart';

class FinancialTransactionFormScreen extends StatefulWidget {
  final FinancialTransaction? initialTransaction;
  final String? initialType;

  const FinancialTransactionFormScreen({
    super.key,
    this.initialTransaction,
    this.initialType,
  });

  @override
  State<FinancialTransactionFormScreen> createState() => _FinancialTransactionFormScreenState();
}

class _FinancialTransactionFormScreenState extends State<FinancialTransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AgriFinancialService _service = AgriFinancialService();
  final NumberFormat _currency = NumberFormat.currency(symbol: 'PHP ');

  late String _type;
  late DateTime _date;
  late String _category;
  String? _selectedFarmItemId;
  List<Map<String, String>> _farmItems = [];
  bool _isLoadingFarmItems = false;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _counterpartyController = TextEditingController();
  final _farmItemIdController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  final List<String> _incomeCategories = const [
    'crop_sale',
    'livestock_sale',
    'subsidy',
    'loan_received',
    'other_income',
  ];

  final List<String> _expenseCategories = const [
    'seeds',
    'fertilizer',
    'pesticide',
    'labor',
    'equipment',
    'transport',
    'loan_repayment',
    'other_expense',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.initialTransaction;
    _type = widget.initialType ?? existing?.type ?? 'income';
    _date = existing?.transactionDate ?? DateTime.now();
    _category = existing?.category ?? (_type == 'income' ? 'crop_sale' : 'seeds');
    _selectedFarmItemId = existing?.farmItemId;

    if (existing != null) {
      _amountController.text = existing.amount.toStringAsFixed(2);
      _descriptionController.text = existing.description ?? '';
      _counterpartyController.text = existing.counterparty ?? '';
      _farmItemIdController.text = existing.farmItemId ?? '';
      _notesController.text = existing.notes ?? '';
    }

    _loadFarmItems();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _counterpartyController.dispose();
    _farmItemIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadFarmItems() async {
    setState(() => _isLoadingFarmItems = true);
    try {
      final options = await _service.getFarmItemOptions();
      if (!mounted) return;
      final hasSelected = _selectedFarmItemId != null &&
          options.any((item) => item['id'] == _selectedFarmItemId);
      setState(() {
        _farmItems = options;
        if (!hasSelected) {
          _selectedFarmItemId = null;
        }
        _isLoadingFarmItems = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingFarmItems = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final amount = double.parse(_amountController.text);
      final existing = widget.initialTransaction;

      final transaction = (existing ?? FinancialTransaction.empty())
          .copyWith(
            type: _type,
            amount: amount,
            transactionDate: _date,
            category: _category,
            description: _descriptionController.text.trim(),
            counterparty: _counterpartyController.text.trim(),
            farmItemId: (_selectedFarmItemId ?? _farmItemIdController.text.trim()).isEmpty
              ? null
              : (_selectedFarmItemId ?? _farmItemIdController.text.trim()),
            notes: _notesController.text.trim(),
          );

      final result = existing == null
          ? await _service.createTransaction(transaction)
          : await _service.updateTransaction(transaction);

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save transaction: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialTransaction != null;
    final categories = _type == 'income' ? _incomeCategories : _expenseCategories;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'income', child: Text('Income')),
                        DropdownMenuItem(value: 'expense', child: Text('Expense')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _type = value;
                          _category = value == 'income'
                              ? _incomeCategories.first
                              : _expenseCategories.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: _currency.currencySymbol,
                      ),
                      validator: (value) {
                        final raw = value?.trim() ?? '';
                        final amount = double.tryParse(raw);
                        if (amount == null || amount <= 0) {
                          return 'Enter a valid amount';
                        }
                        if (amount > 9999999.99) {
                          return 'Max amount is 9,999,999.99';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(_formatCategory(cat)),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _category = value ?? _category),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        hintText: _date.toIso8601String().split('T').first,
                        suffixIcon: const Icon(Icons.date_range_rounded),
                      ),
                      onTap: _pickDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _counterpartyController,
                decoration: const InputDecoration(labelText: 'Buyer / Vendor (optional)'),
              ),
              const SizedBox(height: 12),
              if (_isLoadingFarmItems)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_farmItems.isNotEmpty)
                DropdownButtonFormField<String?>(
                  initialValue: _selectedFarmItemId,
                  decoration: const InputDecoration(labelText: 'Crop / Farm Item (optional)'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('None')),
                    ..._farmItems.map((item) {
                      final season = (item['season'] ?? '').trim();
                      final name = (item['name'] ?? '').trim();
                      final label = season.isEmpty ? name : '$name ($season)';
                      return DropdownMenuItem<String?>(
                        value: item['id'],
                        child: Text(label),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedFarmItemId = value);
                  },
                )
              else
                TextFormField(
                  controller: _farmItemIdController,
                  decoration: const InputDecoration(
                    labelText: 'Farm Item ID (optional)',
                    hintText: 'Enter existing farm_item_id',
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(_isSaving ? 'Saving...' : (isEdit ? 'Update' : 'Save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCategory(String category) {
    return category
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
