// ─────────────────────────────────────────────────────────────────────────────
// AgriForecastEngine — AgriSense DSS Financial Forecasting Module
// PRD v1.0 §6  Computation Engine
//
// Transforms farm-level declarations into forward-looking financial forecasts.
// All formulas match PRD §6.1–6.5 exactly.
// ─────────────────────────────────────────────────────────────────────────────

import '../data/financial_model_assumptions.dart';

// ── Output models ─────────────────────────────────────────────────────────────

class FarmerForecast {
  final String cropKey;
  final double farmSizeHa;
  // Production
  final double egpKg;           // §6.1  Expected Gross Production
  final double preHarvestLossKg;
  final double postHarvestLossKg;
  final double nsqKg;           // §6.1  Net Sellable Quantity
  // Revenue
  final double forecastedPrice; // §6.2
  final double grossRevenue;    // §6.2
  // Cost
  final double totalProductionCost; // §6.3
  // Derived
  final double nfi;             // §6.4  Net Farm Income
  final double roi;             // §6.4  Return on Investment (%)
  final double costPerKg;       // §6.4  Cost per Kilogram
  final double lossValue;       // §6.4  Loss Value (₱)
  // Market
  final double msi;             // §6.5  Market Saturation Index
  final MsiStatus msiStatus;

  const FarmerForecast({
    required this.cropKey,
    required this.farmSizeHa,
    required this.egpKg,
    required this.preHarvestLossKg,
    required this.postHarvestLossKg,
    required this.nsqKg,
    required this.forecastedPrice,
    required this.grossRevenue,
    required this.totalProductionCost,
    required this.nfi,
    required this.roi,
    required this.costPerKg,
    required this.lossValue,
    required this.msi,
    required this.msiStatus,
  });
}

class ScenarioOutput {
  final String scenarioName;        // 'Best Case' | 'Expected Case' | 'Worst Case'
  final double forecastedPrice;
  final double msi;
  final MsiStatus msiStatus;
  final double avgNfiPerFarmer;
  final double totalMunicipalRevenue;
  final double totalMunicipalNfi;
  final double nsqKg;
  final double egpKg;
  final double grossRevenue;
  final double totalCost;
  final double roi;
  final double lossValue;

  const ScenarioOutput({
    required this.scenarioName,
    required this.forecastedPrice,
    required this.msi,
    required this.msiStatus,
    required this.avgNfiPerFarmer,
    required this.totalMunicipalRevenue,
    required this.totalMunicipalNfi,
    required this.nsqKg,
    required this.egpKg,
    required this.grossRevenue,
    required this.totalCost,
    required this.roi,
    required this.lossValue,
  });
}

class CropScenarioResult {
  final String cropKey;
  final ScenarioOutput best;
  final ScenarioOutput expected;
  final ScenarioOutput worst;
  const CropScenarioResult({required this.cropKey, required this.best, required this.expected, required this.worst});
}

// ── Monthly cash flow entry (§8.2) ───────────────────────────────────────────
class MonthlyCashFlow {
  final String month;
  final double harvestVolumeKg;
  final double expectedRevenue;
  final double cumulativeInputCosts;
  final double netCashFlow;
  const MonthlyCashFlow({
    required this.month,
    required this.harvestVolumeKg,
    required this.expectedRevenue,
    required this.cumulativeInputCosts,
    required this.netCashFlow,
  });
}

// ── Engine ────────────────────────────────────────────────────────────────────

class AgriForecastEngine {

  // ── §6.1  Production Forecast ─────────────────────────────────────────────

  static double computeEGP(double farmSizeHa, String cropKey) {
    final yieldPerHa = kYieldPerHa[cropKey] ?? 8000;
    return farmSizeHa * yieldPerHa;
  }

  static double computeNSQ(double egp, String cropKey, {double? overridePostHarvest}) {
    final pre = kPreHarvestLoss[cropKey] ?? 0.05;
    final post = overridePostHarvest ?? (kPostHarvestLoss[cropKey] ?? 0.08);
    return egp * (1 - pre) * (1 - post);
  }

  // ── §6.2  Revenue Forecast ────────────────────────────────────────────────

  static double computeSupplyChangePct(double msf, String cropKey, double supplyMult) {
    final demand = kMonthlyDemand[cropKey] ?? 50000;
    // Supply change % = (MSF - Demand) / Demand
    final adjustedMsf = msf * supplyMult;
    return (adjustedMsf - demand) / demand;
  }

