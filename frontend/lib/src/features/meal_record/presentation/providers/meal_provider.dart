import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/common_providers.dart';
import '../../data/models/meal_model.dart';
import '../../data/repositories/meal_repository.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(ref.watch(apiClientProvider));
});

final todayMealsProvider = FutureProvider.autoDispose<List<MealRecord>>((ref) async {
  final now = DateTime.now();
  final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  
  final result = await ref.read(mealRepositoryProvider).findAll(
    MealListFilter(
      startDate: today,
      endDate: today,
      limit: 10,
    ),
  );
  return result.meals;
});
