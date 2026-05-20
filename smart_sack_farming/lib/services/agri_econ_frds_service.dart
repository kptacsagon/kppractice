// ─────────────────────────────────────────────────────────────────────────────
// AgriEcon-FRDS Service — Agricultural Economic Intelligence & Financial Risk DSS
//
// PRD v1.0 — Implements data models, mock datasets, and computation logic for
// all seven modules (M1–M7). Computations are deterministic so the dashboard
// reflects realistic figures for thesis demonstration without external feeds.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math';

// ─── M1: Advanced Financial Modeling ─────────────────────────────────────────

class CropCycleRecord {
  final String id;
  final String farmerId;
  final String farmerName;
  final String barangay;
  final String crop;
  final String variety;
  final double areaHa;
  final double yieldKg;
  final double farmGatePrice;     // PHP/kg
  final double seedCost;
  final double fertilizerCost;
  final double pesticideCost;
  final double laborCost;
  final double irrigationCost;
  final double transportCost;
  final double landCost;          // rental or amortization
  final double equipmentDeprec;
  final DateTime plantingDate;
  final DateTime harvestDate;

  const CropCycleRecord({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.barangay,
    required this.crop,
    required this.variety,
    required this.areaHa,
    required this.yieldKg,
    required this.farmGatePrice,
    required this.seedCost,
    required this.fertilizerCost,
    required this.pesticideCost,
    required this.laborCost,
    required this.irrigationCost,
    required this.transportCost,
    required this.landCost,
    required this.equipmentDeprec,
    required this.plantingDate,
    required this.harvestDate,
  });

  double get grossRevenue => yieldKg * farmGatePrice;
  double get totalVariableCost =>
      seedCost + fertilizerCost + pesticideCost + laborCost +
      irrigationCost + transportCost;
  double get totalFixedCost => landCost + equipmentDeprec;
  double get totalCost => totalVariableCost + totalFixedCost;
  double get netFarmIncome => grossRevenue - totalCost;
  double get contributionMargin => grossRevenue - totalVariableCost;
  double get cmr => grossRevenue == 0 ? 0 : (contributionMargin / grossRevenue) * 100;
  double get breakEvenPrice => yieldKg == 0 ? 0 : totalCost / yieldKg;
  double get breakEvenRevenue => cmr == 0 ? 0 : (totalFixedCost / cmr) * 100;
  double get safetyMarginPct =>
      grossRevenue == 0 ? 0 : ((grossRevenue - breakEvenRevenue) / grossRevenue) * 100;
}

class FinancialScenario {
  final String label;
  final double inputCostMultiplier;
  final double yieldMultiplier;
  final double priceMultiplier;
  const FinancialScenario(this.label, this.inputCostMultiplier, this.yieldMultiplier, this.priceMultiplier);

  static const base       = FinancialScenario('Base Case',         1.00, 1.00, 1.00);
  static const optimistic = FinancialScenario('Optimistic Case',   0.85, 1.20, 1.10);
  static const pessimistic = FinancialScenario('Pessimistic Case', 1.20, 0.75, 0.70);

  double computeNfi(CropCycleRecord r) {
    final revenue = (r.yieldKg * yieldMultiplier) * (r.farmGatePrice * priceMultiplier);
    final costs   = (r.totalVariableCost * inputCostMultiplier) + r.totalFixedCost;
    return revenue - costs;
  }
}

// ─── M2: Risk-Adjusted Profitability ─────────────────────────────────────────

class MonteCarloResult {
  final double expectedNfi;
  final double stdDev;
  final double probLoss;
  final double var90;
  final double var95;
  final List<double> samples;

  const MonteCarloResult({
    required this.expectedNfi,
    required this.stdDev,
    required this.probLoss,
    required this.var90,
    required this.var95,
    required this.samples,
  });
}

class CompositeRiskScore {
  final double priceVol;       // 0-20
  final double yieldRisk;      // 0-20
  final double weatherRisk;    // 0-25
  final double creditExposure; // 0-20
  final double marketAccess;   // 0-15
  CompositeRiskScore({
    required this.priceVol,
    required this.yieldRisk,
    required this.weatherRisk,
    required this.creditExposure,
    required this.marketAccess,
  });
  double get total => priceVol + yieldRisk + weatherRisk + creditExposure + marketAccess;
  String get classification {
    if (total <= 30) return 'Low Risk';
    if (total <= 55) return 'Moderate Risk';
    if (total <= 75) return 'High Risk';
    return 'Critical Risk';
  }
}

