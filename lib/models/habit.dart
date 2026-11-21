enum HabitFrequency { daily, weekly }

enum HabitDifficulty { easy, medium, hard }

enum HabitType { build, reduce, quit }

enum GoalPeriod { day, week, month }

enum TaskSchedule { everyDay, weekdays, weekends }

enum TimeRange { anytime, morning, afternoon, evening }

const _copyWithUnset = Object();

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
    this.description = '',
    this.groupName = '',
    this.habitType = HabitType.build,
    this.goalPeriod = GoalPeriod.day,
    this.goalValue = 1,
    this.taskSchedule = TaskSchedule.everyDay,
    this.timeRange = TimeRange.anytime,
    this.remindersEnabled = false,
    this.superAlert = false,
    this.reminderTimes = const [],
  });

  final String id;
  final String title;
  final int? iconCodePoint;
  final int colorValue;
  final HabitFrequency frequency;
  final int weeklyTarget;
  final HabitDifficulty difficulty;
  final String goal;
  final DateTime createdAt;
  final String description;
  final String groupName;
  final HabitType habitType;
  final GoalPeriod goalPeriod;
  final int goalValue;
  final TaskSchedule taskSchedule;
  final TimeRange timeRange;
  final bool remindersEnabled;
  final bool superAlert;
  final List<String> reminderTimes;

  Habit copyWith({
    String? title,
    Object? iconCodePoint = _copyWithUnset,
    int? colorValue,
    HabitFrequency? frequency,
    int? weeklyTarget,
    HabitDifficulty? difficulty,
    String? goal,
    String? description,
    String? groupName,
    HabitType? habitType,
    GoalPeriod? goalPeriod,
    int? goalValue,
    TaskSchedule? taskSchedule,
    TimeRange? timeRange,
    bool? remindersEnabled,
    bool? superAlert,
    List<String>? reminderTimes,
  }) {
    return Habit(
      id: id,
      title: title ?? this.title,
      iconCodePoint: identical(iconCodePoint, _copyWithUnset)
          ? this.iconCodePoint
          : iconCodePoint as int?,
      colorValue: colorValue ?? this.colorValue,
      frequency: frequency ?? this.frequency,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      difficulty: difficulty ?? this.difficulty,
      goal: goal ?? this.goal,
      createdAt: createdAt,
      description: description ?? this.description,
      groupName: groupName ?? this.groupName,
      habitType: habitType ?? this.habitType,
      goalPeriod: goalPeriod ?? this.goalPeriod,
      goalValue: goalValue ?? this.goalValue,
      taskSchedule: taskSchedule ?? this.taskSchedule,
      timeRange: timeRange ?? this.timeRange,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      superAlert: superAlert ?? this.superAlert,
      reminderTimes: reminderTimes ?? this.reminderTimes,
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
    'description': description,
    'groupName': groupName,
    'habitType': habitType.name,
    'goalPeriod': goalPeriod.name,
    'goalValue': goalValue,
    'taskSchedule': taskSchedule.name,
    'timeRange': timeRange.name,
    'remindersEnabled': remindersEnabled,
    'superAlert': superAlert,
    'reminderTimes': reminderTimes,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    title: json['title'] as String,
    iconCodePoint: json['iconCodePoint'] as int?,
    colorValue: json['colorValue'] as int,
    frequency: HabitFrequency.values.byName(json['frequency'] as String),
    weeklyTarget: (json['weeklyTarget'] as num?)?.toInt() ?? 1,
    difficulty: HabitDifficulty.values.byName(
      json['difficulty'] as String? ?? HabitDifficulty.easy.name,
    ),
    goal: json['goal'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    description: json['description'] as String? ?? '',
    groupName: json['groupName'] as String? ?? '',
    habitType: HabitType.values.byName(
      json['habitType'] as String? ?? HabitType.build.name,
    ),
    goalPeriod: GoalPeriod.values.byName(
      json['goalPeriod'] as String? ?? GoalPeriod.day.name,
    ),
    goalValue: (json['goalValue'] as num?)?.toInt() ?? 1,
    taskSchedule: TaskSchedule.values.byName(
      json['taskSchedule'] as String? ?? TaskSchedule.everyDay.name,
    ),
    timeRange: TimeRange.values.byName(
      json['timeRange'] as String? ?? TimeRange.anytime.name,
    ),
    remindersEnabled: json['remindersEnabled'] as bool? ?? false,
    superAlert: json['superAlert'] as bool? ?? false,
    reminderTimes: (json['reminderTimes'] as List<dynamic>? ?? const [])
        .map((value) => value as String)
        .toList(),
  );
}
