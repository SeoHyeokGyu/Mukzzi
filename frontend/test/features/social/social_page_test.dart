import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/storage/token_storage.dart';
import 'package:mukzzi/src/core/network/api_client.dart';
import 'package:mukzzi/src/features/social/presentation/pages/social_page.dart';
import 'package:mukzzi/src/features/social/data/repositories/social_repository.dart';
import 'package:mukzzi/src/features/social/presentation/providers/social_providers.dart';
import 'package:mukzzi/src/features/profile/data/models/user_model.dart';
import 'package:mukzzi/src/features/social/data/models/social_models.dart';
import 'package:mukzzi/src/features/social/data/models/feed_model.dart';

class FakeTokenStorage implements TokenStorage {
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> deleteAll(List<String> keys) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async {}
}

class FakeSocialRepository extends SocialRepository {
  FakeSocialRepository() : super(ApiClient(FakeTokenStorage()));

  @override
  Future<List<UserModel>> getFriends() async {
    return [
      UserModel(
        id: 'friend1',
        username: 'friend_user',
        email: 'friend@test.com',
        nickname: '친구1',
        equippedTitle: 'Lv.1',
      ),
    ];
  }

  @override
  Future<void> deleteFriend(String userId) async {}

  @override
  Future<List<UserModel>> getPendingRequests() async {
    return [
      UserModel(
        id: 'req1',
        username: 'req_user',
        email: 'req@test.com',
        nickname: '요청자1',
      ),
    ];
  }

  @override
  Future<List<UserModel>> getSentRequests() async {
    return [];
  }

  @override
  Future<void> sendFriendRequest(String userId) async {}

  @override
  Future<void> acceptFriendRequest(String userId) async {}

  @override
  Future<void> rejectFriendRequest(String userId) async {}

  @override
  Future<void> nudgeFriend(String userId) async {}

  @override
  Future<List<GuestbookModel>> getGuestbooks(String userId, {int page = 1, int limit = 20}) async {
    return [];
  }

  @override
  Future<void> writeGuestbook(String userId, String content, bool isSecret) async {}

  @override
  Future<void> deleteGuestbook(String userId, String guestbookId) async {}

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    return [
      UserModel(
        id: 'search1',
        username: 'search_user',
        email: 'search@test.com',
        nickname: '검색결과1',
      )
    ];
  }

  @override
  Future<UserModel> getOtherProfile(String userId) async {
    return UserModel(
      id: userId,
      username: 'other',
      email: 'other@test.com',
    );
  }

  @override
  Future<void> blockUser(String userId) async {}

  @override
  Future<FeedResponse> getSocialFeed({String? cursor, int limit = 20}) async {
    return const FeedResponse(posts: [], hasNext: false);
  }

  @override
  Future<List<RankingModel>> getSocialRanking() async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> visitFriend(String userId, String interactionType) async {
    return {};
  }

  @override
  Future<List<ComparisonModel>> getFriendsComparison() async {
    return [];
  }
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      socialRepositoryProvider.overrideWithValue(FakeSocialRepository()),
      recommendedUsersProvider.overrideWith((ref) async => [
        UserModel(
          id: 'rec1',
          username: 'rec_user',
          email: 'rec@test.com',
          nickname: '추천유저1',
        )
      ]),
    ],
    child: MaterialApp(theme: AppTheme.darkTheme, home: child),
  );
}

void main() {
  group('SocialPage - 친구 목록 탭', () {
    testWidgets('응원하기 아이콘 버튼이 목록에 바로 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const FriendManagePage()));
      await tester.pumpAndSettle();

      // favorite_outline 아이콘이 리스트에 존재해야 함
      expect(find.byIcon(Icons.favorite_outline), findsWidgets);
    });

    testWidgets('응원하기 버튼 탭 시 SnackBar가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const FriendManagePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.favorite_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('응원을 보냈어요!'), findsOneWidget);
    });

    testWidgets('PopupMenu에 프로필 보기와 친구 삭제만 있다 (응원하기 없음)', (tester) async {
      await tester.pumpWidget(_wrap(const FriendManagePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();

      expect(find.text('프로필 보기'), findsOneWidget);
      expect(find.text('친구 삭제'), findsOneWidget);
      expect(find.text('응원하기'), findsNothing);
    });

    testWidgets('친구 항목에 레벨 정보가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const FriendManagePage()));
      await tester.pumpAndSettle();

      expect(find.text('Lv.1'), findsWidgets);
    });
  });

  group('SocialPage - 요청 탭', () {
    testWidgets('요청 탭으로 전환할 수 있다', (tester) async {
      await tester.pumpWidget(_wrap(const FriendManagePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('요청'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsWidgets);
      expect(find.byIcon(Icons.close), findsWidgets);
    });

    testWidgets('수락 버튼 탭 시 SnackBar가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const FriendManagePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('요청'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check).first);
      await tester.pumpAndSettle();

      expect(find.text('친구 요청을 수락했습니다'), findsOneWidget);
    });

    testWidgets('거절 버튼 탭 시 SnackBar가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const FriendManagePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('요청'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.text('친구 요청을 거절했습니다'), findsOneWidget);
    });
  });

  group('SocialPage - 추천 탭', () {
    testWidgets('추천 탭으로 전환할 수 있다', (tester) async {
      await tester.pumpWidget(_wrap(const FriendManagePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('둘러보기'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_add), findsWidgets);
    });

    testWidgets('친구 요청 버튼 탭 시 SnackBar가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const FriendManagePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('둘러보기'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_add).first);
      await tester.pumpAndSettle();

      expect(find.text('친구 요청을 보냈습니다'), findsOneWidget);
    });

    testWidgets('비슷한 식습관 배지가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const FriendManagePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('둘러보기'));
      await tester.pumpAndSettle();

      expect(find.text('추천'), findsWidgets);
    });
  });
}
