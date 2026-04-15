import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/common_providers.dart';
import '../../data/repositories/character_collection_repository.dart';
import '../../domain/models/character_collection_model.dart';

final characterCollectionRepositoryProvider = Provider<CharacterCollectionRepository>((ref) {
  return CharacterCollectionRepository(ref.watch(apiClientProvider));
});

final characterCollectionListProvider = FutureProvider<List<CharacterCollectionModel>>((ref) {
  return ref.watch(characterCollectionRepositoryProvider).getCollections();
});
