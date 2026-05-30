// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyNutritionModel _$DailyNutritionModelFromJson(Map<String, dynamic> json) =>
    DailyNutritionModel(
      date: json['date'] as String,
      totalCalories: (json['total_calories'] as num).toDouble(),
      totalCarbs: (json['total_carbs'] as num).toDouble(),
      totalProtein: (json['total_protein'] as num).toDouble(),
      totalFat: (json['total_fat'] as num).toDouble(),
      totalSodium: (json['total_sodium'] as num).toDouble(),
      totalFiber: (json['total_fiber'] as num).toDouble(),
      mealCount: (json['meal_count'] as num).toInt(),
      lastCalculatedAt: DateTime.parse(json['last_calculated_at'] as String),
      nutritionGoal: json['nutrition_goal'] == null
          ? null
          : NutritionGoalModel.fromJson(
              json['nutrition_goal'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DailyNutritionModelToJson(
        DailyNutritionModel instance) =>
    <String, dynamic>{
      'date': instance.date,
      'total_calories': instance.totalCalories,
      'total_carbs': instance.totalCarbs,
      'total_protein': instance.totalProtein,
      'total_fat': instance.totalFat,
      'total_sodium': instance.totalSodium,
      'total_fiber': instance.totalFiber,
      'meal_count': instance.mealCount,
      'last_calculated_at': instance.lastCalculatedAt.toIso8601String(),
      'nutrition_goal': instance.nutritionGoal,
    };

WeeklyNutritionItemModel _$WeeklyNutritionItemModelFromJson(
        Map<String, dynamic> json) =>
    WeeklyNutritionItemModel(
      date: json['date'] as String,
      calories: (json['total_calories'] as num).toDouble(),
      carbs: (json['total_carbs'] as num).toDouble(),
      protein: (json['total_protein'] as num).toDouble(),
      fat: (json['total_fat'] as num).toDouble(),
    );

Map<String, dynamic> _$WeeklyNutritionItemModelToJson(
        WeeklyNutritionItemModel instance) =>
    <String, dynamic>{
      'date': instance.date,
      'total_calories': instance.calories,
      'total_carbs': instance.carbs,
      'total_protein': instance.protein,
      'total_fat': instance.fat,
    };

NutritionGoalModel _$NutritionGoalModelFromJson(Map<String, dynamic> json) =>
    NutritionGoalModel(
      calorieGoal: (json['calorie_goal'] as num).toDouble(),
      carbGoal: (json['carb_goal'] as num).toDouble(),
      proteinGoal: (json['protein_goal'] as num).toDouble(),
      fatGoal: (json['fat_goal'] as num).toDouble(),
    );

Map<String, dynamic> _$NutritionGoalModelToJson(NutritionGoalModel instance) =>
    <String, dynamic>{
      'calorie_goal': instance.calorieGoal,
      'carb_goal': instance.carbGoal,
      'protein_goal': instance.proteinGoal,
      'fat_goal': instance.fatGoal,
    };
