import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/user_profile.dart';

class LocalStorageService {
  LocalStorageService(this.preferences);

  final SharedPreferences preferences;
  static const _habitsKey = 'habits';
  static const _logsKey = 'logs';
  static const _profileKey = 'profile';

  List<Habit> readHabits() => _decodeList(_habitsKey, Habit.fromJson);
  bool get hasStoredHabits => preferences.containsKey(_habitsKey);
  List<HabitLog> readLogs() => _decodeList(_logsKey, HabitLog.fromJson);

  UserProfile readProfile() {
    final raw = preferences.getString(_profileKey);
    if (raw == null) return const UserProfile();
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> writeHabits(List<Habit> habits) =>
      _writeList(_habitsKey, habits.map((e) => e.toJson()).toList());
  Future<void> writeLogs(List<HabitLog> logs) =>
      _writeList(_logsKey, logs.map((e) => e.toJson()).toList());
  Future<void> writeProfile(UserProfile profile) =>
      preferences.setString(_profileKey, jsonEncode(profile.toJson()));

  List<T> _decodeList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = preferences.getString(key);
    if (raw == null) return [];
    final values = jsonDecode(raw) as List<dynamic>;
    return values
        .map((value) => fromJson(value as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> values) =>
      preferences.setString(key, jsonEncode(values));
}
