import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/features/social/presentation/pages/social_page.dart';

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.darkTheme, home: child);

void main() {
  group('SocialPage - 친구 목록 탭', () {
    testWidgets('응원하기 아이콘 버튼이 목록에 바로 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const SocialPage()));

      // favorite_outline 아이콘이 리스트에 존재해야 함
      expect(find.byIcon(Icons.favorite_outline), findsWidgets);
    });

    testWidgets('응원하기 버튼 탭 시 SnackBar가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const SocialPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.favorite_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('응원을 보냈어요!'), findsOneWidget);
    });

    testWidgets('PopupMenu에 프로필 보기와 친구 삭제만 있다 (응원하기 없음)', (tester) async {
      await tester.pumpWidget(_wrap(const SocialPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();

      expect(find.text('프로필 보기'), findsOneWidget);
      expect(find.text('친구 삭제'), findsOneWidget);
      expect(find.text('응원하기'), findsNothing);
    });

    testWidgets('친구 항목에 레벨 정보가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const SocialPage()));

      expect(find.text('Lv.1'), findsWidgets);
    });
  });

  group('SocialPage - 요청 탭', () {
    testWidgets('요청 탭으로 전환할 수 있다', (tester) async {
      await tester.pumpWidget(_wrap(const SocialPage()));

      await tester.tap(find.text('요청'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsWidgets);
      expect(find.byIcon(Icons.close), findsWidgets);
    });

    testWidgets('수락 버튼 탭 시 SnackBar가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const SocialPage()));

      await tester.tap(find.text('요청'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check).first);
      await tester.pumpAndSettle();

      expect(find.text('친구 요청을 수락했습니다'), findsOneWidget);
    });

    testWidgets('거절 버튼 탭 시 SnackBar가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const SocialPage()));

      await tester.tap(find.text('요청'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.text('친구 요청을 거절했습니다'), findsOneWidget);
    });
  });

  group('SocialPage - 추천 탭', () {
    testWidgets('추천 탭으로 전환할 수 있다', (tester) async {
      await tester.pumpWidget(_wrap(const SocialPage()));

      await tester.tap(find.text('추천'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_add), findsWidgets);
    });

    testWidgets('친구 요청 버튼 탭 시 SnackBar가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const SocialPage()));

      await tester.tap(find.text('추천'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_add).first);
      await tester.pumpAndSettle();

      expect(find.text('친구 요청을 보냈습니다'), findsOneWidget);
    });

    testWidgets('비슷한 식습관 배지가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const SocialPage()));

      await tester.tap(find.text('추천'));
      await tester.pumpAndSettle();

      expect(find.text('비슷한 식습관'), findsWidgets);
    });
  });
}
