import '../../../../core/network/api_client.dart';
import '../models/favorite_model.dart';

class FavoriteRepository {
  final ApiClient _apiClient;

  FavoriteRepository(this._apiClient);

  /// 즐겨찾기 목록 조회 — GET /menus/favorites
  Future<List<FavoriteModel>> getList({String? cursor, int limit = 20}) async {
    final response = await _apiClient.get(
      '/menus/favorites',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => FavoriteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 즐겨찾기 추가 — POST /menus/{id}/favorites
  Future<void> add(String menuId) async {
    await _apiClient.post('/menus/$menuId/favorites', data: {});
  }

  /// 즐겨찾기 제거 — DELETE /menus/{id}/favorites
  Future<void> remove(String menuId) async {
    await _apiClient.delete('/menus/$menuId/favorites');
  }
}