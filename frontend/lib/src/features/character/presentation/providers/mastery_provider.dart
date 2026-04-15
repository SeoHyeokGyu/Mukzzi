import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/common_providers.dart';
import '../../data/repositories/mastery_repository.dart';
import '../../domain/models/mastery_model.dart';

final masteryRepositoryProvider = Provider<MasteryRepository>((ref) {
  return MasteryRepository(ref.watch(apiClientProvider));
});

final masteryListProvider = FutureProvider<List<MasteryModel>>((ref) {
  return ref.watch(masteryRepositoryProvider).getMasteries();
});
