enum PerishabilityCategory {
  highlyPerishable,
  moderatelyPerishable,
  storable,
}

class AgriFinancialInput {
  final String commodity;
  final PerishabilityCategory perishabilityCategory;
  final double currentMarketPrice;
  final double baselineHistoricalPrice;
  final double totalProductionVolume;
  final double unsoldInventory;
  final double quantitySold;
  final double inputCosts;
  final double laborCosts;
  final double landCosts;
  final double logisticsCosts;

  const AgriFinancialInput({
    required this.commodity,
    required this.perishabilityCategory,
    required this.currentMarketPrice,
    required this.baselineHistoricalPrice,
    required this.totalProductionVolume,
    required this.unsoldInventory,
    required this.quantitySold,
    required this.inputCosts,
    required this.laborCosts,
    this.landCosts = 0,
    required this.logisticsCosts,
  });

  factory AgriFinancialInput.fromJson(Map<String, dynamic> json) {
    return AgriFinancialInput(
      commodity: json['commodity']?.toString() ?? '',
      perishabilityCategory: _parsePerishability(
        json['perishability_category']?.toString(),
      ),
      currentMarketPrice: (json['current_market_price'] as num?)?.toDouble() ?? 0,
      baselineHistoricalPrice:
          (json['baseline_historical_price'] as num?)?.toDouble() ?? 0,
      totalProductionVolume:
          (json['total_production_volume'] as num?)?.toDouble() ?? 0,
      unsoldInventory: (json['unsold_inventory'] as num?)?.toDouble() ?? 0,
      quantitySold: (json['quantity_sold'] as num?)?.toDouble() ?? 0,
      inputCosts: (json['input_costs'] as num?)?.toDouble() ?? 0,
      laborCosts: (json['labor_costs'] as num?)?.toDouble() ?? 0,
      landCosts: (json['land_costs'] as num?)?.toDouble() ?? 0,
      logisticsCosts: (json['logistics_costs'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commodity': commodity,
      'perishability_category': perishabilityCategory.name,
      'current_market_price': currentMarketPrice,
      'baseline_historical_price': baselineHistoricalPrice,
      'total_production_volume': totalProductionVolume,
      'unsold_inventory': unsoldInventory,
      'quantity_sold': quantitySold,
      'input_costs': inputCosts,
      'labor_costs': laborCosts,
      'land_costs': landCosts,
      'logistics_costs': logisticsCosts,
    };
  }

  static PerishabilityCategory _parsePerishability(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'highlyperishable':
      case 'highly_perishable':
      case 'highly perishable':
        return PerishabilityCategory.highlyPerishable;
      case 'storable':
        return PerishabilityCategory.storable;
      default:
        return PerishabilityCategory.moderatelyPerishable;
    }
  }
}

class AgriFinancialMetrics {
  final double pricePressureIndicator;
  final double inventoryUnsoldRatio;
  final double netProfit;
  final double totalCost;
  final double totalRevenue;
  final double netProfitMargin;

  const AgriFinancialMetrics({
    required this.pricePressureIndicator,
    required this.inventoryUnsoldRatio,
    required this.netProfit,
    required this.totalCost,
    required this.totalRevenue,
    required this.netProfitMargin,
  });

  Map<String, dynamic> toJson() {
    return {
      'ppi': pricePressureIndicator,
      'iur': inventoryUnsoldRatio,
      'net_profit': netProfit,
      'total_cost': totalCost,
      'total_revenue': totalRevenue,
      'net_profit_margin': netProfitMargin,
    };
  }
}

class AgriFinancialReport {
  final String commodity;
  final AgriFinancialMetrics metrics;
  final String marketCondition;
  final bool highRiskIllusion;
  final List<String> recommendations;

  const AgriFinancialReport({
    required this.commodity,
    required this.metrics,
    required this.marketCondition,
    required this.highRiskIllusion,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'commodity': commodity,
      'metrics': metrics.toJson(),
      'market_condition': marketCondition,
      'high_risk_illusion': highRiskIllusion,
      'recommendations': recommendations,
    };
  }
}

class AgriFinancialModel {
  static const double defaultHighIurThreshold = 0.20;

  AgriFinancialReport analyze(
    AgriFinancialInput input, {
    double highIurThreshold = defaultHighIurThreshold,
  }) {
    final metrics = _calculateMetrics(input);
    final marketCondition = _deriveMarketCondition(metrics.pricePressureIndicator);

    final recommendations = <String>[];

    final ppiRecommendations = _ppiRecommendations(metrics.pricePressureIndicator);
    recommendations.addAll(ppiRecommendations);

    final iurRecommendation = _iurRecommendation(
      input.perishabilityCategory,
      metrics.inventoryUnsoldRatio,
      highIurThreshold,
    );
    if (iurRecommendation != null) {
      recommendations.add(iurRecommendation);
    }

    final highRiskIllusion = _isHighRiskIllusion(metrics);
    if (highRiskIllusion) {
      recommendations.add(
        'Positive price signal is not translating to healthy margins; reduce variable costs, improve input efficiency, or switch to a lower-cost crop next cycle.',
      );
    }

    final normalizedRecommendations = _normalizeRecommendations(recommendations);

    return AgriFinancialReport(
      commodity: input.commodity,
      metrics: metrics,
      marketCondition: marketCondition,
      highRiskIllusion: highRiskIllusion,
      recommendations: normalizedRecommendations,
    );
  }

