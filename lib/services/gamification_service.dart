import '../models/habit_log.dart';
import '../models/habit.dart';

class GamificationService {
  static const int easyXp = 50;
  static const int mediumXp = 75;
  static const int hardXp = 100;
  static const int baseCoins = 5;

  static int streakFor(String habitId, List<HabitLog> logs, DateTime today) {
    final dates = logs
        .where((log) => log.habitId == habitId)
        .map((log) => _dayKey(log.date))
        .toSet();
    var streak = 0;
    var day = DateTime(today.year, today.month, today.day);
    while (dates.contains(_dayKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    return streak;
  }

  static int weeklyStreakFor(
    String habitId,
    List<HabitLog> logs,
    DateTime today, {
    required int target,
  }) {
    final weekCounts = <int, int>{};
    for (final log in logs.where((log) => log.habitId == habitId)) {
      final week = _weekStart(log.date);
      final key = _dayKey(week);
      weekCounts[key] = (weekCounts[key] ?? 0) + 1;
    }

    var streak = 0;
    var week = _weekStart(today);
    while ((weekCounts[_dayKey(week)] ?? 0) >= target) {
      streak++;
      week = week.subtract(const Duration(days: 7));
    }
    return streak;
  }

  static int xpForCompletion(
    int streak, {
    HabitDifficulty difficulty = HabitDifficulty.easy,
  }) {
    final baseXp = switch (difficulty) {
      HabitDifficulty.easy => easyXp,
      HabitDifficulty.medium => mediumXp,
      HabitDifficulty.hard => hardXp,
    };
    return baseXp + (streak >= 7 ? 5 : 0);
  }

  static int _dayKey(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  static DateTime _weekStart(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }
}
