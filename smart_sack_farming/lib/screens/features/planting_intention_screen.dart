import 'package:flutter/material.dart';
import 'package:smart_sack_farming/models/planting_intention.dart';
import 'package:smart_sack_farming/services/planting_intention_service.dart';

/// Screen for farmers to:
/// 1. Add their planting intentions (crop, quantity, land area)
/// 2. See market saturation prediction
/// 3. Compare crops and get recommendations

class PlantingIntentionScreen extends StatefulWidget {
  final String farmerId;
  final String season; // e.g., "Dry Season 2026", "Wet Season 2026"
  final String barangay;

  const PlantingIntentionScreen({
    required this.farmerId,
    required this.season,
    required this.barangay,
    Key? key,
  }) : super(key: key);

  @override
  State<PlantingIntentionScreen> createState() => _PlantingIntentionScreenState();
}

class _PlantingIntentionScreenState extends State<PlantingIntentionScreen> {
  final _service = PlantingIntentionService();
  final _cropController = TextEditingController();
  final _quantityController = TextEditingController();
  final _landAreaController = TextEditingController();
  final _yieldController = TextEditingController();

  List<PlantingIntention> _myIntentions = [];
  List<SaturationPrediction> _predictions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final intentions = await _service.getMyPlantingIntentions(widget.farmerId);
      final predictions = await _service.getSaturationSummary(
        season: widget.season,
        barangay: widget.barangay,
      );
      setState(() {
        _myIntentions = intentions;
        _predictions = predictions;
      });
    } catch (e) {
      _showError('Error loading data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitIntention() async {
    if (_cropController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _landAreaController.text.isEmpty ||
        _yieldController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    try {
      final intention = PlantingIntention(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        farmerId: widget.farmerId,
        cropId: _cropController.text.toLowerCase(),
        cropName: _cropController.text,
        barangay: widget.barangay,
        plannedQuantityKg: double.parse(_quantityController.text),
        landAreaHa: double.parse(_landAreaController.text),
        expectedYieldPerHaKg: double.parse(_yieldController.text),
        plantingSeason: widget.season,
        recordedAt: DateTime.now(),
      );

      await _service.submitPlantingIntention(intention);
      _showSuccess('Planting intention added!');
      _cropController.clear();
      _quantityController.clear();
      _landAreaController.clear();
      _yieldController.clear();
      _loadData();
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );

  void _showSuccess(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planting Intentions'),
        backgroundColor: Colors.green.shade700,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // INPUT SECTION
                  _buildInputSection(),
                  const SizedBox(height: 24),

                  // MY INTENTIONS
                  _buildMyIntentionsSection(),
                  const SizedBox(height: 24),

                  // MARKET SATURATION PREDICTIONS
                  _buildMarketPredictionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Your Planting Plan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cropController,
              decoration: InputDecoration(
                labelText: 'Crop Name',
                hintText: 'e.g., Cabbage, Okra, Tomato',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Planned Quantity (kg)',
                hintText: 'Total kg you plan to plant',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _landAreaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Land Area (hectares)',
                hintText: 'e.g., 0.5, 1.0, 2.5',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yieldController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Expected Yield per Ha (kg)',
                hintText: 'Based on your farm history',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitIntention,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Add to Planting Plan',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyIntentionsSection() {
    if (_myIntentions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Planting Plans',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ..._myIntentions.map((intention) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      intention.cropName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${intention.plannedQuantityKg.toStringAsFixed(0)}kg',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Land: ${intention.landAreaHa.toStringAsFixed(2)}ha'),
                    Text('Expected: ${intention.expectedHarvestKg.toStringAsFixed(0)}kg'),
                  ],
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildMarketPredictionsSection() {
    if (_predictions.isEmpty) {
      return Center(
        child: Text(
          'No market data yet. Add your planting plans to see predictions.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Market Saturation Forecast',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...(_predictions..sort((a, b) => a.supplyDemandRatio.compareTo(b.supplyDemandRatio))).map((pred) {
          final isRisky = pred.saturationLevel == 'danger';
          final isWarning = pred.saturationLevel == 'caution';
          final isSafe = pred.saturationLevel == 'safe' || pred.saturationLevel == 'undersupply';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pred.cropName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isRisky
                              ? Colors.red.shade100
                              : isWarning
                                  ? Colors.orange.shade100
                                  : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          pred.saturationLevel.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isRisky
                                ? Colors.red
                                : isWarning
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(
                        '${pred.totalFarmersPlanting}',
                        'Farmers Planning',
                      ),
                      _buildStat(
                        '${(pred.supplyDemandRatio * 100).toStringAsFixed(0)}%',
                        'Supply-Demand',
                      ),
                      _buildStat(
                        '${pred.predictedPriceImpactPercent.toStringAsFixed(1)}%',
                        'Price Impact',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price Forecast
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
                          'Price Forecast',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₱${pred.forecastedPricePerKg.toStringAsFixed(2)}/kg',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: pred.predictedPriceImpactPercent < 0
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        if (pred.profitImpactPerFarmer != 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Estimated profit impact: ${pred.profitImpactPerFarmer > 0 ? '+' : ''}₱${pred.profitImpactPerFarmer.toStringAsFixed(0)}',
                            style: TextStyle(
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

                  // Recommendation
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
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.green,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cropController.dispose();
    _quantityController.dispose();
    _landAreaController.dispose();
    _yieldController.dispose();
    super.dispose();
  }
}
