import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/habit.dart';
import 'models/habit_log.dart';
import 'models/shop_item.dart';
import 'models/user_profile.dart';
import 'providers/app_provider.dart';
import 'services/gamification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = SharedPreferences.getInstance();
  runApp(HabitStartupApp(preferences: preferences));
}

class HabitStartupApp extends StatelessWidget {
  const HabitStartupApp({required this.preferences, super.key});

  final Future<SharedPreferences> preferences;

  @override
  Widget build(BuildContext context) => FutureBuilder<SharedPreferences>(
    future: preferences,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: const HabitLoadingScreen(),
        );
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: const HabitStartupErrorScreen(),
        );
      }
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(snapshot.data!),
        ],
        child: const HabitTrackerApp(),
      );
    },
  );
}

class HabitLoadingScreen extends StatelessWidget {
  const HabitLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: AppTheme.accent,
              size: 46,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Habit Tracker',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ],
      ),
    ),
  );
}

class HabitStartupErrorScreen extends StatelessWidget {
  const HabitStartupErrorScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.accent),
            SizedBox(height: 16),
            Text(
              'Could not start Habit Tracker',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Restart the app and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    ),
  );
}

const _materialIconsByCodePoint = <int, IconData>{
  0xe1dc: Icons.directions_run,
  0xe3dd: Icons.menu_book,
  0xf05a2: Icons.water_drop,
  0xe56f: Icons.self_improvement,
  0xe28d: Icons.fitness_center,
  0xe491: Icons.person,
  0xe5f9: Icons.star,
  0xf055d: Icons.rocket_launch,
  0xe798: Icons.water_drop,
  0xe3f1: Icons.directions_run,
  0xe8b8: Icons.menu_book,
  0xe838: Icons.star,
  0xe1a5: Icons.rocket_launch,
};

IconData iconForCodePoint(int? codePoint) =>
    _materialIconsByCodePoint[codePoint] ?? Icons.circle_outlined;

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/stats',
          builder: (context, state) => const StatsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(path: '/shop', builder: (context, state) => const ShopScreen()),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/settings/:section',
      builder: (context, state) =>
          SettingsDetailScreen(section: state.pathParameters['section'] ?? ''),
    ),
    GoRoute(
      path: '/habit/new',
      builder: (context, state) => const HabitFormScreen(),
    ),
    GoRoute(
      path: '/habit/:id',
      builder: (context, state) =>
          HabitFormScreen(habitId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const ProfileEditorScreen(),
    ),
  ],
);

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Habit Tracker',
    theme: AppTheme.dark(),
    routerConfig: _router,
    debugShowCheckedModeBanner: false,
  );
}

class MainShell extends StatelessWidget {
  const MainShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = location == '/profile'
        ? 1
        : location == '/stats'
        ? 2
        : location == '/settings'
        ? 3
        : 0;
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: selected,
              backgroundColor: Colors.transparent,
              indicatorColor: selected == 0
                  ? AppTheme.highlight.withValues(alpha: 0.20)
                  : AppTheme.surfaceLight,
              height: 68,
              onDestinationSelected: (index) {
                if (index == 0) {
                  context.go('/');
                } else if (index == 1) {
                  context.go('/profile');
                } else if (index == 2) {
                  context.go('/stats');
                } else {
                  context.go('/settings');
                }
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.lightbulb_outline),
                  selectedIcon: Icon(
                    Icons.lightbulb,
                    color: AppTheme.highlight,
                  ),
                  label: 'Today',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'Stats',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _xpPopup;
  Timer? _xpPopupTimer;

