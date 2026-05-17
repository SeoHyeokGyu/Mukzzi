import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class CharacterVariantNotifier extends StateNotifier<CharacterVariant> {
  CharacterVariantNotifier() : super(CharacterVariant.v1) {
    unawaited(_load());
  }

  static const _prefsKey = 'character_variant';
  bool _userSelected = false;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && !_userSelected) {
        state = CharacterVariant.values.firstWhere(
          (v) => v.name == saved,
          orElse: () => CharacterVariant.v1,
        );
      }
    } on Exception catch (e) {
      debugPrint('CharacterVariantNotifier: failed to load preference: $e');
    }
  }

  Future<void> setVariant(CharacterVariant variant) async {
    _userSelected = true;
    state = variant;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, variant.name);
    } on Exception catch (e) {
      debugPrint('CharacterVariantNotifier: failed to save preference: $e');
    }
  }
}

final characterVariantProvider = StateNotifierProvider<CharacterVariantNotifier, CharacterVariant>((ref) {
  return CharacterVariantNotifier();
});
