class CashFlowMonth {
  final String month; // YYYY-MM
  final double income;
  final double expenses;
  final double net;
  final double balance;

  CashFlowMonth({
    required this.month,
    required this.income,
    required this.expenses,
    required this.net,
    required this.balance,
  });
}

class CashFlowReport {
  final DateTime startDate;
  final DateTime endDate;
  final double openingBalance;
  final double totalIncome;
  final double totalExpenses;
  final double closingBalance;
  final List<CashFlowMonth> monthlyBreakdown;

  CashFlowReport({
    required this.startDate,
    required this.endDate,
    required this.openingBalance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.closingBalance,
    required this.monthlyBreakdown,
  });
}

class CreditReadinessReport {
  final DateTime startDate;
  final DateTime endDate;
  final double totalIncome;
  final double totalExpenses;
  final double net;
  final double completenessScore;
  final String completenessLabel;
  final double averageMonthlyNetIncome;
  final double monthlyRepaymentCapacity;
  final String disclaimer;

  CreditReadinessReport({
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpenses,
    required this.net,
    required this.completenessScore,
    required this.completenessLabel,
    required this.averageMonthlyNetIncome,
    required this.monthlyRepaymentCapacity,
    required this.disclaimer,
  });
}
