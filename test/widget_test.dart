import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_safety_app/main.dart';

void main() {
  testWidgets('AI Safety App smoke test', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const AISafetyApp());

    // Verify app title on Login Page
    expect(find.text('AI Safety App'), findsOneWidget);

    // Verify Login button exists
    expect(find.text('LOGIN'), findsOneWidget);

    // Verify username and password fields exist
    expect(find.byType(TextField), findsNWidgets(2));
  });
}

