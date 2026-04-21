class UserStatsModel {
  final int totalMeals;
  final int streakDays;
  final int badgeCount;

  const UserStatsModel({
    required this.totalMeals,
    required this.streakDays,
    required this.badgeCount,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      totalMeals: (json['total_meals'] as num?)?.toInt() ?? 0,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      badgeCount: (json['badge_count'] as num?)?.toInt() ?? 0,
    );
  }

  static const empty = UserStatsModel(totalMeals: 0, streakDays: 0, badgeCount: 0);
}
