import 'package:mukzzi/src/features/quest/domain/entities/quest.dart';

class QuestModel extends Quest {
  const QuestModel({
    required super.id,
    required super.code,
    required super.type,
    required super.category,
    required super.title,
    required super.description,
    required super.targetCount,
    required super.currentCount,
    required super.status,
    required super.rewardPoint,
    required super.rewardExp,
    super.rewardTitleId,
    super.rewardBadgeId,
    super.rewardItemId,
    required super.assignedAt,
    required super.expiresAt,
  });

  factory QuestModel.fromJson(Map<String, dynamic> json) {
    // 백엔드의 UserQuestResponse DTO 구조를 따름
    final definition = json['Quest'] as Map<String, dynamic>?;
    
    // ID는 백엔드에서 string으로 넘어옴
    return QuestModel(
      id: json['id'] as String,
      code: definition?['code'] as String? ?? '',
      type: _parseQuestType(definition?['type'] as String? ?? 'DAILY'),
      category: definition?['category'] as String? ?? '',
      title: definition?['title'] as String? ?? '',
      description: definition?['description'] as String? ?? '',
      targetCount: definition?['target_count'] as int? ?? 0,
      currentCount: json['current_count'] as int? ?? 0,
      status: _parseQuestStatus(json['status'] as String? ?? 'PROGRESS'),
      rewardPoint: definition?['reward_point'] as int? ?? 0,
      rewardExp: definition?['reward_exp'] as int? ?? 0,
      rewardTitleId: definition?['reward_title_id']?.toString(),
      rewardBadgeId: definition?['reward_badge_id']?.toString(),
      rewardItemId: definition?['reward_item_id']?.toString(),
      assignedAt: DateTime.parse(json['assigned_at'] as String).toLocal(),
      expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
    );
  }

  static QuestType _parseQuestType(String type) {
    switch (type.toUpperCase()) {
      case 'DAILY':
        return QuestType.daily;
      case 'WEEKLY':
        return QuestType.weekly;
      case 'ACHIEVEMENT':
        return QuestType.achievement;
      default:
        return QuestType.daily;
    }
  }

  static QuestStatus _parseQuestStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PROGRESS':
        return QuestStatus.progress;
      case 'COMPLETED':
        return QuestStatus.completed;
      case 'CLAIMED':
        return QuestStatus.claimed;
      default:
        return QuestStatus.progress;
    }
  }
}

class QuestProgressInfoModel extends QuestProgressInfo {
  const QuestProgressInfoModel({
    required super.questType,
    required super.progress,
    required super.target,
    required super.completed,
  });

  factory QuestProgressInfoModel.fromJson(Map<String, dynamic> json) {
    return QuestProgressInfoModel(
      questType: json['quest_type'] as String? ?? '',
      progress: json['progress'] as int? ?? 0,
      target: json['target'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }
}
