import '../../../../core/network/api_client.dart';
import '../../../profile/data/models/user_model.dart';
import '../models/social_models.dart';

class SocialRepository {
  final ApiClient _apiClient;

  SocialRepository(this._apiClient);

  // 친구 목록 조회
  Future<List<UserModel>> getFriends() async {
    final response = await _apiClient.get('/friends');
    final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
    return data.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // 친구 삭제
  Future<void> deleteFriend(String userId) async {
    await _apiClient.delete('/friends/$userId');
  }

  // 받은 친구 요청 목록 조회
  Future<List<UserModel>> getPendingRequests() async {
    final response = await _apiClient.get('/friends/requests');
    final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
    return data.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // 보낸 친구 요청 목록 조회
  Future<List<UserModel>> getSentRequests() async {
    final response = await _apiClient.get('/friends/requests/sent');
    final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
    return data.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // 친구 요청 전송
  Future<void> sendFriendRequest(String userId) async {
    await _apiClient.post('/friends/requests/$userId', data: {});
  }

  // 친구 요청 수락
  Future<void> acceptFriendRequest(String userId) async {
    await _apiClient.patch('/friends/requests/$userId/accept', data: {});
  }

  // 친구 요청 거절
  Future<void> rejectFriendRequest(String userId) async {
    await _apiClient.patch('/friends/requests/$userId/reject', data: {});
  }

  // 응원하기 (Nudge)
  Future<void> nudgeFriend(String userId) async {
    await _apiClient.post('/users/$userId/nudge', data: {});
  }

  // 방명록 조회
  Future<List<GuestbookModel>> getGuestbooks(String userId) async {
    final response = await _apiClient.get('/users/$userId/guestbook');
    final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
    return data.map((e) => GuestbookModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // 방명록 작성
  Future<void> writeGuestbook(String userId, String content, bool isSecret) async {
    await _apiClient.post(
      '/users/$userId/guestbook',
      data: {'content': content, 'is_secret': isSecret},
    );
  }

  // 사용자 검색
  Future<List<UserModel>> searchUsers(String query) async {
    final response = await _apiClient.get(
      '/users/search',
      queryParameters: {'query': query},
    );
    final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
    return data.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // 타인 프로필 정보 조회
  Future<UserModel> getOtherProfile(String userId) async {
    final response = await _apiClient.get('/users/$userId/profile');
    return UserModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  // 사용자 차단
  Future<void> blockUser(String userId) async {
    await _apiClient.post('/users/$userId/block', data: {});
  }
}
