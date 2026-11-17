class HabitLog {
  const HabitLog({required this.habitId, required this.date});

  final String habitId;
  final DateTime date;

  Map<String, dynamic> toJson() => {
    'habitId': habitId,
    'date': date.toIso8601String(),
  };

  factory HabitLog.fromJson(Map<String, dynamic> json) => HabitLog(
    habitId: json['habitId'] as String,
    date: DateTime.parse(json['date'] as String),
  );
}
