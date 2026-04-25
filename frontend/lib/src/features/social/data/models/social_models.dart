import '../../../profile/data/models/user_model.dart';

class GuestbookModel {
  final String id;
  final String targetUserId;
  final String writerId;
  final String content;
  final bool isSecret;
  final DateTime createdAt;
  final UserModel? writer;

  GuestbookModel({
    required this.id,
    required this.targetUserId,
    required this.writerId,
    required this.content,
    required this.isSecret,
    required this.createdAt,
    this.writer,
  });

  factory GuestbookModel.fromJson(Map<String, dynamic> json) {
    // 백엔드 응답에서 대문자(CreatedAt) 또는 소문자(created_at) 필드 대응
    final rawCreatedAt = json['CreatedAt'] ?? json['created_at'];
    
    return GuestbookModel(
      id: json['id']?.toString() ?? '',
      targetUserId: json['target_user_id']?.toString() ?? '',
      writerId: json['writer_id']?.toString() ?? '',
      content: json['content'] as String? ?? '',
      isSecret: json['is_secret'] as bool? ?? false,
      createdAt: rawCreatedAt != null 
          ? DateTime.parse(rawCreatedAt as String) 
          : DateTime.now(),
      writer: json['writer'] != null ? UserModel.fromJson(json['writer'] as Map<String, dynamic>) : null,
    );
  }
}

class FriendRequestModel {
  final String userId;
  final String nickname;
  final String? profileImageUrl;
  final DateTime createdAt;

  FriendRequestModel({
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
    required this.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['CreatedAt'] ?? json['created_at'];

    return FriendRequestModel(
      userId: json['id']?.toString() ?? '',
      nickname: json['nickname'] as String? ?? '',
      profileImageUrl: json['profile_image_url'] as String?,
      createdAt: rawCreatedAt != null 
          ? DateTime.parse(rawCreatedAt as String) 
          : DateTime.now(),
    );
  }
}
