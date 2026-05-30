import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mukzzi/src/core/network/api_client.dart';
import 'package:mukzzi/src/core/storage/token_storage.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/mukzzi_character.dart';
import 'package:mukzzi/src/features/character/data/models/character_model.dart';
import 'package:mukzzi/src/features/character/data/repositories/character_repository.dart';
import 'package:mukzzi/src/features/character/domain/models/reward_model.dart';
import 'package:mukzzi/src/features/character/presentation/pages/equipment_management_page.dart';
import 'package:mukzzi/src/features/character/presentation/providers/character_provider.dart';
import 'package:mukzzi/src/features/character/presentation/providers/reward_provider.dart';
import 'package:mukzzi/src/features/profile/data/models/user_model.dart';
import 'package:mukzzi/src/features/profile/data/repositories/user_repository.dart';
import 'package:mukzzi/src/features/profile/presentation/providers/user_provider.dart';

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

class _FakeUserRepository extends UserRepository {
  _FakeUserRepository() : super(ApiClient(_FakeTokenStorage()));

  @override
  Future<UserModel> getMe() async => _adminUser;
}

class _FakeCharacterRepository extends CharacterRepository {
  _FakeCharacterRepository(this.character)
      : super(ApiClient(_FakeTokenStorage()));

  final CharacterModel character;
  final equipCalls = <({String slot, String? rewardId})>[];

  @override
  Future<CharacterModel> getMyCharacter() async => character;

  @override
  Future<void> equipItem({
    required String slot,
    required String? rewardId,
  }) async {
    equipCalls.add((slot: slot, rewardId: rewardId));
  }
}

final _adminUser = UserModel(
  id: 'admin-user',
  username: 'admin',
  email: 'admin@example.com',
);

RewardModel _reward({
  required String id,
  required String name,
  required EquipmentSlot slot,
  bool acquired = true,
}) {
  return RewardModel(
    id: id,
    rewardType: 'ACCESSORY',
    code: name,
    name: name,
    description: '$name description',
    assetUrl: 'https://example.com/$id.svg',
    acquired: acquired,
    renderConfig: RewardRenderConfig(
      slot: slot,
      offsetX: 0,
      offsetY: 0,
      scale: 1,
      rotation: 0,
      zIndex: 0,
    ),
  );
}

CharacterModel _character(
    {Map<EquipmentSlot, RewardModel> equipment = const {}}) {
  return CharacterModel(
    id: 'character-1',
    userId: 'user-1',
    name: '먹찌',
    state: CharacterState.normal,
    streakDays: 0,
    bodyType: 0,
    muscle: 0,
    skinTone: 0,
    expression: 0,
    nutritionAchievementDays: 0,
    equipment: equipment,
  );
}

Widget _wrap({
  required _FakeCharacterRepository characterRepository,
  required List<RewardModel> rewards,
}) {
  final userRepository = _FakeUserRepository();

  return ProviderScope(
    overrides: [
      userRepositoryProvider.overrideWithValue(userRepository),
      userProvider.overrideWith(
        (ref) => UserNotifier(userRepository, initialUser: _adminUser),
      ),
      characterRepositoryProvider.overrideWithValue(characterRepository),
      characterProvider.overrideWith(
        (ref) => characterRepository.getMyCharacter(),
      ),
      rewardListProvider.overrideWith((ref) async => rewards),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: const EquipmentManagementPage(),
    ),
  );
}

void main() {
  group('EquipmentManagementPage', () {
    testWidgets('전체 탭에는 모든 장착 보상이 보이고 머리 탭에는 HEAD 보상만 보인다', (tester) async {
      final headReward = _reward(
        id: '1',
        name: '머리 왕관',
        slot: EquipmentSlot.head,
      );
      final faceReward = _reward(
        id: '2',
        name: '얼굴 안경',
        slot: EquipmentSlot.face,
      );

      await tester.pumpWidget(
        _wrap(
          characterRepository: _FakeCharacterRepository(_character()),
          rewards: [headReward, faceReward],
        ),
      );
      await tester.pump();

      expect(find.text('머리 왕관'), findsOneWidget);
      expect(find.text('얼굴 안경'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, '머리'));
      await tester.pump();

      expect(find.text('머리 왕관'), findsOneWidget);
      expect(find.text('얼굴 안경'), findsNothing);
    });

    testWidgets('빈 슬롯 아이템을 누르면 HEAD 슬롯에 해당 보상을 장착한다', (tester) async {
      final headReward = _reward(
        id: '1',
        name: '머리 왕관',
        slot: EquipmentSlot.head,
      );
      final repository = _FakeCharacterRepository(_character());

      await tester.pumpWidget(
        _wrap(characterRepository: repository, rewards: [headReward]),
      );
      await tester.pump();

      await tester.tap(find.text('머리 왕관'));
      await tester.pump();

      expect(
        repository.equipCalls,
        [(slot: 'HEAD', rewardId: '1')],
      );
    });

    testWidgets('장착중 아이템을 누르면 해제하고 SnackBar 되돌리기로 재장착한다', (tester) async {
      final headReward = _reward(
        id: '1',
        name: '머리 왕관',
        slot: EquipmentSlot.head,
      );
      final repository = _FakeCharacterRepository(
        _character(equipment: {EquipmentSlot.head: headReward}),
      );

      await tester.pumpWidget(
        _wrap(characterRepository: repository, rewards: [headReward]),
      );
      await tester.pump();

      await tester.tap(find.text('머리 왕관'));
      await tester.pump();

      expect(
        repository.equipCalls,
        [(slot: 'HEAD', rewardId: null)],
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('되돌리기'), findsOneWidget);

      await tester.tap(find.byType(SnackBarAction));
      await tester.pump();

      expect(
        repository.equipCalls,
        [
          (slot: 'HEAD', rewardId: null),
          (slot: 'HEAD', rewardId: '1'),
        ],
      );
    });
  });
}
