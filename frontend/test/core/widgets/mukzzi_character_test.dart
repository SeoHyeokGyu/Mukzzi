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
    });

    testWidgets('페이드 활성이어도 배경 미장착이면 ShaderMask가 없다', (tester) async {
      await _pumpCharacter(
        tester,
        equipment: const {},
        backgroundEdgeFade: true,
      );

      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('기본값(false)이면 배경을 장착해도 ShaderMask가 없다', (tester) async {
      await _pumpCharacter(
        tester,
        equipment: {EquipmentSlot.background: _backgroundReward()},
        backgroundEdgeFade: false,
      );

      expect(find.byType(ShaderMask), findsNothing);
    });
  });
}
