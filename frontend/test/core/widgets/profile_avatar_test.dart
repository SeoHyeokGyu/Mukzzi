import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mukzzi/src/core/widgets/profile_avatar.dart';

void main() {
  group('ProfileAvatar', () {
    testWidgets('profileImageUrl null → Icons.person 노출', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(profileImageUrl: null),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.person), findsOneWidget);
      await tester.pump(Duration.zero);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('profileImageUrl 빈 문자열 → Icons.person 노출', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(profileImageUrl: ''),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.person), findsOneWidget);
      await tester.pump(Duration.zero);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('profileImageUrl 있음 → Icons.person 미노출', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(
              profileImageUrl: 'https://example.com/img.jpg',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.person), findsNothing);
      await tester.pump(Duration.zero);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('radius 파라미터가 CircleAvatar에 적용된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(profileImageUrl: null, radius: 40),
          ),
        ),
      );
      await tester.pump();

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.radius, 40.0);
      await tester.pump(Duration.zero);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
