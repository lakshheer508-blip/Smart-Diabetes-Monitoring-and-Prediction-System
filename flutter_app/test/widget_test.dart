import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smart_diabetes_app/main.dart';
import 'package:smart_diabetes_app/providers/auth_provider.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const SmartDiabetesApp(),
      ),
    );

    // Wait for the app to settle
    await tester.pump();

    // Verify that the app is running by checking if Dashboard is present or just true
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
