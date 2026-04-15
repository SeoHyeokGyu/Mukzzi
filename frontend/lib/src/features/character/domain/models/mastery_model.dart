class MasteryModel {
  final String id;
  final String menuId;
  final String menuName;
  final String menuCategory;
  final int eatCount;
  final String grade; // BEGINNER | MANIA | ARTISAN | MASTER
  final DateTime firstEatenAt;
  final DateTime lastEatenAt;

  const MasteryModel({
    required this.id,
    required this.menuId,
    required this.menuName,
    required this.menuCategory,
    required this.eatCount,
    required this.grade,
    required this.firstEatenAt,
    required this.lastEatenAt,
  });

  factory MasteryModel.fromJson(Map<String, dynamic> json) {
    return MasteryModel(
      id: json['id'] as String? ?? '',
      menuId: json['menu_id'] as String? ?? '',
      menuName: json['menu_name'] as String? ?? '',
      menuCategory: json['menu_category'] as String? ?? '',
      eatCount: json['eat_count'] as int? ?? 0,
      grade: json['grade'] as String? ?? 'BEGINNER',
      firstEatenAt: DateTime.parse(json['first_eaten_at'] as String),
      lastEatenAt: DateTime.parse(json['last_eaten_at'] as String),
    );
  }

  /// 다음 등급까지 필요한 횟수
  int get nextThreshold {
    switch (grade) {
      case 'BEGINNER':
        return 5;
      case 'MANIA':
        return 20;
      case 'ARTISAN':
        return 50;
      default:
        return 50;
    }
  }

  bool get isMaster => grade == 'MASTER';
}
