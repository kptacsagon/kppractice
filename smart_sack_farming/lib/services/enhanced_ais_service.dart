import '../../models/agri_financial_model.dart';
import '../../models/planting_intention.dart';

/// Enhanced AIS (Agricultural Intelligence System) recommendations
/// that factor in market saturation predictions
/// 
/// This upgrades crop viability recommendations from just looking at
/// historical profit metrics to also considering real-time market saturation

class EnhancedAisRecommendation {
  /// Original AIS metrics
  final double ppi; // Profitability Potential Index
  final double iur; // Inventory Unsold Ratio
  final double netMargin; // Net profit margin %
  
  /// Market saturation factors
  final double supplyDemandRatio;
  final String saturationLevel;
  final double predictedPriceImpact;
  
  /// Combined recommendation
  final String actionLevel; // plant, caution, avoid
  final String recommendation;
  final List<String> reasons;
  final double adjustedProfitEstimate; // Profit adjusted for market saturation
  final double riskScore; // 0-100, higher = riskier

  EnhancedAisRecommendation({
    required this.ppi,
    required this.iur,
    required this.netMargin,
    required this.supplyDemandRatio,
    required this.saturationLevel,
    required this.predictedPriceImpact,
    required this.actionLevel,
    required this.recommendation,
    required this.reasons,
    required this.adjustedProfitEstimate,
    required this.riskScore,
  });
}

/// Service to generate enhanced AIS recommendations
class EnhancedAisService {
  
  /// Generate recommendation combining financial metrics with market saturation
  static EnhancedAisRecommendation generateRecommendation({
    required String cropName,
    required double ppi,
    required double iur,
    required double netMargin,
    required double expectedRevenue,
    required double totalCosts,
    required SaturationPrediction? saturation,
  }) {
    final List<String> reasons = [];
    double riskScore = 0;
    
    // ─── FINANCIAL METRICS ANALYSIS ───
    
    // Check PPI (Profitability Potential Index)
    bool ppiGood = ppi >= -5 && ppi <= 10; // Baseline: -5% to +10% is safe range
    bool ppiStrong = ppi > 10;
    bool ppiWeak = ppi < -5;
    
    if (ppiWeak) {
      reasons.add('⚠️ Weak PPI ($ppi%): Price is significantly below baseline');
      riskScore += 20;
    } else if (ppiGood) {
      reasons.add('✅ Good PPI ($ppi%): Price is within normal range');
    } else if (ppiStrong) {
      reasons.add('✅ Strong PPI ($ppi%): Price is well above baseline');
      riskScore -= 15;
    }
    
    // Check Net Margin
    bool marginHealthy = netMargin >= 25;
    bool marginAcceptable = netMargin >= 15;
    bool marginWeak = netMargin < 15;
    
    if (marginWeak) {
      reasons.add('⚠️ Weak margin ($netMargin%): Limited profitability buffer');
      riskScore += 25;
    } else if (marginAcceptable) {
      reasons.add('⚠️ Acceptable margin ($netMargin%): Tight profitability');
      riskScore += 10;
    } else if (marginHealthy) {
      reasons.add('✅ Healthy margin ($netMargin%): Good profitability cushion');
      riskScore -= 10;
    }
    
    // Check IUR (Inventory Unsold Ratio)
    bool iurGood = iur < 0.15;
    bool iurWarning = iur <= 0.30;
    bool iurRisky = iur > 0.30;
    
    if (iurRisky) {
      reasons.add('⚠️ High unsold inventory ($iur): ${(iur * 100).toStringAsFixed(0)}% waste/spoilage risk');
      riskScore += 30;
    } else if (iurWarning) {
      reasons.add('⚠️ Moderate unsold inventory ($iur): Monitor spoilage');
      riskScore += 15;
    } else if (iurGood) {
      reasons.add('✅ Low unsold inventory ($iur): Good market absorption');
      riskScore -= 10;
    }
    
    // ─── MARKET SATURATION ANALYSIS ───
    
    double marketRiskScore = 0;
    
    if (saturation != null) {
      if (saturation.saturationLevel == 'undersupply') {
        reasons.add('✅ UNDERSUPPLY: Demand exceeds supply - prices likely to stay strong or rise');
        riskScore -= 30;
        marketRiskScore = -30;
      } else if (saturation.saturationLevel == 'safe') {
        reasons.add('✅ BALANCED MARKET: Supply meets demand reasonably');
        riskScore -= 5;
        marketRiskScore = -5;
      } else if (saturation.saturationLevel == 'caution') {
        reasons.add('⚠️ MARKET CAUTION: ${(saturation.supplyDemandRatio * 100 - 100).toStringAsFixed(0)}% oversupply predicted');
        reasons.add('   Price may drop ₱${(saturation.predictedPriceImpactPercent * 0.1).toStringAsFixed(2)}/kg');
        riskScore += 25;
        marketRiskScore = 25;
      } else if (saturation.saturationLevel == 'danger') {
        reasons.add('❌ HIGH MARKET RISK: Severe oversupply (${(saturation.supplyDemandRatio * 100 - 100).toStringAsFixed(0)}% excess)');
        reasons.add('   Price will drop to ₱${saturation.forecastedPricePerKg.toStringAsFixed(2)}/kg');
        reasons.add('   Your profit impact: ${saturation.profitImpactPerFarmer > 0 ? '+' : ''}₱${saturation.profitImpactPerFarmer.toStringAsFixed(0)}');
        riskScore += 50;
        marketRiskScore = 50;
      }
    }
    
    // ─── DETERMINE ACTION LEVEL ───
    
    String actionLevel;
    String recommendation;
    double adjustedProfit = netMargin;
    
    // Clamp risk score
    riskScore = (riskScore).clamp(0, 100).toDouble();
    
    if (riskScore < 30) {
      actionLevel = 'plant';
      recommendation = '✅ RECOMMENDED - Plant this crop';
      adjustedProfit = netMargin * (1 - (marketRiskScore / 100));
    } else if (riskScore < 60) {
      actionLevel = 'caution';
      recommendation = '⚠️ CAUTION - Plant with careful cost management';
      adjustedProfit = netMargin * (1 - (marketRiskScore / 100 * 1.5));
    } else {
      actionLevel = 'avoid';
      recommendation = '❌ HIGH RISK - Consider planting alternative crop';
      adjustedProfit = netMargin * (1 - (marketRiskScore / 100 * 2));
    }
    
    // Add action items
    if (actionLevel == 'caution') {
      reasons.add('');
      reasons.add('MITIGATION STRATEGIES:');
      if (iurRisky) {
        reasons.add('• Improve storage/cooling to reduce spoilage');
        reasons.add('• Coordinate harvest timing with buyers');
      }
      if (marketRiskScore > 0) {
        reasons.add('• Reduce input costs to improve margin');
        reasons.add('• Plan for price drops in budget');
      }
    } else if (actionLevel == 'avoid') {
      reasons.add('');
      reasons.add('BETTER ALTERNATIVES:');
      reasons.add('• Switch to crop with better market conditions');
      reasons.add('• Consider diversifying across multiple crops');
      reasons.add('• Coordinate with farmer group on crop selection');
    }
    
    // Add positive notes
    if (actionLevel == 'plant') {
      reasons.add('');
      reasons.add('FAVORABLE CONDITIONS:');
      if (saturation?.saturationLevel == 'undersupply') {
        reasons.add('• Strong market demand expected');
        reasons.add('• Limited competition from other farmers');
      }
      if (marginHealthy && ppiStrong) {
        reasons.add('• Excellent profit potential');
        reasons.add('• Historical strong performance');
      }
    }
    
    return EnhancedAisRecommendation(
      ppi: ppi,
      iur: iur,
      netMargin: netMargin,
      supplyDemandRatio: saturation?.supplyDemandRatio ?? 1.0,
      saturationLevel: saturation?.saturationLevel ?? 'unknown',
      predictedPriceImpact: saturation?.predictedPriceImpactPercent ?? 0,
      actionLevel: actionLevel,
      recommendation: recommendation,
      reasons: reasons,
      adjustedProfitEstimate: adjustedProfit.clamp(-100, 100).toDouble(),
      riskScore: riskScore,
    );
  }