  @override
  void dispose() {
    _xpPopupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final controller = ref.read(appProvider.notifier);
    final preferences = ref.read(sharedPreferencesProvider);
    final hideCompleted =
        preferences.getBool('settings_hide_completed') ?? false;
    final compactCards = preferences.getBool('settings_compact_cards') ?? false;
    final hapticsEnabled = preferences.getBool('settings_haptics') ?? true;
    final completionFeedback =
        preferences.getBool('settings_completion_feedback') ?? true;
    final visibleHabits = hideCompleted
        ? state.habits
              .where((habit) => controller.canCompleteToday(habit.id))
              .toList()
        : state.habits;
    final date = DateTime.now();
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final weekDays = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  const SizedBox(width: 44),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  ProfileAvatar(profile: state.profile, size: 44),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekDays.map((day) {
                  final selected = _sameDate(day, date);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.surface
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: selected
                              ? Border.all(color: AppTheme.surfaceLight)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _shortWeekday(day.weekday),
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppTheme.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? AppTheme.surfaceLight
                                    : Colors.transparent,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.textMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (state.habits.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${controller.totalCompletions > 0 ? state.habits.where((habit) => !controller.canCompleteToday(habit.id)).length : 0} of ${state.habits.length} quests complete',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: state.habits.isEmpty
                                      ? 0
                                      : state.habits
                                                .where(
                                                  (habit) => !controller
                                                      .canCompleteToday(
                                                        habit.id,
                                                      ),
                                                )
                                                .length /
                                            state.habits.length,
                                  minHeight: 6,
                                  backgroundColor: AppTheme.surfaceLight,
                                  color: AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${((state.habits.isEmpty ? 0 : state.habits.where((habit) => !controller.canCompleteToday(habit.id)).length / state.habits.length) * 100).round()}%',
                          style: const TextStyle(
                            color: AppTheme.highlight,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_xpPopup != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _xpPopup!,
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(
              child: visibleHabits.isEmpty
                  ? _HomeEmptyState(
                      onAdd: () => context.push('/habit/new'),
                      title: hideCompleted && state.habits.isNotEmpty
                          ? 'All Done'
                          : 'No Habits',
                      message: hideCompleted && state.habits.isNotEmpty
                          ? 'All habits are completed for today.'
                          : 'Tap "+" to add your first quest.',
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        compactCards ? 10 : 18,
                        16,
                        24,
                      ),
                      itemCount: visibleHabits.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final habit = visibleHabits[index];
                        final complete = !controller.canCompleteToday(habit.id);
                        return _CompletionHabitTile(
                          key: ValueKey(habit.id),
                          habit: habit,
                          complete: complete,
                          compact: compactCards,
                          hideOnComplete: hideCompleted,
                          onOpen: () => context.push('/habit/${habit.id}'),
                          onComplete: () async {
                            final previousXp = ref.read(appProvider).profile.xp;
                            if (hapticsEnabled) {
                              await HapticFeedback.selectionClick();
                            }
                            final earned = await controller.completeToday(
                              habit.id,
                            );
                            if (context.mounted && earned) {
                              final gainedXp =
                                  ref.read(appProvider).profile.xp - previousXp;
                              if (completionFeedback) {
                                _showXpPopup(gainedXp);
                              }
                            }
                            return earned;
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          right: 18,
          bottom: 18,
          child: Semantics(
            button: true,
            label: 'Create a new quest',
            child: FloatingActionButton.extended(
              onPressed: () => context.push('/habit/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add Quest'),
              tooltip: 'Create a new quest',
            ),
          ),
        ),
      ],
    );
  }

  void _showXpPopup(int gainedXp) {
    _xpPopupTimer?.cancel();
    setState(() => _xpPopup = '+$gainedXp XP earned!');
    _xpPopupTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _xpPopup = null);
    });
  }
}

class _CompletionHabitTile extends StatefulWidget {
  const _CompletionHabitTile({
    super.key,
    required this.habit,
    required this.complete,
    required this.compact,
    required this.hideOnComplete,
    required this.onOpen,
    required this.onComplete,
  });

  final Habit habit;
  final bool complete;
  final bool compact;
  final bool hideOnComplete;
  final VoidCallback onOpen;
  final Future<bool> Function() onComplete;

  @override
  State<_CompletionHabitTile> createState() => _CompletionHabitTileState();
}

class _CompletionHabitTileState extends State<_CompletionHabitTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = Tween<double>(
      begin: 1,
      end: widget.hideOnComplete ? 0.15 : 0.65,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scale = Tween<double>(
      begin: 1,
      end: widget.hideOnComplete ? 0.94 : 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (_completing || widget.complete) return;
    setState(() => _completing = true);
    if (!MediaQuery.disableAnimationsOf(context)) {
      await _controller.forward();
    }
    final earned = await widget.onComplete();
    if (!mounted) return;
    if (!earned) {
      setState(() => _completing = false);
      await _controller.reverse();
      return;
    }
    if (!widget.hideOnComplete && !MediaQuery.disableAnimationsOf(context)) {
      await _controller.reverse();
    }
    if (mounted) setState(() => _completing = false);
  }

  @override
  Widget build(BuildContext context) {
    final complete = widget.complete || _completing;
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          child: ListTile(
            key: ValueKey(widget.habit.id),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: widget.compact ? 2 : 5,
            ),
            onTap: widget.onOpen,
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Color(widget.habit.colorValue).withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconForCodePoint(widget.habit.iconCodePoint),
                color: Color(widget.habit.colorValue),
              ),
            ),
            title: Text(
              widget.habit.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              widget.habit.frequency == HabitFrequency.weekly
                  ? '${widget.habit.weeklyTarget} per week'
                  : widget.habit.description.isNotEmpty
                  ? widget.habit.description
                  : widget.habit.goal,
              style: const TextStyle(color: AppTheme.textMuted),
            ),
            trailing: IconButton(
              tooltip: complete
                  ? 'Completed today'
                  : 'Complete ${widget.habit.title}',
              onPressed: complete ? null : _complete,
              icon: Icon(
                complete ? Icons.check_circle : Icons.radio_button_unchecked,
                color: complete ? AppTheme.success : AppTheme.accent,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({
    required this.onAdd,
    this.title = 'No Habits',
    this.message = 'Tap "+" to add your first quest.',
  });

  final VoidCallback onAdd;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rocket_launch_outlined,
              size: 112,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Quest'),
          ),
        ],
      ),
    ),
  );
}

