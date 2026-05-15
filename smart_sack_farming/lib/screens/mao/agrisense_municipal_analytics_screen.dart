import 'package:flutter/material.dart';

class AgrisenseMunicipalAnalyticsScreen extends StatelessWidget {
  const AgrisenseMunicipalAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Demand & Intelligence'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Commodity Saturation Analysis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSaturationCard('Rice (Oryza sativa)', 500000, 350000, 'Critical', Colors.red),
            const SizedBox(height: 8),
            _buildSaturationCard('Corn (Zea mays)', 120000, 200000, 'Safe', Colors.green),
            const SizedBox(height: 8),
            _buildSaturationCard('Cassava', 80000, 75000, 'Moderate', Colors.yellow.shade800),
            
            const SizedBox(height: 32),
            const Text(
              'Weather & Climate Advisories',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: const ListTile(
                leading: Icon(Icons.water_drop, color: Colors.blue, size: 40),
                title: Text('El Niño Warning Active', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Drought conditions expected starting November. Recommend drought-resistant crops (e.g., Cassava, Sorghum).'),
              ),
            ),
            
            const SizedBox(height: 32),
            const Text(
              'Actionable Interventions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.campaign),
              label: const Text('Broadcast Saturation Alert to Farmers'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaturationCard(String crop, double projectedYield, double projectedDemand, String riskLevel, Color alertColor) {
    double saturationPercentage = ((projectedYield - projectedDemand) / projectedDemand) * 100;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(crop, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(riskLevel, style: const TextStyle(color: Colors.white)),
                  backgroundColor: alertColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Projected Production: ${projectedYield.toStringAsFixed(0)} kg'),
            Text('Estimated Demand: ${projectedDemand.toStringAsFixed(0)} kg'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: projectedDemand == 0 ? 0 : (projectedYield / projectedDemand).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              color: alertColor,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              'Saturation Risk: ${saturationPercentage.toStringAsFixed(1)}%',
              style: TextStyle(color: alertColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
