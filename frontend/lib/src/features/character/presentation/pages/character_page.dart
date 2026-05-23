import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/mukzzi_character.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../providers/character_provider.dart';
import '../providers/title_provider.dart';

class CharacterPage extends ConsumerWidget {
  const CharacterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final currentUser = ref.watch(userProvider).user;
    final isAdmin = kDebugMode || currentUser?.username == 'admin';

    final charAsync = isAdmin
        ? ref.watch(testCharacterProvider)
        : ref.watch(characterProvider);

    final char = charAsync.valueOrNull;

    final nutritionDays = char?.nutritionAchievementDays ?? 0;
    final state = char?.state ?? CharacterState.normal;

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
                    '영양 달성 $nutritionDays일',
                    style: TextStyle(fontSize: 13, color: tokens.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    char?.name ?? '먹찌',
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
              showPaperTexture: true,
              borderRadius: BorderRadius.circular(tokens.rHero),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _nutritionBadge('$nutritionDays일', tokens),
                      _statePill(state, tokens),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MukzziCharacter(
                    state: state,
                    size: 200,
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: CharacterState.values.map((s) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(s.label, style: const TextStyle(fontSize: 10)),
                              onPressed: () => ref.read(testCharacterProvider.notifier).updateState(s),
                              backgroundColor: state == s ? tokens.primary.withValues(alpha: 0.2) : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 영양 달성
            Text('영양 달성', style: _sectionStyle(context, tokens)),
            const SizedBox(height: 10),
            BentoCard(
              borderRadius: BorderRadius.circular(tokens.rCard),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department, color: tokens.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '누적 영양 균형 달성일',
                          style: TextStyle(fontSize: 12, color: tokens.textMuted),
                        ),
                        Text(
                          '$nutritionDays일',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tokens.textPrimary),
                        ),
                      ],
                    ),
                  ),
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
                  _EquipmentItem(
                    label: '칭호',
                    value: ref.watch(equippedTitleProvider).maybeWhen(
                      data: (t) => t?.name ?? '없음',
                      orElse: () => '없음',
                    ),
                    onTap: () => context.push('/character/titles'),
                    tokens: tokens,
                  ),
                  Divider(height: 1, color: tokens.primary.withValues(alpha: 0.08)),
                  _EquipmentItem(
                    label: '배경',
                    value: char?.equippedBackground?.name ?? '기본 배경',
                    onTap: () => context.push('/character/rewards'),
                    tokens: tokens,
                  ),
                  Divider(height: 1, color: tokens.primary.withValues(alpha: 0.08)),
                  _EquipmentItem(
                    label: '악세서리',
                    value: char?.equippedAccessory?.name ?? '없음',
                    onTap: () => context.push('/character/rewards'),
                    tokens: tokens,
                  ),
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

  Widget _nutritionBadge(String text, AppColorTokens tokens) => Container(
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
      CharacterState.sleeping => const Color(0xFF2D6BFF),
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
