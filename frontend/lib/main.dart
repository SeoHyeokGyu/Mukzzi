import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/router/app_router.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/providers/common_providers.dart';
import 'src/core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko');
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MukzziApp(),
    ),
  );
}

class MukzziApp extends ConsumerWidget {
  const MukzziApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final variant = ref.watch(themeVariantProvider);

    return MaterialApp.router(
      title: 'Mukzzi',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.hybridTheme,
      themeMode: variant == AppVariant.light ? ThemeMode.light : ThemeMode.dark,
      routerConfig: router,
    );
  }
}
