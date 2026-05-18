import 'package:flutter/material.dart';
import 'crop_cycling_monitoring_dashboard.dart';

class AgrisenseFarmerDashboardScreen extends StatelessWidget {
  const AgrisenseFarmerDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome, Farmer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildSectionTitle('Active Submissions'),
            _buildCard('Wet Season 2026 - Rice', 'Status: Active Planting\nExpected Harvest: Oct 2026', Icons.agriculture),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Smart Recommendations'),
            _buildCard('Plant Corn Next Season', 'High market demand matching your soil type.', Icons.trending_up, color: Colors.green.shade100),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Crop Monitoring'),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CropCyclingMonitoringDashboard()),
                );
              },
              child: _buildCard('Crop Cycling Monitoring', 'Track crop rotation, soil health, and risk assessment for your fields.', Icons.eco, color: Colors.teal.shade100),
            ),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Market Trends & Alerts'),
            _buildCard('Rice Oversaturation Warning', 'High supply projected in your municipality for Nov 2026.', Icons.warning, color: Colors.orange.shade100),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to new crop submission
              },
              child: const Text('Submit New Planting Intention'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCard(String title, String subtitle, IconData icon, {Color? color}) {
    return Card(
      color: color,
      child: ListTile(
        leading: Icon(icon, size: 40),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
