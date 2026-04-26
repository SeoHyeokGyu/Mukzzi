import '../../../../core/network/api_client.dart';
import '../../../profile/data/models/user_model.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _apiClient.post(
      '/auth/login',
      data: request.toJson(),
    );

    return LoginResponse.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> register(RegisterRequest request) async {
    await _apiClient.post(
      '/auth/register',
      data: request.toJson(),
    );
  }

  Future<void> logout() async {
    await _apiClient.post('/auth/logout', data: {});
  }

  Future<UserModel> fetchMe() async {
    final response = await _apiClient.get('/users/me');
    return UserModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}
