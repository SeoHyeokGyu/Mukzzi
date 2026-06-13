class UserModel {
  final String id;
  final String username;
  final String email;
  final String? nickname;
  final String? profileImageUrl;
  final String? equippedTitle;
  final Map<String, bool> notificationSettings;
  final bool isOnboarded;
  final bool isAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String allergies;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.nickname,
    this.profileImageUrl,
    this.equippedTitle,
    this.isOnboarded = false,
    this.isAdmin = false,
    Map<String, bool>? notificationSettings,
    this.createdAt,
    this.updatedAt,
    this.allergies = '',
  }) : notificationSettings = notificationSettings ?? const {'meal': true, 'social': true, 'badge': true};

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final equippedTitleJson = json['equipped_title'];
    final String? titleName = equippedTitleJson is Map
        ? (equippedTitleJson['Name'] ?? equippedTitleJson['name']) as String?
        : equippedTitleJson as String?;

    final rawNs = json['notification_settings'];
    final Map<String, bool> notificationSettings;
    if (rawNs is Map) {
      notificationSettings = {
        'meal': rawNs['meal'] as bool? ?? true,
        'social': rawNs['social'] as bool? ?? true,
        'badge': rawNs['badge'] as bool? ?? true,
      };
    } else {
      notificationSettings = const {'meal': true, 'social': true, 'badge': true};
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      equippedTitle: titleName,
      notificationSettings: notificationSettings,
      isOnboarded: json['body'] != null || json['Body'] != null,
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: json['CreatedAt'] != null
          ? DateTime.tryParse(json['CreatedAt'] as String)
          : null,
      updatedAt: json['UpdatedAt'] != null
          ? DateTime.tryParse(json['UpdatedAt'] as String)
          : null,
      allergies: json['allergies'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'nickname': nickname,
    'profile_image_url': profileImageUrl,
    'allergies': allergies,
    'CreatedAt': createdAt?.toIso8601String(),
    'UpdatedAt': updatedAt?.toIso8601String(),
  };
}

class UserUpdateRequest {
  final String? email;
  final String? nickname;
  final String? profileImageUrl;
  final String? password;
  final String? allergies;

  UserUpdateRequest({this.email, this.nickname, this.profileImageUrl, this.password, this.allergies});

  Map<String, dynamic> toJson() => {
    if (email != null) 'email': email,
    if (nickname != null) 'nickname': nickname,
    if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
    if (password != null) 'password': password,
    if (allergies != null) 'allergies': allergies,
  };
}