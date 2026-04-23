import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/common_providers.dart';
import '../../data/models/favorite_model.dart';
import '../../data/models/menu_model.dart';
import '../../data/repositories/favorite_repository.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(ref.watch(apiClientProvider));
});

// ── 즐겨찾기 목록 상태 ──

class FavoriteListState {
  final List<FavoriteModel> favorites;
  final bool isLoading;
  final String? error;

  const FavoriteListState({
    this.favorites = const [],
    this.isLoading = false,
    this.error,
  });

  FavoriteListState copyWith({
    List<FavoriteModel>? favorites,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      FavoriteListState(
        favorites: favorites ?? this.favorites,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );

  /// 즐겨찾기 여부 확인
  bool isFavorite(String menuId) =>
      favorites.any((f) => f.menu.id == menuId);
}

class FavoriteListNotifier extends StateNotifier<FavoriteListState> {
  final FavoriteRepository _repository;

  FavoriteListNotifier(this._repository) : super(const FavoriteListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final favorites = await _repository.getList();
      state = state.copyWith(favorites: favorites, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 즐겨찾기 토글 — 낙관적 업데이트 후 API 호출
  Future<void> toggle(MenuModel menu) async {
    final isFav = state.isFavorite(menu.id);

    // 낙관적 업데이트
    if (isFav) {
      state = state.copyWith(
        favorites: state.favorites.where((f) => f.menu.id != menu.id).toList(),
      );
    } else {
      // 임시 FavoriteModel 추가 (id는 서버에서 부여되지만 목록 표시엔 불필요)
      state = state.copyWith(
        favorites: [
          FavoriteModel(id: 'temp_${menu.id}', menu: menu),
          ...state.favorites,
        ],
      );
    }

    try {
      if (isFav) {
        await _repository.remove(menu.id);
      } else {
        await _repository.add(menu.id);
      }
    } catch (_) {
      // 실패 시 롤백
      await load();
    }
  }
}

final favoriteListProvider =
StateNotifierProvider<FavoriteListNotifier, FavoriteListState>(
      (ref) => FavoriteListNotifier(ref.watch(favoriteRepositoryProvider)),
);