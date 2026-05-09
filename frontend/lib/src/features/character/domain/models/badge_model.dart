import 'package:flutter/material.dart';

class BadgeModel {
  final String id;
  final String code;
  final String name;
  final String description;
  final String category; // 'meal' | 'attendance' | 'social'
  final IconData iconData;
  final int progress;
  final int target;
  final bool isUnlocked;
  final String? unlockedAt; // ISO 8601

  const BadgeModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.category,
    required this.iconData,
    required this.progress,
    required this.target,
    required this.isUnlocked,
    this.unlockedAt,
  });

  // 백엔드에 condition 필드 추가 전까지 description을 달성 조건으로 사용
  String get condition => description;

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    final code = json['code'] as String? ?? '';
    return BadgeModel(
      id: json['id'] as String? ?? '',
      code: code,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: _categoryFromCode(code),
      iconData: _iconFromCode(code),
      progress: json['progress'] as int? ?? 0,
      target: json['target'] as int? ?? 0,
      isUnlocked: json['acquired'] as bool? ?? false,
      unlockedAt: json['acquired_at'] as String?,
    );
  }

  static String _categoryFromCode(String code) {
    const attendanceCodes = {'STREAK_7', 'STREAK_30'};
    const socialCodes = {'FIRST_LOGIN', 'SHARE_10', 'SOC_001', 'SOC_002', 'SOC_003', 'SOC_004'};

    if (attendanceCodes.contains(code)) return 'attendance';
    if (socialCodes.contains(code)) return 'social';
    return 'meal';
  }

  static IconData _iconFromCode(String code) {
    switch (code) {
      case 'FIRST_MEAL':
        return Icons.restaurant;
      case 'THREE_MEALS_A_DAY':
        return Icons.dining;
      case 'STREAK_7':
        return Icons.event_available;
      case 'STREAK_30':
        return Icons.calendar_month;
      case 'MENU_EXPLORER':
        return Icons.explore;
      case 'BALANCE_MASTER':
        return Icons.balance;
      case 'COLLECTION_50':
        return Icons.collections_bookmark;
      case 'COLLECTION_ALL':
        return Icons.emoji_events;
      default:
        return Icons.military_tech;
    }
  }
}
