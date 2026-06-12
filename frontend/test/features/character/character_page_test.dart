import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mukzzi/src/core/network/api_client.dart';
import 'package:mukzzi/src/core/storage/token_storage.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/bento_card.dart';
import 'package:mukzzi/src/core/widgets/mukzzi_character.dart';
import 'package:mukzzi/src/features/character/data/models/character_model.dart';
import 'package:mukzzi/src/features/character/data/repositories/character_repository.dart';
import 'package:mukzzi/src/features/character/domain/models/title_model.dart';
import 'package:mukzzi/src/features/character/presentation/pages/character_page.dart';
import 'package:mukzzi/src/features/character/presentation/providers/character_provider.dart';
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
  Future<UserModel> getMe() async => _user;
}

class _FakeCharacterRepository extends CharacterRepository {
  _FakeCharacterRepository(this.character)
      : super(ApiClient(_FakeTokenStorage()));

  final CharacterModel character;

  @override
  Future<CharacterModel> getMyCharacter() async => character;
}

final _user = UserModel(
  id: 'user-1',
  username: 'tester',
  email: 'tester@example.com',
);

CharacterModel _character() {
  return const CharacterModel(
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
    equipment: {},
  );
}

Widget _wrap(_FakeCharacterRepository characterRepository) {
  final userRepository = _FakeUserRepository();

  return ProviderScope(
    overrides: [
      userRepositoryProvider.overrideWithValue(userRepository),
      userProvider.overrideWith(
        (ref) => UserNotifier(userRepository, initialUser: _user),
      ),
      characterRepositoryProvider.overrideWithValue(characterRepository),
      characterProvider.overrideWith(
        (ref) => characterRepository.getMyCharacter(),
      ),
      titleListProvider.overrideWith((ref) async => <TitleModel>[]),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: const CharacterPage(),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('CharacterPage', () {
    testWidgets('히어로 카드 없이 캐릭터가 화면폭 비례 크기로 표시된다', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(_FakeCharacterRepository(_character())));
      await tester.pump();

      final character =
          tester.widget<MukzziCharacter>(find.byType(MukzziCharacter));
      // 400 * 0.45 = 180 (clamp 150~200 범위 내)
      expect(character.size, 180.0);
      expect(character.backgroundEdgeFade, isTrue);

      // 히어로 카드 제거 — 남은 BentoCard는 섹션 카드 3개뿐
      // (영양 달성 / 장착 중 / 도감)
      expect(find.byType(BentoCard), findsNWidgets(3));
    });

    testWidgets('넓은 화면에서는 캐릭터 크기가 200px 상한으로 고정된다', (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(_FakeCharacterRepository(_character())));
      await tester.pump();

      final character =
          tester.widget<MukzziCharacter>(find.byType(MukzziCharacter));
      expect(character.size, 200.0);
    });
  });
}
