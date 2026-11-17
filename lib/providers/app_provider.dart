import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/user_profile.dart';
import '../models/shop_item.dart';
import '../services/gamification_service.dart';
import '../services/local_storage_service.dart';

class AppState {
  const AppState({
    this.habits = const [],
    this.logs = const [],
    this.profile = const UserProfile(),
  });

  final List<Habit> habits;
  final List<HabitLog> logs;
  final UserProfile profile;

  AppState copyWith({
    List<Habit>? habits,
    List<HabitLog>? logs,
    UserProfile? profile,
  }) => AppState(
    habits: habits ?? this.habits,
    logs: logs ?? this.logs,
    profile: profile ?? this.profile,
  );
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden at startup.');
});

final appProvider = StateNotifierProvider<AppController, AppState>((ref) {
  return AppController(
    LocalStorageService(ref.watch(sharedPreferencesProvider)),
  );
});

class AppController extends StateNotifier<AppState> {
  AppController(this._storage)
    : super(
        AppState(
          habits: _initialHabits(_storage),
          logs: _storage.readLogs(),
          profile: _storage.readProfile(),
        ),
      );

  final LocalStorageService _storage;

  static List<Habit> _initialHabits(LocalStorageService storage) {
    final habits = storage.readHabits();
    if (storage.hasStoredHabits) return habits;

    final defaults = [
      Habit(
        id: 'starter-morning-water',
        title: 'Drink water',
        iconCodePoint: 0xe798,
        colorValue: 0xff4f9cf9,
        frequency: HabitFrequency.daily,
        weeklyTarget: 1,
        difficulty: HabitDifficulty.easy,
        goal: 'Drink a glass of water',
        createdAt: DateTime.now(),
      ),
      Habit(
        id: 'starter-move',
        title: 'Move your body',
        iconCodePoint: 0xe3f1,
        colorValue: 0xff66bb6a,
        frequency: HabitFrequency.daily,
        weeklyTarget: 1,
        difficulty: HabitDifficulty.medium,
        goal: 'Move for 10 minutes',
        createdAt: DateTime.now(),
      ),
      Habit(
        id: 'starter-reflect',
        title: 'Reflect on your day',
        iconCodePoint: 0xe8b8,
        colorValue: 0xffffb74d,
        frequency: HabitFrequency.daily,
        weeklyTarget: 1,
        difficulty: HabitDifficulty.medium,
        goal: 'Write one thing you are grateful for',
        createdAt: DateTime.now(),
      ),
    ];
    unawaited(storage.writeHabits(defaults));
    return defaults;
  }

  Future<void> saveHabit(Habit habit) async {
    final existing = state.habits.indexWhere((item) => item.id == habit.id);
    final habits = [...state.habits];
    if (existing == -1) {
      habits.add(habit);
    } else {
      habits[existing] = habit;
    }
    state = state.copyWith(habits: habits);
    await _storage.writeHabits(habits);
  }

  Future<void> deleteHabit(String id) async {
    final habits = state.habits.where((habit) => habit.id != id).toList();
    final logs = state.logs.where((log) => log.habitId != id).toList();
    state = state.copyWith(habits: habits, logs: logs);
    await Future.wait([_storage.writeHabits(habits), _storage.writeLogs(logs)]);
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = state.copyWith(profile: profile);
    await _storage.writeProfile(profile);
  }

  Future<bool> purchaseItem(ShopItem item) async {
    final profile = state.profile;
    if (item.type != ShopItemType.streakSaver &&
        profile.ownedItems.contains(item.id)) {
      return false;
    }
    if (profile.coins < item.price) return false;
    final owned = {
      ...profile.ownedItems,
      if (item.type != ShopItemType.streakSaver) item.id,
    };
    final updated = profile.copyWith(
      coins: profile.coins - item.price,
      ownedItems: owned.toList(),
      streakSavers: item.type == ShopItemType.streakSaver
          ? profile.streakSavers + 1
          : null,
    );
    await updateProfile(updated);
    return true;
  }

  Future<void> equipItem(ShopItem item) async {
    if (!state.profile.ownedItems.contains(item.id)) return;
    final profile = item.type == ShopItemType.avatar
        ? state.profile.copyWith(avatarKey: item.id)
        : state.profile.copyWith(borderKey: item.id);
    await updateProfile(profile);
  }

  bool isCompletedToday(String habitId) => state.logs.any(
    (log) => log.habitId == habitId && _sameDay(log.date, DateTime.now()),
  );

  int weeklyCompletions(String habitId, [DateTime? date]) {
    final current = date ?? DateTime.now();
    final start = _weekStart(current);
    final end = start.add(const Duration(days: 7));
    return state.logs
        .where(
          (log) =>
              log.habitId == habitId &&
              !log.date.isBefore(start) &&
              log.date.isBefore(end),
        )
        .length;
  }

  bool canCompleteToday(String habitId) {
    final habit = state.habits.where((item) => item.id == habitId).firstOrNull;
    if (habit == null || isCompletedToday(habitId)) return false;
    return habit.frequency == HabitFrequency.daily ||
        weeklyCompletions(habitId) < habit.weeklyTarget;
  }

  Future<bool> completeToday(String habitId) async {
    final habit = state.habits.where((item) => item.id == habitId).firstOrNull;
    if (habit == null || !canCompleteToday(habitId)) return false;
    final difficulty = habit.difficulty;
    final today = DateTime.now();
    final previous =
        state.logs
            .where((log) => log.habitId == habitId)
            .map((log) => DateTime(log.date.year, log.date.month, log.date.day))
            .toList()
          ..sort();
    var logs = [...state.logs];
    var profile = state.profile;
    if (habit.frequency == HabitFrequency.daily &&
        previous.isNotEmpty &&
        today.difference(previous.last).inDays == 2 &&
        profile.streakSavers > 0) {
      logs.add(
        HabitLog(
          habitId: habitId,
          date: previous.last.add(const Duration(days: 1)),
        ),
      );
      profile = profile.copyWith(streakSavers: profile.streakSavers - 1);
    }
    logs.add(HabitLog(habitId: habitId, date: today));
    final streak = habit.frequency == HabitFrequency.weekly
        ? GamificationService.weeklyStreakFor(
            habitId,
            logs,
            today,
            target: habit.weeklyTarget,
          )
        : GamificationService.streakFor(habitId, logs, today);
    profile = profile.copyWith(
      xp:
          state.profile.xp +
          GamificationService.xpForCompletion(streak, difficulty: difficulty),
      coins: state.profile.coins + GamificationService.baseCoins,
      longestStreak: streak > state.profile.longestStreak ? streak : null,
    );
    state = state.copyWith(logs: logs, profile: profile);
    await Future.wait([
      _storage.writeLogs(logs),
      _storage.writeProfile(profile),
    ]);
    return true;
  }

  int completionsFor(String habitId) =>
      state.logs.where((log) => log.habitId == habitId).length;

  int get totalCompletions => state.logs.length;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _weekStart(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }
}
