import 'dart:math';

class Expense {
  final String id;
  final String category;
  final String description;
  final double amount;
  final DateTime date;
  final String phase; // 'planting', 'sowing', 'growing', 'harvest', 'post-harvest'

  Expense({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    required this.phase,
  });

  factory Expense.empty() {
    return Expense(
      id: '',
      category: 'Seeds',
      description: '',
      amount: 0,
      date: DateTime.now(),
      phase: 'planting',
    );
  }

  Expense copyWith({
    String? id,
    String? category,
    String? description,
    double? amount,
    DateTime? date,
    String? phase,
  }) {
    return Expense(
      id: id ?? this.id,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      phase: phase ?? this.phase,
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? '',
      category: json['category'] ?? 'Other',
      description: json['description'] ?? '',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : 0.0,
      date: json['expense_date'] is String
          ? DateTime.parse(json['expense_date'])
          : json['date'] is String
              ? DateTime.parse(json['date'])
              : DateTime.now(),
      phase: json['phase'] ?? 'planting',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'description': description,
      'amount': amount,
      'expense_date': date.toIso8601String().split('T').first,
      'phase': phase,
    };
  }
}

// ── Farming Project (upgraded with yield-based revenue & analytics) ──

class FarmingProject {
  final String id;
  final String cropType;
  final double area; // hectares
  final DateTime plantingDate;
  final DateTime harvestDate;
  final double revenue; // actual revenue (manual or yield × price)
  final List<Expense> expenses;
  final DateTime createdDate;
  final String status; // 'active', 'completed', 'cancelled'

  // ── NEW: Yield & market price fields ─────────────────────────
  final double expectedYieldKg;
  final double actualYieldKg;
  final double marketPricePerKg;       // projected price at planting
  final double expectedRevenue;        // expectedYieldKg × marketPricePerKg
  final double actualSalePricePerKg;   // actual sale price recorded on completion

  FarmingProject({
    required this.id,
    required this.cropType,
    required this.area,
    required this.plantingDate,
    required this.harvestDate,
    required this.revenue,
    required this.expenses,
    required this.createdDate,
    required this.status,
    this.expectedYieldKg = 0,
    this.actualYieldKg = 0,
    this.marketPricePerKg = 0,
    this.expectedRevenue = 0,
    this.actualSalePricePerKg = 0,
  });

  // ── Status helpers ───────────────────────────────────────────
  bool get isCompleted => status == 'completed';
  bool get isActive => status == 'active';

  // ── Core financials ──────────────────────────────────────────
  double get totalExpenses => expenses.fold(0, (sum, e) => sum + e.amount);
  double get profit => actualRevenue - totalExpenses;
  double get profitMargin => actualRevenue > 0 ? (profit / actualRevenue * 100) : 0;

  /// Yield-based actual revenue; uses actual sale price if completed, else market price
  double get actualRevenue {
    if (isCompleted && actualYieldKg > 0 && actualSalePricePerKg > 0) {
      return actualYieldKg * actualSalePricePerKg;
    }
    if (actualYieldKg > 0 && marketPricePerKg > 0) {
      return actualYieldKg * marketPricePerKg;
    }
    return revenue;
  }

  /// Projected expected revenue
  double get computedExpectedRevenue {
    if (expectedYieldKg > 0 && marketPricePerKg > 0) {
      return expectedYieldKg * marketPricePerKg;
    }
    return expectedRevenue > 0 ? expectedRevenue : revenue;
  }

  double get expectedProfit => computedExpectedRevenue - totalExpenses;

  // ── Decision-support metrics ─────────────────────────────────
  /// ROI = (Net Profit / Total Expenses) × 100; NaN when no expenses
  double get roi => totalExpenses > 0 ? (profit / totalExpenses * 100) : double.nan;

  /// Display-safe ROI label: shows "N/A" when no cost data
  String get roiLabel => totalExpenses > 0
      ? '${roi.toStringAsFixed(1)}%'
      : 'N/A';

  /// Status-aware revenue label
  String get revenueLabel => isCompleted ? 'Actual Revenue' : 'Projected Revenue';

  /// Status-aware profit label
  String get profitLabel => isCompleted ? 'Net Profit' : 'Projected Net Profit';

