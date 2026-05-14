import 'dart:io';

void main() {
  final analyzeFile = File('analyze_output.txt');
  if (!analyzeFile.existsSync()) return;

  final lines = analyzeFile.readAsLinesSync();
  final targetErrors = lines.where((line) => line.contains('use_build_context_synchronously')).toList();
  
  Map<String, List<int>> fileToLines = {};
  
  for (final error in targetErrors) {
    // Example format:
    //   info - Don't use 'BuildContext's across async gaps - lib\screens\buyer\buyer_reservations_screen.dart:103:28 - use_build_context_synchronously
    final parts = error.split(' - ');
    if (parts.length < 3) continue;
    
    // The path part looks like: lib\screens\buyer\buyer_reservations_screen.dart:103:28
    final pathAndLine = parts[2].trim();
    final colonParts = pathAndLine.split(':');
    if (colonParts.length >= 3) {
      final path = colonParts[0].trim();
      final lineNum = int.parse(colonParts[1].trim());
      
      fileToLines.putIfAbsent(path, () => []).add(lineNum);
    }
  }

  for (final path in fileToLines.keys) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    final fileLines = file.readAsLinesSync();
    
    // Sort descending to not mess up indices
    final linesToFix = fileToLines[path]!.toSet().toList()..sort((a, b) => b.compareTo(a));
    
    for (final lineNum in linesToFix) {
      final idx = lineNum - 1; // 0-based index
      if (idx >= 0 && idx < fileLines.length) {
        final lineText = fileLines[idx];
        final match = RegExp(r'^(\s*)').firstMatch(lineText);
        final indent = match?.group(1) ?? '';
        
        fileLines.insert(idx, '\$indent if (!context.mounted) return;');
      }
    }
    
    file.writeAsStringSync(fileLines.join('\n'));
    print('Fixed \$path');
  }
}
