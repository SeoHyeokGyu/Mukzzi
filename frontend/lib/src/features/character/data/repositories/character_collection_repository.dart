import '../../../../core/network/api_client.dart';
import '../../domain/models/character_collection_model.dart';

class CharacterCollectionRepository {
  final ApiClient _apiClient;
  CharacterCollectionRepository(this._apiClient);

  Future<List<CharacterCollectionModel>> getCollections({int page = 1, int limit = 100}) async {
    final response = await _apiClient.get(
      '/collections/characters',
      queryParameters: {'page': page, 'limit': limit},
    );
    final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => CharacterCollectionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
