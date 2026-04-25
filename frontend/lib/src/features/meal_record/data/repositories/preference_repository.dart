import '../../../../core/network/api_client.dart';

class PreferenceRepository {
  final ApiClient _apiClient;

  PreferenceRepository(this._apiClient);

  /// 선호도 설정 — POST /menus/{id}/preferences
  Future<void> set(String menuId, String preference) async {
    await _apiClient.post(
      '/menus/$menuId/preferences',
      data: {'preference': preference},
    );
  }

  /// 선호도 제거 — DELETE /menus/{id}/preferences
  Future<void> remove(String menuId) async {
    await _apiClient.delete('/menus/$menuId/preferences');
  }
}