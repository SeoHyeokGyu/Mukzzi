import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/providers/common_providers.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/main_shell.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/settings/presentation/pages/admin_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/quest/presentation/pages/quest_list_page.dart';
import '../features/notification/presentation/pages/notification_list_page.dart';
import '../features/character/presentation/pages/character_page.dart';
import '../features/character/presentation/pages/badge_list_page.dart';
import '../features/character/presentation/pages/mastery_list_page.dart';
import '../features/character/presentation/pages/title_list_page.dart';
import '../features/character/presentation/pages/reward_list_page.dart';
import '../features/character/presentation/pages/character_collection_page.dart';
import '../features/profile/presentation/pages/onboarding_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/meal_record/presentation/pages/meal_record_page.dart';
import '../features/meal_record/presentation/pages/meal_calendar_page.dart';
import '../features/social/presentation/pages/social_page.dart';
import '../features/social/presentation/pages/other_profile_page.dart';
import '../features/social/presentation/pages/guestbook_list_page.dart';
import '../features/settings/presentation/pages/privacy_policy_page.dart';
import '../features/settings/presentation/pages/terms_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/profile/presentation/providers/user_provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
    ref.listen<UserState>(userProvider, (_, __) => notifyListeners());
    ref.listen<bool>(isAppInitializedProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: AppColors.orange),
            const SizedBox(height: 24),
            Text(
              '페이지를 찾을 수 없습니다',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    ),
    redirect: (context, state) async {
      final isInitialized = ref.read(isAppInitializedProvider);
      final isSplashPath = state.matchedLocation == '/splash';

      if (!isInitialized) {
        return isSplashPath ? null : '/splash';
      }

      final authState = ref.read(authProvider);
      final userState = ref.read(userProvider);
      final token = await tokenStorage.read(AppConstants.accessTokenKey);

      final currentUser = userState.user ?? authState.user;
      final isLoggedIn = token != null || currentUser != null;
      final isAuthPath = state.matchedLocation == '/auth';
      final isOnboardingPath = state.matchedLocation == '/onboarding';

      if (isInitialized && isSplashPath) {
        if (!isLoggedIn) return '/auth';
        if (currentUser != null && !currentUser.isOnboarded) return '/onboarding';
        return '/home';
      }

      if (!isLoggedIn && !isAuthPath) return '/auth';
      if (isLoggedIn && isAuthPath) return '/home';

      if (isLoggedIn && currentUser != null) {
        if (currentUser.isOnboarded && isOnboardingPath) return '/home';
        if (!currentUser.isOnboarded && !isOnboardingPath) return '/onboarding';

        // 관리자 페이지 접근 제한 (비관리자가 직접 URL 입력 시 차단)
        if (state.matchedLocation.startsWith('/profile/settings/admin') &&
            !currentUser.isAdmin) {
          return '/profile/settings';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // 1. 홈 탭
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomePage(),
              routes: [
                GoRoute(
                  path: 'quests',
                  name: 'quests',
                  builder: (context, state) => const QuestListPage(),
                ),
              ],
            ),
          ]),
          // 2. 식사 기록 탭
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/meal-record',
              name: 'meal-record',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return MealRecordPage(
                  initialMenuName: extra?['initialMenuName'] as String?,
                  initialCategory: extra?['initialCategory'] as String?,
                  initialCalories: extra?['initialCalories'] as double?,
                  initialCarbs: extra?['initialCarbs'] as double?,
                  initialProtein: extra?['initialProtein'] as double?,
                  initialFat: extra?['initialFat'] as double?,
                );
              },
              routes: [
                GoRoute(
                  path: 'masteries',
                  name: 'meal-masteries',
                  builder: (context, state) => const MasteryListPage(),
                ),
                GoRoute(
                  path: 'calendar',
                  name: 'meal-calendar',
                  builder: (context, state) => const MealCalendarPage(),
                ),
              ],
            ),
          ]),
          // 3. 먹찌(캐릭터) 탭
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/character',
              name: 'character',
              builder: (context, state) => const CharacterPage(),
              routes: [
                GoRoute(
                  path: 'collection',
                  name: 'character-collection',
                  builder: (context, state) => const CharacterCollectionPage(),
                ),
                GoRoute(
                  path: 'titles',
                  name: 'character-titles',
                  builder: (context, state) => const TitleListPage(),
                ),
                GoRoute(
                  path: 'rewards',
                  name: 'character-rewards',
                  builder: (context, state) => const RewardListPage(),
                ),
              ],
            ),
          ]),
          // 4. 소셜 탭
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/social',
              name: 'social',
              builder: (context, state) => const SocialPage(),
              routes: [
                GoRoute(
                  path: 'friends',
                  name: 'social-friends',
                  builder: (context, state) => const FriendManagePage(),
                ),
                GoRoute(
                  path: 'profile/:userId',
                  name: 'other-profile',
                  builder: (context, state) => OtherProfilePage(
                    userId: state.pathParameters['userId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'guestbook',
                      name: 'guestbook-list',
                      builder: (context, state) {
                        final userId = state.pathParameters['userId']!;
                        final nickname = state.uri.queryParameters['nickname'] ?? '사용자';
                        return GuestbookListPage(userId: userId, nickname: nickname);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ]),
          // 5. 프로필 탭
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfilePage(),
              routes: [
                GoRoute(
                  path: 'badges',
                  name: 'profile-badges',
                  builder: (context, state) => const BadgeListPage(),
                ),
                GoRoute(
                  path: 'edit',
                  name: 'profile-edit',
                  builder: (context, state) => const EditProfilePage(),
                ),
                GoRoute(
                  path: 'titles',
                  name: 'profile-titles',
                  builder: (context, state) => const TitleListPage(),
                ),
                GoRoute(
                  path: 'rewards',
                  name: 'profile-rewards',
                  builder: (context, state) => const RewardListPage(),
                ),
                GoRoute(
                  path: 'settings',
                  name: 'profile-settings',
                  builder: (context, state) => const SettingsPage(),
                  routes: [
                    GoRoute(
                      path: 'privacy',
                      name: 'privacy-policy',
                      builder: (context, state) => const PrivacyPolicyPage(),
                    ),
                    GoRoute(
                      path: 'terms',
                      name: 'terms-of-service',
                      builder: (context, state) => const TermsPage(),
                    ),
                    // ── 관리자 전용 ──
                    GoRoute(
                      path: 'admin',
                      name: 'admin',
                      builder: (context, state) => const AdminPage(),
                    ),
                  ],
                ),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationListPage(),
      ),
    ],
  );
});