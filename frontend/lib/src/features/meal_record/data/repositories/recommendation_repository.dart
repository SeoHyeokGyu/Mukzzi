import '../../../../core/network/api_client.dart';
import '../../data/models/menu_model.dart';

class RecommendationResult {
  final List<MenuModel> menus;
  final bool isPersonal;

  const RecommendationResult({required this.menus, required this.isPersonal});

  factory RecommendationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final list = data['menus'] as List<dynamic>;
    return RecommendationResult(
      menus: list.map((e) => MenuModel.fromJson(e as Map<String, dynamic>)).toList(),
      isPersonal: data['is_personal'] as bool? ?? false,
    );
  }
}

class RecommendationRepository {
  final ApiClient _apiClient;

  RecommendationRepository(this._apiClient);

  /// GET /menus/recommendations
  Future<RecommendationResult> getRecommendations() async {
    final response = await _apiClient.get('/menus/recommendations');
    return RecommendationResult.fromJson(response as Map<String, dynamic>);
  }
}