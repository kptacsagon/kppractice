import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/financial_reports.dart';
import '../models/financial_summary.dart';
import '../models/financial_transaction.dart';

class AgriFinancialService {
  final SupabaseClient _client;

  AgriFinancialService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<Map<String, String>>> getFarmItemOptions() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('farm_items')
        .select('id,name,season,status')
        .eq('user_id', userId)
        .neq('status', 'archived')
        .order('name', ascending: true);

    return (response as List).map((row) {
      final json = row as Map<String, dynamic>;
      return {
        'id': (json['id'] ?? '').toString(),
        'name': (json['name'] ?? 'Unnamed').toString(),
        'season': (json['season'] ?? '').toString(),
      };
    }).where((item) => (item['id'] ?? '').isNotEmpty).toList();
  }

  Future<FinancialDashboardSummary> getDashboardSummary() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final allTransactions = await _getAllTransactions(userId);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    double totalBalance = 0;
    double incomeThisMonth = 0;
    double expensesThisMonth = 0;

    for (final tx in allTransactions) {
      final delta = tx.type == 'income' ? tx.amount : -tx.amount;
      totalBalance += delta;

      if (!tx.transactionDate.isBefore(monthStart) &&
          !tx.transactionDate.isAfter(monthEnd)) {
        if (tx.type == 'income') {
          incomeThisMonth += tx.amount;
        } else {
          expensesThisMonth += tx.amount;
        }
      }
    }

    return FinancialDashboardSummary(
      currentBalance: totalBalance,
      incomeThisMonth: incomeThisMonth,
      expensesThisMonth: expensesThisMonth,
      netThisMonth: incomeThisMonth - expensesThisMonth,
    );
  }

  Future<List<FinancialTransaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? category,
    String? cropId,
    String? seasonId,
    String? farmItemId,
    String? search,
    int page = 1,
    int limit = 25,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    var query = _client
        .from('financial_transactions')
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false);

    if (startDate != null) {
      query = query.gte('transaction_date', _dateOnly(startDate));
    }
    if (endDate != null) {
      query = query.lte('transaction_date', _dateOnly(endDate));
    }
    if (type != null && type.isNotEmpty && type != 'all') {
      query = query.eq('type', type);
    }
    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    if (cropId != null && cropId.isNotEmpty) {
      query = query.eq('farm_item_id', cropId);
    }
    if (seasonId != null && seasonId.isNotEmpty) {
      query = query.eq('season_id', seasonId);
    }
    if (farmItemId != null && farmItemId.isNotEmpty) {
      query = query.eq('farm_item_id', farmItemId);
    }
    if (search != null && search.trim().isNotEmpty) {
      final term = search.trim();
      query = query.or('description.ilike.%$term%,notes.ilike.%$term%');
    }

    final from = (page - 1) * limit;
    final to = from + limit - 1;

    final response = await query
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false)
        .range(from, to);

    final rows = (response as List)
        .map((r) => FinancialTransaction.fromJson(r as Map<String, dynamic>))
        .toList();

    final runningMap = await _getRunningBalanceMap(userId);
    return rows
        .map((tx) => tx.copyWith(runningBalance: runningMap[tx.id]))
        .toList();
  }

  Future<FinancialTransaction> createTransaction(
      FinancialTransaction transaction) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final payload = {
      ...transaction.toInsertJson(),
      'user_id': userId,
      'entered_by': transaction.enteredBy ?? userId,
    };

    final response = await _client
        .from('financial_transactions')
        .insert(payload)
        .select()
        .single();

    final created = FinancialTransaction.fromJson(
        response as Map<String, dynamic>);

    await _writeAudit(
      userId: userId,
      transactionId: created.id,
      action: 'create',
      oldData: null,
      newData: payload,
    );

    final runningMap = await _getRunningBalanceMap(userId);
    return created.copyWith(runningBalance: runningMap[created.id]);
  }

  Future<FinancialTransaction> updateTransaction(
      FinancialTransaction transaction) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final existing = await _client
        .from('financial_transactions')
        .select()
        .eq('id', transaction.id)
        .maybeSingle();

    final payload = transaction.toUpdateJson();

    final response = await _client
        .from('financial_transactions')
        .update(payload)
        .eq('id', transaction.id)
        .select()
        .single();

    await _writeAudit(
      userId: userId,
      transactionId: transaction.id,
      action: 'update',
      oldData: existing as Map<String, dynamic>?,
      newData: payload,
    );

    final updated = FinancialTransaction.fromJson(
        response as Map<String, dynamic>);
    final runningMap = await _getRunningBalanceMap(userId);
    return updated.copyWith(runningBalance: runningMap[updated.id]);
  }

  Future<void> deleteTransaction(String transactionId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final existing = await _client
        .from('financial_transactions')
        .select()
        .eq('id', transactionId)
        .maybeSingle();

    await _client
        .from('financial_transactions')
        .update({'is_deleted': true})
        .eq('id', transactionId);

    await _writeAudit(
      userId: userId,
      transactionId: transactionId,
      action: 'delete',
      oldData: existing as Map<String, dynamic>?,
      newData: {'is_deleted': true},
    );
  }

  Future<CashFlowReport> getCashFlowReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final allTransactions = await _getAllTransactions(userId);

    double openingBalance = 0;
    double totalIncome = 0;
    double totalExpenses = 0;

    for (final tx in allTransactions) {
      if (tx.transactionDate.isBefore(startDate)) {
        openingBalance += tx.type == 'income' ? tx.amount : -tx.amount;
      }
    }

    final months = _generateMonthKeys(startDate, endDate);
    final monthlyTotals = <String, Map<String, double>>{};
    for (final key in months) {
      monthlyTotals[key] = {'income': 0, 'expenses': 0};
    }

    for (final tx in allTransactions) {
      if (tx.transactionDate.isBefore(startDate) ||
          tx.transactionDate.isAfter(endDate)) {
        continue;
      }
      final monthKey = _monthKey(tx.transactionDate);
      final bucket = monthlyTotals[monthKey];
      if (bucket == null) continue;
      if (tx.type == 'income') {
        bucket['income'] = (bucket['income'] ?? 0) + tx.amount;
        totalIncome += tx.amount;
      } else {
        bucket['expenses'] = (bucket['expenses'] ?? 0) + tx.amount;
        totalExpenses += tx.amount;
      }
    }

    double running = openingBalance;
    final breakdown = <CashFlowMonth>[];
    for (final key in months) {
      final bucket = monthlyTotals[key] ?? {'income': 0, 'expenses': 0};
      final income = bucket['income'] ?? 0;
      final expenses = bucket['expenses'] ?? 0;
      final net = income - expenses;
      running += net;
      breakdown.add(CashFlowMonth(
        month: key,
        income: income,
        expenses: expenses,
        net: net,
        balance: running,
      ));
    }

    return CashFlowReport(
      startDate: startDate,
      endDate: endDate,
      openingBalance: openingBalance,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      closingBalance: running,
      monthlyBreakdown: breakdown,
    );
  }

  Future<CreditReadinessReport> getCreditReadinessReport() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final startDate = DateTime(now.year - 1, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);

    final allTransactions = await _getAllTransactions(userId);

    double totalIncome = 0;
    double totalExpenses = 0;
    final daysWithTransactions = <String>{};

    for (final tx in allTransactions) {
      if (tx.transactionDate.isBefore(startDate) ||
          tx.transactionDate.isAfter(endDate)) {
        continue;
      }
      final dayKey = _dateOnly(tx.transactionDate);
      daysWithTransactions.add(dayKey);
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpenses += tx.amount;
      }
    }

    final totalDays = endDate.difference(startDate).inDays + 1;
    final completenessScore = totalDays == 0
        ? 0.0
        : (daysWithTransactions.length / totalDays) * 100.0;

    final completenessLabel = _completenessLabel(completenessScore);
    final months = _generateMonthKeys(startDate, endDate);

    double monthlyNetTotal = 0;
    for (final monthKey in months) {
      final monthIncome = allTransactions
          .where((tx) => _monthKey(tx.transactionDate) == monthKey)
          .where((tx) => !tx.transactionDate.isBefore(startDate) &&
              !tx.transactionDate.isAfter(endDate) &&
              tx.type == 'income')
          .fold(0.0, (sum, tx) => sum + tx.amount);

      final monthExpenses = allTransactions
          .where((tx) => _monthKey(tx.transactionDate) == monthKey)
          .where((tx) => !tx.transactionDate.isBefore(startDate) &&
              !tx.transactionDate.isAfter(endDate) &&
              tx.type == 'expense')
          .fold(0.0, (sum, tx) => sum + tx.amount);

      monthlyNetTotal += (monthIncome - monthExpenses);
    }

    final averageMonthlyNet = months.isEmpty
        ? 0.0
        : monthlyNetTotal / months.length;
    final repaymentCapacity = averageMonthlyNet * 0.35;

    return CreditReadinessReport(
      startDate: startDate,
      endDate: endDate,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      net: totalIncome - totalExpenses,
      completenessScore: completenessScore,
      completenessLabel: completenessLabel,
      averageMonthlyNetIncome: averageMonthlyNet,
      monthlyRepaymentCapacity: repaymentCapacity,
      disclaimer:
          'Generated by AgriFinance - Data sourced from user-recorded transactions.',
    );
  }

  Future<String> createShareableReport({
    required String reportType,
    DateTime? periodStart,
    DateTime? periodEnd,
    int expiresDays = 30,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final token = _generateToken();
    final expiresAt = DateTime.now().add(Duration(days: expiresDays));

    await _client.from('financial_reports').insert({
      'user_id': userId,
      'report_type': reportType,
      'period_start': periodStart?.toIso8601String().split('T').first,
      'period_end': periodEnd?.toIso8601String().split('T').first,
      'share_token': token,
      'share_expires_at': expiresAt.toIso8601String(),
    });

    return 'https://app.agrifinance.app/report/$token';
  }

  Future<List<FinancialTransaction>> _getAllTransactions(String userId) async {
    final response = await _client
        .from('financial_transactions')
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .order('transaction_date', ascending: true)
        .order('created_at', ascending: true);

    return (response as List)
        .map((r) => FinancialTransaction.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, double>> _getRunningBalanceMap(String userId) async {
    final allTransactions = await _getAllTransactions(userId);
    double running = 0;
    final result = <String, double>{};

    for (final tx in allTransactions) {
      running += tx.type == 'income' ? tx.amount : -tx.amount;
      result[tx.id] = running;
    }
    return result;
  }

  Future<void> _writeAudit({
    required String userId,
    required String transactionId,
    required String action,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  }) async {
    await _client.from('transaction_audit').insert({
      'transaction_id': transactionId,
      'user_id': userId,
      'action': action,
      'old_data': oldData,
      'new_data': newData,
      'performed_by': userId,
    });
  }

  String _dateOnly(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  List<String> _generateMonthKeys(DateTime start, DateTime end) {
    final keys = <String>[];
    DateTime cursor = DateTime(start.year, start.month, 1);
    final last = DateTime(end.year, end.month, 1);

    while (!cursor.isAfter(last)) {
      keys.add(_monthKey(cursor));
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return keys;
  }

  String _completenessLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Low';
  }

  String _generateToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    final buffer = StringBuffer('shrt_');
    for (int i = 0; i < 12; i++) {
      buffer.write(chars[rand.nextInt(chars.length)]);
    }
    return buffer.toString();
  }
}
