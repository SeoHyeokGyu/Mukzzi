import '../../../../core/network/api_client.dart';
import '../models/character_model.dart';

class CharacterRepository {
  final ApiClient _apiClient;

  CharacterRepository(this._apiClient);

  Future<CharacterModel> getMyCharacter() async {
    final response = await _apiClient.get('/users/me/character');
    if (response == null || response['data'] == null) {
      throw Exception('캐릭터 정보를 불러올 수 없습니다.');
    }
    return CharacterModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> applyAppearance({
    required int bodyType,
    required int muscle,
    required int skinTone,
    required int expression,
  }) async {
    await _apiClient.patch('/characters/me/appearance', data: {
      'body_type': bodyType,
      'muscle': muscle,
      'skin_tone': skinTone,
      'expression': expression,
    });
  }

  Future<void> equipItem({int? backgroundId, int? accessoryId}) async {
    await _apiClient.patch('/characters/me/equipment', data: {
      if (backgroundId != null)
        'background_id': backgroundId == 0 ? "" : backgroundId.toString(),
      if (accessoryId != null)
        'accessory_id': accessoryId == 0 ? "" : accessoryId.toString(),
    });
  }
}
