import 'package:mukzzi/src/core/network/api_client.dart';
import 'package:mukzzi/src/features/quest/data/models/quest_model.dart';

abstract class QuestRemoteDataSource {
  Future<List<QuestModel>> fetchQuests({String? period});
  Future<void> claimReward(String userQuestId);
}

class QuestRemoteDataSourceImpl implements QuestRemoteDataSource {
  final ApiClient apiClient;

  QuestRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<QuestModel>> fetchQuests({String? period}) async {
    final response = await apiClient.get(
      '/quests',
      queryParameters: period != null ? {'period': period} : null,
    );

    final data = response['data'] as List;
    return data.map((json) => QuestModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> claimReward(String userQuestId) async {
    await apiClient.post('/quests/$userQuestId/claim', data: {});
  }
}