  /// Status-aware expenses label
  String get expensesLabel => isCompleted ? 'Total Expenses' : 'Current Expenses';

  /// Cost per hectare
  double get costPerHectare => area > 0 ? totalExpenses / area : 0;

  /// Break-even yield in kg = Total Expenses / Market Price per kg
  double get breakEvenYieldKg =>
      marketPricePerKg > 0 ? totalExpenses / marketPricePerKg : 0;

  /// Revenue variance: actual vs expected
  double get revenueVariance => actualRevenue - computedExpectedRevenue;
  double get revenueVariancePercent =>
      computedExpectedRevenue > 0
          ? (revenueVariance / computedExpectedRevenue * 100)
          : 0;

  /// Yield variance
  double get yieldVariance => actualYieldKg - expectedYieldKg;
  double get yieldVariancePercent =>
      expectedYieldKg > 0 ? (yieldVariance / expectedYieldKg * 100) : 0;

  /// Profit variance
  double get profitVariance => profit - expectedProfit;

  // ── Expense breakdowns ───────────────────────────────────────
  Map<String, double> get expensesByCategory {
    final Map<String, double> result = {};
    for (var expense in expenses) {
      result[expense.category] =
          (result[expense.category] ?? 0) + expense.amount;
    }
    return result;
  }

  Map<String, double> get expensesByPhase {
    final Map<String, double> result = {};
    for (var expense in expenses) {
      result[expense.phase] = (result[expense.phase] ?? 0) + expense.amount;
    }
    return result;
  }

