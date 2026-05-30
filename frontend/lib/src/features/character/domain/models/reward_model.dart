enum EquipmentSlot {
  background('BACKGROUND'),
  back('BACK'),
  body('BODY'),
  hand('HAND'),
  face('FACE'),
  head('HEAD'),
  aura('AURA');

  const EquipmentSlot(this.value);

  final String value;

  static EquipmentSlot? fromJson(String? value) {
    if (value == null) return null;
    for (final slot in EquipmentSlot.values) {
      if (slot.value == value) return slot;
    }
    return null;
  }
}

class RewardRenderConfig {
  final EquipmentSlot slot;
  final double offsetX;
  final double offsetY;
  final double scale;
  final double rotation;
  final int zIndex;

  const RewardRenderConfig({
    required this.slot,
    required this.offsetX,
    required this.offsetY,
    required this.scale,
    required this.rotation,
    required this.zIndex,
  });

  factory RewardRenderConfig.fromJson(Map<String, dynamic> json) {
    return RewardRenderConfig(
      slot:
          EquipmentSlot.fromJson(json['slot'] as String?) ?? EquipmentSlot.head,
      offsetX: (json['offset_x'] as num?)?.toDouble() ?? 0,
      offsetY: (json['offset_y'] as num?)?.toDouble() ?? 0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      zIndex: (json['z_index'] as num?)?.toInt() ?? 0,
    );
  }
}

class RewardModel {
  final String id;
  final String rewardType; // BACKGROUND | EFFECT | MOTION | ACCESSORY
  final String code;
  final String name;
  final String description;
  final String assetUrl;
  final RewardRenderConfig? renderConfig;
  final bool acquired;
  final DateTime? achievedAt;

  const RewardModel({
    required this.id,
    required this.rewardType,
    this.code = '',
    required this.name,
    required this.description,
    required this.assetUrl,
    this.renderConfig,
    required this.acquired,
    this.achievedAt,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] as String? ?? '',
      rewardType: json['reward_type'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      assetUrl: json['asset_url'] as String? ?? '',
      renderConfig: json['render_config'] is Map<String, dynamic>
          ? RewardRenderConfig.fromJson(
              json['render_config'] as Map<String, dynamic>)
          : null,
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
