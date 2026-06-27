import 'dart:async' show unawaited;
import 'dart:math' as math;
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mukzzi/src/features/character/domain/models/reward_model.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';

enum CharacterState { normal, happy, hungry, starving, sleeping }

extension CharacterStateLabel on CharacterState {
  String get label {
    switch (this) {
      case CharacterState.normal:
        return '정상';
      case CharacterState.happy:
        return '행복';
      case CharacterState.hungry:
        return '배고픔';
      case CharacterState.starving:
        return '굶주림';
      case CharacterState.sleeping:
        return '수면';
    }
  }

  String get message {
    switch (this) {
      case CharacterState.normal:
        return '식사를 기록하면 먹찌가 성장해요';
      case CharacterState.happy:
        return '맛있는 거 먹어서 기분 좋아요!';
      case CharacterState.hungry:
        return '배가 고파요! 뭔가 드세요';
      case CharacterState.starving:
        return '배고파요... 밥 주세요';
      case CharacterState.sleeping:
        return '먹찌는 꿈나라 여행 중...';
    }
  }

  String get key {
    switch (this) {
      case CharacterState.normal:
        return 'idle';
      case CharacterState.happy:
        return 'happy';
      case CharacterState.hungry:
        return 'hungry';
      case CharacterState.starving:
        return 'starving';
      case CharacterState.sleeping:
        return 'sleeping';
    }
  }

  IconData get icon {
    switch (this) {
      case CharacterState.normal:
        return Icons.sentiment_neutral_outlined;
      case CharacterState.happy:
        return Icons.sentiment_very_satisfied_outlined;
      case CharacterState.hungry:
        return Icons.lunch_dining_outlined;
      case CharacterState.starving:
        return Icons.warning_amber_outlined;
      case CharacterState.sleeping:
        return Icons.bedtime_outlined;
    }
  }

  Color get crownColor {
    switch (this) {
      case CharacterState.normal:
        return const Color(0xFF2D6BFF);
      case CharacterState.happy:
        return const Color(0xFFFF85A1);
      case CharacterState.hungry:
        return const Color(0xFFFFCC33);
      case CharacterState.starving:
        return const Color(0xFFFF4444);
      case CharacterState.sleeping:
        return const Color(0xFF7C4DFF);
    }
  }

  Color get indicatorColor {
    switch (this) {
      case CharacterState.normal:
        return const Color(0xFF4CAF50);
      case CharacterState.happy:
        return const Color(0xFFFF85A1);
      case CharacterState.hungry:
        return const Color(0xFFFFCC33);
      case CharacterState.starving:
        return const Color(0xFFFF4444);
      case CharacterState.sleeping:
        return const Color(0xFF7C4DFF);
    }
  }

}

class MukzziCharacter extends StatelessWidget {
  static const _supportedEquipmentAssets = {
    'aura',
    'bag',
    'cap',
    'crown',
    'glasses',
    'scarf',
    'cook_hat',
    'donut',
    'background_kitchen',
    'background_night',
    'wooden_spoon',
  };

  final CharacterState state;
  final double size;
  final bool showAccessory;
  final String? equippedAccessory;
  final Map<EquipmentSlot, RewardModel> equipment;
  final bool enableAnimation;

  const MukzziCharacter({
    super.key,
    this.state = CharacterState.normal,
    this.size = 160,
    this.showAccessory = false,
    this.equippedAccessory,
    this.equipment = const {},
    this.enableAnimation = false,
  }) : assert(size >= 60,
            'MukzziCharacter: size < 60 renders detail-loss. Use at least 80 for best results.');

  static bool isSupportedEquipmentAsset(String assetUrl) {
    return _supportedEquipmentAssets.contains(assetUrl);
  }

  static bool isSvgHttpResponse({
    required int statusCode,
    required String? contentType,
    required String body,
  }) {
    if (statusCode != 200) return false;

    final normalizedType = contentType?.split(';').first.trim().toLowerCase();
    if (normalizedType == 'image/svg+xml') return true;

    final trimmedBody = body.trimLeft();
    return normalizedType != 'text/html' &&
        (trimmedBody.startsWith('<svg') ||
            trimmedBody.startsWith('<?xml') && trimmedBody.contains('<svg'));
  }

  @override
  Widget build(BuildContext context) {
    return _SvgLayeredCharacter(
      state: state,
      size: size,
      showAccessory: showAccessory,
      equippedAccessory: equippedAccessory,
      equipment: equipment,
      enableAnimation: enableAnimation,
    );
  }
}

class _SvgLayeredCharacter extends StatefulWidget {
  final CharacterState state;
  final double size;
  final bool showAccessory;
  final String? equippedAccessory;
  final Map<EquipmentSlot, RewardModel> equipment;
  final bool enableAnimation;

