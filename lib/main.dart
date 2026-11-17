import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
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
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const HabitTrackerApp(),
    ),
  );
}

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
    title: 'Habit Quest',
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
    final selected = location == '/stats'
        ? 1
        : location == '/profile'
        ? 2
        : location == '/shop'
        ? 3
        : 0;
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0.03, 0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: KeyedSubtree(key: ValueKey(location), child: child),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) {
          context.go(
            index == 0
                ? '/'
                : index == 1
                ? '/stats'
                : index == 2
                ? '/profile'
                : '/shop',
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Shop',
          ),
        ],
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
    final completed = state.habits.where((habit) {
      return habit.frequency == HabitFrequency.weekly
          ? controller.weeklyCompletions(habit.id) >= habit.weeklyTarget
          : controller.isCompletedToday(habit.id);
    }).length;
    final date = DateTime.now();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${state.profile.name}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${_weekday(date.weekday)}, ${date.day} ${_month(date.month)}',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            ProfileAvatar(profile: state.profile, size: 44),
          ],
        ),
        const SizedBox(height: 28),
        _SectionTitle(
          title: 'Daily progress',
          action: '$completed / ${state.habits.length} completed',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Level ${state.profile.level}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${state.profile.currentLevelXp}/'
                      '${state.profile.xpForNextLevel} XP',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${state.profile.xp} XP  •  ${state.profile.coins} coins',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end:
                              state.profile.currentLevelXp /
                              state.profile.xpForNextLevel,
                        ),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) =>
                            LinearProgressIndicator(
                              value: value,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(8),
                            ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${state.profile.currentLevelXp}/${state.profile.xpForNextLevel}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.35),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _xpPopup == null
                      ? const SizedBox(height: 0, key: ValueKey('empty-xp'))
                      : Padding(
                          key: ValueKey(_xpPopup),
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _xpPopup!,
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        _SectionTitle(
          title: "Today's habits",
          action: completed == state.habits.length && state.habits.isNotEmpty
              ? 'Quest complete'
              : null,
          trailing: Semantics(
            button: true,
            label: 'Create a new habit',
            child: IconButton(
              tooltip: 'Create a new habit',
              onPressed: () => context.push('/habit/new'),
              icon: const Icon(
                Icons.add_circle,
                color: AppTheme.accent,
                size: 30,
              ),
            ),
          ),
        ),
        if (state.habits.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 42,
                    color: AppTheme.accent,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Start your quest',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text('Create your first habit and earn XP every day.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.push('/habit/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add habit'),
                  ),
                ],
              ),
            ),
          )
        else
          ...state.habits.map(
            (habit) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  onTap: () => context.push('/habit/${habit.id}'),
                  leading: CircleAvatar(
                    backgroundColor: Color(habit.colorValue)
                        .withValues(alpha: 0.2),
                    child: Icon(
                      IconData(
                        habit.iconCodePoint,
                        fontFamily: 'MaterialIcons',
                      ),
                      color: Color(habit.colorValue),
                    ),
                  ),
                  title: Text(
                    habit.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    habit.frequency == HabitFrequency.weekly
                        ? '${habit.goal}  •  ${controller.weeklyCompletions(habit.id)}/${habit.weeklyTarget} this week'
                        : '${habit.goal}  •  ${habit.difficulty.name.capitalize()}  •  '
                              '${controller.completionsFor(habit.id)} completions',
                  ),
                  trailing: !controller.canCompleteToday(habit.id)
                      ? Semantics(
                          label: habit.frequency == HabitFrequency.weekly
                              ? 'Weekly target reached'
                              : 'Completed today',
                          child: Icon(
                            Icons.check_circle,
                            color: AppTheme.success,
                            size: 30,
                          ),
                        )
                      : FilledButton(
                          onPressed: () async {
                            final previousXp = ref.read(appProvider).profile.xp;
                            final earned = await controller.completeToday(
                              habit.id,
                            );
                            if (context.mounted && earned) {
                              final gainedXp =
                                  ref.read(appProvider).profile.xp - previousXp;
                              _showXpPopup(gainedXp);
                            }
                          },
                          child: const Text('Complete'),
                        ),
                ),
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

