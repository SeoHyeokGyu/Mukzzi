import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/models/reward_model.dart';
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
        error: (_, __) => _ErrorState(onRetry: () => ref.invalidate(rewardListProvider)),
        data: (rewards) {
          if (rewards.isEmpty) return const _EmptyState();

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            typeLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
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

class _RewardCard extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final acquired = reward.acquired;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: acquired ? AppColors.softPeach : AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _typeIcon,
              size: 24,
              color: acquired ? AppColors.orange : AppColors.iconDisabled,
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
                    color: acquired ? AppColors.textPrimary : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reward.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                if (acquired && reward.achievedAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('yyyy.MM.dd').format(reward.achievedAt!.toLocal()),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (acquired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.softPeach,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '획득',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orange,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '미획득',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, size: 64, color: AppColors.iconDisabled),
          SizedBox(height: 16),
          Text('아직 보상 아이템이 없어요', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          SizedBox(height: 8),
          Text('미션을 달성하면 보상 아이템을 받을 수 있어요', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          const Text('불러오지 못했어요', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