class RiskAnalyzer {
  static final _rng = Random(42); // deterministic for thesis reproducibility

  /// Monte Carlo simulation per PRD §6.3 — log-normal price, normal yield,
  /// triangular variable costs, Bernoulli weather event.
  static MonteCarloResult monteCarlo(CropCycleRecord r, {int iterations = 1000}) {
    final samples = <double>[];
    final priceMu = log(r.farmGatePrice);
    final priceSigma = 0.20;
    final yieldSigma = r.yieldKg * 0.18;
    final weatherProb = 0.20;

    for (int i = 0; i < iterations; i++) {
      // Log-normal price draw
      final z1 = _stdNormal();
      final price = exp(priceMu + priceSigma * z1);
      // Normal yield draw
      final z2 = _stdNormal();
      final yieldDraw = max(0.0, r.yieldKg + yieldSigma * z2);
      // Triangular variable cost (min 0.85×, mode 1.0×, max 1.25×)
      final u = _rng.nextDouble();
      const minM = 0.85, mode = 1.0, maxM = 1.25;
      final c = (mode - minM) / (maxM - minM);
      final costMult = u < c
          ? minM + sqrt(u * (maxM - minM) * (mode - minM))
          : maxM - sqrt((1 - u) * (maxM - minM) * (maxM - mode));
      // Bernoulli weather event with 0.55 loss multiplier on revenue
      final weatherLoss = _rng.nextDouble() < weatherProb ? 0.55 : 1.0;
      final revenue = price * yieldDraw * weatherLoss;
      final cost = r.totalVariableCost * costMult + r.totalFixedCost;
      samples.add(revenue - cost);
    }

    final mean = samples.reduce((a, b) => a + b) / samples.length;
    final variance = samples
        .map((x) => pow(x - mean, 2).toDouble())
        .reduce((a, b) => a + b) / samples.length;
    final sd = sqrt(variance);
    final lossCount = samples.where((x) => x < 0).length;
    return MonteCarloResult(
      expectedNfi: mean,
      stdDev: sd,
      probLoss: lossCount / samples.length,
      var90: mean - 1.28 * sd,
      var95: mean - 1.645 * sd,
      samples: samples,
    );
  }

  static double _stdNormal() {
    final u1 = _rng.nextDouble().clamp(1e-9, 1.0);
    final u2 = _rng.nextDouble();
    return sqrt(-2.0 * log(u1)) * cos(2 * pi * u2);
  }

  /// Composite Risk Score per PRD §6.5
  static CompositeRiskScore crs(CropCycleRecord r, MonteCarloResult mc) {
    final priceVol     = (mc.stdDev / r.grossRevenue.abs().clamp(1, double.infinity) * 100).clamp(0, 20).toDouble();
    final yieldRisk    = (mc.probLoss * 40).clamp(0, 20).toDouble();
    final weatherRisk  = (mc.probLoss * 50).clamp(0, 25).toDouble();
    final creditExp    = (r.totalCost / r.grossRevenue.abs().clamp(1, double.infinity) * 18).clamp(0, 20).toDouble();
    final marketAccess = ((1 - r.cmr / 100).abs() * 25).clamp(0, 15).toDouble();
    return CompositeRiskScore(
      priceVol: priceVol,
      yieldRisk: yieldRisk,
      weatherRisk: weatherRisk,
      creditExposure: creditExp,
      marketAccess: marketAccess,
    );
  }
}

// ─── M3: Oversupply Prediction ────────────────────────────────────────────────

