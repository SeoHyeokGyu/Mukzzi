import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mukzzi/src/core/providers/common_providers.dart';
import 'package:mukzzi/src/features/ai/data/models/ai_models.dart';
import 'package:mukzzi/src/features/ai/data/repositories/ai_repository.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(ref.watch(apiClientProvider));
});

// 영양 코칭 프로바이더 (날짜 기반 캐싱)
final nutritionCoachingProvider = FutureProvider.family<NutritionCoachingResponse, String?>((ref, date) async {
  final repository = ref.watch(aiRepositoryProvider);
  return await repository.getNutritionCoaching(date: date);
});

// 식단 추천 프로바이더 (아침, 점심, 저녁 등)
final recommendMealProvider = FutureProvider.family<RecommendMealResponse, String>((ref, mealType) async {
  final repository = ref.watch(aiRepositoryProvider);
  return await repository.recommendMeal(mealType);
});

// 파일 업로드 및 분석은 상태(State)로 관리하기 위해 StateNotifier 활용
class AnalyzeMealState {
  final bool isLoading;
  final AnalyzeMealResponse? data;
  final String? imageUrl;
  final String? error;

  AnalyzeMealState({this.isLoading = false, this.data, this.imageUrl, this.error});

  AnalyzeMealState copyWith({
    bool? isLoading,
    AnalyzeMealResponse? data,
    String? imageUrl,
    String? error,
  }) {
    return AnalyzeMealState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      error: error,
    );
  }
}

class AnalyzeMealNotifier extends StateNotifier<AnalyzeMealState> {
  final AiRepository _repository;

  AnalyzeMealNotifier(this._repository) : super(AnalyzeMealState());

  Future<void> analyzeImage(XFile imageFile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. 이미지 업로드
      final imageUrl = await _repository.uploadImage(imageFile);
      // 2. 이미지 URL로 분석 요청
      final result = await _repository.analyzeMealImage(imageUrl);
      
      state = state.copyWith(isLoading: false, data: result, imageUrl: imageUrl);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = AnalyzeMealState();
  }
}

final analyzeMealProvider = StateNotifierProvider<AnalyzeMealNotifier, AnalyzeMealState>((ref) {
  return AnalyzeMealNotifier(ref.watch(aiRepositoryProvider));
});
