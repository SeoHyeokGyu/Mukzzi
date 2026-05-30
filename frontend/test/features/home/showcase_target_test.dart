import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mukzzi/src/features/home/presentation/pages/home_page.dart';

void main() {
  testWidgets('쇼케이스 대상이 아직 트리에 없으면 준비되지 않은 상태로 본다', (tester) async {
    final key = GlobalKey();

    expect(isShowcaseTargetReady(key), isFalse);
  });

  testWidgets('쇼케이스 대상이 레이아웃된 뒤에만 준비된 상태로 본다', (tester) async {
    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(key: key, width: 80, height: 40),
        ),
      ),
    );

    expect(isShowcaseTargetReady(key), isTrue);
  });
}
