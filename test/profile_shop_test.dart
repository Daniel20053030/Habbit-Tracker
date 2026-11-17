import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habit_tracker_app/models/shop_item.dart';
import 'package:habit_tracker_app/models/user_profile.dart';
import 'package:habit_tracker_app/providers/app_provider.dart';
import 'package:habit_tracker_app/services/local_storage_service.dart';

void main() {
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

  test('automatic streak saver fills one missed day once', () async {
    final previous = DateTime.now().subtract(const Duration(days: 2));
    SharedPreferences.setMockInitialValues({
      'habits': '[{"id":"habit","title":"Habit","iconCodePoint":59136,"colorValue":4283389177,"frequency":"daily","difficulty":"easy","goal":"Daily","createdAt":"2026-10-19T00:00:00.000"}]',
      'profile': '{"name":"Alex","xp":0,"coins":0,"longestStreak":0,"avatarKey":"person","borderKey":"none","ownedItems":["avatar_person"],"streakSavers":1}',
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