  /// Compare multiple crops with saturation-adjusted recommendations
  static List<EnhancedAisRecommendation> compareAndRank({
    required Map<String, AgriFinancialInput> inputs, // crop -> financial input
    required Map<String, SaturationPrediction?> saturations, // crop -> saturation (null if no data)
  }) {
    final recommendations = <EnhancedAisRecommendation>[];
    
    inputs.forEach((cropName, input) {
      // Calculate AIS metrics
      final ppi = input.currentMarketPrice > 0 
          ? ((input.currentMarketPrice - input.baselineHistoricalPrice) / input.baselineHistoricalPrice * 100)
          : 0;
      
      final iur = input.totalProductionVolume > 0
          ? input.unsoldInventory / input.totalProductionVolume
          : 0;
      
      final totalInputCost = input.inputCosts + input.laborCosts + input.landCosts + input.logisticsCosts;
      final grossProfit = (input.quantitySold * input.currentMarketPrice) - totalInputCost;
      final netMargin = (input.quantitySold * input.currentMarketPrice) > 0
          ? (grossProfit / (input.quantitySold * input.currentMarketPrice)) * 100
          : 0;
      
      final recommendation = generateRecommendation(
        cropName: cropName,
        ppi: ppi,
        iur: iur,
        netMargin: netMargin,
        expectedRevenue: input.quantitySold * input.currentMarketPrice,
        totalCosts: totalInputCost,
        saturation: saturations[cropName],
      );
      
      recommendations.add(recommendation);
    });
    
    // Sort by risk score (lowest first = safest/best)
    recommendations.sort((a, b) => a.riskScore.compareTo(b.riskScore));
    
    return recommendations;
  }
}
