enum QuestType { daily, weekly, achievement }

enum QuestStatus { progress, completed, claimed }

class Quest {
  final String id;
  final String code;
  final QuestType type;
  final String category;
  final String title;
  final String description;
  final int targetCount;
  final int currentCount;
  final QuestStatus status;
  final int rewardPoint;
  final int rewardExp;
  final String? rewardTitleId;
  final String? rewardBadgeId;
  final String? rewardItemId;
  final DateTime assignedAt;
  final DateTime expiresAt;

  const Quest({
    required this.id,
    required this.code,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    required this.targetCount,
    required this.currentCount,
    required this.status,
    required this.rewardPoint,
    required this.rewardExp,
    this.rewardTitleId,
    this.rewardBadgeId,
    this.rewardItemId,
    required this.assignedAt,
    required this.expiresAt,
  });

  bool get isCompleted => status == QuestStatus.completed || status == QuestStatus.claimed;
  bool get isClaimed => status == QuestStatus.claimed;
  double get progress => (currentCount / targetCount).clamp(0.0, 1.0);
}

class QuestProgressInfo {
  final String questType;
  final String questTitle;
  final int progress;
  final int target;
  final bool completed;

  const QuestProgressInfo({
    required this.questType,
    required this.questTitle,
    required this.progress,
    required this.target,
    required this.completed,
  });
}
