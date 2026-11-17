import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habit_tracker_app/main.dart';
import 'package:habit_tracker_app/providers/app_provider.dart';

void main() {
  testWidgets('new users receive three starter habits', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const HabitTrackerApp(),
      ),
    );

    expect(find.text('Drink water'), findsOneWidget);
    expect(find.text('Move your body'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Reflect on your day'), findsOneWidget);
  });

  testWidgets('users can create a habit from the quest setup flow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const HabitTrackerApp(),
      ),
    );

    await tester.tap(find.byTooltip('Create a new habit'));
    await tester.pumpAndSettle();
    expect(find.text('Start a small quest'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('habit-name-field')),
      'Read a chapter',
    );
    await tester.drag(
      find.byKey(const ValueKey('habit-form-list')),
      const Offset(0, -1400),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create habit'));
    await tester.tap(find.text('Create habit'));
    await tester.pumpAndSettle();

    expect(find.text('Start a small quest'), findsNothing);
  });
}
