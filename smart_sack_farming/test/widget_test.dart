import 'package:flutter_test/flutter_test.dart';
import 'package:smart_sack_farming/main.dart';

void main() {
  testWidgets('App launches with login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartSackApp());
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
  });
}
