import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_companion/main.dart';

void main() {
  testWidgets('Health Companion App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HealthCompanionApp()));
    expect(find.byType(HealthCompanionApp), findsOneWidget);
  });
}
