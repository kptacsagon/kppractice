import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/financial_summary.dart';
import '../../models/financial_transaction.dart';
import '../../services/agri_financial_service.dart';
import '../../services/agri_ure_service.dart';
import '../../theme/app_theme.dart';
import 'ais_market_viability_screen.dart';
import 'financial_cashflow_report_screen.dart';
import 'financial_credit_readiness_screen.dart';
import 'financial_transaction_form_screen.dart';

class AgriFinancialModelScreen extends StatefulWidget {
  const AgriFinancialModelScreen({super.key});

  @override
  State<AgriFinancialModelScreen> createState() => _AgriFinancialModelScreenState();
}

class _AgriFinancialModelScreenState extends State<AgriFinancialModelScreen>
    with SingleTickerProviderStateMixin {
  final AgriFinancialService _service = AgriFinancialService();
  final NumberFormat _currency = NumberFormat.currency(symbol: 'PHP ');

  late TabController _tabController;
  FinancialDashboardSummary? _summary;
  List<FinancialTransaction> _recentTransactions = [];
  List<FinancialTransaction> _transactions = [];
  bool _isLoadingSummary = true;
  bool _isLoadingTransactions = true;
  bool _isLoadingFarmItems = false;
  String _transactionTypeFilter = 'all';
  String _searchTerm = '';
  String _farmItemIdFilter = '';
  DateTimeRange? _dateRange;
  List<Map<String, String>> _farmItems = [];
  List<UreEvent> _ureEvents = [];
  bool _isLoadingUre = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSummary();
    _loadFarmItems();
    _loadTransactions();
    _loadUre();
  }

  Future<void> _loadUre() async {
    setState(() => _isLoadingUre = true);
    try {
      final farmerId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final events = await AgriUreService().getMyUreEvents(farmerId);
      if (!mounted) return;
      setState(() { _ureEvents = events; _isLoadingUre = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingUre = false);
    }
  }

  Future<void> _loadFarmItems() async {
    setState(() => _isLoadingFarmItems = true);
    try {
      final farmItems = await _service.getFarmItemOptions();
      if (!mounted) return;
      final hasFilter = _farmItemIdFilter.isNotEmpty &&
          farmItems.any((item) => item['id'] == _farmItemIdFilter);
      setState(() {
        _farmItems = farmItems;
        if (!hasFilter) {
          _farmItemIdFilter = '';
        }
        _isLoadingFarmItems = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingFarmItems = false);
    }
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoadingSummary = true);
    try {
      final summary = await _service.getDashboardSummary();
      final recent = await _service.getTransactions(limit: 5);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _recentTransactions = recent;
        _isLoadingSummary = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSummary = false);
      // Silently ignore missing table — DB migration not yet run
      final msg = e.toString();
      if (!msg.contains('PGRST205') && !msg.contains('42P01')) {
        _showError('Failed to load summary: $e');
      }
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoadingTransactions = true);
    try {
      final transactions = await _service.getTransactions(
        type: _transactionTypeFilter,
        farmItemId: _farmItemIdFilter.trim().isEmpty
            ? null
            : _farmItemIdFilter.trim(),
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        search: _searchTerm,
      );
      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _isLoadingTransactions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingTransactions = false);
      final msg = e.toString();
      if (!msg.contains('PGRST205') && !msg.contains('42P01')) {
        _showError('Failed to load transactions: $e');
      }
    }
  }

  Future<void> _openTransactionForm({FinancialTransaction? existing, String? type}) async {
    final result = await Navigator.of(context).push<FinancialTransaction>(
      MaterialPageRoute(
        builder: (_) => FinancialTransactionFormScreen(
          initialTransaction: existing,
          initialType: type,
        ),
      ),
    );

    if (result != null) {
      await _loadSummary();
      await _loadTransactions();
    }
  }

  Future<void> _confirmDelete(FinancialTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This will remove the transaction from your ledger.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.deleteTransaction(transaction.id);
      await _loadSummary();
      await _loadTransactions();
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
      await _loadTransactions();
    }
  }

  void _clearFilters() {
    setState(() {
      _transactionTypeFilter = 'all';
      _searchTerm = '';
      _farmItemIdFilter = '';
      _dateRange = null;
    });
    _loadTransactions();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  String _farmItemLabel(String? id) {
    if (id == null || id.isEmpty) {
      return '-';
    }
    final match = _farmItems.where((item) => item['id'] == id).toList();
    if (match.isEmpty) {
      return id;
    }
    final season = (match.first['season'] ?? '').trim();
    final name = (match.first['name'] ?? '').trim();
    return season.isEmpty ? name : '$name ($season)';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AgriFinancial Model'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Transactions'),
            Tab(text: 'Reports'),
            Tab(text: 'URE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTransactionsTab(),
          _buildReportsTab(),
          _buildUreTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoadingSummary) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = _summary ?? FinancialDashboardSummary(
      currentBalance: 0,
      incomeThisMonth: 0,
      expensesThisMonth: 0,
      netThisMonth: 0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(summary),
          const SizedBox(height: 16),
          _buildQuickActions(),
          const SizedBox(height: 24),
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          if (_recentTransactions.isEmpty)
            _buildEmptyState('No transactions yet. Start by adding income or expenses.')
          else
            Column(
              children: _recentTransactions
                  .map((tx) => _buildTransactionTile(tx))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _isLoadingTransactions
              ? const Center(child: CircularProgressIndicator())
              : _transactions.isEmpty
                  ? _buildEmptyState('No transactions found.')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionTile(_transactions[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildReportCard(
          title: 'Cash Flow Report',
          description: 'Monthly inflows and outflows with running balances.',
          icon: Icons.show_chart_rounded,
          color: const Color(0xFF4CAF50),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FinancialCashFlowReportScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildReportCard(
          title: 'Credit Readiness Report',
          description: 'Completeness score and repayment capacity estimate.',
          icon: Icons.verified_rounded,
          color: const Color(0xFF5B5FFF),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FinancialCreditReadinessScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildReportCard(
          title: 'AIS Crop Viability Analyzer',
          description: 'PPI, IUR, and net-profit decision matrix with immediate actions.',
          icon: Icons.agriculture_rounded,
          color: const Color(0xFF2E7D32),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AisMarketViabilityScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(FinancialDashboardSummary summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Cash Balance',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            _currency.format(summary.currentBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat('Income (Month)', summary.incomeThisMonth, AppTheme.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat('Expenses (Month)', summary.expensesThisMonth, AppTheme.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat('Net (Month)', summary.netThisMonth, Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            _currency.format(value),
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openTransactionForm(type: 'income'),
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Add Income'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openTransactionForm(type: 'expense'),
            icon: const Icon(Icons.remove_circle_outline_rounded),
            label: const Text('Add Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => _tabController.animateTo(2),
          child: const Text('Reports'),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final rangeLabel = _dateRange == null
        ? 'All dates'
        : '${_dateRange!.start.toString().split(' ').first} - ${_dateRange!.end.toString().split(' ').first}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _transactionTypeFilter,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'income', child: Text('Income')),
                    DropdownMenuItem(value: 'expense', child: Text('Expense')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _transactionTypeFilter = value);
                    _loadTransactions();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: _searchTerm,
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    hintText: 'Notes or description',
                  ),
                  onChanged: (value) {
                    _searchTerm = value;
                  },
                  onFieldSubmitted: (_) => _loadTransactions(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _isLoadingFarmItems
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<String>(
                    initialValue: _farmItems
                        .any((item) => item['id'] == _farmItemIdFilter)
                      ? _farmItemIdFilter
                      : '',
                        decoration: const InputDecoration(labelText: 'Crop / Farm Item'),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('All items')),
                          ..._farmItems.map((item) {
                            final season = (item['season'] ?? '').trim();
                            final name = (item['name'] ?? '').trim();
                            final label = season.isEmpty ? name : '$name ($season)';
                            return DropdownMenuItem<String>(
                              value: item['id'],
                              child: Text(label),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => _farmItemIdFilter = value ?? '');
                          _loadTransactions();
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range_rounded),
                  label: Text(rangeLabel, overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(FinancialTransaction tx) {
    final isIncome = tx.type == 'income';
    final amountColor = isIncome ? AppTheme.success : AppTheme.error;
    final balanceText = tx.runningBalance != null
        ? _currency.format(tx.runningBalance)
        : '...';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: amountColor.withAlpha(20),
            child: Icon(
              isIncome ? Icons.call_received_rounded : Icons.call_made_rounded,
              color: amountColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description?.isNotEmpty == true
                      ? tx.description!
                      : _formatCategory(tx.category),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tx.transactionDate.toIso8601String().split('T').first} · ${_formatCategory(tx.category)}',
                  style: const TextStyle(color: AppTheme.textMedium, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  'Balance: $balanceText',
                  style: const TextStyle(color: AppTheme.textMedium, fontSize: 12),
                ),
                if ((tx.farmItemId?.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Farm Item: ${_farmItemLabel(tx.farmItemId)}',
                      style: const TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currency.format(tx.amount),
                style: TextStyle(fontWeight: FontWeight.w700, color: amountColor),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openTransactionForm(existing: tx);
                  } else if (value == 'delete') {
                    _confirmDelete(tx);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: AppTheme.textMedium, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 48, color: AppTheme.textLight),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: AppTheme.textMedium)),
          ],
        ),
      ),
    );
  }

  Widget _buildUreTab() {
    if (_isLoadingUre) return const Center(child: CircularProgressIndicator());
    if (_ureEvents.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_rounded, size: 56, color: Color(0xFFD1D5DB)),
          SizedBox(height: 12),
          Text('No URE reports submitted yet.', style: TextStyle(color: Color(0xFF6B7280))),
        ]),
      );
    }
    final currency = NumberFormat.currency(symbol: 'PHP ');
    return RefreshIndicator(
      onRefresh: _loadUre,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ureEvents.length,
        itemBuilder: (_, i) {
          final e = _ureEvents[i];
          Color statusColor;
          IconData statusIcon;
          switch (e.status) {
            case 'verified':
              statusColor = AppTheme.success;
              statusIcon = Icons.check_circle_rounded;
              break;
            case 'endorsed':
              statusColor = const Color(0xFF2563EB);
              statusIcon = Icons.thumb_up_rounded;
              break;
            case 'escalated':
              statusColor = const Color(0xFFF59E0B);
              statusIcon = Icons.warning_rounded;
              break;
            default:
              statusColor = const Color(0xFF9CA3AF);
              statusIcon = Icons.hourglass_top_rounded;
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('${e.eventType} — ${e.cropType}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(e.status[0].toUpperCase() + e.status.substring(1),
                        style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
              const SizedBox(height: 6),
              Text(e.description, style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.4)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Text(e.createdAt.toIso8601String().split('T').first,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                if (e.financialImpact != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.monetization_on_rounded, size: 12, color: Color(0xFFEF4444)),
                  const SizedBox(width: 4),
                  Text('Impact: ${currency.format(e.financialImpact)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                ],
              ]),
              if (e.verificationNotes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5F1), borderRadius: BorderRadius.circular(8)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.comment_rounded, size: 13, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(e.verificationNotes!, style: const TextStyle(fontSize: 11, color: Color(0xFF374151)))),
                  ]),
                ),
              ],
            ]),
          );
        },
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
