import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:rive/rive.dart' hide LinearGradient; // mukzzi.riv 추가 시 활성화
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/mukzzi_character.dart';

// TODO: (cjkang) 캐릭터 상태/레벨/XP를 API 응답에서 가져오도록 교체
const _mockState = CharacterState.normal;
const int _mockLevel = 1;
const double _mockXp = 0;
const double _mockXpGoal = 100;

class CharacterPage extends ConsumerWidget {
  const CharacterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    final heroBg = switch (_mockState) {
      CharacterState.hungry   => tokens.charBgHungry,
      CharacterState.starving => tokens.charBgStarving,
      _                       => tokens.charBgNormal,
    };

    return GradientScaffold(
      appBar: AppBar(automaticallyImplyLeading: false, toolbarHeight: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 인라인 헤더
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Column(
                children: [
                  Text(
                    'Lv.$_mockLevel · 부화 단계',
                    style: TextStyle(fontSize: 13, color: tokens.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '먹찌',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 캐릭터 히어로 카드
            BentoCard(
              gradient: heroBg,
              borderRadius: BorderRadius.circular(tokens.rHero),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _levelBadge('Lv.$_mockLevel', tokens),
                      _statePill(_mockState, tokens),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MukzziCharacter(state: _mockState, size: 200, level: _mockLevel),
                  const SizedBox(height: 12),
                  Text(
                    'Lv.$_mockLevel까지 ${(_mockXpGoal - _mockXp).toInt()} XP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('EXP', style: TextStyle(fontSize: 11, color: tokens.heroTextSub)),
                      Text(
                        '${_mockXp.toInt()} / ${_mockXpGoal.toInt()}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tokens.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_mockXp / _mockXpGoal).clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor: Colors.black.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 스탯 그리드
            Text('스탯', style: _sectionStyle(context, tokens)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _StatProgressTile(label: '포만감',    value: 68, color: tokens.primary,      icon: Icons.restaurant_outlined, tokens: tokens),
                _StatProgressTile(label: '활력',     value: 82, color: const Color(0xFF3DD68C), icon: Icons.bolt_outlined,       tokens: tokens),
                _StatProgressTile(label: '영양균형',  value: 74, color: const Color(0xFF7BD3FF), icon: Icons.favorite_outline,    tokens: tokens),
                _StatProgressTile(label: '친밀도',   value: 91, color: const Color(0xFFFF8FA3), icon: Icons.star_outline,         tokens: tokens),
              ],
            ),
            const SizedBox(height: 24),

            // 진화 단계
            Text('진화 단계', style: _sectionStyle(context, tokens)),
            const SizedBox(height: 10),
            BentoCard(
              borderRadius: BorderRadius.circular(tokens.rCard),
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _EvolutionStage(label: '알',    minLevel: 1,  current: _mockLevel == 1, done: _mockLevel > 1,  tokens: tokens),
                  _EvolutionStage(label: '아기',   minLevel: 3,  current: _mockLevel >= 3 && _mockLevel < 7, done: _mockLevel >= 7,  tokens: tokens),
                  _EvolutionStage(label: '청소년', minLevel: 7,  current: _mockLevel >= 7 && _mockLevel < 15, done: _mockLevel >= 15, tokens: tokens),
                  _EvolutionStage(label: '성체',   minLevel: 15, current: _mockLevel >= 15 && _mockLevel < 30, done: _mockLevel >= 30, tokens: tokens),
                  _EvolutionStage(label: '전설',   minLevel: 30, current: _mockLevel >= 30, done: false, tokens: tokens),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 장착 중
            Text('장착 중', style: _sectionStyle(context, tokens)),
            const SizedBox(height: 10),
            BentoCard(
              borderRadius: BorderRadius.circular(tokens.rCard),
              child: Column(
                children: [
                  _EquipmentItem(label: '칭호',    value: '없음',  onTap: () => context.push('/character/titles'),  tokens: tokens),
                  Divider(height: 1, color: tokens.primary.withValues(alpha: 0.08)),
                  _EquipmentItem(label: '배경',    value: '빈 방', onTap: () => context.push('/character/rewards'), tokens: tokens),
                  Divider(height: 1, color: tokens.primary.withValues(alpha: 0.08)),
                  _EquipmentItem(label: '악세서리', value: '없음',  onTap: () => context.push('/character/rewards'), tokens: tokens),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 도감
            Text('도감', style: _sectionStyle(context, tokens)),
            const SizedBox(height: 10),
            BentoCard(
              borderRadius: BorderRadius.circular(tokens.rCard),
              child: Column(
                children: [
                  _EquipmentItem(label: '먹찌 도감',   value: '', onTap: () => context.push('/character/collection'),   tokens: tokens),
                  Divider(height: 1, color: tokens.primary.withValues(alpha: 0.08)),
                  _EquipmentItem(label: '먹부림 도감',  value: '', onTap: () => context.push('/meal-record/masteries'), tokens: tokens),
                  Divider(height: 1, color: tokens.primary.withValues(alpha: 0.08)),
                  _EquipmentItem(label: '뱃지',        value: '', onTap: () => context.push('/profile/badges'),         tokens: tokens),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  TextStyle _sectionStyle(BuildContext context, AppColorTokens tokens) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
      );

  Widget _levelBadge(String text, AppColorTokens tokens) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: tokens.heroText),
    ),
  );

  Widget _statePill(CharacterState state, AppColorTokens tokens) {
    final stateColor = switch (state) {
      CharacterState.happy    => const Color(0xFFFF85A1),
      CharacterState.hungry   => const Color(0xFFFFCC33),
      CharacterState.starving => const Color(0xFFFF4444),
      CharacterState.weak     => const Color(0xFFA0A5BB),
      CharacterState.normal   => const Color(0xFF4CAF50),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: stateColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        state.label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
      ),
    );
  }
}

class _StatProgressTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  final AppColorTokens tokens;

  const _StatProgressTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      borderRadius: BorderRadius.circular(tokens.rCard),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 12, color: tokens.textSub, fontWeight: FontWeight.w500)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: '$value',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: tokens.textPrimary),
                  ),
                  TextSpan(
                    text: '/100',
                    style: TextStyle(fontSize: 11, color: tokens.textMuted),
                  ),
                ]),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: value / 100,
                  minHeight: 4,
                  backgroundColor: tokens.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvolutionStage extends StatelessWidget {
  final String label;
  final int minLevel;
  final bool current;
  final bool done;
  final AppColorTokens tokens;

  const _EvolutionStage({
    required this.label,
    required this.minLevel,
    required this.current,
    required this.done,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: current ? tokens.primary : done ? tokens.primaryBg : tokens.listItemBg,
              borderRadius: BorderRadius.circular(12),
              border: current || done ? null : Border.all(color: tokens.primary.withValues(alpha: 0.15)),
            ),
            child: Center(
              child: done
                  ? Icon(Icons.check, size: 16, color: tokens.primary)
                  : current
                      ? Icon(Icons.egg_outlined, size: 20, color: tokens.bg)
                      : Text('?', style: TextStyle(color: tokens.textMuted.withValues(alpha: 0.4), fontSize: 16)),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: current ? FontWeight.w700 : FontWeight.w500,
              color: current ? tokens.primary : tokens.textSub,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'Lv.$minLevel',
            style: TextStyle(fontSize: 9, color: tokens.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EquipmentItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final AppColorTokens tokens;

  const _EquipmentItem({
    required this.label,
    required this.value,
    required this.onTap,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 15, color: tokens.textPrimary)),
            Row(
              children: [
                if (value.isNotEmpty)
                  Text(value, style: TextStyle(fontSize: 14, color: tokens.textSub)),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios, size: 13, color: tokens.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
