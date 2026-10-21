import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_assistant/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FarmerAssistantApp());

    // Verify that the splash screen or home screen loads.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
