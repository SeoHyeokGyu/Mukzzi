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
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      source: json['source'] as String,
      defaultCalories: (json['default_calories'] as num).toDouble(),
      defaultCarbs: (json['default_carbs'] as num).toDouble(),
      defaultProtein: (json['default_protein'] as num).toDouble(),
      defaultFat: (json['default_fat'] as num).toDouble(),
      defaultFiber: (json['default_fiber'] as num).toDouble(),
      defaultVitaminScore: (json['default_vitamin_score'] as num).toDouble(),
    );
  }
}