class HarvestWeekProjection {
  final int weekIndex;             // 0..15 (rolling 16-week window)
  final DateTime weekStart;
  final String commodity;
  final double projectedVolumeKg;
  final double historicalAvgKg;
  final double marketAbsorptionKg;
  HarvestWeekProjection({
    required this.weekIndex,
    required this.weekStart,
    required this.commodity,
    required this.projectedVolumeKg,
    required this.historicalAvgKg,
    required this.marketAbsorptionKg,
  });
  double get volumeDeviationPct =>
      historicalAvgKg == 0 ? 0 : (projectedVolumeKg - historicalAvgKg) / historicalAvgKg * 100;
  double get ori =>
      marketAbsorptionKg == 0 ? 0 : projectedVolumeKg / marketAbsorptionKg;
  String get alertLevel {
    if (ori < 0.85) return 'Green';
    if (ori < 1.10) return 'Yellow';
    if (ori < 1.35) return 'Orange';
    return 'Red';
  }
  String get status {
    if (ori < 0.85) return 'Supply Deficit';
    if (ori < 1.10) return 'Market Balance';
    if (ori < 1.35) return 'Moderate Oversupply';
    return 'Critical Oversupply';
  }
}

// ─── M4: Debt & Loan Analytics ────────────────────────────────────────────────

class LoanRecord {
  final String id;
  final String farmerId;
  final String farmerName;
  final String lenderType;     // formal_bank | cooperative | lgu | informal | acpc
  final String purpose;
  final double principal;
  final double interestRateAnnual;
  final int termMonths;
  final DateTime disbursementDate;
  final double outstandingBalance;
  final int latePayments;
  final String status;         // current | past_due | restructured

  const LoanRecord({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.lenderType,
    required this.purpose,
    required this.principal,
    required this.interestRateAnnual,
    required this.termMonths,
    required this.disbursementDate,
    required this.outstandingBalance,
    required this.latePayments,
    required this.status,
  });

  double get annualDebtService =>
      (principal / (termMonths / 12)) + (outstandingBalance * interestRateAnnual);
}

class DebtMetrics {
  final double dscr, dti, ltAr, ibr;
  final double dds;
  DebtMetrics({required this.dscr, required this.dti, required this.ltAr, required this.ibr, required this.dds});
  String get serviceability {
    if (dscr > 1.5) return 'Strong';
    if (dscr >= 1.0) return 'Adequate';
    if (dscr >= 0.75) return 'Stressed';
    return 'Distressed';
  }
}

class DebtAnalyzer {
  static DebtMetrics compute(List<LoanRecord> loans, double netFarmIncome, double farmAssetValue, double grossRevenue) {
    if (loans.isEmpty) {
      return DebtMetrics(dscr: 99, dti: 0, ltAr: 0, ibr: 0, dds: 0);
    }
    final totalOutstanding = loans.fold(0.0, (s, l) => s + l.outstandingBalance);
    final totalDebtService = loans.fold(0.0, (s, l) => s + l.annualDebtService);
    final totalInterest = loans.fold(0.0, (s, l) => s + (l.outstandingBalance * l.interestRateAnnual));
    final informalPct = loans.where((l) => l.lenderType == 'informal').fold(0.0, (s, l) => s + l.outstandingBalance) / totalOutstanding;
    final lateCount = loans.fold(0, (s, l) => s + l.latePayments);
    final activeLoanCount = loans.where((l) => l.status != 'restructured').length;

    final dscr = totalDebtService == 0 ? 99.0 : netFarmIncome / totalDebtService;
    final dti = netFarmIncome.abs() == 0 ? 99.0 : totalOutstanding / netFarmIncome.abs();
    final ltAr = farmAssetValue == 0 ? 0.0 : totalOutstanding / farmAssetValue;
    final ibr = grossRevenue == 0 ? 0.0 : (totalInterest / grossRevenue) * 100;

    // DDS components per PRD §8.5
    final dscrScore = (30 - (dscr * 10).clamp(0, 30)).clamp(0.0, 30.0);
    final concentrationScore = (informalPct * 25).clamp(0.0, 25.0);
    final delinquencyScore = (lateCount * 4.0).clamp(0.0, 20.0);
    final dtiScore = (dti * 5).clamp(0.0, 15.0);
    final complexityScore = (activeLoanCount > 3 ? 10.0 : activeLoanCount * 2.5);
    final dds = dscrScore + concentrationScore + delinquencyScore + dtiScore + complexityScore;

    return DebtMetrics(
      dscr: dscr, dti: dti, ltAr: ltAr, ibr: ibr, dds: dds.clamp(0.0, 100.0),
    );
  }

