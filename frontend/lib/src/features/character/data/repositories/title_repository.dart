import '../../../../core/network/api_client.dart';
import '../../domain/models/title_model.dart';

class TitleRepository {
  final ApiClient _apiClient;
  TitleRepository(this._apiClient);

  Future<List<TitleModel>> getTitles() async {
    final response = await _apiClient.get('/collections/titles');
    final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
    return data.map((e) => TitleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> equipTitle(String? titleId) async {
    await _apiClient.patch(
      '/collections/titles/equip',
      data: {'title_id': titleId},
    );
  }
}
