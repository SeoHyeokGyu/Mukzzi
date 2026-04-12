import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/common_providers.dart';
import '../../../../core/network/exceptions.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../profile/data/models/user_model.dart';

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
  final SharedPreferences _prefs;

  AuthNotifier(this._repository, this._prefs) : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = _prefs.getString(AppConstants.accessTokenKey);
      if (token != null) {
        final user = await _repository.fetchMe();
        state = state.copyWith(user: user);
      }
    } on UnauthorizedException {
      // 401 인증 에러일 때만 세션 초기화
      await _prefs.remove(AppConstants.accessTokenKey);
      await _prefs.remove(AppConstants.userIdKey);
      state = AuthState();
    } catch (e) {
      // 일반적인 네트워크 에러 등은 토큰을 유지하고 상태만 업데이트
      state = state.copyWith(error: null); 
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.login(
        LoginRequest(username: username, password: password),
      );
      
      await _prefs.setString(AppConstants.accessTokenKey, response.token);
      await _prefs.setString(AppConstants.userIdKey, response.user.id);
      
      state = state.copyWith(user: response.user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e is AppException ? e.message : e.toString());
      return false;
    }
  }

  Future<bool> register(String username, String email, String password, String? nickname) async {
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
      state = state.copyWith(isLoading: false, error: e is AppException ? e.message : e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _prefs.remove(AppConstants.accessTokenKey);
    await _prefs.remove(AppConstants.userIdKey);
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(sharedPreferencesProvider),
  );
});
