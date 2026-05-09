import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/common_providers.dart';
import '../../data/models/character_model.dart';
import '../../data/repositories/character_repository.dart';

final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  return CharacterRepository(ref.watch(apiClientProvider));
});

final characterProvider = FutureProvider.autoDispose<CharacterModel>((ref) async {
  return ref.read(characterRepositoryProvider).getMyCharacter();
});
