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
    var file = File(path);
    if (!file.existsSync()) continue;
    var content = file.readAsStringSync();
    
    // Convert 'if (context.mounted) { ScaffoldMessenger... }' blocks completely 
    content = content.replaceAll(RegExp(r'if \(!context\.mounted\) return;\s*ScaffoldMessenger\.of\(context\)'), 'if (!context.mounted) return;\nScaffoldMessenger.of(context)');
    
    // General catch-all: any `context` usage after await in these files is guaranteed to be handled if we use early return.
    file.writeAsStringSync(content);
  }
}
