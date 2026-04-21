// lib/src/features/meal_record/data/models/meal_model.dart

import 'package:flutter/material.dart';

// ─────────────────────────────────────────
// MealType enum + extension + helper
// ─────────────────────────────────────────

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeX on MealType {
  String get apiValue => name.toUpperCase();

  String get label => const {
    MealType.breakfast: '아침',
    MealType.lunch: '점심',
    MealType.dinner: '저녁',
    MealType.snack: '간식',
  }[this]!;

  IconData get icon => const {
    MealType.breakfast: Icons.wb_sunny_outlined,
    MealType.lunch: Icons.wb_cloudy_outlined,
    MealType.dinner: Icons.nightlight_outlined,
    MealType.snack: Icons.coffee_outlined,
  }[this]!;
}

class MealTypeHelper {
  static MealType fromString(String value) => MealType.values.firstWhere(
        (e) => e.apiValue == value.toUpperCase(),
    orElse: () => MealType.snack,
  );

  static MealType fromHour(int hour) {
    if (hour >= 6 && hour <= 10) return MealType.breakfast;
    if (hour >= 12 && hour <= 13) return MealType.lunch;
    if (hour >= 18 && hour <= 21) return MealType.dinner;
    return MealType.snack;
  }
}

// ─────────────────────────────────────────
// MealRecord
// ─────────────────────────────────────────

class MealRecord {
  final String id;
  final String menuName;
  final String category;
  final String mealType;
  final double servingSize;
  final DateTime recordedAt;
  final double? calories;
  final double? carbs;
  final double? protein;
  final double? fat;
  final String? weatherTag;
  final String? moodTag;
  final String? review;
  final int? rating;
  final String? imageUrl;

  const MealRecord({
    required this.id,
    required this.menuName,
    required this.category,
    required this.mealType,
    required this.servingSize,
    required this.recordedAt,
    this.calories,
    this.carbs,
    this.protein,
    this.fat,
    this.weatherTag,
    this.moodTag,
    this.review,
    this.rating,
    this.imageUrl,
  });

  factory MealRecord.fromJson(Map<String, dynamic> json) {
    final nutrition = json['nutrition'] as Map<String, dynamic>?;
    return MealRecord(
      id: json['id'].toString(),
      menuName: json['menu_name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      mealType: json['meal_type'] as String? ?? '',
      servingSize: (json['serving_size'] as num?)?.toDouble() ?? 1.0,
      recordedAt: DateTime.parse(json['recorded_at'] as String).toLocal(),
      calories: (nutrition?['calories'] as num?)?.toDouble(),
      carbs: (nutrition?['carbs'] as num?)?.toDouble(),
      protein: (nutrition?['protein'] as num?)?.toDouble(),
      fat: (nutrition?['fat'] as num?)?.toDouble(),
      weatherTag: json['weather_tag'] as String?,
      moodTag: json['mood_tag'] as String?,
      review: json['review'] as String?,
      rating: json['rating'] as int?,
      imageUrl: json['image_url'] as String?,
    );
  }
}

// ─────────────────────────────────────────
// CreateMealRequest
// ─────────────────────────────────────────

class CreateMealRequest {
  final int? menuId;
  final String menuName;
  final String category;
  final String mealType;
  final double servingSize;
  final DateTime recordedAt;
  final bool isManual;
  final String? weatherTag;
  final String? moodTag;
  final String? review;
  final int? rating;
  final String? imageUrl;
  final List<int> friendTags;

  const CreateMealRequest({
    this.menuId,
    required this.menuName,
    required this.category,
    required this.mealType,
    required this.servingSize,
    required this.recordedAt,
    required this.isManual,
    this.weatherTag,
    this.moodTag,
    this.review,
    this.rating,
    this.imageUrl,
    this.friendTags = const [],
  });

  Map<String, dynamic> toJson() => {
    'menu_name': menuName,
    'category': category,
    'meal_type': mealType,
    'serving_size': servingSize,
    'recorded_at': '${recordedAt.year.toString().padLeft(4, '0')}-'
        '${recordedAt.month.toString().padLeft(2, '0')}-'
        '${recordedAt.day.toString().padLeft(2, '0')}T'
        '${recordedAt.hour.toString().padLeft(2, '0')}:'
        '${recordedAt.minute.toString().padLeft(2, '0')}:'
        '${recordedAt.second.toString().padLeft(2, '0')}+09:00',
    'is_manual': isManual,
    if (menuId != null) 'menu_id': menuId.toString(),
    if (weatherTag != null) 'weather_tag': weatherTag,
    if (moodTag != null) 'mood_tag': moodTag,
    if (review != null) 'review': review,
    if (rating != null) 'rating': rating,
    if (imageUrl != null) 'image_url': imageUrl,
    if (friendTags.isNotEmpty) 'friend_tags': friendTags,
  };
}

// ─────────────────────────────────────────
// CreateMealResult (POST /meals 응답)
// ─────────────────────────────────────────

class GrantedTitleInfo {
  final String name;
  final String description;

  const GrantedTitleInfo({required this.name, required this.description});

  factory GrantedTitleInfo.fromJson(Map<String, dynamic> json) =>
      GrantedTitleInfo(
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}

class CreateMealResult {
  final MealRecord meal;
  final GrantedTitleInfo? grantedTitle;

  const CreateMealResult({required this.meal, this.grantedTitle});

  factory CreateMealResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final sideEffects = data['side_effects'] as Map<String, dynamic>?;
    final titleJson = sideEffects?['granted_title'] as Map<String, dynamic>?;
    return CreateMealResult(
      meal: MealRecord.fromJson(data['meal'] as Map<String, dynamic>),
      grantedTitle: titleJson != null ? GrantedTitleInfo.fromJson(titleJson) : null,
    );
  }
}

// ─────────────────────────────────────────
// MealListFilter / MealListResult
// ─────────────────────────────────────────

class MealListFilter {
  final String? startDate;
  final String? endDate;
  final String? mealType;
  final String? cursor;
  final int limit;

  const MealListFilter({
    this.startDate,
    this.endDate,
    this.mealType,
    this.cursor,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParameters() => {
    'limit': limit,
    if (startDate != null) 'start_date': startDate,
    if (endDate != null) 'end_date': endDate,
    if (mealType != null) 'meal_type': mealType,
    if (cursor != null) 'cursor': cursor,
  };
}

class MealListResult {
  final List<MealRecord> meals;
  final bool hasNext;
  final String? nextCursor;

  const MealListResult({
    required this.meals,
    required this.hasNext,
    this.nextCursor,
  });
}