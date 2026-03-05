import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/report_model.dart';
import '../../models/recommendation_model.dart';
import '../../theme/app_theme.dart';

/// MAO verification workflow for calamity reports and subsidy allocation.
/// Allows admins to verify, approve, or reject disaster reports and
/// manage subsidy disbursement.
class VerificationWorkflowScreen extends StatefulWidget {
  const VerificationWorkflowScreen({super.key});

  @override
  State<VerificationWorkflowScreen> createState() =>
      _VerificationWorkflowScreenState();
}

class _VerificationWorkflowScreenState
    extends State<VerificationWorkflowScreen>
    with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;
  late TabController _tabController;
  List<CalamityReport> _pendingReports = [];
  List<CalamityReport> _verifiedReports = [];
  List<SubsidyAllocation> _subsidies = [];
  bool _isLoading = true;

  // Summary stats
  int _totalPending = 0;
  int _totalVerified = 0;
  int _totalDisbursed = 0;
  double _totalSubsidyAmount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load calamity reports
      final reportsData = await _client
          .from('calamity_reports')
          .select()
          .order('date_occurred', ascending: false);

      final allReports = List<CalamityReport>.from(
          reportsData.map((r) => CalamityReport.fromJson(r)));

      _pendingReports =
          allReports.where((r) => r.status == 'reported').toList();
      _verifiedReports =
          allReports.where((r) => r.status != 'reported').toList();

      // Load subsidy allocations
      try {
        final subsidyData = await _client
            .from('subsidy_allocations')
            .select()
            .order('created_at', ascending: false);

        _subsidies = List<SubsidyAllocation>.from(
            subsidyData.map((s) => SubsidyAllocation.fromJson(s)));
      } catch (_) {
        _subsidies = [];
      }

      // Compute stats
      _totalPending = _pendingReports.length;
      _totalVerified =
          allReports.where((r) => r.status == 'verified').length;
      _totalDisbursed =
          _subsidies.where((s) => s.status == 'disbursed').length;
      _totalSubsidyAmount = _subsidies
          .where((s) => s.status == 'disbursed')
          .fold<double>(0, (sum, s) => sum + s.subsidyAmount);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Verification & Subsidies'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.primary,
          tabs: [
            Tab(text: 'Pending ($_totalPending)'),
            const Tab(text: 'Verified'),
            const Tab(text: 'Subsidies'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryStrip(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPendingTab(),
                      _buildVerifiedTab(),
                      _buildSubsidiesTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryStrip() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _summaryItem('$_totalPending', 'Pending', Icons.pending_actions),
          _divider(),
          _summaryItem('$_totalVerified', 'Verified', Icons.verified),
          _divider(),
          _summaryItem('$_totalDisbursed', 'Disbursed', Icons.payments),
          _divider(),
          _summaryItem('₱${_formatNum(_totalSubsidyAmount)}', 'Amount',
              Icons.account_balance),
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
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withAlpha(180), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
      width: 1, height: 36, color: Colors.white.withAlpha(50));

  // ================================================================
  // TAB 1: PENDING REPORTS
  // ================================================================
  Widget _buildPendingTab() {
    if (_pendingReports.isEmpty) {
      return _emptyState(
          'No pending reports', 'All calamity reports have been reviewed.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingReports.length,
      itemBuilder: (context, index) {
        return _buildPendingCard(_pendingReports[index]);
      },
    );
  }

  Widget _buildPendingCard(CalamityReport report) {
    final severityColor = report.severity == 'high'
        ? AppTheme.error
        : report.severity == 'medium'
            ? AppTheme.warning
            : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.warning.withAlpha(60), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.severity.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: severityColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(report.type,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Text(
                '${report.dateOccurred.day}/${report.dateOccurred.month}/${report.dateOccurred.year}',
                style:
                    const TextStyle(fontSize: 11, color: AppTheme.textLight),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (report.farmerName.isNotEmpty)
            Text('Farmer: ${report.farmerName}',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textMedium)),
          if (report.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(report.description,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textMedium, height: 1.3),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (report.affectedArea > 0)
                _buildTag(
                    '${report.affectedArea.toStringAsFixed(1)} acres'),
              if (report.affectedCrops.isNotEmpty) ...[
                const SizedBox(width: 6),
                _buildTag(report.affectedCrops.join(', ')),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectReport(report),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _verifyReport(report),
                  icon: const Icon(Icons.check, size: 16),
                  label:
                      const Text('Verify', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showSubsidyDialog(report),
                  icon: const Icon(Icons.payments, size: 16),
                  label: const Text('Subsidy',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // TAB 2: VERIFIED REPORTS
  // ================================================================
  Widget _buildVerifiedTab() {
    if (_verifiedReports.isEmpty) {
      return _emptyState(
          'No verified reports', 'Verified reports will appear here.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _verifiedReports.length,
      itemBuilder: (context, index) {
        final report = _verifiedReports[index];
        return _buildVerifiedCard(report);
      },
    );
  }

  Widget _buildVerifiedCard(CalamityReport report) {
    final statusColor = report.status == 'verified'
        ? AppTheme.success
        : report.status == 'resolved'
            ? AppTheme.primary
            : AppTheme.textMedium;

    return Container(
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
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              report.status == 'verified'
                  ? Icons.verified
                  : Icons.check_circle_outline,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.type,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  '${report.farmerName} — ${report.dateOccurred.day}/${report.dateOccurred.month}/${report.dateOccurred.year}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMedium),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              report.status.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // TAB 3: SUBSIDIES
  // ================================================================
  Widget _buildSubsidiesTab() {
    if (_subsidies.isEmpty) {
      return _emptyState(
          'No subsidies allocated', 'Allocate subsidies from pending reports.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subsidies.length,
      itemBuilder: (context, index) {
        final s = _subsidies[index];
        return _buildSubsidyCard(s);
      },
    );
  }

  Widget _buildSubsidyCard(SubsidyAllocation s) {
    final statusColor = s.status == 'disbursed'
        ? AppTheme.success
        : s.status == 'approved'
            ? AppTheme.primary
            : s.status == 'rejected'
                ? AppTheme.error
                : AppTheme.warning;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(s.statusEmoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.statusLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                      '${s.createdAt.day}/${s.createdAt.month}/${s.createdAt.year}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
              Text(
                '₱${s.subsidyAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          if (s.verificationNotes != null &&
              s.verificationNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(s.verificationNotes!,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textMedium)),
          ],
          if (s.status == 'verified') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _updateSubsidyStatus(s.id, 'rejected'),
                    child: const Text('Reject',
                        style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _updateSubsidyStatus(s.id, 'approved'),
                    child: const Text('Approve',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
          if (s.status == 'approved') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _updateSubsidyStatus(s.id, 'disbursed'),
                icon: const Icon(Icons.payments, size: 16),
                label: const Text('Mark Disbursed',
                    style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // ACTIONS
  // ================================================================

  Future<void> _verifyReport(CalamityReport report) async {
    try {
      await _client
          .from('calamity_reports')
          .update({'status': 'verified'}).eq('id', report.id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report verified successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectReport(CalamityReport report) async {
    try {
      await _client
          .from('calamity_reports')
          .update({'status': 'resolved'}).eq('id', report.id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showSubsidyDialog(CalamityReport report) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    // Estimate subsidy based on severity and area
    double estimatedAmount = 0;
    if (report.severity == 'high') {
      estimatedAmount = report.affectedArea * 15000;
    } else if (report.severity == 'medium') {
      estimatedAmount = report.affectedArea * 10000;
    } else {
      estimatedAmount = report.affectedArea * 5000;
    }
    amountController.text = estimatedAmount.toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Allocate Subsidy'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Calamity: ${report.type}',
                  style: const TextStyle(fontSize: 14)),
              Text('Farmer: ${report.farmerName}',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textMedium)),
              Text(
                  'Severity: ${report.severity.toUpperCase()} | Area: ${report.affectedArea.toStringAsFixed(1)} acres',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textMedium)),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Subsidy Amount (₱)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Verification Notes',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount =
                  double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;

              try {
                // Verify the report
                await _client.from('calamity_reports').update(
                    {'status': 'verified'}).eq('id', report.id);

                // Create subsidy allocation
                await _client.from('subsidy_allocations').insert({
                  'calamity_report_id': report.id,
                  'farmer_id': report.farmerId,
                  'verified_by': _client.auth.currentUser?.id,
                  'verification_date': DateTime.now()
                      .toIso8601String()
                      .split('T')
                      .first,
                  'subsidy_amount': amount,
                  'status': 'verified',
                  'verification_notes': notesController.text.trim(),
                });

                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Subsidy allocated and report verified')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Allocate'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSubsidyStatus(String subsidyId, String status) async {
    try {
      await _client
          .from('subsidy_allocations')
          .update({'status': status}).eq('id', subsidyId);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 11, color: AppTheme.primary)),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.fact_check_outlined,
              size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textMedium, fontSize: 15)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  color: AppTheme.textLight, fontSize: 13)),
        ],
      ),
    );
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
