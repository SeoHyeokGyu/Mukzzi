import '../../../profile/data/models/user_model.dart';

enum NotificationType {
  friendRequest,
  friendAccepted,
  nudge,
  guestbook,
  levelUp,
  badgeAcquired,
  mealTag,
  mealTagAccepted,
  unknown;

  static NotificationType fromString(String? value) {
    if (value == null) return NotificationType.unknown;
    return switch (value) {
      'FRIEND_REQUEST' => NotificationType.friendRequest,
      'FRIEND_ACCEPTED' => NotificationType.friendAccepted,
      'NUDGE' => NotificationType.nudge,
      'GUESTBOOK' => NotificationType.guestbook,
      'LEVEL_UP' => NotificationType.levelUp,
      'BADGE_ACQUIRED' => NotificationType.badgeAcquired,
      'MEAL_TAG' => NotificationType.mealTag,
      'MEAL_TAG_ACCEPTED' => NotificationType.mealTagAccepted,
      _ => NotificationType.unknown,
    };
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

  /// 알림 클릭 시 이동할 경로를 결정합니다.
  String get navigationPath {
    if (linkUrl != null && linkUrl!.isNotEmpty) return linkUrl!;

    switch (type) {
      case NotificationType.friendRequest:
        return '/social'; // 요청 탭으로 자동 전환 필요 시 추가 로직 가능
      case NotificationType.friendAccepted:
      case NotificationType.nudge:
      case NotificationType.guestbook:
        if (senderId != null) return '/social/profile/$senderId';
        return '/social';
      case NotificationType.levelUp:
        return '/character';
      case NotificationType.badgeAcquired:
        return '/profile/badges';
      default:
        return '/home';
    }
  }
}