  /// Monthly cash flow: map of YYYY-MM → net amount (negative = expense)
  Map<String, double> get monthlyCashFlow {
    final Map<String, double> flow = {};
    for (var e in expenses) {
      final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
      flow[key] = (flow[key] ?? 0) - e.amount;
    }
    // Add revenue in harvest month
    if (actualRevenue > 0) {
      final hKey =
          '${harvestDate.year}-${harvestDate.month.toString().padLeft(2, '0')}';
      flow[hKey] = (flow[hKey] ?? 0) + actualRevenue;
    }
    return Map.fromEntries(
      flow.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  // ── Copy / serialization ─────────────────────────────────────
  FarmingProject copyWith({
    String? id,
    String? cropType,
    double? area,
    DateTime? plantingDate,
    DateTime? harvestDate,
    double? revenue,
    List<Expense>? expenses,
    DateTime? createdDate,
    String? status,
    double? expectedYieldKg,
    double? actualYieldKg,
    double? marketPricePerKg,
    double? expectedRevenue,
    double? actualSalePricePerKg,
  }) {
    return FarmingProject(
      id: id ?? this.id,
      cropType: cropType ?? this.cropType,
      area: area ?? this.area,
      plantingDate: plantingDate ?? this.plantingDate,
      harvestDate: harvestDate ?? this.harvestDate,
      revenue: revenue ?? this.revenue,
      expenses: expenses ?? this.expenses,
      createdDate: createdDate ?? this.createdDate,
      status: status ?? this.status,
      expectedYieldKg: expectedYieldKg ?? this.expectedYieldKg,
      actualYieldKg: actualYieldKg ?? this.actualYieldKg,
      marketPricePerKg: marketPricePerKg ?? this.marketPricePerKg,
      expectedRevenue: expectedRevenue ?? this.expectedRevenue,
      actualSalePricePerKg: actualSalePricePerKg ?? this.actualSalePricePerKg,
    );
  }

  factory FarmingProject.fromJson(Map<String, dynamic> json) {
    return FarmingProject(
      id: json['id'] ?? '',
      cropType: json['crop_type'] ?? 'Rice',
      area: (json['area_hectares'] is num)
          ? (json['area_hectares'] as num).toDouble()
          : (json['area'] is num)
              ? (json['area'] as num).toDouble()
              : 0.0,
      plantingDate: json['planting_date'] is String
          ? DateTime.parse(json['planting_date'])
          : DateTime.now(),
      harvestDate: json['harvest_date'] is String
          ? DateTime.parse(json['harvest_date'])
          : DateTime.now(),
      revenue: (json['revenue'] is num)
          ? (json['revenue'] as num).toDouble()
          : 0.0,
      expenses: json['expenses'] is List
          ? (json['expenses'] as List)
              .map((e) => Expense.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      createdDate: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      status: json['status'] ?? 'active',
      expectedYieldKg: (json['expected_yield_kg'] is num)
          ? (json['expected_yield_kg'] as num).toDouble()
          : 0.0,
      actualYieldKg: (json['actual_yield_kg'] is num)
          ? (json['actual_yield_kg'] as num).toDouble()
          : 0.0,
      marketPricePerKg: (json['market_price_per_kg'] is num)
          ? (json['market_price_per_kg'] as num).toDouble()
          : 0.0,
      expectedRevenue: (json['expected_revenue'] is num)
          ? (json['expected_revenue'] as num).toDouble()
          : 0.0,
      actualSalePricePerKg: (json['actual_sale_price_per_kg'] is num)
          ? (json['actual_sale_price_per_kg'] as num).toDouble()
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crop_type': cropType,
      'area_hectares': area,
      'planting_date': plantingDate.toIso8601String().split('T').first,
      'harvest_date': harvestDate.toIso8601String().split('T').first,
      'revenue': revenue,
      'status': status,
      'expected_yield_kg': expectedYieldKg,
      'actual_yield_kg': actualYieldKg,
      'market_price_per_kg': marketPricePerKg,
      'expected_revenue': expectedRevenue,
      'actual_sale_price_per_kg': actualSalePricePerKg,
    };
  }
}

// ── Risk Assessment Model ──────────────────────────────────────

class RiskAssessment {
  final double saturationRisk;  // 0-100
  final double marketRisk;      // 0-100
  final double calamityRisk;    // 0-100
  final String saturationLevel; // low/medium/high
  final String marketTrend;     // rising/stable/falling
  final int recentCalamities;

  RiskAssessment({
    this.saturationRisk = 0,
    this.marketRisk = 0,
    this.calamityRisk = 0,
    this.saturationLevel = 'medium',
    this.marketTrend = 'stable',
    this.recentCalamities = 0,
  });

  /// Overall composite risk score (0-100)
  double get overallRisk =>
      (saturationRisk * 0.35) + (marketRisk * 0.35) + (calamityRisk * 0.30);

  String get overallRiskLabel {
    if (overallRisk < 30) return 'Low';
    if (overallRisk < 60) return 'Medium';
    return 'High';
  }

  /// Risk factor for adjusting profit (0.0 – 1.0)
  double get riskFactor => (overallRisk / 100).clamp(0.0, 1.0);

  /// Risk-adjusted profit estimate
  double riskAdjustedProfit(double rawProfit) =>
      rawProfit * (1.0 - riskFactor * 0.5); // discount up to 50%
}

// ── Forecast vs Actual Comparison ──────────────────────────────

class ForecastComparison {
  final String metric;
  final double expected;
  final double actual;

  ForecastComparison({
    required this.metric,
    required this.expected,
    required this.actual,
  });

  double get variance => actual - expected;
  double get variancePercent =>
      expected != 0 ? (variance / expected * 100) : 0;
  bool get isPositive => variance >= 0;
}

// ── ProfitLossData (kept for backward compat) ──────────────────

class ProfitLossData {
  final List<Expense> expenses;
  final double revenue;
  final String cropType;
  final DateTime plantingDate;
  final DateTime harvestDate;

  ProfitLossData({
    required this.expenses,
    required this.revenue,
    required this.cropType,
    required this.plantingDate,
    required this.harvestDate,
  });

  double get totalExpenses => expenses.fold(0, (sum, e) => sum + e.amount);
  double get profit => revenue - totalExpenses;
  double get profitMargin => totalExpenses > 0 ? (profit / revenue * 100) : 0;

  Map<String, double> get expensesByCategory {
    final Map<String, double> result = {};
    for (var expense in expenses) {
      result[expense.category] =
          (result[expense.category] ?? 0) + expense.amount;
    }
    return result;
  }

  Map<String, double> get expensesByPhase {
    final Map<String, double> result = {};
    for (var expense in expenses) {
      result[expense.phase] = (result[expense.phase] ?? 0) + expense.amount;
    }
    return result;
  }
}
