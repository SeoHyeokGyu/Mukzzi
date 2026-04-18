import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/providers/common_providers.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/main_shell.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/notification/presentation/pages/notification_list_page.dart';
import '../features/character/presentation/pages/character_page.dart';
import '../features/character/presentation/pages/badge_list_page.dart';
import '../features/character/presentation/pages/mastery_list_page.dart';
import '../features/character/presentation/pages/title_list_page.dart';
import '../features/character/presentation/pages/reward_list_page.dart';
import '../features/character/presentation/pages/character_collection_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/meal_record/presentation/pages/meal_record_page.dart';
import '../features/social/presentation/pages/social_page.dart';
import '../features/social/presentation/pages/other_profile_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

// authProvider 상태 변화를 GoRouter에 전달하는 ChangeNotifier.
// GoRouter 인스턴스는 재생성하지 않고 redirect만 재실행하게 한다.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/home',
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
      final authState = ref.read(authProvider);
      final String? token;
      if (kIsWeb) {
        token = prefs.getString(AppConstants.accessTokenKey);
      } else {
        token = await secureStorage.read(key: AppConstants.accessTokenKey);
      }

      final isLoggedIn = token != null || authState.user != null;
      final isAuthPath = state.matchedLocation == '/auth';

      if (!isLoggedIn && !isAuthPath) return '/auth';
      if (isLoggedIn && isAuthPath) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthPage(),
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
                  path: 'notifications',
                  name: 'notifications',
                  builder: (context, state) => const NotificationListPage(),
                ),
              ],
            ),
          ]),
          // 2. 식사 기록 탭
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/meal-record',
              name: 'meal-record',
              builder: (context, state) => const MealRecordPage(),
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
                  path: 'masteries',
                  name: 'character-masteries',
                  builder: (context, state) => const MasteryListPage(),
                ),
                GoRoute(
                  path: 'collection',
                  name: 'character-collection',
                  builder: (context, state) => const CharacterCollectionPage(),
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
                  path: 'profile/:userId',
                  name: 'other-profile',
                  builder: (context, state) => OtherProfilePage(
                    userId: state.pathParameters['userId']!,
                  ),
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
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