  const _SvgLayeredCharacter({
    required this.state,
    required this.size,
    required this.showAccessory,
    this.equippedAccessory,
    required this.equipment,
    required this.enableAnimation,
  });

  @override
  State<_SvgLayeredCharacter> createState() => _SvgLayeredCharacterState();
}

class _SvgLayeredCharacterState extends State<_SvgLayeredCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _duration);
    _setupAnimation();
    _startRepeat();
    unawaited(_resolveStateKey());
  }

  @override
  void didUpdateWidget(_SvgLayeredCharacter old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state ||
        old.showAccessory != widget.showAccessory ||
        old.equippedAccessory != widget.equippedAccessory ||
        old.equipment != widget.equipment) {
      unawaited(_resolveStateKey());
    }
    if (old.state != widget.state) {
      _ctrl.duration = _duration;
      _setupAnimation();
      _startRepeat();
    }
  }

  Duration get _duration => switch (widget.state) {
        CharacterState.sleeping => const Duration(milliseconds: 2800),
        CharacterState.happy => const Duration(milliseconds: 650),
        CharacterState.hungry => const Duration(milliseconds: 700),
        CharacterState.starving => const Duration(milliseconds: 400),
        _ => const Duration(milliseconds: 2000),
      };

  void _startRepeat() {
    if (!widget.enableAnimation) {
      _ctrl.value = 0.0;
      return;
    }
    final isTesting = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTesting) {
      _ctrl.value = 1.0;
      return;
    }
    _ctrl.repeat(reverse: widget.state != CharacterState.happy);
  }

  void _setupAnimation() {
    _anim = switch (widget.state) {
      CharacterState.sleeping => Tween(begin: 0.97, end: 1.03)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      CharacterState.happy => Tween(begin: 0.0, end: -18.0)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
      CharacterState.hungry => Tween(begin: -5.0, end: 5.0)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      CharacterState.starving => Tween(begin: -6.0, end: 6.0)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      _ => Tween(begin: 0.0, end: -8.0)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
    };
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _fallbackStateKey = 'idle';

  String? _resolvedStateKey;

  String _accessoryAssetName() {
    final name = widget.equippedAccessory ?? '';
    return MukzziCharacter.isSupportedEquipmentAsset(name) ? name : '';
  }

  String _buildPath(String layer, String stateKey) {
    if (layer == 'accessory') {
      final name = _accessoryAssetName();
      return 'assets/svg/mukzzi2_$name.svg';
    }
    return 'assets/svg/mukzzi2_${stateKey}_$layer.svg';
  }

  String _path(String layer) =>
      _buildPath(layer, _resolvedStateKey ?? _fallbackStateKey);

  Future<bool> _assetExists(String path) async {
    if (kIsWeb) {
      try {
        final uri = Uri.base.resolve(path);
        final res = await http.get(uri);
        return MukzziCharacter.isSvgHttpResponse(
          statusCode: res.statusCode,
          contentType: res.headers['content-type'],
          body: res.body,
        );
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

  Future<void> _resolveStateKey() async {
    final preferred = widget.state.key;
    final bodyExists = await _assetExists(_buildPath('body', preferred));
    final stateKey = bodyExists ? preferred : _fallbackStateKey;

    if (mounted) {
      setState(() {
        _resolvedStateKey = stateKey;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyPath = _path('body');
    final equipmentLayers = _equipmentLayers();

    // 배경과 비배경 분리 (slot 기준)
    final backgroundSpecs = <_CharacterLayerSpec>[
      for (final item in equipmentLayers)
        if (item.renderConfig?.slot == EquipmentSlot.background)
          _CharacterLayerSpec.equipment(item),
    ]..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    final characterSpecs = <_CharacterLayerSpec>[
      for (final item in equipmentLayers)
        if (item.renderConfig?.slot != EquipmentSlot.background)
          _CharacterLayerSpec.equipment(item),
      _CharacterLayerSpec.asset(bodyPath, 0),
    ]..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    final characterStack = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: characterSpecs.map(_buildLayer).toList(),
      ),
    );

    final animatedCharacter = AnimatedBuilder(
      key: const ValueKey('character_loop'),
      animation: _anim,
      child: characterStack,
      builder: (_, child) => switch (widget.state) {
        CharacterState.sleeping => Transform.scale(
            scale: _anim.value,
            child: child,
          ),
        CharacterState.hungry || CharacterState.starving => Transform.translate(
            offset: Offset(_anim.value, 0),
            child: child,
          ),
        _ => Transform.translate(
            offset: Offset(0, _anim.value),
            child: child,
          ),
      },
    );

    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final ambient = switch (widget.state) {
      CharacterState.hungry => tokens.charBgHungry,
      CharacterState.starving => tokens.charBgStarving,
      _ => tokens.charBgNormal,
    };
    final radius = BorderRadius.circular(widget.size * 0.16);

    // 스테이지: 테마·상태별 ambient 받침 + 둥근 클립 + 그림자.
    // 장착 배경(scene)은 이 클립에 채워져 의도된 "액자"로 렌더되고,
    // 배경 미장착 시 ambient 받침이 보인다.
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: ambient,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // 배경 미장착 시: 빌트인 기본 backdrop(스포트라이트 + 바닥 + 접지 그림자)
              if (backgroundSpecs.isEmpty) const _DefaultBackdrop(),
              // 배경(장착): Transform 없이 정적, 스테이지에 클립됨
              for (final spec in backgroundSpecs) _buildLayer(spec),
              // 캐릭터 + 비배경 장비: 루프 애니메이션
              animatedCharacter,
              _FloatingParticles(
                state: widget.state,
                size: widget.size,
                enableAnimation: widget.enableAnimation,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<RewardModel> _equipmentLayers() {
    final rewards = widget.equipment.values
        .where(
          (reward) =>
              MukzziCharacter.isSupportedEquipmentAsset(reward.assetUrl),
        )
        .toList();
    if (rewards.isEmpty &&
        widget.showAccessory &&
        _accessoryAssetName().isNotEmpty) {
      rewards.add(RewardModel(
        id: 'legacy-accessory',
        rewardType: 'ACCESSORY',
        name: 'legacy-accessory',
        description: '',
        assetUrl: _accessoryAssetName(),
        renderConfig: const RewardRenderConfig(
          slot: EquipmentSlot.head,
          offsetX: 0,
          offsetY: 0,
          scale: 1,
          rotation: 0,
          zIndex: 30,
        ),
        acquired: true,
      ));
    }
    rewards.sort((a, b) =>
        (a.renderConfig?.zIndex ?? 30).compareTo(b.renderConfig?.zIndex ?? 30));
    return rewards;
  }

  Widget _buildLayer(_CharacterLayerSpec spec) {
    if (spec.reward == null) {
      return SvgPicture.asset(
        spec.path!,
        key: ValueKey(spec.path),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      );
    }

    final reward = spec.reward!;
    final config = reward.renderConfig ??
        const RewardRenderConfig(
          slot: EquipmentSlot.head,
          offsetX: 0,
          offsetY: 0,
          scale: 1,
          rotation: 0,
          zIndex: 30,
        );
    final path = 'assets/svg/mukzzi2_${reward.assetUrl}.svg';
    final isBackground = config.slot == EquipmentSlot.background;
    final layerSize = (widget.size * config.scale * (isBackground ? 1.02 : 1.0)).roundToDouble();

    Widget layer = SvgPicture.asset(
      path,
      key: ValueKey(path),
      width: layerSize,
      height: layerSize,
      fit: BoxFit.contain,
    );

    // 배경 가장자리는 스테이지 ClipRRect가 크리스프하게 처리(알파 페이드 불필요).

    return Positioned.fill(
      child: Transform.translate(
        offset:
            Offset(widget.size * config.offsetX, widget.size * config.offsetY),
        child: Transform.rotate(
          angle: config.rotation * math.pi / 180,
          child: Center(child: layer),
        ),
      ),
    );
  }
}



/// 배경 미장착 시 스테이지를 채우는 빌트인 기본 backdrop.
/// 상단 스포트라이트로 빈 헤드룸을 채우고, 바닥 그라데이션 + 발밑 접지
/// 그림자로 캐릭터를 안착시킨다. ambient 그라데이션 위에 합성된다.
class _DefaultBackdrop extends StatelessWidget {
  const _DefaultBackdrop();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        // 상단 소프트 스포트라이트 → 빈 윗공간을 채워 깊이감 부여
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.28),
                radius: 0.95,
                colors: [Color(0x1FFFFFFF), Color(0x00FFFFFF)],
              ),
            ),
          ),
        ),
        // 하단 바닥 그라데이션 → 은은한 받침
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.42,
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x1A000000)],
                ),
              ),
            ),
          ),
        ),
        // 발밑 접지 그림자(타원 소프트)
        Align(
          alignment: Alignment(0, 0.74),
          child: FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 0.07,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x2B000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ParticleData {
  final String icon;
  final Duration delay;
  final Duration duration;
  final double fontSize;

  const _ParticleData({
    required this.icon,
    required this.delay,
    required this.duration,
    this.fontSize = 18,
  });
}

class _FloatingParticles extends StatelessWidget {
  final CharacterState state;
  final double size;
  final bool enableAnimation;

  const _FloatingParticles({
    required this.state,
    required this.size,
    required this.enableAnimation,
  });

  // 파티클 위치: 좌상 / 우상 / 상단 중앙
  static const _positions = [
    (leftRatio: 0.15, topRatio: 0.30),
    (leftRatio: 0.65, topRatio: 0.28),
    (leftRatio: 0.40, topRatio: 0.20),
  ];

  // sleeping: 우측으로 몰아서 오름
  static const _sleepingPositions = [
    (leftRatio: 0.60, topRatio: 0.40),
    (leftRatio: 0.68, topRatio: 0.28),
    (leftRatio: 0.74, topRatio: 0.14),
  ];

  @override
  Widget build(BuildContext context) {
    if (!enableAnimation) return const SizedBox.shrink();

    final positions = state == CharacterState.sleeping
        ? _sleepingPositions
        : _positions;

    final particles = switch (state) {
      CharacterState.normal => const [
          _ParticleData(icon: '✨', delay: Duration.zero, duration: Duration(milliseconds: 2200)),
          _ParticleData(icon: '✨', delay: Duration(milliseconds: 700), duration: Duration(milliseconds: 2000)),
          _ParticleData(icon: '✨', delay: Duration(milliseconds: 1400), duration: Duration(milliseconds: 2400)),
        ],
      CharacterState.happy => const [
          _ParticleData(icon: '♥', delay: Duration.zero, duration: Duration(milliseconds: 1600)),
          _ParticleData(icon: '♥', delay: Duration(milliseconds: 500), duration: Duration(milliseconds: 1400)),
          _ParticleData(icon: '♥', delay: Duration(milliseconds: 1000), duration: Duration(milliseconds: 1800)),
        ],
      CharacterState.hungry => const [
          _ParticleData(icon: '🔥', delay: Duration.zero, duration: Duration(milliseconds: 1800)),
          _ParticleData(icon: '🔥', delay: Duration(milliseconds: 600), duration: Duration(milliseconds: 1600)),
          _ParticleData(icon: '🔥', delay: Duration(milliseconds: 1200), duration: Duration(milliseconds: 2000)),
        ],
      CharacterState.starving => const [
          _ParticleData(icon: '⚠️', delay: Duration.zero, duration: Duration(milliseconds: 1000)),
          _ParticleData(icon: '⚠️', delay: Duration(milliseconds: 300), duration: Duration(milliseconds: 900)),
          _ParticleData(icon: '⚠️', delay: Duration(milliseconds: 600), duration: Duration(milliseconds: 1100)),
        ],
      CharacterState.sleeping => const [
          _ParticleData(icon: 'z', delay: Duration.zero, duration: Duration(milliseconds: 2800), fontSize: 14),
          _ParticleData(icon: 'z', delay: Duration(milliseconds: 900), duration: Duration(milliseconds: 2800), fontSize: 18),
          _ParticleData(icon: 'z', delay: Duration(milliseconds: 1800), duration: Duration(milliseconds: 2800), fontSize: 22),
        ],
    };

    assert(
      particles.length == positions.length,
      '_FloatingParticles: particles.length (${particles.length}) != '
      'positions.length (${positions.length}) for state $state',
    );

    final disableAnimations = (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: List.generate(particles.length, (i) {
          final p = particles[i];
          final pos = positions[i];
          final child = Text(
            p.icon,
            style: TextStyle(fontSize: p.fontSize),
          );

          if (disableAnimations) {
            return Positioned(
              left: size * pos.leftRatio,
              top: size * pos.topRatio,
              child: child,
            );
          }

          return Positioned(
            left: size * pos.leftRatio,
            top: size * pos.topRatio,
            child: child
                .animate(onPlay: (c) => c.repeat())
                // delay workaround: `.animate(delay:)` leaves pending timers in test env
                .custom(
                  duration: p.delay,
                  builder: (_, __, child) => child,
                )
                .then()
                .moveY(
                  begin: 0,
                  end: -size * 0.35,
                  duration: p.duration,
                  curve: Curves.easeOut,
                )
                .fadeIn(duration: p.duration * 0.15)
                .then(delay: p.duration * 0.55)
                .fadeOut(duration: p.duration * 0.30),
          );
        }),
      ),
    );
  }
}

class _CharacterLayerSpec {
  final String? path;
  final RewardModel? reward;
  final int zIndex;

  const _CharacterLayerSpec.asset(this.path, this.zIndex) : reward = null;

  _CharacterLayerSpec.equipment(this.reward)
      : path = null,
        zIndex = reward!.renderConfig?.zIndex ?? 30;
}
