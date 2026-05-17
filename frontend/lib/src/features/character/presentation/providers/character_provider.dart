import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/common_providers.dart';
import '../../../../core/widgets/mukzzi_character.dart';
import '../../data/models/character_model.dart';
import '../../data/repositories/character_repository.dart';

final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  return CharacterRepository(ref.watch(apiClientProvider));
});

final characterProvider = FutureProvider.autoDispose<CharacterModel>((ref) async {
  return ref.read(characterRepositoryProvider).getMyCharacter();
});

class TestCharacterNotifier extends StateNotifier<AsyncValue<CharacterModel?>> {
  TestCharacterNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref ref;

  Future<void> _init() async {
    state = await AsyncValue.guard(() async {
      return await ref.read(characterProvider.future);
    });
  }

  void updateState(CharacterState newState) {
    state.whenData((char) {
      if (char == null) return;
      state = AsyncValue.data(char.copyWith(state: newState));
    });
  }

  void updateLevel(int newLevel) {
    state.whenData((char) {
      if (char == null) return;
      state = AsyncValue.data(char.copyWith(
        level: newLevel,
        evolutionStage: _evolutionStageForLevel(newLevel),
      ));
    });
  }

  String _evolutionStageForLevel(int level) {
    if (level <= 2) return 'EGG';
    if (level <= 6) return 'BABY';
    if (level <= 14) return 'TEEN';
    if (level <= 29) return 'ADULT';
    return 'LEGENDARY';
  }
}

final testCharacterProvider = StateNotifierProvider.autoDispose<TestCharacterNotifier, AsyncValue<CharacterModel?>>((ref) {
  return TestCharacterNotifier(ref);
});
