import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/common_providers.dart';
import '../../data/models/menu_model.dart';
import '../../data/repositories/roulette_repository.dart';

final rouletteRepositoryProvider = Provider<RouletteRepository>((ref) {
  return RouletteRepository(ref.watch(apiClientProvider));
});

// 필터 토글 상태 — 위젯 재빌드에 영향 안 받도록 provider로 관리
final filterExpandedProvider = StateProvider<bool>((ref) => false);

// ── 룰렛 상태 ──
class RouletteState {
  final List<MenuModel> candidates;
  final MenuModel? result;
  final MenuModel? pendingResult;  // 추가 — API 응답 왔지만 아직 표시 안 함
  final String reason;
  final bool isSpinning;
  final String? error;

  const RouletteState({
    this.candidates = const [],
    this.result,
    this.pendingResult,
    this.reason = '',
    this.isSpinning = false,
    this.error,
  });

  RouletteState copyWith({
    List<MenuModel>? candidates,
    MenuModel? result,
    MenuModel? pendingResult,
    String? reason,
    bool? isSpinning,
    String? error,
    bool clearResult = false,
    bool clearError = false,
    bool clearPending = false,
  }) =>
      RouletteState(
        candidates: candidates ?? this.candidates,
        result: clearResult ? null : result ?? this.result,
        pendingResult: clearPending ? null : pendingResult ?? this.pendingResult,
        reason: reason ?? this.reason,
        isSpinning: isSpinning ?? this.isSpinning,
        error: clearError ? null : error ?? this.error,
      );
}

class RouletteNotifier extends StateNotifier<RouletteState> {
  final RouletteRepository _repo;

  RouletteNotifier(this._repo) : super(const RouletteState());

  Future<void> spin() async {
    if (state.isSpinning) return;
    state = state.copyWith(
      isSpinning: true,
      clearError: true,
      clearResult: true,
      clearPending: true,
    );
    try {
      final result = await _repo.spin();
      // API 응답 왔지만 isSpinning은 유지 — pendingResult에만 저장
      state = state.copyWith(
        candidates: result.candidates,
        pendingResult: result.menu,
        reason: result.reason,
      );
    } catch (e) {
      state = state.copyWith(isSpinning: false, error: e.toString());
    }
  }

  // 애니메이션 끝난 후 위젯에서 호출
  void onAnimationComplete() {
    state = state.copyWith(
      isSpinning: false,
      result: state.pendingResult,
      clearPending: true,
    );
  }

  void reset() => state = const RouletteState();
}

final rouletteProvider = StateNotifierProvider<RouletteNotifier, RouletteState>(
      (ref) => RouletteNotifier(ref.watch(rouletteRepositoryProvider)),
);

// ── 필터 상태 ──

class MenuFilterState {
  final Set<String> selectedWeathers;
  final Set<String> selectedMoods;
  final List<MenuModel> results;
  final String source;
  final bool isLoading;
  final String? error;

  const MenuFilterState({
    this.selectedWeathers = const {},
    this.selectedMoods = const {},
    this.results = const [],
    this.source = '',
    this.isLoading = false,
    this.error,
  });

  MenuFilterState copyWith({
    Set<String>? selectedWeathers,
    Set<String>? selectedMoods,
    List<MenuModel>? results,
    String? source,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      MenuFilterState(
        selectedWeathers: selectedWeathers ?? this.selectedWeathers,
        selectedMoods: selectedMoods ?? this.selectedMoods,
        results: results ?? this.results,
        source: source ?? this.source,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class MenuFilterNotifier extends StateNotifier<MenuFilterState> {
  final RouletteRepository _repo;

  MenuFilterNotifier(this._repo) : super(const MenuFilterState());

  void toggleWeather(String tag) {
    final set = Set<String>.from(state.selectedWeathers);
    set.contains(tag) ? set.remove(tag) : set.add(tag);
    state = state.copyWith(selectedWeathers: set);
  }

  void toggleMood(String tag) {
    final set = Set<String>.from(state.selectedMoods);
    set.contains(tag) ? set.remove(tag) : set.add(tag);
    state = state.copyWith(selectedMoods: set);
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.filter(
        weathers: state.selectedWeathers.toList(),
        moods: state.selectedMoods.toList(),
      );
      state = state.copyWith(
        isLoading: false,
        results: result.menus,
        source: result.source,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final menuFilterProvider =
StateNotifierProvider<MenuFilterNotifier, MenuFilterState>(
      (ref) => MenuFilterNotifier(ref.watch(rouletteRepositoryProvider)),
);