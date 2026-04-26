import '../../../profile/data/models/user_model.dart';

class LoginRequest {
  final String? username;
  final String? email;
  final String password;

  LoginRequest({this.username, this.email, required this.password});

  Map<String, dynamic> toJson() => {
    if (username != null) 'username': username,
    if (email != null) 'email': email,
    'password': password,
  };
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // 백엔드 DTO(accessToken)와 일반적인 관례(access_token) 모두 대응
    final accessToken = (json['accessToken'] ?? json['access_token'] ?? json['token']) as String? ?? '';
    final refreshToken = (json['refreshToken'] ?? json['refresh_token']) as String? ?? '';
    
    return LoginResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String? nickname;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    this.nickname,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'password': password,
    if (nickname != null) 'nickname': nickname,
  };
}
