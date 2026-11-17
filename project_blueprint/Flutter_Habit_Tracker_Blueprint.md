Gamified Habit Tracker Blueprint

# 1\. What You Need for a Gamified Habit Tracker

## Core features (MVP)

-   **Habit CRUD:** create, edit, delete habits (name, icon, color, frequency).
-   **Daily check-in:** tap to complete a habit for today.
-   **Streak tracking:** consecutive days completed, with a "longest streak" record.
-   **Local persistence:** data survives app restarts.

## Gamification layer

-   **XP and levels:** each completion gives XP; XP thresholds unlock levels.
-   **Streak multipliers:** longer streaks give bonus XP.
-   **Achievements/badges:** "First habit", "7-day streak", "30 completions", etc.
-   **Virtual rewards:** coins to spend on avatar items or themes.
-   **Avatar or pet:** a character that grows or stays healthy as you stay consistent.
-   **Daily/weekly challenges:** "Complete 5 habits today" for bonus XP.
-   **Penalties (optional):** a pet losing health when you miss days. Use gently to avoid discouraging users.

## Screens

1.  Home / today's habits
2.  Add/edit habit
3.  Stats and calendar heatmap
4.  Profile (level, XP bar, badges)
5.  Achievements gallery
6.  Shop/rewards (optional)
7.  Settings (theme, notifications)

## Flutter skills and packages

| **Area** | **What to use** |
| --- | --- |
| State management | Provider or Riverpod (start with Provider) |
| Local storage | Hive, Isar, or sqflite |
| Notifications | flutter_local_notifications |
| Charts | fl_chart |
| Calendar/heatmap | table_calendar, flutter_heatmap_calendar |
| Animations | Lottie, confetti, or Flutter built-in animations |
| Navigation | go_router |
| Dates | intl |

## Data model (simple version)

-   **Habit:** id, title, icon, color, frequency, createdAt
-   **HabitLog:** habitId, date, completed
-   **UserProfile:** xp, level, coins
-   **Achievement:** id, title, condition, unlockedAt

## Suggested build order

1.  Habit list UI with hardcoded data
2.  Add/delete habits with Provider
3.  Save data locally
4.  Check-in and streak logic
5.  XP and level system
6.  Achievements and animations
7.  Stats screen and charts
8.  Notifications
9.  Polish: themes, sounds, haptics

## Stretch goals

-   Firebase auth and cloud sync
-   Friends and leaderboards
-   Home screen widgets
-   Dark mode and custom themes

# Tip

The hardest part is streak logic (time zones, missed days, editing past days). Build it early and write a few unit tests for it. That alone will teach you a lot.