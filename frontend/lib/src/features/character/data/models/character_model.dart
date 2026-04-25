import '../../../../core/widgets/mukzzi_character.dart';

class CharacterModel {
  final String id;
  final String userId;
  final String name;
  final int level;
  final int exp;
  final CharacterState state;
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
    required this.bodyType,
    required this.muscle,
    required this.skinTone,
    required this.expression,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    // 백엔드 EvolutionStage, PenaltyStatus 등을 CharacterState 로 매핑하는 로직 필요
    // 일단 간단히 매핑
    CharacterState status = CharacterState.normal;
    final penalty = json['penalty_status'] as String? ?? 'NORMAL';
    if (penalty == 'HUNGRY') status = CharacterState.hungry;
    if (penalty == 'STARVING') status = CharacterState.starving;

    return CharacterModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      name: json['name'] as String? ?? '먹찌',
      level: json['level'] as int? ?? 1,
      exp: json['exp'] as int? ?? 0,
      state: status,
      bodyType: json['body_type'] as int? ?? 0,
      muscle: json['muscle'] as int? ?? 0,
      skinTone: json['skin_tone'] as int? ?? 0,
      expression: json['expression'] as int? ?? 0,
    );
  }
}
