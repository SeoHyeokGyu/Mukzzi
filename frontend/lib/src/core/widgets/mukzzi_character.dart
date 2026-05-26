import 'dart:async' show unawaited;
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum CharacterState { normal, happy, hungry, starving, sleeping }


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
  final bool showAccessory;
  final String? equippedAccessory;
  final String growthStage;

  const MukzziCharacter({
    super.key,
    this.state = CharacterState.normal,
    this.size = 160,
    this.showAccessory = false,
    this.equippedAccessory,
    this.growthStage = 'baby',
  }) : assert(size >= 60, 'MukzziCharacter: size < 60 renders detail-loss. Use at least 80 for best results.');

  @override
  Widget build(BuildContext context) {
    return _SvgLayeredCharacter(
      state: state,
      size: size,
      showAccessory: showAccessory,
      equippedAccessory: equippedAccessory,
      growthStage: growthStage,
    );
  }
}

class _SvgLayeredCharacter extends StatefulWidget {
  final CharacterState state;
  final double size;
  final bool showAccessory;
  final String? equippedAccessory;
  final String growthStage;

  const _SvgLayeredCharacter({
    required this.state,
    required this.size,
    required this.showAccessory,
    this.equippedAccessory,
    required this.growthStage,
  });

  @override
  State<_SvgLayeredCharacter> createState() => _SvgLayeredCharacterState();
}

class _SvgLayeredCharacterState extends State<_SvgLayeredCharacter>
    with SingleTickerProviderStateMixin {
  static const _requiredLayers = ['body'];
  static const _optionalLayers = ['face', 'accessory'];

  List<String> _visibleLayers = _requiredLayers;

  late final AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _duration);
    _setupAnimation();
    _startRepeat();
    unawaited(_resolveOptionalLayers());
  }

  @override
  void didUpdateWidget(_SvgLayeredCharacter old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state ||
        old.showAccessory != widget.showAccessory ||
        old.equippedAccessory != widget.equippedAccessory ||
        old.growthStage != widget.growthStage) {
      setState(() => _visibleLayers = _requiredLayers);
      unawaited(_resolveOptionalLayers());
    }
    if (old.state != widget.state) {
      _ctrl.duration = _duration;
      _setupAnimation();
      _startRepeat();
    }
  }

  Duration get _duration => switch (widget.state) {
    CharacterState.sleeping => const Duration(milliseconds: 2800),
    CharacterState.happy    => const Duration(milliseconds: 650),
    CharacterState.hungry   => const Duration(milliseconds: 700),
    CharacterState.starving => const Duration(milliseconds: 400),
    _                       => const Duration(milliseconds: 2000),
  };

  void _startRepeat() {
    _ctrl.repeat(reverse: widget.state != CharacterState.happy);
  }

  void _setupAnimation() {
    _anim = switch (widget.state) {
      CharacterState.sleeping => Tween(begin: 0.97, end: 1.03).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      CharacterState.happy    => Tween(begin: 0.0, end: -18.0).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
      CharacterState.hungry   => Tween(begin: -5.0, end: 5.0).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      CharacterState.starving => Tween(begin: -6.0, end: 6.0).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      _                       => Tween(begin: 0.0, end: -8.0).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
    };
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _fallbackStateKey = 'idle';

  String? _resolvedStateKey;

  String _buildPath(String layer, String stateKey) {
    final stage = widget.growthStage;
    if (layer == 'accessory') {
      final name = (widget.equippedAccessory != null && widget.equippedAccessory!.isNotEmpty)
          ? widget.equippedAccessory!
          : 'accessory';
      return 'assets/svg/mukzzi2_${stage}_${stateKey}_$name.svg';
    }
    return 'assets/svg/mukzzi2_${stage}_${stateKey}_$layer.svg';
  }

  String _path(String layer) =>
      _buildPath(layer, _resolvedStateKey ?? _fallbackStateKey);

  Future<bool> _assetExists(String path) async {
    if (kIsWeb) {
      try {
        final res = await http.get(Uri.parse(path));
        return res.statusCode == 200;
      } catch (_) {
        return false;
      }
    } else {
      try {
        await rootBundle.load(path);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<void> _resolveOptionalLayers() async {
    final preferred = widget.state.key;
    final bodyExists = await _assetExists(_buildPath('body', preferred));
    final stateKey = bodyExists ? preferred : _fallbackStateKey;

    final available = <String>[];
    for (final layer in _optionalLayers) {
      if (layer == 'accessory' && !widget.showAccessory) {
        continue;
      }
      if (await _assetExists(_buildPath(layer, stateKey))) {
        available.add(layer);
      }
    }
    if (mounted) {
      setState(() {
        _resolvedStateKey = stateKey;
        _visibleLayers = [..._requiredLayers, ...available];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final svgStack = SizedBox(
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

    return AnimatedBuilder(
      animation: _anim,
      child: svgStack,
      builder: (_, child) => switch (widget.state) {
        CharacterState.sleeping => Transform.scale(
          scale: _anim.value,
          child: child,
        ),
        CharacterState.hungry ||
        CharacterState.starving => Transform.translate(
          offset: Offset(_anim.value, 0),
          child: child,
        ),
        _ => Transform.translate(
          offset: Offset(0, _anim.value),
          child: child,
        ),
      },
    );
  }
}