class HabitFormScreen extends ConsumerStatefulWidget {
  const HabitFormScreen({this.habitId, super.key});
  final String? habitId;

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _goalController;
  late HabitFrequency _frequency;
  late HabitDifficulty _difficulty;
  late int _color;
  late int _icon;
  late int _weeklyTarget;
  bool _saving = false;
  bool _deleting = false;

  final _colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.purple,
  ];
  final _icons = [
    Icons.directions_run,
    Icons.menu_book,
    Icons.water_drop,
    Icons.self_improvement,
    Icons.fitness_center,
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
    _goalController = TextEditingController(text: habit?.goal ?? 'Daily');
    _frequency = habit?.frequency ?? HabitFrequency.daily;
    _difficulty = habit?.difficulty ?? HabitDifficulty.easy;
    _weeklyTarget = habit?.weeklyTarget ?? 1;
    _color = habit?.colorValue ?? Colors.blue.toARGB32();
    _icon = habit?.iconCodePoint ?? Icons.directions_run.codePoint;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.habitId != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit habit' : 'New habit')),
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
              const SizedBox(height: 20),
              const Text(
                'Choose a marker',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _icons
                    .map(
                      (icon) => Semantics(
                        label: 'Habit icon ${_iconLabel(icon)}',
                        selected: _icon == icon.codePoint,
                        child: ChoiceChip(
                          selected: _icon == icon.codePoint,
                          label: Icon(icon),
                          onSelected: (_) =>
                              setState(() => _icon = icon.codePoint),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose a color',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _colors
                    .map(
                      (color) => Semantics(
                        label: 'Habit color ${_colorLabel(color)}',
                        selected: _color == color.toARGB32(),
                        child: ChoiceChip(
                          selected: _color == color.toARGB32(),
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
              const SizedBox(height: 20),
              DropdownButtonFormField<HabitFrequency>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: HabitFrequency.values
                    .map(
                      (frequency) => DropdownMenuItem(
                        value: frequency,
                        child: Text(frequency.name.capitalize()),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _frequency = value ?? HabitFrequency.daily),
              ),
              if (_frequency == HabitFrequency.weekly) ...[
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  initialValue: _weeklyTarget,
                  decoration: const InputDecoration(
                    labelText: 'Weekly target',
                    helperText:
                        'How many times should you complete this each week?',
                  ),
                  items: [1, 2, 3]
                      .map(
                        (target) => DropdownMenuItem(
                          value: target,
                          child: Text(
                            '$target ${target == 1 ? 'time' : 'times'}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _weeklyTarget = value ?? 1),
                ),
              ],
              const SizedBox(height: 20),
              DropdownButtonFormField<HabitDifficulty>(
                initialValue: _difficulty,
                decoration: const InputDecoration(labelText: 'Difficulty'),
                items: HabitDifficulty.values
                    .map(
                      (difficulty) => DropdownMenuItem(
                        value: difficulty,
                        child: Text(difficulty.name.capitalize()),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _difficulty = value ?? HabitDifficulty.easy),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('habit-goal-field'),
                controller: _goalController,
                decoration: const InputDecoration(
                  labelText: 'Goal',
                  hintText: '30 minutes',
                  prefixIcon: Icon(Icons.track_changes),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a goal'
                    : null,
              ),
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
              if (editing) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _saving || _deleting ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  child: Text(_deleting ? 'Deleting...' : 'Delete habit'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
      difficulty: _difficulty,
      goal: _goalController.text.trim(),
      createdAt: existing?.createdAt ?? DateTime.now(),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: const Text(
          'This will remove the habit and its completion history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
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
          'Habit breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...state.habits.map(
          (habit) => Card(
            child: ListTile(
              leading: Icon(
                IconData(habit.iconCodePoint, fontFamily: 'MaterialIcons'),
                color: Color(habit.colorValue),
              ),
              title: Text(habit.title),
              subtitle: Text(
                habit.frequency == HabitFrequency.weekly
                    ? '${controller.weeklyCompletions(habit.id)}/${habit.weeklyTarget} this week'
                    : '${habit.difficulty.name.capitalize()}  •  '
                          '${controller.completionsFor(habit.id)} completions',
              ),
              trailing: Text(
                '${habit.frequency == HabitFrequency.weekly ? GamificationService.weeklyStreakFor(habit.id, state.logs, today, target: habit.weeklyTarget) : GamificationService.streakFor(habit.id, state.logs, today)} '
                '${habit.frequency == HabitFrequency.weekly ? 'week' : 'day'} streak',
              ),
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Profile',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Center(child: ProfileAvatar(profile: state.profile, size: 88)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            state.profile.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.push('/profile/edit'),
              icon: const Icon(Icons.edit),
              label: const Text('Edit profile'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => context.go('/shop'),
              icon: const Icon(Icons.storefront),
              label: const Text('Shop'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Settings'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Level progress',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value:
                      state.profile.currentLevelXp /
                      state.profile.xpForNextLevel,
                  minHeight: 10,
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.profile.currentLevelXp} / '
                  '${state.profile.xpForNextLevel} XP to next level',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _MetricCard(
          label: 'Coins',
          value: '${state.profile.coins}',
          icon: Icons.monetization_on,
        ),
        const SizedBox(height: 12),
        _MetricCard(
          label: 'Longest streak',
          value: '${state.profile.longestStreak} days',
          icon: Icons.local_fire_department,
        ),
      ],
    );
  }
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
    final border = profile.borderKey == 'border_gold'
        ? Colors.amber
        : profile.borderKey == 'border_blue'
        ? AppTheme.accent
        : AppTheme.surfaceLight;
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
              IconData(
                shopItemById(profile.avatarKey).iconCodePoint ??
                    Icons.person.codePoint,
                fontFamily: 'MaterialIcons',
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
  late String _avatarKey;
  late String _borderKey;
  String? _imageBase64;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(appProvider).profile;
    _nameController = TextEditingController(text: profile.name);
    _avatarKey = profile.avatarKey;
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
    final avatars = shopItems.where((item) => item.type == ShopItemType.avatar);
    final borders = shopItems.where((item) => item.type == ShopItemType.border);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ProfileAvatar(
                profile: ref
                    .watch(appProvider)
                    .profile
                    .copyWith(
                      avatarKey: _avatarKey,
                      borderKey: _borderKey,
                      profileImageBase64: _imageBase64 ?? '',
                    ),
                size: 92,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose image from device'),
            ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Display name'),
              maxLength: 24,
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Use at least 2 characters'
                  : null,
            ),
            const SizedBox(height: 16),
            const Text('Avatar', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: avatars
                  .map(
                    (item) => ChoiceChip(
                      selected: _avatarKey == item.id && _imageBase64 == null,
                      label: Icon(
                        IconData(
                          item.iconCodePoint!,
                          fontFamily: 'MaterialIcons',
                        ),
                      ),
                      onSelected: (_) => setState(() {
                        _avatarKey = item.id;
                        _imageBase64 = null;
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Profile border',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  selected: _borderKey == 'none',
                  label: const Text('None'),
                  onSelected: (_) => setState(() => _borderKey = 'none'),
                ),
                ...borders.map(
                  (item) => ChoiceChip(
                    selected: _borderKey == item.id,
                    label: Text(item.name),
                    onSelected: (_) => setState(() => _borderKey = item.id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save profile'),
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
            avatarKey: _avatarKey,
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
    final profile = ref.watch(appProvider).profile;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profile'),
                subtitle: Text(profile.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile/edit'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('Shop'),
                subtitle: const Text('Customize your profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/shop'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Habit Quest'),
            subtitle: const Text(
              'Build small habits and keep your streak alive.',
            ),
          ),
        ),
      ],
    );
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
      child: Icon(
        item.iconCodePoint == null
            ? Icons.person
            : IconData(item.iconCodePoint!, fontFamily: 'MaterialIcons'),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.action,
    this.trailing,
  });
  final String title;
  final String? action;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      if (action != null) Text(action!),
      if (trailing != null) trailing!,
    ],
  );
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

String _weekday(int value) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][value - 1];

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
  return 'fitness';
}

String _colorLabel(Color color) {
  if (color == Colors.blue) return 'blue';
  if (color == Colors.green) return 'green';
  if (color == Colors.orange) return 'orange';
  if (color == Colors.pink) return 'pink';
  return 'purple';
}

extension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
