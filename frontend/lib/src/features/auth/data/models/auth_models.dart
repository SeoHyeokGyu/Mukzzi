import '../../../profile/data/models/user_model.dart';

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
  };
}

class LoginResponse {
  final String token;
  final UserModel user;

  LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
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
