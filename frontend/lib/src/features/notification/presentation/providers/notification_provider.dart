import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mukzzi/src/core/providers/common_providers.dart';
import 'package:mukzzi/src/features/auth/presentation/providers/auth_provider.dart';
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

  void clear() {
    debugPrint('[$_now][NotificationNotifier] 알림 상태 초기화');
    _subscription?.cancel();
    _subscription = null;
    state = NotificationState();
  }

  Future<void> fetchNotifications() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repository.getNotifications();
      if (!mounted) return;
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _repository.subscribeToNotifications().listen(
      (NotificationModel newNotification) {
        if (!mounted) return;
        debugPrint('[$_now][NotificationNotifier] 알림 수신: ${newNotification.title}');
        state = state.copyWith(
          notifications: <NotificationModel>[newNotification, ...state.notifications],
        );
      },
      onError: (e) {
        debugPrint('[$_now][NotificationNotifier] 스트림 에러: $e');
        // 웹 EventSource 는 내부적으로 재연결하므로 여기서 중복 호출하지 않음
        // 모바일이나 치명적 에러 시에만 10초 후 재시도
        if (mounted && !kIsWeb) {
          Future.delayed(const Duration(seconds: 10), () => _subscribe());
        }
      },
      onDone: () {
        debugPrint('[$_now][NotificationNotifier] 스트림 종료');
      },
    );
  }

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
  final repository = ref.watch(notificationRepositoryProvider);
  final notifier = NotificationNotifier(repository);

  ref.listen(authProvider, (previous, next) {
    if (next.user == null && previous?.user != null) {
      notifier.clear();
    }
  });

  return notifier;
});
