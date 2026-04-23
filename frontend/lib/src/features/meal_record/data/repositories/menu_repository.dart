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

  /// 사용자 정의 메뉴 등록 (source=USER)
  /// 이미 동일한 name+category가 존재하면 서버가 400을 반환하고,
  /// ApiClient가 BadRequestException으로 변환해서 던짐.
  Future<MenuModel> create({
    required String name,
    required String category,
  }) async {
    final response = await _apiClient.post(
      '/menus',
      data: {
        'name': name,
        'category': category,
      },
    );

    return MenuModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}