import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mukzzi/src/core/constants/app_constants.dart';
import 'package:mukzzi/src/core/providers/common_providers.dart';
import 'package:mukzzi/src/core/network/exceptions.dart';
import 'package:mukzzi/src/core/storage/token_storage.dart';
import 'package:mukzzi/src/features/auth/data/models/auth_models.dart';
import 'package:mukzzi/src/features/auth/data/repositories/auth_repository.dart';
import 'package:mukzzi/src/features/profile/data/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final TokenStorage _tokenStorage;
  final SharedPreferences _prefs;

  AuthNotifier(this._repository, this._tokenStorage, this._prefs)
      : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _tokenStorage.read(AppConstants.accessTokenKey);
      if (token != null) {
        final user = await _repository.fetchMe();
        state = state.copyWith(user: user);
      }
    } on UnauthorizedException {
      await _clearTokens();
      state = AuthState();
    } catch (_) {
      state = state.copyWith(error: null);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> login(String identity, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final isEmail = identity.contains('@');
      final response = await _repository.login(
        LoginRequest(
          username: isEmail ? null : identity,
          email: isEmail ? identity : null,
          password: password,
        ),
      );

      await _tokenStorage.write(
          AppConstants.accessTokenKey, response.accessToken);
      await _tokenStorage.write(
          AppConstants.refreshTokenKey, response.refreshToken);
      await _prefs.setString(AppConstants.userIdKey, response.user.id);

      state = state.copyWith(user: response.user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is AppException ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<bool> register(
      String username, String email, String password, String? nickname) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.register(
        RegisterRequest(
          username: username,
          email: email,
          password: password,
          nickname: nickname,
        ),
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is AppException ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {}
    await _clearTokens();
    state = AuthState();
  }

  // API에서 refresh 실패 시 호출 — API 호출 없이 상태만 초기화한다.
  Future<void> forceLogout() async {
    await _clearTokens();
    state = AuthState();
  }

  Future<void> _clearTokens() async {
    await _tokenStorage.deleteAll([
      AppConstants.accessTokenKey,
      AppConstants.refreshTokenKey,
    ]);
    await _prefs.remove(AppConstants.userIdKey);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(sharedPreferencesProvider),
  );

  // ApiClient의 refresh 실패 이벤트를 수신해 강제 로그아웃 처리한다.
  ref.listen(forceLogoutEventProvider, (previous, next) {
    if (next > (previous ?? 0)) unawaited(notifier.forceLogout());
  });

  return notifier;
});
