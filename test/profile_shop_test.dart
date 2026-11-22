import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habit_tracker_app/main.dart';
import 'package:habit_tracker_app/models/habit.dart';
import 'package:habit_tracker_app/models/shop_item.dart';
import 'package:habit_tracker_app/models/user_profile.dart';
import 'package:habit_tracker_app/providers/app_provider.dart';
import 'package:habit_tracker_app/services/local_storage_service.dart';

void main() {
  test('new profiles default to User1 with 60 coins', () {
    expect(const UserProfile().name, 'User1');
    expect(const UserProfile().coins, 60);
    expect(UserProfile.fromJson({}).name, 'User1');
    expect(UserProfile.fromJson({}).coins, 60);
  });

  test('level XP requirements grow by 1.5x', () {
    expect(const UserProfile(xp: 99).level, 1);
    expect(const UserProfile(xp: 100).level, 2);
    expect(const UserProfile(xp: 100).xpForNextLevel, 150);
    expect(const UserProfile(xp: 249).level, 2);
    expect(const UserProfile(xp: 250).level, 3);
    expect(const UserProfile(xp: 250).currentLevelXp, 0);
    expect(const UserProfile(xp: 250).xpForNextLevel, 225);
  });

  test('profile edits and shop purchases persist', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AppController(LocalStorageService(preferences));

    await controller.updateProfile(
      controller.state.profile.copyWith(name: 'Jamie'),
    );
    expect(controller.state.profile.name, 'Jamie');

    final item = shopItemById('streak_saver');
    await controller.updateProfile(
      controller.state.profile.copyWith(coins: 200),
    );
    expect(await controller.purchaseItem(item), isTrue);
    expect(controller.state.profile.coins, 50);
    expect(controller.state.profile.streakSavers, 1);

    final reloaded = LocalStorageService(preferences).readProfile();
    expect(reloaded.name, 'Jamie');
    expect(reloaded.streakSavers, 1);
  });

  test('shop reward notification state persists after it is shown', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AppController(LocalStorageService(preferences));

    await controller.markShopRewardNotificationShown();

    expect(controller.state.profile.shopRewardNotificationShown, isTrue);
    expect(
      LocalStorageService(preferences)
          .readProfile()
          .shopRewardNotificationShown,
      isTrue,
    );
  });

  testWidgets('profile shows an affordable reward dot and one-time notice', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'profile': jsonEncode({'coins': 75}),
    });
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const HabitTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('shop-reward-indicator')), findsOneWidget);
    expect(find.text('View'), findsOneWidget);

    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();
    expect(
      find.text('Shop reward ready! Redeem an item starting at 75 coins.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Daily Quote'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);

    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();
    expect(
      find.text('Shop reward ready! Redeem an item starting at 75 coins.'),
      findsNothing,
    );
  });

  test('deleting a habit also removes its completion history', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AppController(LocalStorageService(preferences));
    final habit = Habit(
      id: 'deletable',
      title: 'Read',
      iconCodePoint: null,
      colorValue: 0xffa78bfa,
      frequency: HabitFrequency.daily,
      goal: 'Read a few pages',
      createdAt: DateTime.now(),
    );

    await controller.saveHabit(habit);
    expect(await controller.completeToday(habit.id), isTrue);
    expect(controller.state.logs, hasLength(1));

    await controller.deleteHabit(habit.id);

    expect(
      controller.state.habits.where((item) => item.id == habit.id),
      isEmpty,
    );
    expect(
      controller.state.logs.where((log) => log.habitId == habit.id),
      isEmpty,
    );
    final reloaded = LocalStorageService(preferences);
    expect(reloaded.readHabits().where((item) => item.id == habit.id), isEmpty);
    expect(
      reloaded.readLogs().where((log) => log.habitId == habit.id),
      isEmpty,
    );
  });

  test(
    'markerless habits persist without a marker or health sync field',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final controller = AppController(LocalStorageService(preferences));
      final habit = Habit(
        id: 'markerless',
        title: 'Breathe',
        iconCodePoint: null,
        colorValue: 0xff62d6a7,
        frequency: HabitFrequency.daily,
        goal: 'Take a mindful break',
        createdAt: DateTime.now(),
      );

      await controller.saveHabit(habit);

      final raw = preferences.getString('habits');
      expect(raw, isNot(contains('healthSync')));
      final reloaded = LocalStorageService(preferences).readHabits();
      expect(
        reloaded.firstWhere((item) => item.id == 'markerless').iconCodePoint,
        isNull,
      );
    },
  );

  test('automatic streak saver fills one missed day once', () async {
    final previous = DateTime.now().subtract(const Duration(days: 2));
    SharedPreferences.setMockInitialValues({
      'habits': '[{"id":"habit","title":"Habit","iconCodePoint":59136,"colorValue":4283389177,"frequency":"daily","difficulty":"easy","goal":"Daily","createdAt":"2026-10-19T00:00:00.000"}]',
      'profile': '{"name":"Lanciao","xp":0,"coins":0,"longestStreak":0,"avatarKey":"person","borderKey":"none","ownedItems":["avatar_person"],"streakSavers":1}',
      'logs': '[{"habitId":"habit","date":"${previous.toIso8601String()}"}]',
    });
    final preferences = await SharedPreferences.getInstance();
    final controller = AppController(LocalStorageService(preferences));

    final earned = await controller.completeToday('habit');

    expect(earned, isTrue);
    expect(controller.state.profile.streakSavers, 0);
    expect(controller.state.logs, hasLength(3));
  });

  test('weekly habits enforce a target and one completion per day', () async {
    SharedPreferences.setMockInitialValues({
      'habits': '[{"id":"read","title":"Read","iconCodePoint":59136,"colorValue":4283389177,"frequency":"weekly","weeklyTarget":2,"difficulty":"easy","goal":"Read twice","createdAt":"2026-10-19T00:00:00.000"}]',
    });
    final preferences = await SharedPreferences.getInstance();
    final controller = AppController(LocalStorageService(preferences));

    expect(await controller.completeToday('read'), isTrue);
    expect(await controller.completeToday('read'), isFalse);
    expect(controller.weeklyCompletions('read'), 1);
    expect(controller.canCompleteToday('read'), isFalse);
  });
}
