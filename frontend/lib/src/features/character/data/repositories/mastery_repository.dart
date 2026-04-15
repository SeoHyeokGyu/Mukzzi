import '../../../../core/network/api_client.dart';
import '../../domain/models/mastery_model.dart';

class MasteryRepository {
  final ApiClient _apiClient;
  MasteryRepository(this._apiClient);

  Future<List<MasteryModel>> getMasteries({int page = 1, int limit = 50}) async {
    final response = await _apiClient.get(
      '/collections/mastery',
      queryParameters: {'page': page, 'limit': limit},
    );
    final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
    return data.map((e) => MasteryModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
