import 'package:flutter_test/flutter_test.dart';
import 'package:mukzzi/src/core/network/api_client.dart';
import 'package:mukzzi/src/core/storage/token_storage.dart';
import 'package:mukzzi/src/features/character/data/repositories/character_repository.dart';

class _FakeTokenStorage implements TokenStorage {
  @override
  Future<void> delete(String key) async {}

  @override
  Future<void> deleteAll(List<String> keys) async {}

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient() : super(_FakeTokenStorage());

  String? lastPath;
  dynamic lastData;

  @override
  Future<dynamic> patch(String path, {required dynamic data}) async {
    lastPath = path;
    lastData = data;
    return null;
  }
}

void main() {
  group('CharacterRepository.equipItem', () {
    test('keeps large reward IDs as strings when equipping a slot item',
        () async {
      final apiClient = _RecordingApiClient();
      final repository = CharacterRepository(apiClient);

      await repository.equipItem(slot: 'HEAD', rewardId: '621143988300152778');

      expect(apiClient.lastPath, '/characters/me/equipment');
      expect(apiClient.lastData,
          {'slot': 'HEAD', 'reward_id': '621143988300152778'});
    });

    test('sends null reward_id when unequipping a slot', () async {
      final apiClient = _RecordingApiClient();
      final repository = CharacterRepository(apiClient);

      await repository.equipItem(slot: 'HEAD', rewardId: null);

      expect(apiClient.lastPath, '/characters/me/equipment');
      expect(apiClient.lastData, {'slot': 'HEAD', 'reward_id': null});
    });
  });
}
