enum HabitFrequency { daily, weekly }

enum HabitDifficulty { easy, medium, hard }

class Habit {
  const Habit({
    required this.id,
    required this.title,
    required this.iconCodePoint,
    required this.colorValue,
    required this.frequency,
    this.weeklyTarget = 1,
    this.difficulty = HabitDifficulty.easy,
    required this.goal,
    required this.createdAt,
  });

  final String id;
  final String title;
  final int iconCodePoint;
  final int colorValue;
  final HabitFrequency frequency;
  final int weeklyTarget;
  final HabitDifficulty difficulty;
  final String goal;
  final DateTime createdAt;

  Habit copyWith({
    String? title,
    int? iconCodePoint,
    int? colorValue,
    HabitFrequency? frequency,
    int? weeklyTarget,
    HabitDifficulty? difficulty,
    String? goal,
  }) {
    return Habit(
      id: id,
      title: title ?? this.title,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      frequency: frequency ?? this.frequency,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      difficulty: difficulty ?? this.difficulty,
      goal: goal ?? this.goal,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'iconCodePoint': iconCodePoint,
    'colorValue': colorValue,
    'frequency': frequency.name,
    'weeklyTarget': weeklyTarget,
    'difficulty': difficulty.name,
    'goal': goal,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    title: json['title'] as String,
    iconCodePoint: json['iconCodePoint'] as int,
    colorValue: json['colorValue'] as int,
    frequency: HabitFrequency.values.byName(json['frequency'] as String),
    weeklyTarget: (json['weeklyTarget'] as num?)?.toInt() ?? 1,
    difficulty: HabitDifficulty.values.byName(
      json['difficulty'] as String? ?? HabitDifficulty.easy.name,
    ),
    goal: json['goal'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
