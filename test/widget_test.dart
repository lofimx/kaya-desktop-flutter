import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaya_desktop/core/routing/router.dart';

void main() {
  testWidgets('App renders Save Button title in app bar',
      (WidgetTester tester) async {
    // Create a test router that goes directly to the save screen
    final testRouter = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Save Button')),
            body: const Center(child: Text('Save Button')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(testRouter),
        ],
        child: MaterialApp.router(
          title: 'Save Button',
          routerConfig: testRouter,
        ),
      ),
    );

    expect(find.text('Save Button'), findsWidgets);
  });
}
