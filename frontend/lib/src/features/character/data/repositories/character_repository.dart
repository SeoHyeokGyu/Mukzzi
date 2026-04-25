import '../../../../core/network/api_client.dart';
import '../models/character_model.dart';

class CharacterRepository {
  final ApiClient _apiClient;

  CharacterRepository(this._apiClient);

  Future<CharacterModel> getMyCharacter() async {
    final response = await _apiClient.get('/users/me/character');
    return CharacterModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}
