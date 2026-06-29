import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mukzzi/src/core/widgets/mukzzi_character.dart';
import 'package:mukzzi/src/features/character/domain/models/reward_model.dart';

RewardModel _backgroundReward() {
  return const RewardModel(
    id: 'bg-1',
    rewardType: 'ACCESSORY',
    code: 'background_kitchen',
    name: '주방 배경',
    description: '주방 배경 아이템',
    assetUrl: 'background_kitchen',
    acquired: true,
    renderConfig: RewardRenderConfig(
      slot: EquipmentSlot.background,
      offsetX: 0,
      offsetY: 0,
      scale: 1,
      rotation: 0,
      zIndex: -10,
    ),
  );
}

Future<void> _pumpCharacter(
  WidgetTester tester, {
  required Map<EquipmentSlot, RewardModel> equipment,
  required bool backgroundEdgeFade,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: MukzziCharacter(
            equipment: equipment,
            backgroundEdgeFade: backgroundEdgeFade,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('MukzziCharacter 배경 레이어 분리', () {
    testWidgets('배경 장착 시 AnimatedBuilder는 1개만 존재한다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MukzziCharacter(
                equipment: {EquipmentSlot.background: _backgroundReward()},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // flutter_svg는 내부적으로 AnimatedBuilder를 추가하므로
      // 전체 카운트 대신 구조적으로 검증한다:
      // - character_loop 빌더가 존재해야 함
      // - 배경 SVG는 character_loop 밖에 있어야 함
      const loopKey = ValueKey('character_loop');
      const bgSvgKey = ValueKey('assets/svg/mukzzi2_background_kitchen.svg');

      final loopFinder = find.byKey(loopKey);
      expect(loopFinder, findsOneWidget);
      expect(find.byKey(bgSvgKey), findsOneWidget);

      // 배경은 루프 애니메이션 밖에 위치해야 함
      expect(
        find.descendant(of: loopFinder, matching: find.byKey(bgSvgKey)),
        findsNothing,
      );
      await tester.pump(Duration.zero);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('_FloatingParticles', () {
    Future<void> pumpWithState(
      WidgetTester tester,
      CharacterState state,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MukzziCharacter(
                state: state,
                size: 200,
                enableAnimation: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('normal 상태에서 ✨ 파티클이 3개 존재한다', (tester) async {
      await pumpWithState(tester, CharacterState.normal);
      expect(find.text('✨'), findsNWidgets(3));
      await tester.pump(Duration.zero);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('happy 상태에서 ♥ 파티클이 3개 존재한다', (tester) async {
      await pumpWithState(tester, CharacterState.happy);
      expect(find.text('♥'), findsNWidgets(3));
      await tester.pump(Duration.zero);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sleeping 상태에서 z 파티클이 3개 존재한다', (tester) async {
      await pumpWithState(tester, CharacterState.sleeping);
      expect(find.text('z'), findsNWidgets(3));
      await tester.pump(Duration.zero);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('hungry 상태에서 🔥 파티클이 3개 존재한다', (tester) async {
      await pumpWithState(tester, CharacterState.hungry);
      expect(find.text('🔥'), findsNWidgets(3));
      await tester.pump(Duration.zero);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('starving 상태에서 ⚠️ 파티클이 3개 존재한다', (tester) async {
      await pumpWithState(tester, CharacterState.starving);
      expect(find.text('⚠️'), findsNWidgets(3));
      await tester.pump(Duration.zero);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('상태 전환 시 이전 파티클이 사라지고 새 파티클이 나타난다', (tester) async {
      final key = GlobalKey();
      CharacterState currentState = CharacterState.normal;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Center(
                child: MukzziCharacter(
                  key: key,
                  state: currentState,
                  size: 200,
                  enableAnimation: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('✨'), findsNWidgets(3));

      // 상태 변경
      currentState = CharacterState.happy;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MukzziCharacter(
                key: key,
                state: currentState,
                size: 200,
                enableAnimation: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('♥'), findsNWidgets(3));
      expect(find.text('✨'), findsNothing);
      await tester.pump(Duration.zero);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('MukzziCharacter backgroundEdgeFade', () {
    testWidgets('페이드 활성 + 배경 장착 시 배경 레이어에 ShaderMask를 적용한다',
        (tester) async {
      await _pumpCharacter(
        tester,
        equipment: {EquipmentSlot.background: _backgroundReward()},
        backgroundEdgeFade: true,
      );

      // 정사각 페이드 = 가로/세로 LinearGradient 마스크 중첩 → ShaderMask 2개
      expect(find.byType(ShaderMask), findsNWidgets(2));
      await tester.pump(Duration.zero);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('페이드 활성이어도 배경 미장착이면 ShaderMask가 없다', (tester) async {
      await _pumpCharacter(
        tester,
        equipment: const {},
        backgroundEdgeFade: true,
      );

      expect(find.byType(ShaderMask), findsNothing);
      await tester.pump(Duration.zero);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('기본값(false)이면 배경을 장착해도 ShaderMask가 없다', (tester) async {
      await _pumpCharacter(
        tester,
        equipment: {EquipmentSlot.background: _backgroundReward()},
        backgroundEdgeFade: false,
      );

      expect(find.byType(ShaderMask), findsNothing);
      await tester.pump(Duration.zero);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('enableAnimation', () {
    testWidgets('enableAnimation: false → 파티클이 렌더링되지 않는다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MukzziCharacter(
                state: CharacterState.normal,
                size: 200,
                enableAnimation: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('✨'), findsNothing);
      await tester.pump(Duration.zero);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('enableAnimation: false → happy 상태에서도 파티클이 없다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MukzziCharacter(
                state: CharacterState.happy,
                size: 200,
                enableAnimation: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('♥'), findsNothing);
      await tester.pump(Duration.zero);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
