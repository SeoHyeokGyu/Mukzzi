import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'lottie_web_player_stub.dart' if (dart.library.js_interop) 'lottie_web_player_web.dart';

enum CharacterState { normal, happy, hungry, starving, sleeping }

enum CharacterStage { baby, teen, adult }

extension CharacterLevelExtension on int {
  CharacterStage get stage {
    if (this <= 2) return CharacterStage.baby;
    if (this <= 14) return CharacterStage.teen;
    return CharacterStage.adult;
  }
}

extension CharacterStateLabel on CharacterState {
  String get label {
    switch (this) {
      case CharacterState.normal:   return '정상';
      case CharacterState.happy:    return '행복';
      case CharacterState.hungry:   return '배고픔';
      case CharacterState.starving: return '굶주림';
      case CharacterState.sleeping: return '수면';
    }
  }

  String get message {
    switch (this) {
      case CharacterState.normal:   return '식사를 기록하면 먹찌가 성장해요';
      case CharacterState.happy:    return '맛있는 거 먹어서 기분 좋아요!';
      case CharacterState.hungry:   return '배가 고파요! 뭔가 드세요';
      case CharacterState.starving: return '배고파요... 밥 주세요';
      case CharacterState.sleeping: return '먹찌는 꿈나라 여행 중...';
    }
  }

  String get key {
    switch (this) {
      case CharacterState.normal:   return 'idle';
      case CharacterState.happy:    return 'happy';
      case CharacterState.hungry:   return 'hungry';
      case CharacterState.starving: return 'starving';
      case CharacterState.sleeping: return 'sleeping';
    }
  }

  IconData get icon {
    switch (this) {
      case CharacterState.normal:   return Icons.sentiment_neutral_outlined;
      case CharacterState.happy:    return Icons.sentiment_very_satisfied_outlined;
      case CharacterState.hungry:   return Icons.lunch_dining_outlined;
      case CharacterState.starving: return Icons.warning_amber_outlined;
      case CharacterState.sleeping: return Icons.bedtime_outlined;
    }
  }

  Color get crownColor {
    switch (this) {
      case CharacterState.normal:   return const Color(0xFF2D6BFF);
      case CharacterState.happy:    return const Color(0xFFFF85A1);
      case CharacterState.hungry:   return const Color(0xFFFFCC33);
      case CharacterState.starving: return const Color(0xFFFF4444);
      case CharacterState.sleeping: return const Color(0xFF7C4DFF);
    }
  }

  Color get indicatorColor {
    switch (this) {
      case CharacterState.normal:   return const Color(0xFF4CAF50);
      case CharacterState.happy:    return const Color(0xFFFF85A1);
      case CharacterState.hungry:   return const Color(0xFFFFCC33);
      case CharacterState.starving: return const Color(0xFFFF4444);
      case CharacterState.sleeping: return const Color(0xFF7C4DFF);
    }
  }
}

class MukzziCharacter extends StatelessWidget {
  final CharacterState state;
  final double size;
  final int level;

  const MukzziCharacter({
    super.key,
    this.state = CharacterState.normal,
    this.size = 160,
    this.level = 1,
  }) : assert(size >= 60, 'MukzziCharacter: size < 60 renders detail-loss. Use at least 80 for best results.');

  @override
  Widget build(BuildContext context) {
    final stage = level.stage.name.toLowerCase();
    final stateKey = state.key;
    final assetPath = 'assets/animations/mukzzi_${stage}_$stateKey.json';

    if (kIsWeb) {
      return buildLottieWebPlayer('assets/$assetPath', size);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        assetPath,
        fit: BoxFit.contain,
        repeat: true,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets, size: size * 0.4, color: const Color(0xFF2D6BFF)),
                const SizedBox(height: 4),
                Text('Load Failed: $assetPath', style: const TextStyle(fontSize: 8, color: Colors.red)),
              ],
            ),
          );
        },
      ),
    );
  }
}
