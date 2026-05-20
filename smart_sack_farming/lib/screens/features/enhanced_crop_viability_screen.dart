import 'package:flutter/material.dart';
import '../../models/agri_financial_model.dart';
import '../../models/planting_intention.dart';
import '../../services/enhanced_ais_service.dart';
import '../../services/planting_intention_service.dart';

/// Enhanced crop viability screen that shows:
/// 1. Financial metrics (PPI, IUR, Net Margin)
/// 2. Market saturation predictions
/// 3. Combined recommendation with action items

class EnhancedCropViabilityScreen extends StatefulWidget {
  final AgriFinancialInput crop;
  final String cropName;
  final String season;
  final String barangay;
  final String farmerId;

  const EnhancedCropViabilityScreen({
    required this.crop,
    required this.cropName,
    required this.season,
    required this.barangay,
    required this.farmerId,
    Key? key,
  }) : super(key: key);

  @override
  State<EnhancedCropViabilityScreen> createState() =>
      _EnhancedCropViabilityScreenState();
}

class _EnhancedCropViabilityScreenState extends State<EnhancedCropViabilityScreen> {
  late Future<_ViewData> _dataFuture;
  final _satService = PlantingIntentionService();
  final _aisService = EnhancedAisService();

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_ViewData> _loadData() async {
    try {
      // Get market saturation prediction
      final saturation = await _satService.predictMarketSaturation(
        cropName: widget.cropName,
        season: widget.season,
        barangay: widget.barangay,
        baselineHistoricalPrice: widget.crop.baselineHistoricalPrice,
        estimatedMarketDemandKg: 50000, // Default market demand
        avgProductionCosts: (widget.crop.inputCosts +
                widget.crop.laborCosts +
                widget.crop.landCosts +
                widget.crop.logisticsCosts) /
            widget.crop.totalProductionVolume,
      );

      // Calculate AIS metrics
      final ppi = widget.crop.currentMarketPrice > 0
          ? ((widget.crop.currentMarketPrice -
                  widget.crop.baselineHistoricalPrice) /
              widget.crop.baselineHistoricalPrice *
              100)
          : 0;

      final iur = widget.crop.totalProductionVolume > 0
          ? widget.crop.unsoldInventory / widget.crop.totalProductionVolume
          : 0;

      final totalCosts = widget.crop.inputCosts +
          widget.crop.laborCosts +
          widget.crop.landCosts +
          widget.crop.logisticsCosts;
      final grossProfit = (widget.crop.quantitySold * widget.crop.currentMarketPrice) - totalCosts;
      final netMargin = (widget.crop.quantitySold * widget.crop.currentMarketPrice) > 0
          ? (grossProfit / (widget.crop.quantitySold * widget.crop.currentMarketPrice)) * 100
          : 0;

      // Generate enhanced recommendation
      final recommendation = _aisService.generateRecommendation(
        cropName: widget.cropName,
        ppi: ppi,
        iur: iur,
        netMargin: netMargin,
        expectedRevenue: widget.crop.quantitySold * widget.crop.currentMarketPrice,
        totalCosts: totalCosts,
        saturation: saturation,
      );

      return _ViewData(
        saturation: saturation,
        recommendation: recommendation,
        ppi: ppi,
        iur: iur,
        netMargin: netMargin,
      );
    } catch (e) {
      print('Error loading data: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cropName} Viability Analysis'),
        backgroundColor: Colors.green.shade700,
      ),
      body: FutureBuilder<_ViewData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _dataFuture = _loadData()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MAIN RECOMMENDATION
                _buildMainRecommendation(data.recommendation),
                const SizedBox(height: 24),

                // RISK METER
                _buildRiskMeter(data.recommendation),
                const SizedBox(height: 24),

                // FINANCIAL METRICS
                _buildFinancialMetrics(data),
                const SizedBox(height: 24),

                // MARKET SATURATION
                _buildMarketSaturation(data.saturation),
                const SizedBox(height: 24),

                // REASONS & ANALYSIS
                _buildAnalysisDetails(data.recommendation),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainRecommendation(EnhancedAisRecommendation rec) {
    final isPlant = rec.actionLevel == 'plant';
    final isCaution = rec.actionLevel == 'caution';
    final isAvoid = rec.actionLevel == 'avoid';

    final Color bgColor = isPlant
        ? Colors.green.shade50
        : isCaution
            ? Colors.orange.shade50
            : Colors.red.shade50;

    final Color borderColor = isPlant
        ? Colors.green.shade300
        : isCaution
            ? Colors.orange.shade300
            : Colors.red.shade300;

    final Color textColor = isPlant
        ? Colors.green.shade800
        : isCaution
            ? Colors.orange.shade800
            : Colors.red.shade800;

    final IconData icon =
        isPlant ? Icons.check_circle : isCaution ? Icons.warning : Icons.cancel;
    final Color iconColor = isPlant
        ? Colors.green
        : isCaution
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.recommendation,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Risk Score: ${rec.riskScore.toStringAsFixed(0)}/100',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskMeter(EnhancedAisRecommendation rec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk Assessment',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: rec.riskScore / 100,
            minHeight: 24,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              rec.riskScore < 30
                  ? Colors.green
                  : rec.riskScore < 60
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Low Risk', style: Theme.of(context).textTheme.bodySmall),
            Text(
              '${rec.riskScore.toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('High Risk', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialMetrics(
_ViewData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Metrics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricBox(
                  'PPI',
                  '${data.ppi.toStringAsFixed(1)}%',
                  data.ppi > 10
                      ? Colors.green
                      : data.ppi > -5
                          ? Colors.blue
                          : Colors.red,
                ),
                _buildMetricBox(
                  'IUR',
                  '${(data.iur * 100).toStringAsFixed(1)}%',
                  data.iur < 0.15
                      ? Colors.green
                      : data.iur <= 0.30
                          ? Colors.orange
                          : Colors.red,
                ),
                _buildMetricBox(
                  'Net Margin',
                  '${data.netMargin.toStringAsFixed(1)}%',
                  data.netMargin >= 25
                      ? Colors.green
                      : data.netMargin >= 15
                          ? Colors.orange
                          : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarketSaturation(SaturationPrediction sat) {
    final isRisky = sat.saturationLevel == 'danger';
    final isWarning = sat.saturationLevel == 'caution';

    return Card(
      color: isRisky
          ? Colors.red.shade50
          : isWarning
              ? Colors.orange.shade50
              : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market Saturation Forecast',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farmers Planning',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${sat.totalFarmersPlanting}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supply/Demand',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${(sat.supplyDemandRatio * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price Impact',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${sat.predictedPriceImpactPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: sat.predictedPriceImpactPercent < 0
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(150),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Forecasted Price: ₱${sat.forecastedPricePerKg.toStringAsFixed(2)}/kg',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisDetails(EnhancedAisRecommendation rec) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis & Recommendations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...rec.reasons.asMap().entries.map((entry) {
              final idx = entry.key;
              final reason = entry.value;
              final isHeader = reason.startsWith('BETTER') ||
                  reason.startsWith('MITIGATION') ||
                  reason.startsWith('FAVORABLE');

              return Padding(
                padding: EdgeInsets.only(bottom: 8, top: idx == 0 ? 0 : 4),
                child: Text(
                  reason,
                  style: isHeader
                      ? TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        )
                      : Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ViewData {
  final SaturationPrediction saturation;
  final EnhancedAisRecommendation recommendation;
  final double ppi;
  final double iur;
  final double netMargin;

  _ViewData({
    required this.saturation,
    required this.recommendation,
    required this.ppi,
    required this.iur,
    required this.netMargin,
  });
}