  /// Restructuring simulator — extends term, reduces rate, or forgives partial balance.
  static DebtMetrics simulateRestructuring(
      List<LoanRecord> loans, double netFarmIncome, double farmAssetValue, double grossRevenue, {
        double termExtensionMonths = 0,
        double rateReduction = 0,
        double partialForgivenessPct = 0,
      }) {
    final restructured = loans.map((l) => LoanRecord(
      id: l.id, farmerId: l.farmerId, farmerName: l.farmerName,
      lenderType: l.lenderType, purpose: l.purpose,
      principal: l.principal,
      interestRateAnnual: (l.interestRateAnnual - rateReduction).clamp(0.01, 1.0),
      termMonths: (l.termMonths + termExtensionMonths.toInt()),
      disbursementDate: l.disbursementDate,
      outstandingBalance: l.outstandingBalance * (1 - partialForgivenessPct),
      latePayments: l.latePayments, status: 'restructured',
    )).toList();
    return compute(restructured, netFarmIncome, farmAssetValue, grossRevenue);
  }
}

// ─── M5: Behavioral Farmer Modeling ───────────────────────────────────────────

class BehavioralProfile {
  final String farmerId;
  final String farmerName;
  final String riskAttitude;   // Risk Averse | Risk Neutral | Risk Tolerant | Loss Averse
  final List<String> biasFlags;
  final double advisoryComplianceRate;
  final double diversificationIndex; // 0..1
  final String sellingPattern;       // Panic Sell | Optimal | Late Hold
  const BehavioralProfile({
    required this.farmerId,
    required this.farmerName,
    required this.riskAttitude,
    required this.biasFlags,
    required this.advisoryComplianceRate,
    required this.diversificationIndex,
    required this.sellingPattern,
  });

  String get advisoryFraming {
    switch (riskAttitude) {
      case 'Risk Averse':   return 'Safety-first; emphasize guaranteed programs';
      case 'Loss Averse':   return 'Loss-prevention framing; avoid gain framing';
      case 'Risk Tolerant': return 'Data-heavy; mandatory CRS disclosure';
      default:              return 'Standard probability-based briefing';
    }
  }
}

// ─── M6: Intervention Economics Simulation ────────────────────────────────────

enum InterventionType {
  inputSubsidy,
  priceSupport,
  postHarvestInfra,
  loanProgram,
  marketLinkage,
  diversificationIncentive,
  cooperativeSupport,
}

extension InterventionLabel on InterventionType {
  String get label {
    switch (this) {
      case InterventionType.inputSubsidy:             return 'Input Subsidy Program';
      case InterventionType.priceSupport:             return 'Price Support Mechanism';
      case InterventionType.postHarvestInfra:         return 'Post-Harvest Infrastructure';
      case InterventionType.loanProgram:              return 'Production Loan Program';
      case InterventionType.marketLinkage:            return 'Market Linkage Program';
      case InterventionType.diversificationIncentive: return 'Crop Diversification Incentive';
      case InterventionType.cooperativeSupport:       return 'Cooperative Consolidation Support';
    }
  }
}

class InterventionScenario {
  final String name;
  final InterventionType type;
  final double budgetPhp;
  final int beneficiaries;
  final double incomeUpliftPerFarmer;
  final double debtPreventionPerFarmer;
  final double marketStabilizationValue;
  final double multiplierCoefficient;
  final double opportunityCostRate;
  final int termYears;
  final double adminCostPct;
  const InterventionScenario({
    required this.name,
    required this.type,
    required this.budgetPhp,
    required this.beneficiaries,
    required this.incomeUpliftPerFarmer,
    required this.debtPreventionPerFarmer,
    required this.marketStabilizationValue,
    this.multiplierCoefficient = 1.6,
    this.opportunityCostRate = 0.05,
    this.termYears = 1,
    this.adminCostPct = 0.12,
  });

  double get directCost => budgetPhp;
  double get adminCost => budgetPhp * adminCostPct;
  double get opportunityCost => budgetPhp * opportunityCostRate * termYears;
  double get totalCost => directCost + adminCost + opportunityCost;

  double get incomeGain => incomeUpliftPerFarmer * beneficiaries;
  double get debtPrevention => debtPreventionPerFarmer * beneficiaries;
  double get multiplierBenefit => incomeGain * multiplierCoefficient;
  double get totalBenefit => incomeGain + debtPrevention + marketStabilizationValue + multiplierBenefit;

