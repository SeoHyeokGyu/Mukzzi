import '../../../../core/network/api_client.dart';
import '../models/nutrition_model.dart';

class NutritionRepository {
  final ApiClient _apiClient;

  NutritionRepository(this._apiClient);

  Future<DailyNutritionModel> getTodayNutrition() async {
    final response = await _apiClient.get('/nutrition/today');
    if (response == null || response['data'] == null) {
      return DailyNutritionModel.empty();
    }
    return DailyNutritionModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<WeeklyNutritionItemModel>> getWeeklyNutrition() async {
    final response = await _apiClient.get('/nutrition/weekly');
    if (response == null || response['data'] == null) {
      return [];
    }
    
    return (response['data'] as List<dynamic>)
        .map((e) => WeeklyNutritionItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
