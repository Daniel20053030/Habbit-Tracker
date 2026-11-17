import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker_app/models/habit_log.dart';
import 'package:habit_tracker_app/models/habit.dart';
import 'package:habit_tracker_app/services/gamification_service.dart';

void main() {
  test('calculates consecutive streak ending today', () {
    final today = DateTime(2026, 10, 19);
    final logs = [
      HabitLog(habitId: 'run', date: today),
      HabitLog(habitId: 'run', date: today.subtract(const Duration(days: 1))),
      HabitLog(habitId: 'run', date: today.subtract(const Duration(days: 2))),
    ];

    expect(GamificationService.streakFor('run', logs, today), 3);
    expect(GamificationService.streakFor('read', logs, today), 0);
  });

  test('adds streak bonus at seven days', () {
    expect(GamificationService.xpForCompletion(6), 50);
    expect(GamificationService.xpForCompletion(7), 55);
  });

  test('awards XP by habit difficulty', () {
    expect(
      GamificationService.xpForCompletion(1, difficulty: HabitDifficulty.easy),
      50,
    );
    expect(
      GamificationService.xpForCompletion(
        1,
        difficulty: HabitDifficulty.medium,
      ),
      75,
    );
    expect(
      GamificationService.xpForCompletion(1, difficulty: HabitDifficulty.hard),
      100,
    );
  });

  test('counts weekly streaks only after the weekly target is met', () {
    final today = DateTime(2026, 10, 19);
    final logs = [
      HabitLog(habitId: 'read', date: today),
      HabitLog(habitId: 'read', date: today.add(const Duration(days: 1))),
      HabitLog(habitId: 'read', date: today.subtract(const Duration(days: 7))),
    ];

    expect(
      GamificationService.weeklyStreakFor('read', logs, today, target: 2),
      1,
    );
    expect(
      GamificationService.weeklyStreakFor('read', logs, today, target: 1),
      2,
    );
  });
}
