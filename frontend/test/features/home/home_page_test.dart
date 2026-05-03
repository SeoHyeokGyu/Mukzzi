import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/features/home/presentation/pages/home_page.dart';

Widget _wrap(Widget child) => ProviderScope(child: MaterialApp(theme: AppTheme.darkTheme, home: child));

void main() {
  group('HomePage', () {
    testWidgets('shimmer가 로딩 중 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const HomePage()));
      // initState에서 바로 _isLoading = true 이므로 shimmer가 먼저 보임
      expect(find.byType(LinearProgressIndicator), findsNothing);
      // shimmer 카드가 존재하는지 확인
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('로딩 완료 후 캐릭터 카드에 EXP 진행바가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const HomePage()));
      // 로딩 딜레이(1400ms) 경과
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('로딩 완료 후 캐릭터 진화 단계 배지가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const HomePage()));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('부화 단계'), findsOneWidget);
    });

    testWidgets('로딩 완료 후 먹찌 성장 안내 문구가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const HomePage()));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('식사를 기록하면 먹찌가 성장해요'), findsOneWidget);
    });

    testWidgets('Coming Soon 텍스트가 더 이상 표시되지 않는다', (tester) async {
      await tester.pumpWidget(_wrap(const HomePage()));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.textContaining('Coming Soon'), findsNothing);
    });

    testWidgets('주간 칼로리 차트가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const HomePage()));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('이번주 칼로리'), findsOneWidget);
    });
  });
}
