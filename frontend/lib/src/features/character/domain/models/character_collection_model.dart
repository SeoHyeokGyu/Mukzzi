class CharacterCollectionModel {
  final String id;
  final int bodyType;
  final int muscle;
  final int skinTone;
  final int expression;
  final DateTime achievedAt;

  const CharacterCollectionModel({
    required this.id,
    required this.bodyType,
    required this.muscle,
    required this.skinTone,
    required this.expression,
    required this.achievedAt,
  });

  factory CharacterCollectionModel.fromJson(Map<String, dynamic> json) {
    return CharacterCollectionModel(
      id: json['id'] as String? ?? '',
      bodyType: json['body_type'] as int? ?? 3,
      muscle: json['muscle'] as int? ?? 3,
      skinTone: json['skin_tone'] as int? ?? 3,
      expression: json['expression'] as int? ?? 3,
      achievedAt: DateTime.parse(json['achieved_at'] as String),
    );
  }

  String get label => '$bodyType-$muscle-$skinTone-$expression';
}
