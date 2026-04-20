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
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        // 모바일 폭이면 그대로, 넓은 화면이면 430px 폰 프레임으로 중앙 고정
        if (mq.size.width <= 600) return child!;

        const maxWidth = 430.0;
        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            child: MediaQuery(
              data: mq.copyWith(size: Size(maxWidth, mq.size.height)),
              child: SizedBox(width: maxWidth, child: ClipRect(child: child!)),
            ),
          ),
        );
      },
    );
  }
}
