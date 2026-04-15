class TitleModel {
  final String id;
  final String code;
  final String name;
  final String description;
  final bool acquired;
  final DateTime? achievedAt;
  final bool isEquipped;

  const TitleModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.acquired,
    this.achievedAt,
    required this.isEquipped,
  });

  factory TitleModel.fromJson(Map<String, dynamic> json) {
    return TitleModel(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      acquired: json['acquired'] as bool? ?? false,
      achievedAt: json['achieved_at'] != null
          ? DateTime.tryParse(json['achieved_at'] as String)
          : null,
      isEquipped: json['is_equipped'] as bool? ?? false,
    );
  }
}
