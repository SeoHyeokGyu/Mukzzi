import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mukzzi/src/core/network/api_client.dart';
import 'package:mukzzi/src/core/providers/common_providers.dart';
import 'package:mukzzi/src/core/storage/token_storage.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/features/notification/data/models/notification_model.dart';
import 'package:mukzzi/src/features/notification/data/repositories/notification_repository.dart';
import 'package:mukzzi/src/features/notification/presentation/pages/notification_list_page.dart';
import 'package:mukzzi/src/features/notification/presentation/providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTokenStorage implements TokenStorage {
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> deleteAll(List<String> keys) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async {}
}

NotificationModel _notif({required String id, required bool isRead}) =>
    NotificationModel(
      id: id,
      userId: 'user-1',
      type: NotificationType.nudge,
      title: '제목 $id',
      content: '내용 $id',
      isRead: isRead,
      createdAt: DateTime.now(),
    );

class _FakeNotificationRepository extends NotificationRepository {
  _FakeNotificationRepository(SharedPreferences prefs)
      : super(ApiClient(_FakeTokenStorage()), prefs);

  @override
  Future<List<NotificationModel>> getNotifications(
          {int limit = 20, String? cursor}) async =>
      [_notif(id: 'a', isRead: false), _notif(id: 'b', isRead: true)];

  @override
  Stream<NotificationModel> subscribeToNotifications() => const Stream.empty();

  // No-op: NotificationNotifier flips isRead in its own state after awaiting
  // these. The stubs only prevent real HTTP — the button-disappears assertion
  // passes because of the notifier's state update, not a repository response.
  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAllAsRead() async {}
}

Future<Widget> _wrap() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationRepositoryProvider
          .overrideWithValue(_FakeNotificationRepository(prefs)),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: const NotificationListPage(),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('안 읽은 알림이 있으면 전체 읽음 버튼이 보이고, 탭하면 사라진다', (tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pumpAndSettle();

    expect(find.text('전체 읽음'), findsOneWidget);

    await tester.tap(find.text('전체 읽음'));
    await tester.pumpAndSettle();

    expect(find.text('전체 읽음'), findsNothing);
  });

  testWidgets('읽음 여부와 무관하게 안읽음 점이 트리에 유지된다', (tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('notif-unread-dot')), findsNWidgets(2));
  });
}
