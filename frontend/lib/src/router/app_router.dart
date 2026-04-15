import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/providers/common_providers.dart';
import '../core/widgets/main_shell.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/home/presentation/pages/home_page.dart';
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
import '../features/auth/presentation/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) async {
      // SecureStorage는 비동기이므로 redirect에서 직접 await 사용
      // 웹에서는 HTTPS가 아닐 경우 SharedPreferences 사용
      final String? token;
      if (kIsWeb) {
        token = prefs.getString(AppConstants.accessTokenKey);
      } else {
        token = await secureStorage.read(key: AppConstants.accessTokenKey);
      }
      
      final isLoggedIn = token != null || authState.user != null;
      final isAuthPath = state.matchedLocation == '/auth';

      if (!isLoggedIn && !isAuthPath) {
        return '/auth';
      }
      if (isLoggedIn && isAuthPath) {
        return '/home';
      }
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
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomePage(),
              routes: [
                GoRoute(
                  path: 'profile',
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
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/meal-record',
              name: 'meal-record',
              builder: (context, state) => const MealRecordPage(),
            ),
          ]),
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
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/social',
              name: 'social',
              builder: (context, state) => const SocialPage(),
            ),
          ]),
        ],
      ),
    ],
  );
});