  static double computeForecastedPrice(String cropKey, double supplyChangePct, double priceMult) {
    final basePrice = kFmBasePrices[cropKey] ?? 50.0;
    final elasticity = kPriceElasticity[cropKey] ?? -0.40;
    // FP = Base Price × priceMult × (1 + elasticity × supplyChange%)
    return basePrice * priceMult * (1 + elasticity * supplyChangePct);
  }

  // ── §6.3  Cost Forecast ───────────────────────────────────────────────────

  static double computeTPC(double farmSizeHa, {double? customCostPerHa}) {
    final costPerHa = customCostPerHa ?? kTotalDefaultCostPerHa;
    return farmSizeHa * costPerHa;
  }

  // ── §6.4  NFI, ROI, CPK, Loss Value ─────────────────────────────────────

  static double computeNFI(double grossRevenue, double tpc) => grossRevenue - tpc;
  static double computeROI(double nfi, double tpc) => tpc == 0 ? 0 : (nfi / tpc) * 100;
  static double computeCPK(double tpc, double nsq) => nsq == 0 ? 0 : tpc / nsq;
  static double computeLossValue(double egp, String cropKey, double forecastedPrice, {double? overridePostHarvest}) {
    final pre = kPreHarvestLoss[cropKey] ?? 0.05;
    final post = overridePostHarvest ?? (kPostHarvestLoss[cropKey] ?? 0.08);
    final totalLossPct = pre + (1 - pre) * post;
    return egp * totalLossPct * forecastedPrice;
  }

  // ── §6.5  MSI ────────────────────────────────────────────────────────────

  static double computeMSI(double msf, String cropKey, double demandMult) {
    final demand = (kMonthlyDemand[cropKey] ?? 50000) * demandMult;
    return demand == 0 ? 0 : msf / demand;
  }

  // ── Full farmer forecast (FR02) ───────────────────────────────────────────

  static FarmerForecast computeFarmerForecast({
    required String cropKey,
    required double farmSizeHa,
    required double municipalSupplyKg, // sum of NSQ for this crop across all declarations
    double? customCostPerHa,
  }) {
    final egp = computeEGP(farmSizeHa, cropKey);
    final pre = kPreHarvestLoss[cropKey] ?? 0.05;
    final post = kPostHarvestLoss[cropKey] ?? 0.08;
    final preHarvestLossKg = egp * pre;
    final postHarvestLossKg = (egp - preHarvestLossKg) * post;
    final nsq = egp * (1 - pre) * (1 - post);

    final supplyChangePct = computeSupplyChangePct(municipalSupplyKg, cropKey, 1.0);
    final fp = computeForecastedPrice(cropKey, supplyChangePct, 1.0);
    final gr = nsq * fp;
    final tpc = computeTPC(farmSizeHa, customCostPerHa: customCostPerHa);
    final nfi = computeNFI(gr, tpc);
    final roi = computeROI(nfi, tpc);
    final cpk = computeCPK(tpc, nsq);
    final lv = computeLossValue(egp, cropKey, fp);
    final msi = computeMSI(municipalSupplyKg, cropKey, 1.0);

    return FarmerForecast(
      cropKey: cropKey,
      farmSizeHa: farmSizeHa,
      egpKg: egp,
      preHarvestLossKg: preHarvestLossKg,
      postHarvestLossKg: postHarvestLossKg,
      nsqKg: nsq,
      forecastedPrice: fp,
      grossRevenue: gr,
      totalProductionCost: tpc,
      nfi: nfi,
      roi: roi,
      costPerKg: cpk,
      lossValue: lv,
      msi: msi,
      msiStatus: getMsiStatus(msi),
    );
  }

  // ── Scenario computation (FR06) ───────────────────────────────────────────

