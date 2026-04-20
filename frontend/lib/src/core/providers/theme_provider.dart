import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common_providers.dart';

enum AppVariant { hybrid, light }

class ThemeNotifier extends StateNotifier<AppVariant> {
  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs)
      : super(
          _prefs.getString('theme_variant') == 'light'
              ? AppVariant.light
              : AppVariant.hybrid,
        );

  void setVariant(AppVariant variant) {
    state = variant;
    _prefs.setString('theme_variant', variant.name);
  }
}

final themeVariantProvider = StateNotifierProvider<ThemeNotifier, AppVariant>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});
