import 'dart:io';

void main() {
  final analyzeFile = File('analyze_output.txt');
  if (!analyzeFile.existsSync()) return;

  final lines = analyzeFile.readAsLinesSync();
  final targetErrors = lines.where((line) => line.contains('use_build_context_synchronously')).toList();
  
  Map<String, List<int>> fileToLines = {};
  
  for (final error in targetErrors) {
    final parts = error.split(' - ');
    if (parts.length < 3) continue;
    
    final pathAndLine = parts[2].trim();
    final colonParts = pathAndLine.split(':');
    if (colonParts.length >= 3) {
      final path = colonParts[0].trim();
      final fileToLinesMap = fileToLines[path] ?? [];
      fileToLines[path] = fileToLinesMap;
    }
  }

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
    content = content.replaceAll('\$indent if (!context.mounted) return;\n', '');
    content = content.replaceAll('if (!mounted) return;', 'if (!context.mounted) return;');
    content = content.replaceAll('  if (!context.mounted) return;\n  if (!context.mounted) return;', '  if (!context.mounted) return;');
    
    file.writeAsStringSync(content);
  }
}