  static ScenarioOutput runScenario({
    required String name,
    required String cropKey,
    required double farmSizeHa,
    required double activeFarmers,
    required double municipalSupplyKg,
    required ScenarioDrivers drivers,
    double? customCostPerHa,
  }) {
    final egp = computeEGP(farmSizeHa, cropKey) * drivers.yieldMult;
    final pre = kPreHarvestLoss[cropKey] ?? 0.05;
    final nsq = egp * (1 - pre) * (1 - drivers.postHarvestLoss);

    final supplyChangePct = computeSupplyChangePct(
        municipalSupplyKg * drivers.supplyMult, cropKey, 1.0);
    final fp = computeForecastedPrice(cropKey, supplyChangePct, drivers.priceMult);
    final gr = nsq * fp;
    final tpc = computeTPC(farmSizeHa, customCostPerHa: customCostPerHa);
    final nfi = computeNFI(gr, tpc);
    final roi = computeROI(nfi, tpc);
    final lv = computeLossValue(egp, cropKey, fp, overridePostHarvest: drivers.postHarvestLoss);
    final msi = computeMSI(municipalSupplyKg * drivers.supplyMult, cropKey, drivers.demandMult);
    final totalRev = gr * activeFarmers;
    final totalNfi = nfi * activeFarmers;
    final avgNfi = activeFarmers == 0 ? 0.0 : totalNfi / activeFarmers;

    return ScenarioOutput(
      scenarioName: name,
      forecastedPrice: fp,
      msi: msi,
      msiStatus: getMsiStatus(msi),
      avgNfiPerFarmer: avgNfi,
      totalMunicipalRevenue: totalRev,
      totalMunicipalNfi: totalNfi,
      nsqKg: nsq,
      egpKg: egp,
      grossRevenue: gr,
      totalCost: tpc,
      roi: roi,
      lossValue: lv,
    );
  }

  static CropScenarioResult computeScenarios({
    required String cropKey,
    required double farmSizeHa,
    required double activeFarmers,
    required double municipalSupplyKg,
    double? customCostPerHa,
  }) {
    return CropScenarioResult(
      cropKey: cropKey,
      best: runScenario(
        name: 'Best Case',
        cropKey: cropKey, farmSizeHa: farmSizeHa,
        activeFarmers: activeFarmers, municipalSupplyKg: municipalSupplyKg,
        drivers: kScenarioBest, customCostPerHa: customCostPerHa,
      ),
      expected: runScenario(
        name: 'Expected Case',
        cropKey: cropKey, farmSizeHa: farmSizeHa,
        activeFarmers: activeFarmers, municipalSupplyKg: municipalSupplyKg,
        drivers: kScenarioExpected, customCostPerHa: customCostPerHa,
      ),
      worst: runScenario(
        name: 'Worst Case',
        cropKey: cropKey, farmSizeHa: farmSizeHa,
        activeFarmers: activeFarmers, municipalSupplyKg: municipalSupplyKg,
        drivers: kScenarioWorst, customCostPerHa: customCostPerHa,
      ),
    );
  }

  // ── §8.2  Municipal Cash Flow Projection ─────────────────────────────────
  // Maps harvest volumes to month-by-month cash flow based on crop calendar

  static List<MonthlyCashFlow> buildMunicipalCashFlow({
    required String cropKey,
    required double totalFarmerCount,
    required double avgFarmSizeHa,
    required double forecastedPrice,
    required double costPerHa,
  }) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    // Input costs happen in months before harvest (spread across planting months)
    final yieldPerHa = kYieldPerHa[cropKey] ?? 8000;
    final costPerFarmer = avgFarmSizeHa * costPerHa;
    final totalCosts = totalFarmerCount * costPerFarmer;
    final pre = kPreHarvestLoss[cropKey] ?? 0.05;
    final post = kPostHarvestLoss[cropKey] ?? 0.08;

    // Placeholder monthly distribution — in production, use actual harvest dates from declarations
    const harvestPct = [0.0, 0.0, 0.08, 0.12, 0.15, 0.10, 0.08, 0.12, 0.15, 0.10, 0.07, 0.03];
    const inputCostPct = [0.12, 0.15, 0.15, 0.12, 0.08, 0.08, 0.08, 0.05, 0.05, 0.04, 0.04, 0.04];

    return List.generate(12, (i) {
      final harvestVol = totalFarmerCount * avgFarmSizeHa * yieldPerHa *
          (1 - pre) * (1 - post) * harvestPct[i];
      final revenue = harvestVol * forecastedPrice;
      final costs = totalCosts * inputCostPct[i];
      return MonthlyCashFlow(
        month: months[i],
        harvestVolumeKg: harvestVol,
        expectedRevenue: revenue,
        cumulativeInputCosts: costs,
        netCashFlow: revenue - costs,
      );
    });
  }
}
