import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'lottie_web_player_stub.dart' if (dart.library.js_interop) 'lottie_web_player_web.dart';

enum CharacterVariant { v1, v2 }

extension CharacterVariantLabel on CharacterVariant {
  String get label => switch (this) {
    CharacterVariant.v1 => '먹찌 1',
    CharacterVariant.v2 => '먹찌 2',
  };
}

enum CharacterState { normal, happy, hungry, starving, sleeping }

enum CharacterStage { baby, teen, adult }

extension CharacterLevelExtension on int {
  CharacterStage get stage {
    if (this <= 6) return CharacterStage.baby;
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
  final CharacterVariant variant;

  const MukzziCharacter({
    super.key,
    this.state = CharacterState.normal,
    this.size = 160,
    this.level = 1,
    this.variant = CharacterVariant.v1,
  }) : assert(size >= 60, 'MukzziCharacter: size < 60 renders detail-loss. Use at least 80 for best results.');

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      CharacterVariant.v1 => _LottieCharacter(state: state, size: size, level: level),
      CharacterVariant.v2 => _SvgLayeredCharacter(state: state, size: size, level: level),
    };
  }
}

class _LottieCharacter extends StatelessWidget {
  final CharacterState state;
  final double size;
  final int level;

  const _LottieCharacter({required this.state, required this.size, required this.level});

  @override
  Widget build(BuildContext context) {
    final stage = level.stage.name.toLowerCase();
    final stateKey = state.key;
    final assetPath = 'assets/animations/mukzzi_${stage}_$stateKey.json';

    if (kIsWeb) {
      return KeyedSubtree(
        key: ValueKey(assetPath),
        child: buildLottieWebPlayer('assets/$assetPath', size),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        assetPath,
        key: ValueKey(assetPath),
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

class _SvgLayeredCharacter extends StatefulWidget {
  final CharacterState state;
  final double size;
  final int level;

  const _SvgLayeredCharacter({
    required this.state,
    required this.size,
    required this.level,
  });

  @override
  State<_SvgLayeredCharacter> createState() => _SvgLayeredCharacterState();
}

class _SvgLayeredCharacterState extends State<_SvgLayeredCharacter> {
  static const _requiredLayers = ['body'];
  static const _optionalLayers = ['face', 'accessory'];

  List<String> _visibleLayers = _requiredLayers;

  @override
  void initState() {
    super.initState();
    unawaited(_resolveOptionalLayers());
  }

  @override
  void didUpdateWidget(_SvgLayeredCharacter old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state || old.level != widget.level) {
      setState(() => _visibleLayers = _requiredLayers);
      unawaited(_resolveOptionalLayers());
    }
  }

  String _path(String layer) {
    final stage = widget.level.stage.name.toLowerCase();
    final stateKey = widget.state.key;
    return 'assets/svg/mukzzi2_${stage}_${stateKey}_$layer.svg';
  }

  Future<void> _resolveOptionalLayers() async {
    final available = <String>[];
    for (final layer in _optionalLayers) {
      try {
        await rootBundle.load(_path(layer));
        available.add(layer);
      } catch (_) {
        // layer file absent — skip silently
      }
    }
    if (mounted && available.isNotEmpty) {
      setState(() => _visibleLayers = [..._requiredLayers, ...available]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: _visibleLayers.map((layer) {
          final path = _path(layer);
          return SvgPicture.asset(
            path,
            key: ValueKey(path),
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
          );
        }).toList(),
      ),
    );
  }
}