  double get bcr => totalCost == 0 ? 0 : totalBenefit / totalCost;
  double get ropi => totalCost == 0 ? 0 : (totalBenefit - totalCost) / totalCost * 100;
  double get npv => totalBenefit - totalCost;
  int get paybackSeasons {
    if (totalBenefit <= 0) return 99;
    return ((totalCost / totalBenefit) * 2).ceil().clamp(1, 99);
  }
}

// ─── M7: Municipal Agricultural Intelligence ──────────────────────────────────

class BarangayIntel {
  final String barangay;
  final int farmingHouseholds;
  final double riceHa;
  final double cornHa;
  final double vegetableHa;
  final double hvcHa;
  final double orchardHa;
  final double idleHa;
  final double avgYieldPerHa;
  final double avgRevenuePerHa;
  final double avgCrs;
  final double pctHighDistress;
  final double oriContribution;
  final double interventionCoveragePct;
  const BarangayIntel({
    required this.barangay,
    required this.farmingHouseholds,
    required this.riceHa,
    required this.cornHa,
    required this.vegetableHa,
    required this.hvcHa,
    required this.orchardHa,
    required this.idleHa,
    required this.avgYieldPerHa,
    required this.avgRevenuePerHa,
    required this.avgCrs,
    required this.pctHighDistress,
    required this.oriContribution,
    required this.interventionCoveragePct,
  });
  double get totalHa => riceHa + cornHa + vegetableHa + hvcHa + orchardHa + idleHa;
  double get landProductivityIndex => avgRevenuePerHa;
}

// ─── Service: mock data provider ──────────────────────────────────────────────

class AgriEconFrdsService {
  static final _instance = AgriEconFrdsService._();
  factory AgriEconFrdsService() => _instance;
  AgriEconFrdsService._();

  // ── Demo crop cycle dataset ─────────────────────────────────────────────────
  List<CropCycleRecord> get cropCycles => [
    CropCycleRecord(
      id: 'C001', farmerId: 'F101', farmerName: 'Juan Dela Cruz', barangay: 'Buenavista',
      crop: 'Palay', variety: 'NSIC Rc 222',
      areaHa: 2.5, yieldKg: 8750, farmGatePrice: 21.50,
      seedCost: 4200, fertilizerCost: 21500, pesticideCost: 6800,
      laborCost: 19500, irrigationCost: 3200, transportCost: 4200,
      landCost: 12000, equipmentDeprec: 3500,
      plantingDate: DateTime(2025, 11, 15), harvestDate: DateTime(2026, 3, 10),
    ),
    CropCycleRecord(
      id: 'C002', farmerId: 'F102', farmerName: 'Maria Santos', barangay: 'Cabilauan',
      crop: 'Ampalaya', variety: 'Galaxy',
      areaHa: 0.75, yieldKg: 6800, farmGatePrice: 38.00,
      seedCost: 3500, fertilizerCost: 14200, pesticideCost: 9500,
      laborCost: 22500, irrigationCost: 1800, transportCost: 3800,
      landCost: 6500, equipmentDeprec: 1800,
      plantingDate: DateTime(2026, 1, 5), harvestDate: DateTime(2026, 4, 28),
    ),
    CropCycleRecord(
      id: 'C003', farmerId: 'F103', farmerName: 'Pedro Reyes', barangay: 'Alegria',
      crop: 'Corn', variety: 'Bt Yellow',
      areaHa: 1.8, yieldKg: 9200, farmGatePrice: 18.20,
      seedCost: 8800, fertilizerCost: 19500, pesticideCost: 4200,
      laborCost: 14500, irrigationCost: 0, transportCost: 3500,
      landCost: 8500, equipmentDeprec: 2400,
      plantingDate: DateTime(2025, 12, 8), harvestDate: DateTime(2026, 4, 15),
    ),
    CropCycleRecord(
      id: 'C004', farmerId: 'F104', farmerName: 'Rosa Villanueva', barangay: 'Buenavista',
      crop: 'Tomato', variety: 'Diamante Max',
      areaHa: 0.5, yieldKg: 4500, farmGatePrice: 32.00,
      seedCost: 2200, fertilizerCost: 9800, pesticideCost: 6500,
      laborCost: 16800, irrigationCost: 1200, transportCost: 2800,
      landCost: 4500, equipmentDeprec: 1200,
      plantingDate: DateTime(2025, 12, 20), harvestDate: DateTime(2026, 4, 5),
    ),
    CropCycleRecord(
      id: 'C005', farmerId: 'F105', farmerName: 'Carlos Mendoza', barangay: 'Canabuan',
      crop: 'Eggplant', variety: 'Mara',
      areaHa: 0.6, yieldKg: 5400, farmGatePrice: 28.50,
      seedCost: 2800, fertilizerCost: 11500, pesticideCost: 7200,
      laborCost: 18500, irrigationCost: 1500, transportCost: 3200,
      landCost: 5200, equipmentDeprec: 1400,
      plantingDate: DateTime(2026, 1, 12), harvestDate: DateTime(2026, 5, 8),
    ),
    CropCycleRecord(
      id: 'C006', farmerId: 'F106', farmerName: 'Linda Garcia', barangay: 'San Isidro',
      crop: 'Cabbage', variety: 'Scorpio',
      areaHa: 0.4, yieldKg: 6200, farmGatePrice: 22.00,
      seedCost: 1800, fertilizerCost: 8500, pesticideCost: 4800,
      laborCost: 12500, irrigationCost: 900, transportCost: 2200,
      landCost: 3500, equipmentDeprec: 950,
      plantingDate: DateTime(2026, 2, 1), harvestDate: DateTime(2026, 5, 20),
    ),
  ];

