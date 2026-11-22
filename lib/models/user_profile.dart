class UserProfile {
  const UserProfile({
    this.name = 'User1',
    this.xp = 0,
    this.coins = 60,
    this.longestStreak = 0,
    this.avatarKey = 'person',
    this.profileImageBase64,
    this.borderKey = 'none',
    this.ownedItems = const ['avatar_person'],
    this.streakSavers = 0,
    this.shopRewardNotificationShown = false,
  });

  final String name;
  final int xp;
  final int coins;
  final int longestStreak;
  final String avatarKey;
  final String? profileImageBase64;
  final String borderKey;
  final List<String> ownedItems;
  final int streakSavers;
  final bool shopRewardNotificationShown;

  int get level {
    var remainingXp = xp;
    var currentLevel = 1;
    while (remainingXp >= _xpRequiredForLevel(currentLevel)) {
      remainingXp -= _xpRequiredForLevel(currentLevel);
      currentLevel++;
    }
    return currentLevel;
  }

  int get currentLevelXp {
    var remainingXp = xp;
    var currentLevel = 1;
    while (remainingXp >= _xpRequiredForLevel(currentLevel)) {
      remainingXp -= _xpRequiredForLevel(currentLevel);
      currentLevel++;
    }
    return remainingXp;
  }

  int get xpForNextLevel => _xpRequiredForLevel(level);

  int _xpRequiredForLevel(int level) {
    var requiredXp = 100;
    for (var currentLevel = 1; currentLevel < level; currentLevel++) {
      requiredXp = (requiredXp * 1.5).round();
    }
    return requiredXp;
  }

  UserProfile copyWith({
    String? name,
    int? xp,
    int? coins,
    int? longestStreak,
    String? avatarKey,
    String? profileImageBase64,
    String? borderKey,
    List<String>? ownedItems,
    int? streakSavers,
    bool? shopRewardNotificationShown,
  }) => UserProfile(
    name: name ?? this.name,
    xp: xp ?? this.xp,
    coins: coins ?? this.coins,
    longestStreak: longestStreak ?? this.longestStreak,
    avatarKey: avatarKey ?? this.avatarKey,
    profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
    borderKey: borderKey ?? this.borderKey,
    ownedItems: ownedItems ?? this.ownedItems,
    streakSavers: streakSavers ?? this.streakSavers,
    shopRewardNotificationShown:
        shopRewardNotificationShown ?? this.shopRewardNotificationShown,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'xp': xp,
    'coins': coins,
    'longestStreak': longestStreak,
    'avatarKey': avatarKey,
    'profileImageBase64': profileImageBase64,
    'borderKey': borderKey,
    'ownedItems': ownedItems,
    'streakSavers': streakSavers,
    'shopRewardNotificationShown': shopRewardNotificationShown,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? 'User1',
    xp: json['xp'] as int? ?? 0,
    coins: json['coins'] as int? ?? 60,
    longestStreak: json['longestStreak'] as int? ?? 0,
    avatarKey: json['avatarKey'] as String? ?? 'person',
    profileImageBase64: json['profileImageBase64'] as String?,
    borderKey: json['borderKey'] as String? ?? 'none',
    ownedItems:
        (json['ownedItems'] as List<dynamic>?)?.cast<String>() ??
        const ['avatar_person'],
    streakSavers: json['streakSavers'] as int? ?? 0,
    shopRewardNotificationShown:
        json['shopRewardNotificationShown'] as bool? ?? false,
  );
}
