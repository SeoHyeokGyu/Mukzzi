import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/common_providers.dart';
import '../../data/models/favorite_model.dart';
import '../../data/models/menu_model.dart';
import '../../data/repositories/favorite_repository.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(ref.watch(apiClientProvider));
});

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
      // 즐겨찾기는 전체를 한 번에 가져옴 (칩 + 바텀시트 공용)
      final favorites = await _repository.getList(limit: 50);
      state = state.copyWith(favorites: favorites, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggle(MenuModel menu) async {
    final isFav = state.isFavorite(menu.id);

    if (isFav) {
      state = state.copyWith(
        favorites: state.favorites.where((f) => f.menu.id != menu.id).toList(),
      );
    } else {
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
      await load();
    }
  }
}

final favoriteListProvider =
StateNotifierProvider<FavoriteListNotifier, FavoriteListState>(
      (ref) => FavoriteListNotifier(ref.watch(favoriteRepositoryProvider)),
);