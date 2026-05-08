import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/common_providers.dart';
import '../../data/models/menu_model.dart';
import '../../data/repositories/recommendation_repository.dart';

final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  return RecommendationRepository(ref.watch(apiClientProvider));
});

// 추천 섹션 펼침 상태
final recommendationExpandedProvider = StateProvider<bool>((ref) => false);

class RecommendationState {
  final List<MenuModel> menus;
  final bool isPersonal;
  final bool isLoading;
  final String? error;

  const RecommendationState({
    this.menus = const [],
    this.isPersonal = false,
    this.isLoading = false,
    this.error,
  });

  RecommendationState copyWith({
    List<MenuModel>? menus,
    bool? isPersonal,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      RecommendationState(
        menus: menus ?? this.menus,
        isPersonal: isPersonal ?? this.isPersonal,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final RecommendationRepository _repo;

  RecommendationNotifier(this._repo) : super(const RecommendationState());

  Future<void> fetch() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.getRecommendations();
      state = state.copyWith(
        isLoading: false,
        menus: result.menus,
        isPersonal: result.isPersonal,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const RecommendationState();
}

final recommendationProvider =
StateNotifierProvider<RecommendationNotifier, RecommendationState>(
      (ref) => RecommendationNotifier(ref.watch(recommendationRepositoryProvider)),
);