import 'package:json_annotation/json_annotation.dart';

part 'nutrition_model.g.dart';

@JsonSerializable()
class DailyNutritionModel {
  final String date;
  @JsonKey(name: 'total_calories')
  final double totalCalories;
  @JsonKey(name: 'total_carbs')
  final double totalCarbs;
  @JsonKey(name: 'total_protein')
  final double totalProtein;
  @JsonKey(name: 'total_fat')
  final double totalFat;
  @JsonKey(name: 'total_sodium')
  final double totalSodium;
  @JsonKey(name: 'total_fiber')
  final double totalFiber;
  @JsonKey(name: 'meal_count')
  final int mealCount;
  @JsonKey(name: 'last_calculated_at')
  final DateTime lastCalculatedAt;
  @JsonKey(name: 'nutrition_goal')
  final NutritionGoalModel? nutritionGoal;

  DailyNutritionModel({
    required this.date,
    required this.totalCalories,
    required this.totalCarbs,
    required this.totalProtein,
    required this.totalFat,
    required this.totalSodium,
    required this.totalFiber,
    required this.mealCount,
    required this.lastCalculatedAt,
    this.nutritionGoal,
  });

  factory DailyNutritionModel.empty() {
    return DailyNutritionModel(
      date: DateTime.now().toIso8601String().split('T')[0],
      totalCalories: 0,
      totalCarbs: 0,
      totalProtein: 0,
      totalFat: 0,
      totalSodium: 0,
      totalFiber: 0,
      mealCount: 0,
      lastCalculatedAt: DateTime.now(),
    );
  }

  factory DailyNutritionModel.fromJson(Map<String, dynamic> json) =>
      _$DailyNutritionModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailyNutritionModelToJson(this);
}

@JsonSerializable()
class WeeklyNutritionItemModel {
  final String date;
  @JsonKey(name: 'total_calories')
  final double calories;
  @JsonKey(name: 'total_carbs')
  final double carbs;
  @JsonKey(name: 'total_protein')
  final double protein;
  @JsonKey(name: 'total_fat')
  final double fat;

  WeeklyNutritionItemModel({
    required this.date,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  factory WeeklyNutritionItemModel.fromJson(Map<String, dynamic> json) =>
      _$WeeklyNutritionItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyNutritionItemModelToJson(this);
}

@JsonSerializable()
class NutritionGoalModel {
  @JsonKey(name: 'calorie_goal')
  final double calorieGoal;
  @JsonKey(name: 'carb_goal')
  final double carbGoal;
  @JsonKey(name: 'protein_goal')
  final double proteinGoal;
  @JsonKey(name: 'fat_goal')
  final double fatGoal;

  NutritionGoalModel({
    required this.calorieGoal,
    required this.carbGoal,
    required this.proteinGoal,
    required this.fatGoal,
  });

  factory NutritionGoalModel.fromJson(Map<String, dynamic> json) =>
      _$NutritionGoalModelFromJson(json);

  Map<String, dynamic> toJson() => _$NutritionGoalModelToJson(this);
}
