import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AgrisenseMunicipalDashboardScreen extends StatelessWidget {
  const AgrisenseMunicipalDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Municipal Agriculture Office'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Municipal Forecasting Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(child: _buildMetricCard('Total Active Farms', '1,245', Icons.landscape, Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('At-Risk Crops', '2', Icons.warning_amber_rounded, Colors.orange)),
              ],
            ),
            
            const SizedBox(height: 24),
            const Text('Oversupply Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: const [
                    ListTile(
                      title: Text('Rice (Wet Season)'),
                      subtitle: Text('Projected Yield: 500,000 kg\nDemand: 350,000 kg'),
                      trailing: Chip(label: Text('High Risk', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
                    ),
                    Divider(),
                    ListTile(
                      title: Text('Corn (Wet Season)'),
                      subtitle: Text('Projected Yield: 120,000 kg\nDemand: 200,000 kg'),
                      trailing: Chip(label: Text('Safe', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('Barangay Heatmap Integration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(10.3157, 123.8854),
                    initialZoom: 12.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.smart_sack_farming',
                    ),
                    PolygonLayer(
                      polygons: <Polygon<Object>>[
                        Polygon<Object>(
                          points: [
                            LatLng(10.3157, 123.8854),
                            LatLng(10.3257, 123.8854),
                            LatLng(10.3257, 123.8954),
                            LatLng(10.3157, 123.8954),
                          ],
                          color: Colors.red.withOpacity(0.5), // High saturation indicator
                        ),
                        Polygon<Object>(
                          points: [
                            LatLng(10.2957, 123.8654),
                            LatLng(10.3057, 123.8654),
                            LatLng(10.3057, 123.8754),
                            LatLng(10.2957, 123.8754),
                          ],
                          color: Colors.green.withOpacity(0.5), // Safe area indicator
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
