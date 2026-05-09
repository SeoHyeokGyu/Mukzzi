import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/common_providers.dart';
import '../../data/models/nutrition_model.dart';
import '../../data/repositories/nutrition_repository.dart';

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(ref.watch(apiClientProvider));
});

final todayNutritionProvider = FutureProvider.autoDispose<DailyNutritionModel>((ref) async {
  return ref.read(nutritionRepositoryProvider).getTodayNutrition();
});

final weeklyNutritionProvider = FutureProvider.autoDispose<List<WeeklyNutritionItemModel>>((ref) async {
  return ref.read(nutritionRepositoryProvider).getWeeklyNutrition();
});
