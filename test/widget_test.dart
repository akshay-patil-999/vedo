// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:vedo/main.dart';
import 'package:vedo/providers/auth_provider.dart';
import 'package:vedo/screens/auth/login_screen.dart';
import 'package:vedo/screens/parent/parent_home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VedoApp());
    expect(find.text('VEDO'), findsWidgets);
  });

  testWidgets('Login screen shows Google sign in button', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('Parent dashboard shows overview navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: ParentHomeScreen()),
      ),
    );

    expect(find.text('Overview'), findsOneWidget);
  });
}

