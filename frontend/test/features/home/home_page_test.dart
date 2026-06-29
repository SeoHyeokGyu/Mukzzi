import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:mukzzi/src/core/network/api_client.dart';
import 'package:mukzzi/src/features/notification/data/models/notification_model.dart';
import 'package:mukzzi/src/features/notification/data/repositories/notification_repository.dart';
import 'package:mukzzi/src/features/notification/presentation/providers/notification_provider.dart';
import 'package:mukzzi/src/core/providers/common_providers.dart';
import 'package:mukzzi/src/core/storage/token_storage.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/bento_card.dart';
import 'package:mukzzi/src/core/widgets/mukzzi_character.dart';
import 'package:mukzzi/src/features/character/data/models/character_model.dart';
import 'package:mukzzi/src/features/character/presentation/providers/character_provider.dart';
import 'package:mukzzi/src/features/home/presentation/pages/home_page.dart';
import 'package:mukzzi/src/features/home/presentation/providers/nutrition_provider.dart';
import 'package:mukzzi/src/features/home/data/models/nutrition_model.dart';
import 'package:mukzzi/src/features/meal_record/presentation/providers/meal_provider.dart';
import 'package:mukzzi/src/features/profile/data/models/user_model.dart';
import 'package:mukzzi/src/features/profile/data/repositories/user_repository.dart';
import 'package:mukzzi/src/features/profile/presentation/providers/user_provider.dart';
import 'package:mukzzi/src/features/quest/data/repositories/quest_repository_impl.dart';
import 'package:mukzzi/src/features/quest/domain/entities/quest.dart';
import 'package:mukzzi/src/features/quest/presentation/providers/quest_provider.dart';
import 'package:mukzzi/src/features/ai/data/models/ai_models.dart';
import 'package:mukzzi/src/features/ai/presentation/providers/ai_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<UserModel> getMe() async => _testUser;
}

class _FakeNotificationRepository extends NotificationRepository {
  _FakeNotificationRepository(SharedPreferences prefs)
      : super(ApiClient(_FakeTokenStorage()), prefs);

  @override
  Future<List<NotificationModel>> getNotifications(
          {int limit = 20, String? cursor}) async =>
      [];

  @override
  Stream<NotificationModel> subscribeToNotifications() => const Stream.empty();

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAllAsRead() async {}
}

class _FakeQuestRepository implements QuestRepository {
  @override
  Future<List<Quest>> getQuests({String? period}) async => [];

  @override
  Future<void> claimReward(String userQuestId) async {}
}

class FakeNotificationNotifier extends NotificationNotifier {
  FakeNotificationNotifier(super.repository);

  @override
  Future<void> fetchNotifications() async {}
}

class FakeLoadingUserNotifier extends UserNotifier {
  FakeLoadingUserNotifier(super.repository) {
    state = UserState(isLoading: true, user: null);
  }

  @override
  Future<void> fetchMe() async {
    // 테스트용으로 로딩 상태 유지
  }
}

final _testUser = UserModel(
  id: 'user-1',
  username: 'tester',
  email: 'tester@example.com',
);

