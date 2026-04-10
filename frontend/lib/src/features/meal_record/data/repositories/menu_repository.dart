import '../../../../core/network/api_client.dart';
import '../models/menu_model.dart';

class MenuRepository {
  final ApiClient _apiClient;

  MenuRepository(this._apiClient);

  Future<List<MenuModel>> search({
    required String query,
    String? category,
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      '/menus/search',
      queryParameters: {
        'query': query,
        if (category != null) 'category': category,
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );

    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => MenuModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}