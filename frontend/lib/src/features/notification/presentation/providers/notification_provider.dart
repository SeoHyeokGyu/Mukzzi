import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mukzzi/src/core/providers/common_providers.dart';
import 'package:mukzzi/src/features/notification/data/models/notification_model.dart';
import 'package:mukzzi/src/features/notification/data/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    ref.watch(apiClientProvider),
    ref.watch(sharedPreferencesProvider),
  );
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
    _init();
  }

  String get _now => DateFormat('HH:mm:ss.SSS').format(DateTime.now());

  Future<void> _init() async {
    debugPrint('[$_now][NotificationNotifier] 초기화 시작');
    await fetchNotifications();
    _subscribe();
  }

  Future<void> fetchNotifications() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repository.getNotifications();
      if (!mounted) return;
      debugPrint('[$_now][NotificationNotifier] 알림 목록 로드 완료: ${list.length}개');
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      debugPrint('[$_now][NotificationNotifier] 알림 목록 로드 실패: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _subscribe() {
    debugPrint('[$_now][NotificationNotifier] SSE 구독 시도...');
    _subscription?.cancel();
    _subscription = _repository.subscribeToNotifications().listen(
      (newNotification) {
        if (!mounted) return;
        debugPrint('[$_now][NotificationNotifier] 새 알림 수신 성공: ${newNotification.title}');
        state = state.copyWith(
          notifications: [newNotification, ...state.notifications],
        );
      },
      onError: (e) {
        debugPrint('[$_now][NotificationNotifier] SSE 스트림 에러 발생: $e');
        if (!mounted) return;
        Future.delayed(const Duration(seconds: 5), () => _subscribe());
      },
      onDone: () {
        debugPrint('[$_now][NotificationNotifier] SSE 스트림 종료됨 (onDone)');
        if (mounted) {
           // 서버가 끊은 경우 3초 후 재연결 시도
           Future.delayed(const Duration(seconds: 3), () => _subscribe());
        }
      },
    );
    debugPrint('[$_now][NotificationNotifier] SSE 리스너 등록 완료');
  }

  // ... (markAsRead 등 나머지 메서드는 동일)
  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      if (!mounted) return;
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
      debugPrint('[$_now][NotificationNotifier] 읽음 처리 에러: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      if (!mounted) return;
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
      debugPrint('[$_now][NotificationNotifier] 전체 읽음 처리 에러: $e');
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
