import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/agri_financial_model.dart';
import '../../theme/app_theme.dart';

class AisMarketViabilityScreen extends StatefulWidget {
  const AisMarketViabilityScreen({super.key});

  @override
  State<AisMarketViabilityScreen> createState() => _AisMarketViabilityScreenState();
}

class _AisMarketViabilityScreenState extends State<AisMarketViabilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _engine = AgriFinancialModel();
  final _currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
  final _percent = NumberFormat('0.00');

  final _commodityController = TextEditingController();
  final _currentPriceController = TextEditingController();
  final _baselinePriceController = TextEditingController();
  final _totalProductionController = TextEditingController();
  final _unsoldInventoryController = TextEditingController();
  final _quantitySoldController = TextEditingController();
  final _inputCostController = TextEditingController();
  final _laborCostController = TextEditingController();
  final _landCostController = TextEditingController();
  final _logisticsCostController = TextEditingController();

  PerishabilityCategory _perishability = PerishabilityCategory.moderatelyPerishable;
  AgriFinancialReport? _report;

  @override
  void dispose() {
    _commodityController.dispose();
    _currentPriceController.dispose();
    _baselinePriceController.dispose();
    _totalProductionController.dispose();
    _unsoldInventoryController.dispose();
    _quantitySoldController.dispose();
    _inputCostController.dispose();
    _laborCostController.dispose();
    _landCostController.dispose();
    _logisticsCostController.dispose();
    super.dispose();
  }

  void _analyze() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final input = AgriFinancialInput(
      commodity: _commodityController.text.trim(),
      perishabilityCategory: _perishability,
      currentMarketPrice: _asDouble(_currentPriceController.text),
      baselineHistoricalPrice: _asDouble(_baselinePriceController.text),
      totalProductionVolume: _asDouble(_totalProductionController.text),
      unsoldInventory: _asDouble(_unsoldInventoryController.text),
      quantitySold: _asDouble(_quantitySoldController.text),
      inputCosts: _asDouble(_inputCostController.text),
      laborCosts: _asDouble(_laborCostController.text),
      landCosts: _asDouble(_landCostController.text),
      logisticsCosts: _asDouble(_logisticsCostController.text),
    );

    setState(() {
      _report = _engine.analyze(input);
    });
  }

  double _asDouble(String value) => double.tryParse(value.trim()) ?? 0;

  String? _requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  String? _requiredNumber(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    if (double.tryParse(value.trim()) == null) {
      return 'Enter a valid number for $label';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AIS Crop Viability'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroCard(),
            const SizedBox(height: 12),
            _buildFormCard(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _analyze,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Run AIS Analysis'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_report != null) ...[
              const SizedBox(height: 16),
              _buildReportCard(_report!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Text(
        'Uses observable proxies only: Price Pressure Indicator (PPI), Inventory Unsold Ratio (IUR), and strict Net Profit. Demand modeling is intentionally excluded.',
        style: TextStyle(color: AppTheme.textMedium),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _textField(
              controller: _commodityController,
              label: 'Commodity',
              hint: 'e.g. Tomato',
              validator: (v) => _requiredText(v, 'Commodity'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PerishabilityCategory>(
              initialValue: _perishability,
              decoration: const InputDecoration(
                labelText: 'Perishability Category',
              ),
              items: const [
                DropdownMenuItem(
                  value: PerishabilityCategory.highlyPerishable,
                  child: Text('Highly Perishable'),
                ),
                DropdownMenuItem(
                  value: PerishabilityCategory.moderatelyPerishable,
                  child: Text('Moderately Perishable'),
                ),
                DropdownMenuItem(
                  value: PerishabilityCategory.storable,
                  child: Text('Storable'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _perishability = value);
              },
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: _currentPriceController,
              label: 'Current Market Price (PHP)',
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: _baselinePriceController,
              label: 'Baseline Historical Price (PHP)',
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: _totalProductionController,
              label: 'Total Production Volume',
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: _unsoldInventoryController,
              label: 'Unsold Inventory',
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: _quantitySoldController,
              label: 'Quantity Sold',
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: _inputCostController,
              label: 'Total Input Costs (PHP)',
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: _laborCostController,
              label: 'Total Labor Costs (PHP)',
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: _landCostController,
              label: 'Total Land Costs (PHP)',
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: _logisticsCostController,
              label: 'Total Logistics/Transport Costs (PHP)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(AgriFinancialReport report) {
    final m = report.metrics;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AIS Report: ${report.commodity}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          _metricRow('Price Pressure Indicator (PPI)', '${_percent.format(m.pricePressureIndicator)}%'),
          _metricRow('Inventory Unsold Ratio (IUR)', '${_percent.format(m.inventoryUnsoldRatio * 100)}%'),
          _metricRow('Net Profit', _currency.format(m.netProfit)),
          const Divider(height: 24),
          _metricRow('Market Condition', report.marketCondition),
          if (report.highRiskIllusion)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Flag: High-Risk Illusion (positive PPI but weak margin behavior)',
                style: TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Immediate Recommendations',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          for (final rec in report.recommendations)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $rec', style: const TextStyle(color: AppTheme.textMedium)),
            ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMedium),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: validator,
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (v) => _requiredNumber(v, label),
    );
  }
}