import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/common_providers.dart';
import '../../data/repositories/title_repository.dart';
import '../../domain/models/title_model.dart';

final titleRepositoryProvider = Provider<TitleRepository>((ref) {
  return TitleRepository(ref.watch(apiClientProvider));
});

final titleListProvider = FutureProvider<List<TitleModel>>((ref) {
  return ref.watch(titleRepositoryProvider).getTitles();
});

final equippedTitleProvider = Provider<AsyncValue<TitleModel?>>((ref) {
  return ref.watch(titleListProvider).whenData(
    (titles) => titles.where((t) => t.isEquipped).firstOrNull,
  );
});
