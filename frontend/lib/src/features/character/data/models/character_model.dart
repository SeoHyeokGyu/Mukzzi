import '../../../../core/widgets/mukzzi_character.dart';

class CharacterModel {
  final String id;
  final String userId;
  final String name;
  final int level;
  final int exp;
  final CharacterState state;
  final String evolutionStage;
  final int streakDays;
  final int bodyType;
  final int muscle;
  final int skinTone;
  final int expression;

  CharacterModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.level,
    required this.exp,
    required this.state,
    required this.evolutionStage,
    required this.streakDays,
    required this.bodyType,
    required this.muscle,
    required this.skinTone,
    required this.expression,
  });

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
      level: json['level'] as int? ?? 1,
      exp: json['exp'] as int? ?? 0,
      state: status,
      evolutionStage: json['evolution_stage'] as String? ?? 'EGG',
      streakDays: json['streak_days'] as int? ?? 0,
      bodyType: json['body_type'] as int? ?? 0,
      muscle: json['muscle'] as int? ?? 0,
      skinTone: json['skin_tone'] as int? ?? 0,
      expression: json['expression'] as int? ?? 0,
    );
  }

  String get evolutionLabel {
    switch (evolutionStage) {
      case 'EGG':       return '부화 단계';
      case 'BABY':      return '아기 단계';
      case 'TEEN':      return '청소년 단계';
      case 'ADULT':     return '성체 단계';
      case 'LEGENDARY': return '전설 단계';
      default:          return '부화 단계';
    }
  }
}
