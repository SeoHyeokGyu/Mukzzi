import '../../../profile/data/models/user_model.dart';

enum NotificationType {
  FRIEND_REQUEST,
  FRIEND_ACCEPTED,
  NUDGE,
  GUESTBOOK,
  LEVEL_UP,
  BADGE_ACQUIRED,
  MEAL_TAG,
  MEAL_TAG_ACCEPTED,
  UNKNOWN;

  static NotificationType fromString(String? value) {
    if (value == null) return NotificationType.UNKNOWN;
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.UNKNOWN,
    );
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String? senderId;
  final NotificationType type;
  final String title;
  final String content;
  final String? linkUrl;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final UserModel? sender;

  NotificationModel({
    required this.id,
    required this.userId,
    this.senderId,
    required this.type,
    required this.title,
    required this.content,
    this.linkUrl,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.sender,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString(),
      type: NotificationType.fromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      linkUrl: json['link_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'] as String) : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(), // 폴백
      sender: json['sender'] != null ? UserModel.fromJson(json['sender'] as Map<String, dynamic>) : null,
    );
  }
}