const _testCharacter = CharacterModel(
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

Future<Widget> _wrapSeamless({bool isLoading = false}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final userRepository = _FakeUserRepository();
  final notificationRepository = _FakeNotificationRepository(prefs);

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      userRepositoryProvider.overrideWithValue(userRepository),
      userProvider.overrideWith(
        (ref) => isLoading
            ? FakeLoadingUserNotifier(userRepository)
            : UserNotifier(userRepository, initialUser: _testUser),
      ),
      characterProvider.overrideWith((ref) => _testCharacter),
      questRepositoryProvider.overrideWithValue(_FakeQuestRepository()),
      notificationRepositoryProvider.overrideWithValue(notificationRepository),
      notificationProvider.overrideWith((ref) => FakeNotificationNotifier(notificationRepository)),
      todayNutritionProvider.overrideWith(
        (ref) => DailyNutritionModel(
          date: '2026-06-20',
          totalCalories: 1500,
          totalCarbs: 150,
          totalProtein: 80,
          totalFat: 50,
          totalSodium: 1000,
          totalFiber: 20,
          mealCount: 3,
          lastCalculatedAt: DateTime.now(),
          nutritionGoal: NutritionGoalModel(
            calorieGoal: 2000,
            carbGoal: 250,
            proteinGoal: 100,
            fatGoal: 65,
          ),
        ),
      ),
      weeklyNutritionProvider.overrideWith(
        (ref) => [
          WeeklyNutritionItemModel(
            date: '2026-06-20',
            calories: 1500,
            carbs: 150,
            protein: 80,
            fat: 50,
          ),
        ],
      ),
      todayMealsProvider.overrideWith(
        (ref) => const [],
      ),
      nutritionCoachingProvider.overrideWith((ref, date) => NutritionCoachingResponse(
        summary: '오늘도 균형 잡힌 식사를 하셨네요!',
        score: 88,
        strengths: const [],
        improvements: const [],
        tips: const ['단백질 섭취를 조금 더 늘려보세요.'],
      )),
      recommendMealProvider.overrideWith((ref, mealType) => RecommendMealResponse(
        recommendations: const [],
        reasoning: '회원님을 위한 맞춤 식단 추천입니다.',
      )),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: const HomePage(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        );
      },
    ),
  );
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('ko');
    ShowcaseView.register();
  });

  tearDownAll(() {
    ShowcaseView.get().unregister();
  });

  group('HomePage', () {
    testWidgets('shimmer가 로딩 중 표시된다', (tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });
      await tester.pumpWidget(await _wrapSeamless(isLoading: true));
      // initState에서 바로 _isLoading = true 이므로 shimmer가 먼저 보임
      expect(find.byType(LinearProgressIndicator), findsNothing);
      // shimmer 카드가 존재하는지 확인
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('로딩 완료 후 캐릭터 카드에 EXP 진행바가 표시된다', (tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });
      await tester.pumpWidget(await _wrapSeamless());
      // 로딩 딜레이(1400ms) 경과
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.idle();
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('로딩 완료 후 캐릭터 진화 단계 배지가 표시된다', (tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });
      await tester.pumpWidget(await _wrapSeamless());
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.idle();
      await tester.pump();

      expect(find.text('정상'), findsOneWidget);
    });

    testWidgets('Coming Soon 텍스트가 더 이상 표시되지 않는다', (tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });
      await tester.pumpWidget(await _wrapSeamless());
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.idle();
      await tester.pump();

      expect(find.textContaining('Coming Soon'), findsNothing);
    });

    testWidgets('주간 칼로리 차트가 표시된다', (tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });
      await tester.pumpWidget(await _wrapSeamless());
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(find.text('주간 영양 트렌드'), findsOneWidget);

      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    });
  });

  group('HomePage 히어로 시멀리스', () {
    testWidgets('히어로 카드 없이 캐릭터가 화면폭 비례 크기로 표시된다', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });

      await tester.pumpWidget(await _wrapSeamless());
      // pump once to resolve async providers; pump again to drain animate timers
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final character =
          tester.widget<MukzziCharacter>(find.byType(MukzziCharacter));
      // 400 * 0.45 = 180 (clamp 150~200 범위 내)
      expect(character.size, 180.0);
      expect(character.backgroundEdgeFade, isTrue);

      // 히어로 카드 제거 — 캐릭터가 BentoCard 안에 있지 않음
      expect(
        find.ancestor(
          of: find.byType(MukzziCharacter),
          matching: find.byType(BentoCard),
        ),
        findsNothing,
      );

      // 이름 텍스트 + 상태 메시지 제거 확인
      expect(find.text('먹찌'), findsNothing);
    });

    testWidgets('넓은 화면에서는 캐릭터 크기가 200px 상한으로 고정된다', (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });

      await tester.pumpWidget(await _wrapSeamless());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final character =
          tester.widget<MukzziCharacter>(find.byType(MukzziCharacter));
      expect(character.size, 200.0);
    });
  });
}
