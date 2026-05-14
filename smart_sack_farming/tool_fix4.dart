import 'dart:io';

void main() {
  final files = [
    'lib/screens/admin/alerts_notifications_screen.dart',
    'lib/screens/admin/farmer_management_screen.dart',
    'lib/screens/admin/intervention_management_screen.dart',
    'lib/screens/admin/market_prices_screen.dart',
    'lib/screens/admin/supply_map_screen.dart',
    'lib/screens/features/financial_forecast_screen.dart'
  ];

  for (final path in files) {
    var file = File(path);
    if (!file.existsSync()) continue;
    var content = file.readAsStringSync();
    
    // We only want to replace Navigator.push( inside _onNavTap or similar. Let's just do a naive replace
    // because pushing from these sidebar screens is exclusively navigation across dashboards.
    content = content.replaceAll('await Navigator.push(', 'await Navigator.pushReplacement(');
    
    file.writeAsStringSync(content);
  }
}
