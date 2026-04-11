import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/main_shell.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/character/presentation/pages/character_page.dart';
import '../features/character/presentation/pages/badge_list_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/meal_record/presentation/pages/meal_record_page.dart';
import '../features/social/presentation/pages/social_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthPage(),
      ),
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
        ],
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