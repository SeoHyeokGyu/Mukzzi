import '../../../../core/network/api_client.dart';
import '../../domain/models/reward_model.dart';

class RewardRepository {
  final ApiClient _apiClient;
  RewardRepository(this._apiClient);

  Future<List<RewardModel>> getRewards() async {
    final response = await _apiClient.get('/collections/rewards');
    final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
    return data.map((e) => RewardModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
