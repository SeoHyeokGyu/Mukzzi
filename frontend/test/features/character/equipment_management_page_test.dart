import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mukzzi/src/core/network/api_client.dart';
import 'package:mukzzi/src/core/storage/token_storage.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/mukzzi_character.dart';
import 'package:mukzzi/src/features/character/data/models/character_model.dart';
import 'package:mukzzi/src/features/character/data/repositories/character_repository.dart';
import 'package:mukzzi/src/features/character/domain/models/reward_model.dart';
import 'package:mukzzi/src/features/character/domain/models/title_model.dart';
import 'package:mukzzi/src/features/character/data/repositories/title_repository.dart';
import 'package:mukzzi/src/features/character/presentation/pages/equipment_management_page.dart';
import 'package:mukzzi/src/features/character/presentation/providers/character_provider.dart';
import 'package:mukzzi/src/features/character/presentation/providers/reward_provider.dart';
import 'package:mukzzi/src/features/character/presentation/providers/title_provider.dart';
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

class _FakeTitleRepository extends TitleRepository {
  _FakeTitleRepository() : super(ApiClient(_FakeTokenStorage()));

  @override
  Future<List<TitleModel>> getTitles() async => [];

  @override
  Future<void> equipTitle(String? titleId) async {}
}

class _FailingCharacterRepository extends _FakeCharacterRepository {
  _FailingCharacterRepository(super.character);

  @override
  Future<void> equipItem({
    required String slot,
    required String? rewardId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1));
    throw Exception('Network Error');
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

TitleModel _title({
  required String id,
  required String name,
  bool acquired = true,
  bool isEquipped = false,
}) {
  return TitleModel(
    id: id,
    code: name,
    name: name,
    description: '$name 설명',
    acquired: acquired,
    isEquipped: isEquipped,
  );
}

Widget _wrap({
  required _FakeCharacterRepository characterRepository,
  required List<RewardModel> rewards,
  List<TitleModel> titles = const [],
  GoRouter? router,
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
      titleRepositoryProvider.overrideWithValue(_FakeTitleRepository()),
      titleListProvider.overrideWith((ref) async => titles),
    ],
    child: router != null
        ? MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          )
        : MaterialApp(
            theme: AppTheme.darkTheme,
            home: const EquipmentManagementPage(),
          ),
  );
}

