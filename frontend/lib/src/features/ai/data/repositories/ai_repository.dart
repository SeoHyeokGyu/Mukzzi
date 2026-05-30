import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mukzzi/src/core/network/api_client.dart';
import 'package:mukzzi/src/features/ai/data/models/ai_models.dart';

class AiRepository {
  final ApiClient _apiClient;

  AiRepository(this._apiClient);

  Future<String> uploadImage(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    final response = await _apiClient.post('/upload/image', data: formData);
    // response.data format: { "status": "success", "data": "http://..." }
    return response['data'] as String;
  }

  Future<AnalyzeMealResponse> analyzeMealImage(String imageUrl) async {
    final response = await _apiClient.post(
      '/ai/analyze-meal',
      data: {'image_url': imageUrl},
    );
    return AnalyzeMealResponse.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<RecommendMealResponse> recommendMeal(String mealType) async {
    final response = await _apiClient.post(
      '/ai/recommend-meal',
      data: {'meal_type': mealType},
    );
    return RecommendMealResponse.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<NutritionCoachingResponse> getNutritionCoaching({String? date}) async {
    final data = <String, dynamic>{};
    if (date != null) {
      data['date'] = date;
    }
    final response = await _apiClient.post(
      '/ai/nutrition-coaching',
      data: data,
    );
    return NutritionCoachingResponse.fromJson(response['data'] as Map<String, dynamic>);
  }
}
