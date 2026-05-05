import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/financial_reports.dart';
import '../../services/agri_financial_service.dart';
import '../../theme/app_theme.dart';

class FinancialCashFlowReportScreen extends StatefulWidget {
  const FinancialCashFlowReportScreen({super.key});

  @override
  State<FinancialCashFlowReportScreen> createState() => _FinancialCashFlowReportScreenState();
}

class _FinancialCashFlowReportScreenState extends State<FinancialCashFlowReportScreen> {
  final AgriFinancialService _service = AgriFinancialService();
  final NumberFormat _currency = NumberFormat.currency(symbol: 'PHP ');

  String _period = '90d';
  DateTimeRange? _customRange;
  CashFlowReport? _report;
  bool _isLoading = false;

  Future<void> _generateReport() async {
    final range = _resolveRange();
    if (range == null) return;

    setState(() => _isLoading = true);
    try {
      final report = await _service.getCashFlowReport(
        startDate: range.start,
        endDate: range.end,
      );
      if (!mounted) return;
      setState(() => _report = report);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate report: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DateTimeRange? _resolveRange() {
    final now = DateTime.now();
    if (_period == 'custom') {
      return _customRange;
    }

    final days = int.tryParse(_period.replaceAll('d', '')) ?? 90;
    final start = now.subtract(Duration(days: days));
    return DateTimeRange(start: start, end: now);
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = 'custom';
      });
    }
  }

  Future<void> _shareReport() async {
    if (_report == null) return;
    final url = await _service.createShareableReport(
      reportType: 'cashflow',
      periodStart: _report!.startDate,
      periodEnd: _report!.endDate,
    );

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shareable Link'),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rangeLabel = _period == 'custom' && _customRange != null
        ? '${_customRange!.start.toString().split(' ').first} - ${_customRange!.end.toString().split(' ').first}'
        : 'Last ${_period.replaceAll('d', '')} days';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Cash Flow Report'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _period,
                  decoration: const InputDecoration(labelText: 'Period'),
                  items: const [
                    DropdownMenuItem(value: '30d', child: Text('Last 30 days')),
                    DropdownMenuItem(value: '90d', child: Text('Last 90 days')),
                    DropdownMenuItem(value: '180d', child: Text('Last 180 days')),
                    DropdownMenuItem(value: '365d', child: Text('Last 365 days')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom range')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _period = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pickCustomRange,
                icon: const Icon(Icons.date_range_rounded),
                label: const Text('Pick Range'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(rangeLabel, style: const TextStyle(color: AppTheme.textMedium))),
              ElevatedButton(
                onPressed: _isLoading ? null : _generateReport,
                child: Text(_isLoading ? 'Loading...' : 'Generate'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_report == null)
            _buildEmptyState('Generate a report to view cash flow trends.')
          else ...[
            _buildSummaryCard(_report!),
            const SizedBox(height: 16),
            _buildChart(_report!),
            const SizedBox(height: 16),
            _buildMonthlyBreakdown(_report!),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareReport,
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share Report'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(CashFlowReport report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opening Balance: ${_currency.format(report.openingBalance)}',
            style: const TextStyle(color: AppTheme.textMedium),
          ),
          const SizedBox(height: 8),
          Text('Total Income: ${_currency.format(report.totalIncome)}'),
          Text('Total Expenses: ${_currency.format(report.totalExpenses)}'),
          const SizedBox(height: 8),
          Text(
            'Closing Balance: ${_currency.format(report.closingBalance)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(CashFlowReport report) {
    if (report.monthlyBreakdown.isEmpty) {
      return _buildEmptyState('No monthly data for this period.');
    }

    final maxValue = report.monthlyBreakdown
        .map((m) => [m.income, m.expenses].reduce((a, b) => a > b ? a : b))
        .fold<double>(0, (prev, curr) => curr > prev ? curr : prev);

    return Container(
      height: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          maxY: maxValue <= 0 ? 1 : maxValue * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= report.monthlyBreakdown.length) {
                    return const SizedBox.shrink();
                  }
                  final month = report.monthlyBreakdown[index].month;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(month.substring(5), style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(report.monthlyBreakdown.length, (index) {
            final data = report.monthlyBreakdown[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data.income,
                  color: AppTheme.success,
                  width: 8,
                ),
                BarChartRodData(
                  toY: data.expenses,
                  color: AppTheme.error,
                  width: 8,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMonthlyBreakdown(CashFlowReport report) {
    return Column(
      children: report.monthlyBreakdown.map((month) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  month.month,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('In: ${_currency.format(month.income)}', style: const TextStyle(color: AppTheme.success)),
                  Text('Out: ${_currency.format(month.expenses)}', style: const TextStyle(color: AppTheme.error)),
                  Text('Bal: ${_currency.format(month.balance)}'),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded, size: 48, color: AppTheme.textLight),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: AppTheme.textMedium)),
          ],
        ),
      ),
    );
  }
}
