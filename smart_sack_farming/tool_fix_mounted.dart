import 'dart:io';

void main() {
  final files = [
    'lib/screens/admin/market_prices_screen.dart',
    'lib/screens/buyer/buyer_reservations_screen.dart',
    'lib/screens/buyer/marketplace_screen.dart',
    'lib/screens/farmer/planting_entry_screen.dart',
    'lib/screens/features/rentals_screen.dart',
    'lib/screens/features/reports_screen.dart',
    'lib/screens/mao/harvest_dashboard.dart'
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();
    
    content = content.replaceAll(RegExp(r'if \(!mounted\) return;'), 'if (!context.mounted) return;');
    content = content.replaceAll(RegExp(r'if \(mounted\) \{'), 'if (context.mounted) {');
    
    file.writeAsStringSync(content);
  }
  print('Done.');
}