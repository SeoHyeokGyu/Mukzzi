class UserModel {
  final String id;
  final String username;
  final String email;
  final String? nickname;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.nickname,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String?,
      createdAt: json['CreatedAt'] != null 
          ? DateTime.parse(json['CreatedAt'] as String) 
          : null,
      updatedAt: json['UpdatedAt'] != null 
          ? DateTime.parse(json['UpdatedAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'nickname': nickname,
    'CreatedAt': createdAt?.toIso8601String(),
    'UpdatedAt': updatedAt?.toIso8601String(),
  };
}

class UserUpdateRequest {
  final String? email;
  final String? nickname;
  final String? password;

  UserUpdateRequest({this.email, this.nickname, this.password});

  Map<String, dynamic> toJson() => {
    if (email != null) 'email': email,
    if (nickname != null) 'nickname': nickname,
    if (password != null) 'password': password,
  };
}
