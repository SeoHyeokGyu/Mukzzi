import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/common_providers.dart';
import '../../data/models/menu_model.dart';
import '../../data/repositories/menu_repository.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(ref.watch(apiClientProvider));
});

class MenuSearchState {
  final List<MenuModel> results;
  final bool isLoading;
  final String? error;

  const MenuSearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  MenuSearchState copyWith({
    List<MenuModel>? results,
    bool? isLoading,
    String? error,
  }) {
    return MenuSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MenuSearchNotifier extends StateNotifier<MenuSearchState> {
  final MenuRepository _repository;
  Timer? _debounce;

  MenuSearchNotifier(this._repository) : super(const MenuSearchState());

  void search(String query) {
    _debounce?.cancel();

    if (query.isEmpty) {
      state = const MenuSearchState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await _repository.search(query: query);
        state = state.copyWith(results: results, isLoading: false);
      } catch (e) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    });
  }

  void clear() {
    _debounce?.cancel();
    state = const MenuSearchState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final menuSearchProvider = StateNotifierProvider.autoDispose<
    MenuSearchNotifier, MenuSearchState>((ref) {
  return MenuSearchNotifier(ref.watch(menuRepositoryProvider));
});