import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/exceptions.dart';
import '../../../../core/providers/common_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/user_model.dart';
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

  Future<void> fetchMe() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.getMe();
      state = state.copyWith(user: user, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '알 수 없는 오류가 발생했습니다.');
    }
  }

  Future<bool> updateProfile(String id, UserUpdateRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.updateProfile(id, request);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '수정 중 오류가 발생했습니다.');
      return false;
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final authState = ref.watch(authProvider);
  return UserNotifier(
    ref.watch(userRepositoryProvider),
    initialUser: authState.user,
  );
});