class _StarterQuestChip extends StatelessWidget {
  const _StarterQuestChip({
    required this.title,
    required this.description,
    required this.iconCodePoint,
    required this.color,
    required this.onSelected,
  });

  final String title;
  final String description;
  final int iconCodePoint;
  final Color color;
  final void Function(
    String title,
    String description,
    int iconCodePoint,
    Color color,
  )
  onSelected;

  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(iconForCodePoint(iconCodePoint), color: color, size: 18),
    label: Text(title),
    onPressed: () => onSelected(title, description, iconCodePoint, color),
  );
}

class HabitFormScreen extends ConsumerStatefulWidget {
  const HabitFormScreen({this.habitId, super.key});
  final String? habitId;

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _goalValueController;
  final HabitFrequency _frequency = HabitFrequency.daily;
  final int _weeklyTarget = 1;
  late int _color;
  late int? _icon;
  late HabitType _habitType;
  late GoalPeriod _goalPeriod;
  late TaskSchedule _taskSchedule;
  late TimeRange _timeRange;
  late bool _remindersEnabled;
  late bool _superAlert;
  late List<String> _reminderTimes;
  bool _saving = false;
  bool _deleting = false;

  final _colors = [
    const Color(0xFF42D9FF),
    const Color(0xFF64E8A5),
    const Color(0xFFF2B84B),
    const Color(0xFFFF79B0),
    const Color(0xFFA78BFA),
  ];
  final _icons = [
    Icons.directions_run,
    Icons.menu_book,
    Icons.water_drop,
    Icons.self_improvement,
    Icons.fitness_center,
    Icons.check_circle_outline,
    Icons.cleaning_services_outlined,
    Icons.restaurant_outlined,
    Icons.bedtime_outlined,
    Icons.code,
    Icons.music_note,
    Icons.spa_outlined,
    Icons.work_outline,
    Icons.savings_outlined,
    Icons.directions_bike,
  ];