  AgriFinancialMetrics _calculateMetrics(AgriFinancialInput input) {
    final baselinePrice = input.baselineHistoricalPrice;
    final totalProduction = input.totalProductionVolume;
    final totalRevenue = input.currentMarketPrice * input.quantitySold;
    final totalCost =
        input.inputCosts + input.laborCosts + input.landCosts + input.logisticsCosts;
    final netProfit = totalRevenue - totalCost;

    final ppi = baselinePrice == 0
      ? 0.0
        : ((input.currentMarketPrice - baselinePrice) / baselinePrice) * 100;

    final iur = totalProduction == 0 ? 0.0 : input.unsoldInventory / totalProduction;

    final netProfitMargin = totalRevenue == 0 ? 0.0 : netProfit / totalRevenue;

    return AgriFinancialMetrics(
      pricePressureIndicator: ppi,
      inventoryUnsoldRatio: iur,
      netProfit: netProfit,
      totalCost: totalCost,
      totalRevenue: totalRevenue,
      netProfitMargin: netProfitMargin,
    );
  }

  String _deriveMarketCondition(double ppi) {
    if (ppi > 10) {
      return 'Constrained Supply';
    }
    if (ppi >= -5 && ppi <= 5) {
      return 'Market Equilibrium';
    }
    if (ppi >= -20 && ppi <= -10) {
      return 'Structural Oversupply';
    }
    if (ppi < -25) {
      return 'Severe Oversupply';
    }
    if (ppi > 5 && ppi <= 10) {
      return 'Tightening Supply';
    }
    if (ppi < -20 && ppi >= -25) {
      return 'Deep Oversupply';
    }
    return 'Mild Price Pressure';
  }

  List<String> _ppiRecommendations(double ppi) {
    if (ppi > 10) {
      return [
        'Supply appears constrained; increase planting area next cycle where agronomic conditions permit.',
        'Consider controlled importation or inter-regional sourcing to stabilize short-term availability.',
      ];
    }

    if (ppi >= -5 && ppi <= 5) {
      return [
        'Market is in equilibrium; maintain current production levels and avoid aggressive expansion.',
      ];
    }

    if (ppi >= -20 && ppi <= -10) {
      return [
        'Saturation warning: redirect unsold produce to alternative markets and improve distribution timing.',
        'Use storage or staggered release strategies to reduce price depression in the next cycle.',
      ];
    }

    if (ppi < -25) {
      return [
        'Severe oversupply detected; shift crop selection immediately for the next planting cycle.',
        'Reduce exposure by diversifying into crops with stronger local clearing rates.',
      ];
    }

    if (ppi > 5 && ppi <= 10) {
      return [
        'Prices are rising moderately; expand planting cautiously while tracking weekly price volatility.',
      ];
    }

    return [
      'Monitor prices and inventory weekly to avoid unplanned overproduction.',
    ];
  }

  String? _iurRecommendation(
    PerishabilityCategory category,
    double iur,
    double highIurThreshold,
  ) {
    if (iur < highIurThreshold) {
      return null;
    }

    switch (category) {
      case PerishabilityCategory.highlyPerishable:
        return 'High unsold ratio for a highly perishable crop; prioritize immediate repurposing (e.g., jam/cheese/processing) or deep discount liquidation.';
      case PerishabilityCategory.storable:
        return 'High unsold ratio for a storable crop; use strategic overstocking, timed release, or hedging contracts to protect value.';
      case PerishabilityCategory.moderatelyPerishable:
        return 'High unsold ratio for a moderately perishable crop; accelerate channel expansion and controlled markdowns before quality decline.';
    }
  }

  bool _isHighRiskIllusion(AgriFinancialMetrics metrics) {
    final hasPositivePpi = metrics.pricePressureIndicator > 0;
    final weakOrNegativeMargin = metrics.netProfitMargin <= 0.08;

    return hasPositivePpi && weakOrNegativeMargin;
  }

  List<String> _normalizeRecommendations(List<String> source) {
    final unique = <String>[];
    final seen = <String>{};

    for (final item in source) {
      final normalized = item.trim();
      if (normalized.isEmpty) continue;
      if (seen.add(normalized)) {
        unique.add(normalized);
      }
    }

    if (unique.length >= 2) {
      return unique.take(2).toList();
    }

    if (unique.isEmpty) {
      return [
        'Maintain current production discipline and monitor price/inventory movements weekly.',
        'Document cost drivers before the next cycle to improve margin decisions.',
      ];
    }

    return [
      unique.first,
      'Track PPI, IUR, and net profit each cycle to refine planting and sales timing.',
    ];
  }
}
