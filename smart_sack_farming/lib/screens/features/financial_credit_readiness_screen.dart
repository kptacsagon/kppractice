import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/financial_reports.dart';
import '../../services/agri_financial_service.dart';
import '../../theme/app_theme.dart';

class FinancialCreditReadinessScreen extends StatefulWidget {
  const FinancialCreditReadinessScreen({super.key});

  @override
  State<FinancialCreditReadinessScreen> createState() => _FinancialCreditReadinessScreenState();
}

class _FinancialCreditReadinessScreenState extends State<FinancialCreditReadinessScreen> {
  final AgriFinancialService _service = AgriFinancialService();
  final NumberFormat _currency = NumberFormat.currency(symbol: 'PHP ');

  CreditReadinessReport? _report;
  bool _isLoading = false;

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final report = await _service.getCreditReadinessReport();
      if (!mounted) return;
      setState(() => _report = report);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load report: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _shareReport() async {
    if (_report == null) return;
    final url = await _service.createShareableReport(
      reportType: 'credit_readiness',
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
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Credit Readiness Report'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _report == null
              ? _buildEmptyState('No report data yet.')
              : _buildReportContent(_report!),
    );
  }

  Widget _buildReportContent(CreditReadinessReport report) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildScoreCard(report),
        const SizedBox(height: 16),
        _buildFinancialSummary(report),
        const SizedBox(height: 16),
        _buildRepaymentCard(report),
        const SizedBox(height: 16),
        Text(
          report.disclaimer,
          style: const TextStyle(color: AppTheme.textMedium, fontSize: 12),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _shareReport,
          icon: const Icon(Icons.share_rounded),
          label: const Text('Share Report'),
        ),
      ],
    );
  }

  Widget _buildScoreCard(CreditReadinessReport report) {
    final scoreColor = report.completenessScore >= 80
        ? AppTheme.success
        : report.completenessScore >= 60
            ? Colors.orange
            : report.completenessScore >= 40
                ? Colors.amber
                : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: scoreColor.withAlpha(20),
            child: Text(
              report.completenessScore.toStringAsFixed(0),
              style: TextStyle(color: scoreColor, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data Completeness Score',
                  style: TextStyle(color: AppTheme.textMedium)),
              const SizedBox(height: 6),
              Text(
                report.completenessLabel,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(CreditReadinessReport report) {
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
          const Text('12-Month Summary', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Total Income: ${_currency.format(report.totalIncome)}'),
          Text('Total Expenses: ${_currency.format(report.totalExpenses)}'),
          Text('Net: ${_currency.format(report.net)}'),
        ],
      ),
    );
  }

  Widget _buildRepaymentCard(CreditReadinessReport report) {
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
          const Text('Projected Repayment Capacity',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            _currency.format(report.monthlyRepaymentCapacity),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Estimate based on 35% of average monthly net income (${_currency.format(report.averageMonthlyNetIncome)}).',
            style: const TextStyle(color: AppTheme.textMedium, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.verified_outlined, size: 48, color: AppTheme.textLight),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: AppTheme.textMedium)),
          ],
        ),
      ),
    );
  }
}