  // ── Demo loan dataset ────────────────────────────────────────────────────────
  List<LoanRecord> get loans => [
    LoanRecord(id: 'L001', farmerId: 'F101', farmerName: 'Juan Dela Cruz',
      lenderType: 'formal_bank', purpose: 'production_input',
      principal: 45000, interestRateAnnual: 0.08, termMonths: 12,
      disbursementDate: DateTime(2025, 10, 1), outstandingBalance: 32000,
      latePayments: 1, status: 'current'),
    LoanRecord(id: 'L002', farmerId: 'F101', farmerName: 'Juan Dela Cruz',
      lenderType: 'informal', purpose: 'consumption',
      principal: 15000, interestRateAnnual: 0.60, termMonths: 6,
      disbursementDate: DateTime(2025, 12, 15), outstandingBalance: 12500,
      latePayments: 2, status: 'past_due'),
    LoanRecord(id: 'L003', farmerId: 'F102', farmerName: 'Maria Santos',
      lenderType: 'cooperative', purpose: 'production_input',
      principal: 25000, interestRateAnnual: 0.10, termMonths: 10,
      disbursementDate: DateTime(2025, 12, 1), outstandingBalance: 18000,
      latePayments: 0, status: 'current'),
    LoanRecord(id: 'L004', farmerId: 'F103', farmerName: 'Pedro Reyes',
      lenderType: 'lgu', purpose: 'equipment',
      principal: 80000, interestRateAnnual: 0.04, termMonths: 36,
      disbursementDate: DateTime(2024, 8, 1), outstandingBalance: 52000,
      latePayments: 0, status: 'current'),
    LoanRecord(id: 'L005', farmerId: 'F104', farmerName: 'Rosa Villanueva',
      lenderType: 'informal', purpose: 'production_input',
      principal: 20000, interestRateAnnual: 0.72, termMonths: 4,
      disbursementDate: DateTime(2025, 11, 20), outstandingBalance: 17500,
      latePayments: 3, status: 'past_due'),
    LoanRecord(id: 'L006', farmerId: 'F105', farmerName: 'Carlos Mendoza',
      lenderType: 'acpc', purpose: 'production_input',
      principal: 30000, interestRateAnnual: 0.06, termMonths: 12,
      disbursementDate: DateTime(2025, 11, 1), outstandingBalance: 22500,
      latePayments: 0, status: 'current'),
    LoanRecord(id: 'L007', farmerId: 'F106', farmerName: 'Linda Garcia',
      lenderType: 'cooperative', purpose: 'production_input',
      principal: 18000, interestRateAnnual: 0.10, termMonths: 8,
      disbursementDate: DateTime(2026, 1, 5), outstandingBalance: 16200,
      latePayments: 1, status: 'current'),
  ];

