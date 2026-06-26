import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/collection_states.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/models/reward_model.dart';
import '../providers/character_provider.dart';
import '../providers/reward_provider.dart';

class RewardListPage extends ConsumerWidget {
  const RewardListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardListProvider);

    return GradientScaffold(
      appBar: AppBar(title: const Text('보상 아이템')),
      body: rewardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => CollectionErrorState(
            onRetry: () => ref.invalidate(rewardListProvider)),
        data: (rewards) {
          if (rewards.isEmpty) {
            return const CollectionEmptyState(
              icon: Icons.card_giftcard,
              title: '아직 보상 아이템이 없어요',
              subtitle: '미션을 달성하면 보상 아이템을 받을 수 있어요',
            );
          }

          // 타입별로 그룹화
          final groups = <String, List<RewardModel>>{};
          for (final r in rewards) {
            groups.putIfAbsent(r.rewardType, () => []).add(r);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: groups.entries.map((entry) {
              return _RewardGroup(
                typeLabel: entry.value.first.typeLabel,
                rewards: entry.value,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _RewardGroup extends StatelessWidget {
  final String typeLabel;
  final List<RewardModel> rewards;

  const _RewardGroup({required this.typeLabel, required this.rewards});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            typeLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.textSub,
            ),
          ),
        ),
        ...rewards.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RewardCard(reward: r),
            )),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _RewardCard extends ConsumerWidget {
  final RewardModel reward;

  const _RewardCard({required this.reward});

  IconData get _typeIcon {
    switch (reward.rewardType) {
      case 'BACKGROUND':
        return Icons.wallpaper;
      case 'EFFECT':
        return Icons.auto_awesome;
      case 'MOTION':
        return Icons.animation;
      case 'ACCESSORY':
        return Icons.diamond_outlined;
      default:
        return Icons.card_giftcard;
    }
  }

  bool get _isEquippable => reward.acquired && reward.renderConfig != null;

  Future<void> _toggleEquip(
      BuildContext context, WidgetRef ref, bool isCurrentlyEquipped) async {
    try {
      final repo = ref.read(characterRepositoryProvider);
      final slot = reward.renderConfig?.slot.value;
      if (slot == null) return;
      if (isCurrentlyEquipped) {
        await repo.equipItem(slot: slot, rewardId: null);
        ref.invalidate(characterProvider);
        ref.invalidate(testCharacterProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('장착 해제되었습니다.')),
          );
        }
      } else {
        await repo.equipItem(slot: slot, rewardId: reward.id);
        ref.invalidate(characterProvider);
        ref.invalidate(testCharacterProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('장착되었습니다.')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(isCurrentlyEquipped ? '장착 해제에 실패했습니다.' : '장착에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acquired = reward.acquired;
    final char = ref.watch(characterProvider).value;
    final slot = reward.renderConfig?.slot;
    final isEquipped =
        char != null && slot != null && char.equipment[slot]?.id == reward.id;
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: acquired ? tokens.primaryBg : tokens.listItemBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _typeIcon,
              size: 24,
              color: acquired ? tokens.primary : tokens.textMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: acquired ? tokens.textPrimary : tokens.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reward.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.textMuted,
                  ),
                ),
                if (acquired && reward.achievedAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('yyyy.MM.dd')
                        .format(reward.achievedAt!.toLocal()),
                    style: TextStyle(
                      fontSize: 11,
                      color: tokens.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_isEquippable)
            GestureDetector(
              onTap: () => _toggleEquip(context, ref, isEquipped),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isEquipped ? tokens.listItemBg : tokens.primaryBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isEquipped ? '해제' : '장착',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isEquipped ? tokens.textSub : tokens.primary,
                  ),
                ),
              ),
            )
          else if (acquired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: tokens.primaryBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '획득',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tokens.primary,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: tokens.listItemBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '미획득',
                style: TextStyle(fontSize: 11, color: tokens.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}
