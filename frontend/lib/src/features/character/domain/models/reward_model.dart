class RewardModel {
  final String id;
  final String rewardType; // BACKGROUND | EFFECT | MOTION | ACCESSORY
  final String name;
  final String description;
  final String assetUrl;
  final bool acquired;
  final DateTime? achievedAt;

  const RewardModel({
    required this.id,
    required this.rewardType,
    required this.name,
    required this.description,
    required this.assetUrl,
    required this.acquired,
    this.achievedAt,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] as String? ?? '',
      rewardType: json['reward_type'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      assetUrl: json['asset_url'] as String? ?? '',
      acquired: json['acquired'] as bool? ?? false,
      achievedAt: json['achieved_at'] != null
          ? DateTime.tryParse(json['achieved_at'] as String)
          : null,
    );
  }

  String get typeLabel {
    switch (rewardType) {
      case 'BACKGROUND':
        return '배경';
      case 'EFFECT':
        return '이펙트';
      case 'MOTION':
        return '모션';
      case 'ACCESSORY':
        return '악세서리';
      default:
        return rewardType;
    }
  }
}
