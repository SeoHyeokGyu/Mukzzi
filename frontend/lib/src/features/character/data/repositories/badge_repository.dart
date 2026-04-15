import '../../../../core/network/api_client.dart';
import '../../domain/models/badge_model.dart';

class BadgeRepository {
  final ApiClient _apiClient;

  BadgeRepository(this._apiClient);

  Future<List<BadgeModel>> getBadges() async {
    final response = await _apiClient.get(
      '/collections/badges',
      queryParameters: {'include_acquired': 'true', 'limit': 50},
    );
    final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
