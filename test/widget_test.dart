import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habit_tracker_app/main.dart';
import 'package:habit_tracker_app/providers/app_provider.dart';

void main() {
  testWidgets('startup shows a loading screen before preferences are ready', (
    tester,
  ) async {
    final preferences = Completer<SharedPreferences>();
    await tester.pumpWidget(HabitStartupApp(preferences: preferences.future));

    expect(find.text('Habit Tracker'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

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

    await tester.tap(find.byTooltip('Create a new quest'));
    await tester.pumpAndSettle();
    expect(find.text('Start a small quest'), findsOneWidget);
    expect(find.text('Starter quests'), findsOneWidget);
    expect(find.text('Drink water'), findsOneWidget);
    expect(find.text('Frequency'), findsNothing);
    expect(find.text('Goal'), findsNothing);
    expect(find.text('Description (optional)'), findsOneWidget);
    expect(find.text('Habit type'), findsOneWidget);
    expect(find.text('Goal period'), findsOneWidget);
    expect(find.text('Task days'), findsOneWidget);

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

  testWidgets('Android settings options open real detail screens', (
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

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Android Widgets'), findsOneWidget);
    expect(find.text('iCloud Sync'), findsNothing);
    expect(find.text('Dynamic Island'), findsNothing);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Habit reminders'), findsOneWidget);
    expect(find.text('Completion feedback'), findsOneWidget);
  });
}
