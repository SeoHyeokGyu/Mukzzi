import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/features/meal_record/presentation/pages/meal_record_page.dart';

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.darkTheme, home: child);

void main() {
  group('MealRecordPage - 폼 순서', () {
    testWidgets('메뉴명 입력 필드가 가장 먼저 나타난다', (tester) async {
      await tester.pumpWidget(_wrap(const MealRecordPage()));

      // 기록 추가 탭이 기본
      final menuField = find.widgetWithText(TextField, '');
      expect(menuField, findsOneWidget);

      // 메뉴명 힌트가 첫 번째 TextField에 있어야 함
      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(textFields.isNotEmpty, isTrue);
      expect(textFields.first.decoration?.hintText, '예: 김치찌개');
    });

    testWidgets('날씨/기분 섹션에 선택사항 라벨이 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const MealRecordPage()));

      expect(find.text('선택사항'), findsOneWidget);
    });

    testWidgets('식사 종류 SegmentedButton이 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const MealRecordPage()));

      expect(find.text('아침'), findsOneWidget);
      expect(find.text('점심'), findsOneWidget);
      expect(find.text('저녁'), findsOneWidget);
      expect(find.text('간식'), findsOneWidget);
    });

    testWidgets('날씨 DropdownMenu가 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const MealRecordPage()));

      // DropdownMenu가 렌더링되는지 확인
      expect(find.byType(DropdownMenu<String>), findsNWidgets(2));
    });

    testWidgets('기록 저장 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(_wrap(const MealRecordPage()));

      expect(find.text('기록 저장'), findsOneWidget);
    });
  });

  group('MealRecordPage - 기록 목록 탭', () {
    testWidgets('기록 목록 탭으로 전환할 수 있다', (tester) async {
      await tester.pumpWidget(_wrap(const MealRecordPage()));

      await tester.tap(find.text('기록 목록'));
      await tester.pumpAndSettle();

      // mock 데이터(10개)가 있으므로 목록이 표시됨
      expect(find.text('김치찌개'), findsOneWidget);
    });

    testWidgets('식사 아이템 탭 시 상세 다이얼로그가 열린다', (tester) async {
      await tester.pumpWidget(_wrap(const MealRecordPage()));

      await tester.tap(find.text('기록 목록'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('김치찌개'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('닫기'), findsOneWidget);
    });

    testWidgets('날짜 포맷이 zero-padding 형식이다', (tester) async {
      await tester.pumpWidget(_wrap(const MealRecordPage()));

      await tester.tap(find.text('기록 목록'));
      await tester.pumpAndSettle();

      // 날짜 형식 확인: YYYY-MM-DD HH:mm 패턴
      final dateRegex = RegExp(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}');
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final hasFormattedDate = textWidgets.any(
        (w) => w.data != null && dateRegex.hasMatch(w.data!),
      );
      expect(hasFormattedDate, isTrue);
    });
  });
}
