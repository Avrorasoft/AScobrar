import 'package:flutter_test/flutter_test.dart';
import 'package:loan_collector_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LoanCollectorApp());
    await tester.pump(const Duration(seconds: 1));
  });
}