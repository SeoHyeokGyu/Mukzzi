import '../../../../core/widgets/mukzzi_character.dart';
import '../../domain/models/reward_model.dart';

class CharacterModel {
  final String id;
  final String userId;
  final String name;
  final CharacterState state;
  final int streakDays;
  final int bodyType;
  final int muscle;
  final int skinTone;
  final int expression;
  final int nutritionAchievementDays;
  final RewardModel? equippedBackground;
  final RewardModel? equippedAccessory;

  const CharacterModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.state,
    required this.streakDays,
    required this.bodyType,
    required this.muscle,
    required this.skinTone,
    required this.expression,
    required this.nutritionAchievementDays,
    this.equippedBackground,
    this.equippedAccessory,
  });

  CharacterModel copyWith({
    String? id,
    String? userId,
    String? name,
    CharacterState? state,
    int? streakDays,
    int? bodyType,
    int? muscle,
    int? skinTone,
    int? expression,
    int? nutritionAchievementDays,
    RewardModel? equippedBackground,
    RewardModel? equippedAccessory,
  }) {
    return CharacterModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      state: state ?? this.state,
      streakDays: streakDays ?? this.streakDays,
      bodyType: bodyType ?? this.bodyType,
      muscle: muscle ?? this.muscle,
      skinTone: skinTone ?? this.skinTone,
      expression: expression ?? this.expression,
      nutritionAchievementDays:
          nutritionAchievementDays ?? this.nutritionAchievementDays,
      equippedBackground: equippedBackground ?? this.equippedBackground,
      equippedAccessory: equippedAccessory ?? this.equippedAccessory,
    );
  }

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    CharacterState status = CharacterState.normal;
    final penalty = json['penalty_status'] as String? ?? 'NORMAL';
    if (penalty == 'HUNGRY') status = CharacterState.hungry;
    if (penalty == 'STARVING') status = CharacterState.starving;
    if (penalty == 'WEAKENED') status = CharacterState.sleeping;

    return CharacterModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      name: json['name'] as String? ?? '먹찌',
      state: status,
      streakDays: json['streak_days'] as int? ?? 0,
      bodyType: json['body_type'] as int? ?? 0,
      muscle: json['muscle'] as int? ?? 0,
      skinTone: json['skin_tone'] as int? ?? 0,
      expression: json['expression'] as int? ?? 0,
      nutritionAchievementDays: json['nutrition_achievement_days'] as int? ?? 0,
      equippedBackground: json['equipped_background'] != null
          ? RewardModel.fromJson(
              json['equipped_background'] as Map<String, dynamic>)
          : null,
      equippedAccessory: json['equipped_accessory'] != null
          ? RewardModel.fromJson(
              json['equipped_accessory'] as Map<String, dynamic>)
          : null,
    );
  }
}
