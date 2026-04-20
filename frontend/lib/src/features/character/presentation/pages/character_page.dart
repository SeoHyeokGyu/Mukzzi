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
      appBar: AppBar(title: const Text('내 캐릭터')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 캐릭터 히어로 카드
            BentoCard(
              gradient: heroBg,
              borderRadius: BorderRadius.circular(tokens.rHero),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  // 상태 뱃지 행
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _badge('Lv.$_mockLevel', tokens),
                      _statePill(_mockState, tokens),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MukzziCharacter(state: _mockState, size: 180, level: _mockLevel),
                  const SizedBox(height: 12),
                  Text(
                    '먹찌',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: tokens.heroText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '부화 단계 (EGG)',
                    style: TextStyle(fontSize: 13, color: tokens.heroTextSub),
                  ),
                  const SizedBox(height: 16),
                  // XP 바
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
            Row(
              children: [
                Expanded(child: _StatTile(label: '레벨', value: '$_mockLevel', icon: Icons.star_outline, tokens: tokens)),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(label: '경험치', value: '${_mockXp.toInt()}', icon: Icons.bolt_outlined, tokens: tokens)),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(label: '상태', value: _mockState.label, icon: Icons.favorite_outline, tokens: tokens)),
              ],
            ),
            const SizedBox(height: 24),

            // 파츠 조합
            Text('파츠 조합', style: _sectionStyle(context, tokens)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _PartCard(icon: Icons.person_outline,           label: '체형',  value: '보통',   tokens: tokens),
                _PartCard(icon: Icons.fitness_center,           label: '근육',  value: '보통',   tokens: tokens),
                _PartCard(icon: Icons.palette_outlined,         label: '피부색', value: '건강',  tokens: tokens),
                _PartCard(icon: Icons.sentiment_satisfied_outlined, label: '표정', value: '기분좋음', tokens: tokens),
              ],
            ),
            const SizedBox(height: 24),

            // 장착 중
            Text('장착 중', style: _sectionStyle(context, tokens)),
            const SizedBox(height: 10),
            BentoCard(
              borderRadius: BorderRadius.circular(tokens.rCard),
              child: Column(
                children: [
                  _EquipmentItem(label: '칭호',   value: '없음',  onTap: () => context.push('/character/titles'),  tokens: tokens),
                  const Divider(height: 1),
                  _EquipmentItem(label: '배경',   value: '빈 방', onTap: () => context.push('/character/rewards'), tokens: tokens),
                  const Divider(height: 1),
                  _EquipmentItem(label: '악세서리', value: '없음', onTap: () => context.push('/character/rewards'), tokens: tokens),
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
                  _EquipmentItem(label: '먹찌 도감',  value: '', onTap: () => context.push('/character/collection'),   tokens: tokens),
                  const Divider(height: 1),
                  _EquipmentItem(label: '먹부림 도감', value: '', onTap: () => context.push('/meal-record/masteries'), tokens: tokens),
                  const Divider(height: 1),
                  _EquipmentItem(label: '뱃지',       value: '', onTap: () => context.push('/profile/badges'),         tokens: tokens),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  TextStyle _sectionStyle(BuildContext context, AppColorTokens tokens) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w700,
      color: tokens.textPrimary,
    );
  }

  Widget _badge(String text, AppColorTokens tokens) {
    return Container(
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
  }

  Widget _statePill(CharacterState state, AppColorTokens tokens) {
    final dotColor = switch (state) {
      CharacterState.happy    => const Color(0xFFFF85A1),
      CharacterState.hungry   => const Color(0xFFFFCC33),
      CharacterState.starving => const Color(0xFFFF4444),
      CharacterState.weak     => const Color(0xFFA0A5BB),
      CharacterState.normal   => const Color(0xFF4CAF50),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(state.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.heroText)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final AppColorTokens tokens;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      borderRadius: BorderRadius.circular(tokens.rItem),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          Icon(icon, size: 20, color: tokens.primary),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: tokens.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: tokens.textMuted)),
        ],
      ),
    );
  }
}

class _PartCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppColorTokens tokens;

  const _PartCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      borderRadius: BorderRadius.circular(tokens.rItem),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: tokens.primary),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: tokens.textSub)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: tokens.textPrimary)),
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
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
