import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<UserModel> getMe() async {
    final response = await _apiClient.get('/users/me');
    return UserModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<UserModel> getProfile(String id) async {
    final response = await _apiClient.get('/users/$id');
    return UserModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<UserModel> updateProfile(String id, UserUpdateRequest request) async {
    final response = await _apiClient.put(
      '/users/$id',
      data: request.toJson(),
    );
    return UserModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAccount(String id) async {
    await _apiClient.delete('/users/$id');
  }
}
