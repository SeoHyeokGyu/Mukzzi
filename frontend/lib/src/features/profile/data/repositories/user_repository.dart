import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../models/user_stats_model.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<UserModel> getMe() async {
    final response = await _apiClient.get('/users/me');
    return UserModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<UserStatsModel> getStats() async {
    final response = await _apiClient.get('/users/me/stats');
    return UserStatsModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<UserModel> updateNotificationSettings(Map<String, bool> settings) async {
    final response = await _apiClient.patch(
      '/users/me/settings',
      data: {'notification_settings': settings},
    );
    return UserModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<UserModel> getProfile(String id) async {
    final response = await _apiClient.get('/users/$id');
    return UserModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<UserModel> updateProfile(UserUpdateRequest request) async {
    final response = await _apiClient.patch(
      '/users/me',
      data: request.toJson(),
    );
    return UserModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAccount() async {
    await _apiClient.delete('/users/me');
  }
}
