// Basic smoke test for TeleMedCare app.
//
// This verifies the app widget can be instantiated and renders.
// Full integration testing should be done manually on emulator
// with the backend services running.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemed_app/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TeleMedCareApp(),
      ),
    );

    // Verify the MaterialApp.router is rendered
    expect(find.byType(TeleMedCareApp), findsOneWidget);
  });
}