  List<LoanRecord> loansForFarmer(String farmerId) =>
      loans.where((l) => l.farmerId == farmerId).toList();

  // ── M3: Harvest calendar / oversupply projections ───────────────────────────
  List<HarvestWeekProjection> harvestProjections() {
    final result = <HarvestWeekProjection>[];
    final commodities = ['Palay', 'Corn', 'Ampalaya', 'Tomato', 'Eggplant'];
    final baseAbsorption = {
      'Palay': 25000.0, 'Corn': 18000.0, 'Ampalaya': 8000.0,
      'Tomato': 6500.0, 'Eggplant': 7200.0,
    };
    final volumeProfiles = {
      'Palay':    [4000, 8000, 14000, 22000, 32000, 28000, 18000, 9000, 5000, 3000, 2500, 2000, 1800, 1500, 1300, 1100],
      'Corn':     [2000, 4500, 8000, 16000, 22000, 19000, 12000, 6500, 3800, 2500, 2000, 1700, 1500, 1300, 1100, 950],
      'Ampalaya': [3500, 5800, 8500, 11200, 9500, 7800, 5500, 3800, 2800, 2200, 1900, 1700, 1500, 1400, 1300, 1200],
      'Tomato':   [3000, 5200, 7800, 9800, 8200, 6500, 4500, 3200, 2400, 2000, 1700, 1500, 1300, 1200, 1100, 1000],
      'Eggplant': [3200, 5500, 7900, 9000, 7600, 6200, 4400, 3000, 2300, 1900, 1650, 1450, 1300, 1200, 1100, 1000],
    };
    final start = DateTime(2026, 5, 1);
    for (final c in commodities) {
      for (int w = 0; w < 16; w++) {
        final projected = volumeProfiles[c]![w].toDouble();
        final histAvg = projected * (0.78 + (w % 5) * 0.04);
        result.add(HarvestWeekProjection(
          weekIndex: w,
          weekStart: start.add(Duration(days: w * 7)),
          commodity: c,
          projectedVolumeKg: projected,
          historicalAvgKg: histAvg,
          marketAbsorptionKg: baseAbsorption[c]!,
        ));
      }
    }
    return result;
  }

  /// Returns weeks with active oversupply alerts (Orange or Red).
  List<HarvestWeekProjection> activeAlerts() =>
      harvestProjections().where((p) => p.alertLevel == 'Orange' || p.alertLevel == 'Red').toList();

  // ── M5: Behavioral profiles ─────────────────────────────────────────────────
  List<BehavioralProfile> get behavioralProfiles => const [
    BehavioralProfile(
      farmerId: 'F101', farmerName: 'Juan Dela Cruz',
      riskAttitude: 'Risk Averse',
      biasFlags: ['Anchoring Bias', 'Status Quo Bias'],
      advisoryComplianceRate: 0.62,
      diversificationIndex: 0.21,
      sellingPattern: 'Panic Sell',
    ),
    BehavioralProfile(
      farmerId: 'F102', farmerName: 'Maria Santos',
      riskAttitude: 'Risk Neutral',
      biasFlags: ['Optimism Bias'],
      advisoryComplianceRate: 0.81,
      diversificationIndex: 0.58,
      sellingPattern: 'Optimal',
    ),
    BehavioralProfile(
      farmerId: 'F103', farmerName: 'Pedro Reyes',
      riskAttitude: 'Risk Tolerant',
      biasFlags: ['Optimism Bias', 'Sunk Cost Fallacy'],
      advisoryComplianceRate: 0.55,
      diversificationIndex: 0.35,
      sellingPattern: 'Late Hold',
    ),
    BehavioralProfile(
      farmerId: 'F104', farmerName: 'Rosa Villanueva',
      riskAttitude: 'Loss Averse',
      biasFlags: ['Availability Heuristic', 'Herding Behavior', 'Sunk Cost Fallacy'],
      advisoryComplianceRate: 0.41,
      diversificationIndex: 0.18,
      sellingPattern: 'Panic Sell',
    ),
    BehavioralProfile(
      farmerId: 'F105', farmerName: 'Carlos Mendoza',
      riskAttitude: 'Risk Neutral',
      biasFlags: ['Herding Behavior'],
      advisoryComplianceRate: 0.74,
      diversificationIndex: 0.62,
      sellingPattern: 'Optimal',
    ),
    BehavioralProfile(
      farmerId: 'F106', farmerName: 'Linda Garcia',
      riskAttitude: 'Risk Averse',
      biasFlags: ['Anchoring Bias'],
      advisoryComplianceRate: 0.69,
      diversificationIndex: 0.44,
      sellingPattern: 'Optimal',
    ),
  ];