void main() {
  group('MukzziCharacter', () {
    test('지원하는 장비 asset key만 SVG asset으로 렌더링한다', () {
      expect(MukzziCharacter.isSupportedEquipmentAsset('cap'), isTrue);
      expect(MukzziCharacter.isSupportedEquipmentAsset('glasses'), isTrue);
      expect(
        MukzziCharacter.isSupportedEquipmentAsset(
          'https://example.com/head.svg',
        ),
        isFalse,
      );
      expect(MukzziCharacter.isSupportedEquipmentAsset('unknown'), isFalse);
    });

    test('웹 asset 존재 확인은 HTML fallback 응답을 SVG로 취급하지 않는다', () {
      expect(
        MukzziCharacter.isSvgHttpResponse(
          statusCode: 200,
          contentType: 'image/svg+xml',
          body: '<svg viewBox="0 0 10 10"></svg>',
        ),
        isTrue,
      );
      expect(
        MukzziCharacter.isSvgHttpResponse(
          statusCode: 200,
          contentType: 'text/html',
          body: '<!DOCTYPE html><html></html>',
        ),
        isFalse,
      );
      expect(
        MukzziCharacter.isSvgHttpResponse(
          statusCode: 404,
          contentType: 'image/svg+xml',
          body: '<svg viewBox="0 0 10 10"></svg>',
        ),
        isFalse,
      );
    });
  });

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

    testWidgets('획득한 아이템만 보기 토글이 기본 활성화되어 미획득 아이템은 숨겨지고 해제 시 노출된다',
        (tester) async {
      final acquiredReward = _reward(
          id: '1', name: '획득 왕관', slot: EquipmentSlot.head, acquired: true);
      final lockedReward = _reward(
          id: '2', name: '잠금 안경', slot: EquipmentSlot.face, acquired: false);

      await tester.pumpWidget(
        _wrap(
          characterRepository: _FakeCharacterRepository(_character()),
          rewards: [acquiredReward, lockedReward],
        ),
      );
      await tester.pump();

      // 기본 활성화 상태이므로 획득한 것만 보여야 함
      expect(find.text('획득 왕관'), findsOneWidget);
      expect(find.text('잠금 안경'), findsNothing);

      // 토글 버튼을 탭하여 비활성화
      await tester.tap(find.text('획득한 아이템만'));
      await tester.pump();

      // 이제 미획득 아이템도 노출되어야 함
      expect(find.text('획득 왕관'), findsOneWidget);
      expect(find.text('잠금 안경'), findsOneWidget);
    });

    testWidgets('미획득 아이템 카드에는 획득처로의 이동 유도 버튼이 표시된다', (tester) async {
      final lockedReward = _reward(
          id: '2', name: '잠금 안경', slot: EquipmentSlot.face, acquired: false);

      final router = GoRouter(
        initialLocation: '/equipment',
        routes: [
          GoRoute(
            path: '/equipment',
            builder: (context, state) => const EquipmentManagementPage(),
          ),
          GoRoute(
            path: '/collection',
            builder: (context, state) => const Scaffold(body: Text('도감 화면')),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          characterRepository: _FakeCharacterRepository(_character()),
          rewards: [lockedReward],
          router: router,
        ),
      );
      await tester.pump();

      // 획득 필터 해제
      await tester.tap(find.text('획득한 아이템만'));
      await tester.pump();

      // 자물쇠 아이콘 및 이동 버튼 검증
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('획득하러 가기 →'), findsOneWidget);

      // 이동 버튼 탭
      await tester.tap(find.text('획득하러 가기 →'));
      await tester.pumpAndSettle();

      // 도감 화면으로 이동했는지 검증
      expect(find.text('도감 화면'), findsOneWidget);
    });

    testWidgets('프리뷰는 카드·이름 없이 캐릭터만 표시하고 큰 화면에서 130px 상한을 적용한다',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          characterRepository: _FakeCharacterRepository(_character()),
          rewards: [
            _reward(id: '1', name: '머리 왕관', slot: EquipmentSlot.head),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(MukzziCharacter), findsOneWidget);
      // 프리뷰에 캐릭터 이름 텍스트 없음
      expect(find.text('먹찌'), findsNothing);

      final preview =
          tester.widget<MukzziCharacter>(find.byType(MukzziCharacter));
      expect(preview.size, 130.0);
      expect(preview.backgroundEdgeFade, isTrue);
    });

    testWidgets('중간 화면에서는 프리뷰 크기가 가용 높이에 비례한다', (tester) async {
      tester.view.physicalSize = const Size(800, 660);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          characterRepository: _FakeCharacterRepository(_character()),
          rewards: [
            _reward(id: '1', name: '머리 왕관', slot: EquipmentSlot.head),
          ],
        ),
      );
      await tester.pump();

      final preview =
          tester.widget<MukzziCharacter>(find.byType(MukzziCharacter));
      expect(preview.size, greaterThan(80.0));
      expect(preview.size, lessThan(130.0));
    });

    testWidgets('가용 높이가 380 미만이면 프리뷰를 숨긴다', (tester) async {
      tester.view.physicalSize = const Size(800, 430);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          characterRepository: _FakeCharacterRepository(_character()),
          rewards: [
            _reward(id: '1', name: '머리 왕관', slot: EquipmentSlot.head),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(MukzziCharacter), findsNothing);
    });

    testWidgets('장착 실패 시 상태가 롤백되고 에러 스낵바가 뜬다', (tester) async {
      final headReward =
          _reward(id: '1', name: '머리 왕관', slot: EquipmentSlot.head);
      final failingRepo = _FailingCharacterRepository(_character());

      await tester.pumpWidget(
        _wrap(characterRepository: failingRepo, rewards: [headReward]),
      );
      await tester.pump();

      // 탭하여 장착 시도
      await tester.tap(find.text('장착'));

      // API 완료 전 즉각 장착 반영 검증 (낙관적 업데이트 확인)
      await tester.pump();
      expect(find.text('장착중'), findsOneWidget);

      // 1ms의 딜레이에 대응하여 롤백 진행 대기
      await tester.pump(const Duration(milliseconds: 1));
      // 프레임 진행하여 네트워크 에러 처리 완료
      await tester.pumpAndSettle();

      // 실패 후 롤백되어 다시 '장착' 버튼이 보이고 스낵바 에러가 떠야 함
      expect(find.text('장착'), findsOneWidget);
      expect(find.text('장착에 실패했습니다.'), findsOneWidget);
    });

    testWidgets('알 수 없는 장비 assetUrl은 SVG 로드를 시도하지 않는다', (tester) async {
      final invalidReward = _reward(
        id: 'head',
        name: '외부 URL 왕관',
        slot: EquipmentSlot.head,
      );
      final repository = _FakeCharacterRepository(
        _character(equipment: {EquipmentSlot.head: invalidReward}),
      );

      await tester.pumpWidget(
        _wrap(characterRepository: repository, rewards: [invalidReward]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('칭호-아이템 통합', () {
    testWidgets('initialTab=title이면 칭호 칩이 선택되고 칭호 리스트가 보인다', (tester) async {
      final title1 = _title(id: 't1', name: '미식가', isEquipped: true);
      final title2 = _title(id: 't2', name: '연속 도전자');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
            userProvider.overrideWith(
              (ref) => UserNotifier(_FakeUserRepository(), initialUser: _adminUser),
            ),
            characterRepositoryProvider
                .overrideWithValue(_FakeCharacterRepository(_character())),
            characterProvider.overrideWith(
              (ref) => _FakeCharacterRepository(_character()).getMyCharacter(),
            ),
            rewardListProvider.overrideWith((ref) async => <RewardModel>[]),
            titleRepositoryProvider.overrideWithValue(_FakeTitleRepository()),
            titleListProvider.overrideWith((ref) async => [title1, title2]),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const EquipmentManagementPage(initialTab: 'title'),
          ),
        ),
      );
      await tester.pump();

      // 칭호 칩이 선택 상태
      final titleChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '칭호'),
      );
      expect(titleChip.selected, isTrue);

      // 칭호 이름 보임
      expect(find.text('미식가'), findsOneWidget);
      expect(find.text('연속 도전자'), findsOneWidget);
    });

    testWidgets('칭호 칩 탭 시 칭호 리스트로 전환된다', (tester) async {
      final title1 = _title(id: 't1', name: '미식가');
      final headReward = _reward(id: '1', name: '머리 왕관', slot: EquipmentSlot.head);

      await tester.pumpWidget(
        _wrap(
          characterRepository: _FakeCharacterRepository(_character()),
          rewards: [headReward],
          titles: [title1],
        ),
      );
      await tester.pump();

      // 아이템 먼저 보임
      expect(find.text('머리 왕관'), findsOneWidget);

      // 칭호 칩 탭
      await tester.tap(find.widgetWithText(ChoiceChip, '칭호'));
      await tester.pump();

      // 칭호 보이고 아이템 카드 없음
      expect(find.text('미식가'), findsOneWidget);
      expect(find.text('머리 왕관'), findsNothing);
    });

    testWidgets('칭호 선택 후 아이템 칩 탭 시 그리드로 전환된다', (tester) async {
      final title1 = _title(id: 't1', name: '미식가');
      final headReward = _reward(id: '1', name: '머리 왕관', slot: EquipmentSlot.head);

      await tester.pumpWidget(
        _wrap(
          characterRepository: _FakeCharacterRepository(_character()),
          rewards: [headReward],
          titles: [title1],
        ),
      );
      await tester.pump();

      // 칭호 칩 탭
      await tester.tap(find.widgetWithText(ChoiceChip, '칭호'));
      await tester.pump();
      expect(find.text('미식가'), findsOneWidget);

      // 전체 칩 탭 (아이템 전체)
      await tester.tap(find.widgetWithText(ChoiceChip, '전체'));
      await tester.pump();

      // 칭호 없고 아이템 그리드
      expect(find.text('미식가'), findsNothing);
      expect(find.text('머리 왕관'), findsOneWidget);
    });

    testWidgets('칭호 모드와 아이템 모드 모두에서 MukzziCharacter가 표시된다', (tester) async {
      await tester.pumpWidget(
        _wrap(
          characterRepository: _FakeCharacterRepository(_character()),
          rewards: [],
        ),
      );
      await tester.pump();

      // 아이템 모드: MukzziCharacter 표시
      expect(find.byType(MukzziCharacter), findsOneWidget);

      // 칭호 모드 전환
      await tester.tap(find.widgetWithText(ChoiceChip, '칭호'));
      await tester.pump();

      // 칭호 모드에서도 MukzziCharacter 표시
      expect(find.byType(MukzziCharacter), findsOneWidget);
    });
  });
}