  Habit? get _habit {
    final habits = ref.read(appProvider).habits;
    return widget.habitId == null
        ? null
        : habits.where((item) => item.id == widget.habitId).firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    final habit = _habit;
    _titleController = TextEditingController(text: habit?.title);
    _descriptionController = TextEditingController(text: habit?.description);
    _goalValueController = TextEditingController(
      text: '${habit?.goalValue ?? 1}',
    );
    _color = habit?.colorValue ?? AppTheme.accent.toARGB32();
    _icon = habit?.iconCodePoint;
    _habitType = habit?.habitType ?? HabitType.build;
    _goalPeriod = habit?.goalPeriod ?? GoalPeriod.day;
    _taskSchedule = habit?.taskSchedule ?? TaskSchedule.everyDay;
    _timeRange = habit?.timeRange ?? TimeRange.anytime;
    _remindersEnabled = habit?.remindersEnabled ?? false;
    _superAlert = habit?.superAlert ?? false;
    _reminderTimes = [...?habit?.reminderTimes];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _goalValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.habitId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit habit' : 'New habit'),
        actions: editing
            ? [
                IconButton(
                  tooltip: 'Delete habit',
                  onPressed: _saving || _deleting ? null : _delete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          key: const ValueKey('habit-form-list'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                editing ? 'Tune your quest' : 'Start a small quest',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                editing
                    ? 'Keep the goal clear and easy to return to.'
                    : 'Give this habit a name you will recognize at a glance.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),
              if (!editing) ...[
                const Text(
                  'Starter quests',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StarterQuestChip(
                      title: 'Drink water',
                      description: 'Drink a glass of water',
                      iconCodePoint: 0xf05a2,
                      color: Color(0xFF42D9FF),
                      onSelected: _applyStarterQuest,
                    ),
                    _StarterQuestChip(
                      title: 'Move your body',
                      description: 'Move for 10 minutes',
                      iconCodePoint: 0xe3f1,
                      color: Color(0xFF64E8A5),
                      onSelected: _applyStarterQuest,
                    ),
                    _StarterQuestChip(
                      title: 'Read',
                      description: 'Read a few pages',
                      iconCodePoint: 0xe3dd,
                      color: Color(0xFFA78BFA),
                      onSelected: _applyStarterQuest,
                    ),
                    _StarterQuestChip(
                      title: 'Meditate',
                      description: 'Take a mindful 5-minute break',
                      iconCodePoint: 0xe56f,
                      color: Color(0xFFF2B84B),
                      onSelected: _applyStarterQuest,
                    ),
                    _StarterQuestChip(
                      title: 'Plan your day',
                      description: 'Choose your top priorities',
                      iconCodePoint: 0xe491,
                      color: Color(0xFFFF79B0),
                      onSelected: _applyStarterQuest,
                    ),
                    _StarterQuestChip(
                      title: 'Sleep on time',
                      description: 'Begin your bedtime routine',
                      iconCodePoint: 0xe1a5,
                      color: Color(0xFF42D9FF),
                      onSelected: _applyStarterQuest,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                key: const ValueKey('habit-name-field'),
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Habit name',
                  hintText: 'Morning run',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLength: 40,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a habit name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('habit-description-field'),
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add a short note',
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLength: 120,
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose a marker',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  Semantics(
                    label: 'No marker',
                    selected: _icon == null,
                    child: ChoiceChip(
                      selected: _icon == null,
                      showCheckmark: false,
                      selectedColor: AppTheme.success,
                      label: const Icon(Icons.circle_outlined),
                      onSelected: (_) => setState(() => _icon = null),
                    ),
                  ),
                  ..._icons.map(
                    (icon) => Semantics(
                      label: 'Habit icon ${_iconLabel(icon)}',
                      selected: _icon == icon.codePoint,
                      child: ChoiceChip(
                        selected: _icon == icon.codePoint,
                        showCheckmark: false,
                        selectedColor: AppTheme.success,
                        label: Icon(icon),
                        onSelected: (_) =>
                            setState(() => _icon = icon.codePoint),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose a color',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: _colors
                    .map(
                      (color) => Semantics(
                        label: 'Habit color ${_colorLabel(color)}',
                        selected: _color == color.toARGB32(),
                        child: ChoiceChip(
                          selected: _color == color.toARGB32(),
                          showCheckmark: false,
                          selectedColor: AppTheme.success,
                          label: CircleAvatar(
                            backgroundColor: color,
                            radius: 10,
                          ),
                          onSelected: (_) =>
                              setState(() => _color = color.toARGB32()),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<HabitType>(
                initialValue: _habitType,
                decoration: const InputDecoration(labelText: 'Habit type'),
                items: HabitType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.name.capitalize()),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _habitType = value ?? HabitType.build),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<GoalPeriod>(
                initialValue: _goalPeriod,
                decoration: const InputDecoration(labelText: 'Goal period'),
                items: GoalPeriod.values
                    .map(
                      (period) => DropdownMenuItem(
                        value: period,
                        child: Text(
                          period == GoalPeriod.day
                              ? 'Day - Long'
                              : period.name.capitalize(),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _goalPeriod = value ?? GoalPeriod.day),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('habit-goal-value-field'),
                controller: _goalValueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Goal value',
                  suffixText: 'per day',
                ),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  return parsed == null || parsed < 1
                      ? 'Enter a whole number of 1 or more'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskSchedule>(
                initialValue: _taskSchedule,
                decoration: const InputDecoration(labelText: 'Task days'),
                items: TaskSchedule.values
                    .map(
                      (schedule) => DropdownMenuItem(
                        value: schedule,
                        child: Text(
                          schedule == TaskSchedule.everyDay
                              ? 'Every Day'
                              : schedule.name.capitalize(),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(
                  () => _taskSchedule = value ?? TaskSchedule.everyDay,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Time range',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SegmentedButton<TimeRange>(
                segments: TimeRange.values
                    .map(
                      (range) => ButtonSegment(
                        value: range,
                        label: Text(
                          range.name == 'anytime'
                              ? 'Anytime'
                              : range.name.capitalize(),
                        ),
                      ),
                    )
                    .toList(),
                selected: {_timeRange},
                onSelectionChanged: (selection) =>
                    setState(() => _timeRange = selection.first),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reminders'),
                value: _remindersEnabled,
                onChanged: (value) => setState(() => _remindersEnabled = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Super alert'),
                value: _superAlert,
                onChanged: (value) => setState(() => _superAlert = value),
              ),
              if (_remindersEnabled) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._reminderTimes.map(
                      (time) => InputChip(
                        label: Text(time),
                        onDeleted: () => setState(
                          () => _reminderTimes = _reminderTimes
                              .where((item) => item != time)
                              .toList(),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _addReminder,
                      icon: const Icon(Icons.add),
                      label: const Text('Add time'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving || _deleting ? null : _save,
                child: Text(
                  _saving
                      ? 'Saving quest...'
                      : editing
                      ? 'Save changes'
                      : 'Create habit',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyStarterQuest(
    String title,
    String description,
    int iconCodePoint,
    Color color,
  ) {
    setState(() {
      _titleController.text = title;
      _descriptionController.text = description;
      _icon = iconCodePoint;
      _color = color.toARGB32();
    });
  }

  Future<void> _addReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted || picked == null) return;
    final label = picked.format(context);
    if (!_reminderTimes.contains(label)) {
      setState(() => _reminderTimes = [..._reminderTimes, label]);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final existing = _habit;
    final habit = Habit(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      iconCodePoint: _icon,
      colorValue: _color,
      frequency: _frequency,
      weeklyTarget: _weeklyTarget,
      difficulty: existing?.difficulty ?? HabitDifficulty.easy,
      goal: _descriptionController.text.trim().isEmpty
          ? _titleController.text.trim()
          : _descriptionController.text.trim(),
      createdAt: existing?.createdAt ?? DateTime.now(),
      description: _descriptionController.text.trim(),
      groupName: existing?.groupName ?? '',
      habitType: _habitType,
      goalPeriod: _goalPeriod,
      goalValue: int.parse(_goalValueController.text.trim()),
      taskSchedule: _taskSchedule,
      timeRange: _timeRange,
      remindersEnabled: _remindersEnabled,
      superAlert: _superAlert,
      reminderTimes: _reminderTimes,
    );
    try {
      await ref.read(appProvider.notifier).saveHabit(habit);
      if (mounted) context.go('/');
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save this habit: $error')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final habitName = _titleController.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "$habitName"?'),
        content: const Text(
          'This removes the quest and all of its completion history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _deleting = true);
      try {
        await ref.read(appProvider.notifier).deleteHabit(widget.habitId!);
        if (mounted) context.go('/');
      } catch (error) {
        if (mounted) {
          setState(() => _deleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete this habit: $error')),
          );
        }
      }
    }
  }
}

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final controller = ref.read(appProvider.notifier);
    final today = _dateOnly(DateTime.now());
    final weeklyDays = List.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );
    final weeklyCounts = weeklyDays
        .map(
          (day) => state.logs.where((log) => _sameDate(log.date, day)).length,
        )
        .toList();
    final monthlyDays = List.generate(
      28,
      (index) => today.subtract(Duration(days: 27 - index)),
    );
    final monthlyLogs = state.logs
        .where((log) => monthlyDays.any((day) => _sameDate(log.date, day)))
        .length;
    final activeDays = monthlyDays
        .where((day) => state.logs.any((log) => _sameDate(log.date, day)))
        .length;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Stats',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total XP',
                value: '${state.profile.xp}',
                icon: Icons.stars,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Completed',
                value: '${controller.totalCompletions}',
                icon: Icons.check_circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricCard(
          label: 'Best streak',
          value: '${state.profile.longestStreak} days',
          icon: Icons.local_fire_department,
        ),
        const SizedBox(height: 26),
        const Text(
          'Last 7 days',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _WeeklyActivity(days: weeklyDays, counts: weeklyCounts),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: _StatSummary(
                    label: '28-day completions',
                    value: '$monthlyLogs',
                  ),
                ),
                Expanded(
                  child: _StatSummary(
                    label: 'Active days',
                    value: '$activeDays / 28',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Completion calendar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _CompletionCalendar(days: monthlyDays, logs: state.logs),
        const SizedBox(height: 26),
        const Text(
          'Last 7 days by quest',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _HabitDayMatrix(
          days: weeklyDays,
          habits: state.habits,
          logs: state.logs,
        ),
        const SizedBox(height: 26),
        const Text(
          'Habit breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...state.habits.map(
          (habit) => Card(
            child: ListTile(
              leading: Icon(
                iconForCodePoint(habit.iconCodePoint),
                color: Color(habit.colorValue),
              ),
              title: Text(habit.title),
              subtitle: Text(
                habit.frequency == HabitFrequency.weekly
                    ? '${controller.weeklyCompletions(habit.id)}/${habit.weeklyTarget} this week'
                    : '${habit.taskSchedule.name == 'everyDay' ? 'Every day' : habit.taskSchedule.name.capitalize()}  •  '
                          '${controller.completionsFor(habit.id)} completions',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${habit.frequency == HabitFrequency.weekly ? GamificationService.weeklyStreakFor(habit.id, state.logs, today, target: habit.weeklyTarget) : GamificationService.streakFor(habit.id, state.logs, today)} '
                    '${habit.frequency == HabitFrequency.weekly ? 'week' : 'day'} streak',
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Delete ${habit.title}',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text('Delete "${habit.title}"?'),
                          content: const Text(
                            'This removes the quest and all of its completion history. This cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      try {
                        await controller.deleteHabit(habit.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${habit.title} deleted')),
                          );
                        }
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not delete ${habit.title}: $error',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HabitDayMatrix extends StatelessWidget {
  const _HabitDayMatrix({
    required this.days,
    required this.habits,
    required this.logs,
  });

  final List<DateTime> days;
  final List<Habit> habits;
  final List<HabitLog> logs;

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'Add a quest to see your 7-day activity.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: DataTable(
          horizontalMargin: 8,
          columnSpacing: 12,
          columns: [
            const DataColumn(label: SizedBox(width: 112, child: Text('Quest'))),
            ...days.map(
              (day) => DataColumn(
                label: SizedBox(
                  width: 24,
                  child: Center(
                    child: Text(
                      _shortWeekday(day.weekday),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ),
            ),
          ],
          rows: habits.map((habit) {
            return DataRow(
              cells: [
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 112),
                    child: Text(
                      habit.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                ...days.map((day) {
                  final completed = logs.any(
                    (log) =>
                        log.habitId == habit.id && _sameDate(log.date, day),
                  );
                  return DataCell(
                    Tooltip(
                      message: completed ? 'Completed' : 'Not completed',
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: completed
                              ? AppTheme.accent
                              : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: completed
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: AppTheme.background,
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _WeeklyActivity extends StatelessWidget {
  const _WeeklyActivity({required this.days, required this.counts});

  final List<DateTime> days;
  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final maxCount = counts.fold<int>(
      1,
      (max, count) => count > max ? count : max,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
        child: SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var index = 0; index < days.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${counts[index]}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 88 * counts[index] / maxCount + 4,
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _shortWeekday(days[index].weekday),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionCalendar extends StatelessWidget {
  const _CompletionCalendar({required this.days, required this.logs});

  final List<DateTime> days;
  final List<HabitLog> logs;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: days.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final day = days[index];
          final completed = logs.any((log) => _sameDate(log.date, day));
          return Tooltip(
            message:
                '${_monthDay(day)}: ${completed ? 'completed' : 'no activity'}',
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: completed ? AppTheme.accent : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _StatSummary extends StatelessWidget {
  const _StatSummary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            ProfileAvatar(profile: state.profile, size: 78),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                state.profile.name,
                style: const TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Edit profile',
              onPressed: () => context.push('/profile/edit'),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ProfileSectionTitle(title: 'Progress', action: 'View'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: _ProfileStat(
                    value: '${state.profile.longestStreak}',
                    label: 'Best streak',
                  ),
                ),
                Container(width: 1, height: 52, color: AppTheme.surfaceLight),
                Expanded(
                  child: _ProfileStat(
                    value: '${state.profile.coins}',
                    label: 'Coins',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.storefront_outlined,
              color: AppTheme.highlight,
            ),
            title: const Text('Shop'),
            subtitle: Text('${state.profile.coins} coins available'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/shop'),
          ),
        ),
        const SizedBox(height: 18),
        _ProfileSectionTitle(title: 'Daily Quote', action: 'View'),
        const SizedBox(height: 8),
        Container(
          height: 150,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFFBAC7A7), Color(0xFF375C57)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Small steps become lasting change.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      Text(action, style: const TextStyle(color: AppTheme.textMuted)),
      const SizedBox(width: 4),
      const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
    ],
  );
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
      Text(label, style: const TextStyle(color: AppTheme.textMuted)),
    ],
  );
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.profile,
    required this.size,
    this.showLevel = false,
    super.key,
  });

  final UserProfile profile;
  final double size;
  final bool showLevel;

  @override
  Widget build(BuildContext context) {
    final borderItem = shopItems
        .where(
          (item) =>
              item.type == ShopItemType.border && item.id == profile.borderKey,
        )
        .firstOrNull;
    final border = borderItem?.colorValue == null
        ? AppTheme.surfaceLight
        : Color(borderItem!.colorValue!);
    final imageBytes =
        profile.profileImageBase64 == null ||
            profile.profileImageBase64!.isEmpty
        ? null
        : base64Decode(profile.profileImageBase64!);
    final avatar = imageBytes != null
        ? CircleAvatar(
            radius: size / 2,
            backgroundImage: MemoryImage(imageBytes),
          )
        : CircleAvatar(
            radius: size / 2,
            backgroundColor: AppTheme.surfaceLight,
            child: Icon(
              iconForCodePoint(
                shopItemById(profile.avatarKey).iconCodePoint ??
                    Icons.person.codePoint,
              ),
              size: size * .5,
            ),
          );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 4),
          ),
          child: avatar,
        ),
        if (showLevel)
          Positioned(
            right: -4,
            bottom: -4,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.accent,
              child: Text(
                '${profile.level}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ProfileEditorScreen extends ConsumerStatefulWidget {
  const ProfileEditorScreen({super.key});

  @override
  ConsumerState<ProfileEditorScreen> createState() =>
      _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends ConsumerState<ProfileEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _borderKey;
  String? _imageBase64;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(appProvider).profile;
    _nameController = TextEditingController(text: profile.name);
    _borderKey = profile.borderKey;
    _imageBase64 = profile.profileImageBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borders = shopItems.where((item) => item.type == ShopItemType.border);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                child: Column(
                  children: [
                    ProfileAvatar(
                      profile: ref
                          .watch(appProvider)
                          .profile
                          .copyWith(
                            borderKey: _borderKey,
                            profileImageBase64: _imageBase64 ?? '',
                          ),
                      size: 104,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _nameController.text.trim().isEmpty
                          ? 'Your profile'
                          : _nameController.text.trim(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Profile details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display name',
                helperText: 'Choose a name your future self will recognize.',
              ),
              maxLength: 24,
              onChanged: (_) => setState(() {}),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Use at least 2 characters'
                  : null,
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose image from device'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Profile border',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose a border for your profile.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      selected: _borderKey == 'none',
                      label: const Text('None'),
                      onSelected: (_) => setState(() => _borderKey = 'none'),
                    ),
                    ...borders.map(
                      (item) => ChoiceChip(
                        selected: _borderKey == item.id,
                        label: Text(item.name.replaceAll(' border', '')),
                        onSelected: (_) => setState(() => _borderKey = item.id),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 1500000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please choose an image smaller than 1.5 MB.'),
          ),
        );
      }
      return;
    }
    setState(() => _imageBase64 = base64Encode(bytes));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final current = ref.read(appProvider).profile;
    await ref
        .read(appProvider.notifier)
        .updateProfile(
          current.copyWith(
            name: _nameController.text.trim(),
            borderKey: _borderKey,
            profileImageBase64: _imageBase64 ?? '',
          ),
        );
    if (mounted) context.go('/profile');
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Settings',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Theme'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/appearance'),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Page & Function'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/page'),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Notifications'),
                subtitle: const Text('Reminders and completion feedback'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/notifications'),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Android Widgets'),
                subtitle: const Text('Home screen widget support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/widgets'),
              ),
            ],
          ), //ABDASDBASDASDASD
        ),
        const SizedBox(height: 24),
        const Text(
          'About',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Usage Tips'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/tips'),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('FAQs'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/faqs'),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Support'),
                subtitle: const Text('App help and feedback'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/support'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsDetailScreen extends ConsumerStatefulWidget {
  const SettingsDetailScreen({required this.section, super.key});

  final String section;

  @override
  ConsumerState<SettingsDetailScreen> createState() =>
      _SettingsDetailScreenState();
}

class _SettingsDetailScreenState extends ConsumerState<SettingsDetailScreen> {
  static const _compactKey = 'settings_compact_cards';
  static const _hideCompletedKey = 'settings_hide_completed';
  static const _hapticsKey = 'settings_haptics';
  static const _habitRemindersKey = 'settings_habit_reminders';
  static const _completionFeedbackKey = 'settings_completion_feedback';

  bool get _compactCards =>
      ref.read(sharedPreferencesProvider).getBool(_compactKey) ?? false;

  bool get _hideCompleted =>
      ref.read(sharedPreferencesProvider).getBool(_hideCompletedKey) ?? false;

  bool get _haptics =>
      ref.read(sharedPreferencesProvider).getBool(_hapticsKey) ?? true;

  bool get _habitReminders =>
      ref.read(sharedPreferencesProvider).getBool(_habitRemindersKey) ?? false;

  bool get _completionFeedback =>
      ref.read(sharedPreferencesProvider).getBool(_completionFeedbackKey) ??
      true;

  String get _title {
    switch (widget.section) {
      case 'appearance':
        return 'Theme';
      case 'page':
        return 'Page & Function';
      case 'notifications':
        return 'Notifications';
      case 'widgets':
        return 'Android Widgets';
      case 'tips':
        return 'Usage Tips';
      case 'faqs':
        return 'FAQs';
      case 'support':
        return 'Support';
      default:
        return 'Settings';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: _content(context),
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    switch (widget.section) {
      case 'appearance':
        return [
          const Card(
            child: ListTile(
              leading: Icon(Icons.nights_stay_outlined),
              title: Text('Dark navy'),
              subtitle: Text('Active theme'),
              trailing: Icon(Icons.check_circle, color: AppTheme.success),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Habit Tracker uses a dark navy interface optimized for '
                'clear reading and low-light use on Android.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ),
        ];
      case 'page':
        return [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Hide completed habits'),
                  subtitle: const Text(
                    'Keep completed items available from the habit list',
                  ),
                  value: _hideCompleted,
                  onChanged: (value) => _save(_hideCompletedKey, value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Compact habit cards'),
                  subtitle: const Text('Reduce spacing in the Today list'),
                  value: _compactCards,
                  onChanged: (value) => _save(_compactKey, value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Haptic feedback'),
                  subtitle: const Text('Vibrate when a habit is completed'),
                  value: _haptics,
                  onChanged: (value) => _save(_hapticsKey, value),
                ),
              ],
            ),
          ),
        ];
      case 'notifications':
        return [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Habit reminders'),
                  subtitle: const Text(
                    'Use reminder times saved with individual habits',
                  ),
                  value: _habitReminders,
                  onChanged: (value) => _save(_habitRemindersKey, value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Completion feedback'),
                  subtitle: const Text(
                    'Show XP and coin feedback after check-in',
                  ),
                  value: _completionFeedback,
                  onChanged: (value) => _save(_completionFeedbackKey, value),
                ),
              ],
            ),
          ),
        ];
      case 'widgets':
        return const [
          Card(
            child: ListTile(
              leading: Icon(Icons.widgets_outlined),
              title: Text('Android home widgets'),
              subtitle: Text(
                'Widget support is not included in this build. '
                'Use the floating Add Quest button or open the app for check-ins.',
              ),
              isThreeLine: true,
            ),
          ),
        ];
      case 'tips':
        return const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build a consistent routine',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Use short habit names, choose a clear time range, and '
                    'complete one check-in per day. Tap a habit card to edit it.',
                  ),
                ],
              ),
            ),
          ),
        ];
      case 'faqs':
        return const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where is my data stored?',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Habits, logs, and profile settings are stored locally on '
                    'this device.',
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Can completed habits be changed?',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Open the habit card to edit its name or schedule. '
                    'Completion history remains in Stats.',
                  ),
                ],
              ),
            ),
          ),
        ];
      case 'support':
        return [
          const Card(
            child: ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('App help'),
              subtitle: Text(
                'Restart from Settings if a preference does not appear.',
              ),
              isThreeLine: true,
            ),
          ),
        ];
      default:
        return const [
          Card(
            child: ListTile(
              title: Text('Setting not found'),
              subtitle: Text('Choose an option from Settings.'),
            ),
          ),
        ];
    }
  }

  Future<void> _save(String key, bool value) async {
    await ref.read(sharedPreferencesProvider).setBool(key, value);
    if (mounted) setState(() {});
  }
}

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appProvider).profile;
    final controller = ref.read(appProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Shop',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Chip(
              avatar: const Icon(Icons.monetization_on, size: 18),
              label: Text('${profile.coins}'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Spend coins to customize your quest profile and protect streaks.',
        ),
        const SizedBox(height: 20),
        ...shopItems.where((item) => item.price > 0).map((item) {
          final owned = profile.ownedItems.contains(item.id);
          final equipped =
              profile.avatarKey == item.id || profile.borderKey == item.id;
          final count = item.type == ShopItemType.streakSaver
              ? profile.streakSavers
              : null;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: _ShopItemIcon(item: item),
              title: Text(item.name),
              subtitle: Text(
                '${item.description}${count != null ? '\nOwned: $count' : ''}',
              ),
              isThreeLine: count != null,
              trailing: owned
                  ? OutlinedButton(
                      onPressed: equipped
                          ? null
                          : () => controller.equipItem(item),
                      child: Text(equipped ? 'Equipped' : 'Equip'),
                    )
                  : FilledButton(
                      onPressed: profile.coins < item.price
                          ? null
                          : () async {
                              final bought = await controller.purchaseItem(
                                item,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      bought
                                          ? 'Purchased ${item.name}!'
                                          : 'Purchase unavailable.',
                                    ),
                                  ),
                                );
                              }
                            },
                      child: Text('${item.price}'),
                    ),
            ),
          );
        }),
      ],
    );
  }
}

class _ShopItemIcon extends StatelessWidget {
  const _ShopItemIcon({required this.item});
  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    if (item.type == ShopItemType.streakSaver) {
      return const CircleAvatar(child: Icon(Icons.shield));
    }
    return CircleAvatar(
      backgroundColor: item.colorValue == null
          ? AppTheme.surfaceLight
          : Color(item.colorValue!),
      child: Icon(iconForCodePoint(item.iconCodePoint)),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent),
          const SizedBox(width: 14),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}

String _shortWeekday(int value) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][value - 1];

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _sameDate(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _monthDay(DateTime date) => '${_month(date.month)} ${date.day}';
String _month(int value) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][value - 1];

String _iconLabel(IconData icon) {
  if (icon == Icons.directions_run) return 'movement';
  if (icon == Icons.menu_book) return 'reading';
  if (icon == Icons.water_drop) return 'water';
  if (icon == Icons.self_improvement) return 'mindfulness';
  if (icon == Icons.fitness_center) return 'fitness';
  if (icon == Icons.check_circle_outline) return 'completion';
  if (icon == Icons.cleaning_services_outlined) return 'cleaning';
  if (icon == Icons.restaurant_outlined) return 'nutrition';
  if (icon == Icons.bedtime_outlined) return 'sleep';
  if (icon == Icons.code) return 'coding';
  if (icon == Icons.music_note) return 'music';
  if (icon == Icons.spa_outlined) return 'wellness';
  if (icon == Icons.work_outline) return 'work';
  if (icon == Icons.savings_outlined) return 'savings';
  return 'cycling';
}

String _colorLabel(Color color) {
  if (color == const Color(0xFF42D9FF)) return 'cyan';
  if (color == const Color(0xFF64E8A5)) return 'lime';
  if (color == const Color(0xFFF2B84B)) return 'amber';
  if (color == const Color(0xFFFF79B0)) return 'pink';
  return 'violet';
}

extension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}


//jacky kkontol