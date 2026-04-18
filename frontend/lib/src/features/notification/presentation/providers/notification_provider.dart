import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/common_providers.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(apiClientProvider));
});

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;
  StreamSubscription? _subscription;

  NotificationNotifier(this._repository) : super(NotificationState()) {
    // 초기 목록 로드 및 SSE 구독 시작
    _init();
  }

  Future<void> _init() async {
    await fetchNotifications();
    _subscribe();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repository.getNotifications();
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _repository.subscribeToNotifications().listen(
      (newNotification) {
        // 새 알림이 오면 목록 맨 앞에 추가
        state = state.copyWith(
          notifications: [newNotification, ...state.notifications],
        );
      },
      onError: (e) {
        // 에러 발생 시 일정 시간 후 재연결 시도
        Future.delayed(const Duration(seconds: 5), () => _subscribe());
      },
    );
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          if (n.id == id) {
            return NotificationModel(
              id: n.id,
              userId: n.userId,
              senderId: n.senderId,
              type: n.type,
              title: n.title,
              content: n.content,
              linkUrl: n.linkUrl,
              isRead: true,
              readAt: DateTime.now(),
              createdAt: n.createdAt,
              sender: n.sender,
            );
          }
          return n;
        }).toList(),
      );
    } catch (e) {
      // 에러 처리
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            senderId: n.senderId,
            type: n.type,
            title: n.title,
            content: n.content,
            linkUrl: n.linkUrl,
            isRead: true,
            readAt: DateTime.now(),
            createdAt: n.createdAt,
            sender: n.sender,
          );
        }).toList(),
      );
    } catch (e) {
      // 에러 처리
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref.watch(notificationRepositoryProvider));
});
