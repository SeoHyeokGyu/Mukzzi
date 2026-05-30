class AnalyzeMealResponse {
  final String menuName;
  final String category;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final double fiber;
  final double sodium;
  final double vitaminScore;
  final double confidence;

  AnalyzeMealResponse({
    required this.menuName,
    required this.category,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.fiber,
    required this.sodium,
    required this.vitaminScore,
    required this.confidence,
  });

  factory AnalyzeMealResponse.fromJson(Map<String, dynamic> json) {
    return AnalyzeMealResponse(
      menuName: json['menu_name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
      sodium: (json['sodium'] as num?)?.toDouble() ?? 0.0,
      vitaminScore: (json['vitamin_score'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menu_name': menuName,
      'category': category,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
      'fiber': fiber,
      'sodium': sodium,
      'vitamin_score': vitaminScore,
      'confidence': confidence,
    };
  }
}

class MealRecommendation {
  final String menuName;
  final String category;
  final double calories;
  final String description;

  MealRecommendation({
    required this.menuName,
    required this.category,
    required this.calories,
    required this.description,
  });

  factory MealRecommendation.fromJson(Map<String, dynamic> json) {
    return MealRecommendation(
      menuName: json['menu_name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menu_name': menuName,
      'category': category,
      'calories': calories,
      'description': description,
    };
  }
}

class RecommendMealResponse {
  final List<MealRecommendation> recommendations;
  final String reasoning;

  RecommendMealResponse({
    required this.recommendations,
    required this.reasoning,
  });

  factory RecommendMealResponse.fromJson(Map<String, dynamic> json) {
    return RecommendMealResponse(
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => MealRecommendation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reasoning: json['reasoning'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendations': recommendations.map((e) => e.toJson()).toList(),
      'reasoning': reasoning,
    };
  }
}

class NutritionCoachingResponse {
  final String summary;
  final int score;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> tips;

  NutritionCoachingResponse({
    required this.summary,
    required this.score,
    required this.strengths,
    required this.improvements,
    required this.tips,
  });

  factory NutritionCoachingResponse.fromJson(Map<String, dynamic> json) {
    return NutritionCoachingResponse(
      summary: json['summary'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      strengths: (json['strengths'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      improvements: (json['improvements'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      tips: (json['tips'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'score': score,
      'strengths': strengths,
      'improvements': improvements,
      'tips': tips,
    };
  }
}
