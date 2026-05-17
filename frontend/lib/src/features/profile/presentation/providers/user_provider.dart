import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/exceptions.dart';
import '../../../../core/providers/common_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/user_model.dart';
import '../../data/models/user_stats_model.dart';
import '../../data/models/onboarding_request.dart';
import '../../data/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(apiClientProvider));
});

class UserState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  UserState({this.user, this.isLoading = false, this.error});

  UserState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final UserRepository _repository;

  UserNotifier(this._repository, {UserModel? initialUser}) 
      : super(UserState(user: initialUser));

  // Auth 상태 변경 시 호출될 메서드 — copyWith은 null을 무시하므로 직접 할당한다.
  void updateUserInfo(UserModel? user) {
    if (mounted) {
      state = UserState(user: user, isLoading: state.isLoading, error: state.error);
    }
  }

  Future<void> fetchMe() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.getMe();
      if (!mounted) return;
      state = state.copyWith(user: user, isLoading: false);
    } on AppException catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: '알 수 없는 오류가 발생했습니다.');
    }
  }

  Future<bool> updateProfile(UserUpdateRequest request) async {
    if (!mounted) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.updateProfile(request);
      if (!mounted) return true;
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on AppException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isLoading: false, error: '수정 중 오류가 발생했습니다.');
      return false;
    }
  }

  Future<bool> updateNotificationSettings(Map<String, bool> settings) async {
    if (!mounted) return false;
    try {
      final user = await _repository.updateNotificationSettings(settings);
      if (!mounted) return false;
      state = state.copyWith(user: user);
      return true;
    } on AppException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(error: e.message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(error: '설정 저장 중 오류가 발생했습니다.');
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    if (!mounted) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteAccount();
      if (!mounted) return true;
      state = UserState(); // 상태 초기화
      return true;
    } on AppException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isLoading: false, error: '탈퇴 중 오류가 발생했습니다.');
      return false;
    }
  }

  Future<bool> onboarding(OnboardingRequest request) async {
    if (!mounted) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.onboarding(request);
      // 온보딩 완료 후 유저 정보 갱신
      await fetchMe();
      return true;
    } on AppException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isLoading: false, error: '온보딩 중 오류가 발생했습니다.');
      return false;
    }
  }
}

final userStatsProvider = FutureProvider<UserStatsModel>((ref) {
  return ref.watch(userRepositoryProvider).getStats();
});

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  final authState = ref.watch(authProvider);
  
  final notifier = UserNotifier(
    repository,
    initialUser: authState.user,
  );

  // Auth 유저 정보가 비동기로 로드되거나 변경될 때 UserNotifier 에 알려줌
  ref.listen(authProvider, (previous, next) {
    if (next.user != previous?.user) {
      notifier.updateUserInfo(next.user);
    }
  });

  return notifier;
});
