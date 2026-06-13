import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mukzzi/src/core/network/api_client.dart';
import 'package:mukzzi/src/features/ai/data/models/ai_models.dart';

class AiRepository {
  final ApiClient _apiClient;

  AiRepository(this._apiClient);

  Future<String> uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.name,
        contentType: MediaType('image', file.name.split('.').last),
      ),
    });

    final response = await _apiClient.post(
      '/upload/image',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
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
