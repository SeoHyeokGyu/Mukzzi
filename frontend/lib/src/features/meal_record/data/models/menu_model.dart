class MenuModel {
  final String id;
  final String name;
  final String category;
  final String source;
  final double defaultCalories;
  final double defaultCarbs;
  final double defaultProtein;
  final double defaultFat;
  final double defaultFiber;
  final double defaultVitaminScore;
  final bool isFavorite;
  final String? preference; // 'LIKE' | 'DISLIKE' | null

  const MenuModel({
    required this.id,
    required this.name,
    required this.category,
    required this.source,
    required this.defaultCalories,
    required this.defaultCarbs,
    required this.defaultProtein,
    required this.defaultFat,
    required this.defaultFiber,
    required this.defaultVitaminScore,
    this.isFavorite = false,
    this.preference,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    // 백엔드 dto.MenuResponse 및 dto.MenuDetailResponse 필드 대응
    // 중첩된 구조(menu)일 수도 있고, 평탄화된 구조일 수도 있음
    final Map<String, dynamic> data = json.containsKey('id') ? json : (json['menu'] ?? json);

    return MenuModel(
      id: data['id']?.toString() ?? '',
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      source: data['source'] as String? ?? '',
      defaultCalories: (data['default_calories'] ?? data['DefaultCalories'] ?? 0).toDouble(),
      defaultCarbs: (data['default_carbs'] ?? data['DefaultCarbs'] ?? 0).toDouble(),
      defaultProtein: (data['default_protein'] ?? data['DefaultProtein'] ?? 0).toDouble(),
      defaultFat: (data['default_fat'] ?? data['DefaultFat'] ?? 0).toDouble(),
      defaultFiber: (data['default_fiber'] ?? data['DefaultFiber'] ?? 0).toDouble(),
      defaultVitaminScore: (data['default_vitamin_score'] ?? data['DefaultVitaminScore'] ?? 0).toDouble(),
      isFavorite: json['is_favorite'] as bool? ?? false,
      preference: json['preference'] as String?,
    );
  }
}