  // ── M6: Pre-loaded intervention scenarios ───────────────────────────────────
  List<InterventionScenario> get demoInterventions => const [
    InterventionScenario(
      name: 'Fertilizer Subsidy — Palay Belt',
      type: InterventionType.inputSubsidy,
      budgetPhp: 1_500_000, beneficiaries: 250,
      incomeUpliftPerFarmer: 8500,
      debtPreventionPerFarmer: 2200,
      marketStabilizationValue: 0,
    ),
    InterventionScenario(
      name: 'Ampalaya Price Floor — Harvest Peak',
      type: InterventionType.priceSupport,
      budgetPhp: 900_000, beneficiaries: 95,
      incomeUpliftPerFarmer: 6500,
      debtPreventionPerFarmer: 1800,
      marketStabilizationValue: 425_000,
    ),
    InterventionScenario(
      name: 'Communal Dryer — Buenavista',
      type: InterventionType.postHarvestInfra,
      budgetPhp: 3_500_000, beneficiaries: 420,
      incomeUpliftPerFarmer: 4200,
      debtPreventionPerFarmer: 1100,
      marketStabilizationValue: 280_000,
      termYears: 5, adminCostPct: 0.08,
    ),
    InterventionScenario(
      name: 'SURE-Aid Loan Restructuring',
      type: InterventionType.loanProgram,
      budgetPhp: 2_200_000, beneficiaries: 180,
      incomeUpliftPerFarmer: 3800,
      debtPreventionPerFarmer: 9500,
      marketStabilizationValue: 0,
    ),
  ];

  // ── M7: Barangay intelligence ───────────────────────────────────────────────
  List<BarangayIntel> get barangayIntel => const [
    BarangayIntel(barangay: 'Buenavista', farmingHouseholds: 312,
      riceHa: 145, cornHa: 38, vegetableHa: 22, hvcHa: 18, orchardHa: 12, idleHa: 18,
      avgYieldPerHa: 3850, avgRevenuePerHa: 78500, avgCrs: 48,
      pctHighDistress: 0.19, oriContribution: 0.28, interventionCoveragePct: 0.42),
    BarangayIntel(barangay: 'Alegria', farmingHouseholds: 198,
      riceHa: 95, cornHa: 62, vegetableHa: 15, hvcHa: 8, orchardHa: 6, idleHa: 14,
      avgYieldPerHa: 3420, avgRevenuePerHa: 68200, avgCrs: 52,
      pctHighDistress: 0.22, oriContribution: 0.18, interventionCoveragePct: 0.35),
    BarangayIntel(barangay: 'Cabilauan', farmingHouseholds: 245,
      riceHa: 88, cornHa: 28, vegetableHa: 48, hvcHa: 32, orchardHa: 10, idleHa: 9,
      avgYieldPerHa: 4180, avgRevenuePerHa: 92800, avgCrs: 38,
      pctHighDistress: 0.11, oriContribution: 0.22, interventionCoveragePct: 0.58),
    BarangayIntel(barangay: 'Canabuan', farmingHouseholds: 168,
      riceHa: 72, cornHa: 35, vegetableHa: 24, hvcHa: 14, orchardHa: 8, idleHa: 12,
      avgYieldPerHa: 3580, avgRevenuePerHa: 72400, avgCrs: 56,
      pctHighDistress: 0.28, oriContribution: 0.15, interventionCoveragePct: 0.31),
    BarangayIntel(barangay: 'San Isidro', farmingHouseholds: 285,
      riceHa: 122, cornHa: 42, vegetableHa: 38, hvcHa: 22, orchardHa: 15, idleHa: 16,
      avgYieldPerHa: 3920, avgRevenuePerHa: 81600, avgCrs: 44,
      pctHighDistress: 0.16, oriContribution: 0.17, interventionCoveragePct: 0.48),
  ];
}
