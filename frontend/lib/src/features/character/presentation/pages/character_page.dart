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
import '../../domain/models/reward_model.dart';
import '../providers/character_provider.dart';
import '../providers/title_provider.dart';

class CharacterPage extends ConsumerWidget {
  const CharacterPage({super.key});

  // 화면폭 대비 캐릭터 크기 비율. clamp와 함께 333~444px 폭 구간에서만 비례 동작.
  static const double _widthRatio = 0.45;
  static const double _minCharSize = 150;
  static const double _maxCharSize = 200;

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
            // 캐릭터 히어로 — 시멀리스 (카드 없음)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _nutritionBadge('$nutritionDays일', tokens),
                _statePill(state, tokens),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: MukzziCharacter(
                state: state,
                size: (MediaQuery.sizeOf(context).width * _widthRatio)
                    .clamp(_minCharSize, _maxCharSize)
                    .toDouble(),
                showAccessory: char?.equippedAccessory != null,
                equippedAccessory: char?.equippedAccessory?.assetUrl,
                equipment: char?.equipment ?? const {},
                backgroundEdgeFade: true,
              ),
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
                        label: Text(s.label,
                            style: const TextStyle(fontSize: 10)),
                        onPressed: () => ref
                            .read(testCharacterProvider.notifier)
                            .updateState(s),
                        backgroundColor: state == s
                            ? tokens.primary.withValues(alpha: 0.2)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // 영양 달성
            Text('영양 달성', style: _sectionStyle(context, tokens)),
            const SizedBox(height: 10),
            BentoCard(
              borderRadius: BorderRadius.circular(tokens.rCard),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department,
                      color: tokens.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '누적 영양 균형 달성일',
                          style:
                              TextStyle(fontSize: 12, color: tokens.textMuted),
                        ),
                        Text(
                          '$nutritionDays일',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: tokens.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 장착 중
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('장착 중', style: _sectionStyle(context, tokens)),
                TextButton(
                  onPressed: () => context.push('/character/equipment?tab=item'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '변경',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.primary,
                    ),
                  ),
                ),
              ],
            ),
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
                    tokens: tokens,
                  ),
                  ...() {
                    final activeSlots = [
                      EquipmentSlot.background,
                      EquipmentSlot.head,
                      EquipmentSlot.face,
                      EquipmentSlot.back,
                      EquipmentSlot.hand,
                      EquipmentSlot.aura,
                    ];
                    final equippedItems = <Widget>[];
                    for (final slot in activeSlots) {
                      final item = char?.equipment[slot];
                      if (item != null) {
                        equippedItems.add(
                          Divider(height: 1, color: tokens.primary.withValues(alpha: 0.08)),
                        );
                        equippedItems.add(
                          _EquipmentItem(
                            label: slot.label,
                            value: item.name,
                            tokens: tokens,
                          ),
                        );
                      } else if (slot == EquipmentSlot.background) {
                        equippedItems.add(
                          Divider(height: 1, color: tokens.primary.withValues(alpha: 0.08)),
                        );
                        equippedItems.add(
                          _EquipmentItem(
                            label: slot.label,
                            value: '기본 배경',
                            tokens: tokens,
                          ),
                        );
                      }
                    }
                    return equippedItems;
                  }(),
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
                  _EquipmentItem(
                      label: '먹찌 도감',
                      value: '',
                      onTap: () => context.push('/character/collection'),
                      tokens: tokens),
                  Divider(
                      height: 1, color: tokens.primary.withValues(alpha: 0.08)),
                  _EquipmentItem(
                      label: '먹부림 도감',
                      value: '',
                      onTap: () => context.push('/meal-record/masteries'),
                      tokens: tokens),
                  Divider(
                      height: 1, color: tokens.primary.withValues(alpha: 0.08)),
                  _EquipmentItem(
                      label: '뱃지',
                      value: '',
                      onTap: () => context.push('/profile/badges'),
                      tokens: tokens),
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
          style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary),
        ),
      );

  Widget _statePill(CharacterState state, AppColorTokens tokens) {
    final stateColor = switch (state) {
      CharacterState.happy => const Color(0xFFFF85A1),
      CharacterState.hungry => const Color(0xFFFFCC33),
      CharacterState.starving => const Color(0xFFFF4444),
      CharacterState.sleeping => const Color(0xFF2D6BFF),
      CharacterState.normal => const Color(0xFF4CAF50),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: stateColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        state.label,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A)),
      ),
    );
  }
}

class _EquipmentItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final AppColorTokens tokens;

  const _EquipmentItem({
    required this.label,
    required this.value,
    this.onTap,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final hasTap = onTap != null;
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 15, color: tokens.textPrimary)),
          Row(
            children: [
              if (value.isNotEmpty)
                Text(value,
                    style: TextStyle(fontSize: 14, color: tokens.textSub)),
              if (hasTap) ...[
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios,
                    size: 13, color: tokens.textMuted),
              ],
            ],
          ),
        ],
      ),
    );

    if (hasTap) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }
}
