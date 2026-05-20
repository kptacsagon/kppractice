import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/planting_intention.dart';
import '../../services/planting_intention_service.dart';
import '../../models/agri_dss_models.dart';

/// Widget to display market saturation predictions in the AgriFinancial DSS
/// Integrated into Financial Model tabs for real-time market risk assessment

class MarketSaturationWidget extends StatefulWidget {
  final String farmerId;
  final String barangay;
  final String season;
  final String? selectedCommodity;

  const MarketSaturationWidget({
    required this.farmerId,
    required this.barangay,
    required this.season,
    this.selectedCommodity,
    Key? key,
  }) : super(key: key);

  @override
  State<MarketSaturationWidget> createState() => _MarketSaturationWidgetState();
}

class _MarketSaturationWidgetState extends State<MarketSaturationWidget> {
  final _service = PlantingIntentionService();
  List<SaturationPrediction> _predictions = [];
  List<PlantingIntention> _myIntentions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final intentions = await _service.getMyPlantingIntentions(widget.farmerId);
      final predictions = await _service.getSaturationSummary(
        season: widget.season,
        barangay: widget.barangay,
      );
      
      if (mounted) {
        setState(() {
          _myIntentions = intentions;
          _predictions = widget.selectedCommodity != null
              ? predictions.where((p) => p.cropName.toLowerCase() == widget.selectedCommodity!.toLowerCase()).toList()
              : predictions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
      print('Error loading saturation data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_predictions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade600, size: 40),
            const SizedBox(height: 12),
            Text(
              'No market data available',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your planting plans to see market saturation predictions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _predictions.length,
      itemBuilder: (context, index) {
        final pred = _predictions[index];
        return _buildSaturationCard(pred);
      },
    );
  }

  Widget _buildSaturationCard(SaturationPrediction pred) {
    final isRisky = pred.saturationLevel == 'danger';
    final isWarning = pred.saturationLevel == 'caution';
    final isSafe = pred.saturationLevel == 'safe' || pred.saturationLevel == 'undersupply';

    final Color headerBg = isRisky
        ? Colors.red.shade50
        : isWarning
            ? Colors.orange.shade50
            : Colors.green.shade50;

    final Color headerBorder = isRisky
        ? Colors.red.shade300
        : isWarning
            ? Colors.orange.shade300
            : Colors.green.shade300;

    final Color statusBg = isRisky
        ? Colors.red.shade100
        : isWarning
            ? Colors.orange.shade100
            : Colors.green.shade100;

    final Color statusText = isRisky
        ? Colors.red
        : isWarning
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(bottom: BorderSide(color: headerBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pred.cropName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pred.saturationLevel.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: statusText,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      '${pred.totalFarmersPlanting}',
                      'Farmers',
                      Colors.blue,
                    ),
                    _buildStatCard(
                      '${(pred.supplyDemandRatio * 100).toStringAsFixed(0)}%',
                      'Supply/Demand',
                      Colors.purple,
                    ),
                    _buildStatCard(
                      '${pred.predictedPriceImpactPercent.toStringAsFixed(1)}%',
                      'Price Impact',
                      isRisky ? Colors.red : (isWarning ? Colors.orange : Colors.green),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Price Forecast Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Forecasted Price',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₱${pred.forecastedPricePerKg.toStringAsFixed(2)}/kg',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: pred.predictedPriceImpactPercent < 0
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      if (pred.profitImpactPerFarmer != 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Profit impact: ${pred.profitImpactPerFarmer > 0 ? '+' : ''}₱${pred.profitImpactPerFarmer.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: pred.profitImpactPerFarmer > 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Recommendation Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRisky
                        ? Colors.red.shade50
                        : isWarning
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isRisky
                          ? Colors.red.shade300
                          : isWarning
                              ? Colors.orange.shade300
                              : Colors.green.shade300,
                    ),
                  ),
                  child: Text(
                    pred.recommendation,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: isRisky
                          ? Colors.red.shade800
                          : isWarning
                              ? Colors.orange.shade800
                              : Colors.green.shade800,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Supply Details
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Supply',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${pred.estimatedTotalHarvestKg.toStringAsFixed(0)} kg',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Market Demand',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${pred.estimatedMarketDemandKg.toStringAsFixed(0)} kg',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
