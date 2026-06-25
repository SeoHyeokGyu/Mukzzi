import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/bento_card.dart';
import 'package:mukzzi/src/features/quest/domain/entities/quest.dart';
import 'package:mukzzi/src/features/quest/presentation/providers/quest_provider.dart';

class QuestItem extends ConsumerWidget {
  final Quest quest;

  const QuestItem({super.key, required this.quest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final isCompleted = quest.isCompleted;
    final isClaimed = quest.isClaimed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BentoCard(
        borderRadius: BorderRadius.circular(tokens.rItem),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 태그 및 상태 표시 (수령 완료/완료)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(quest.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    quest.category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(quest.category),
                    ),
                  ),
                ),
                if (isClaimed)
                  Text(
                    '수령 완료',
                    style: TextStyle(fontSize: 12, color: tokens.textMuted, fontWeight: FontWeight.bold),
                  )
                else if (isCompleted)
                  const Text(
                    '완료!',
                    style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // 퀘스트 제목 및 설명
            Text(
              quest.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              quest.description,
              style: TextStyle(fontSize: 13, color: tokens.textSub),
            ),
            const SizedBox(height: 16),
            // 진행도 인디케이터
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: quest.progress,
                      minHeight: 8,
                      backgroundColor: tokens.primaryBg,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? Colors.green : tokens.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${quest.currentCount} / ${quest.targetCount}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 퀘스트 보상 목록 (포인트, EXP, 뱃지, 칭호, 아이템)
            Wrap(
              spacing: 8,
              children: [
                if (quest.rewardPoint > 0)
                  _RewardBadge(
                    icon: Icons.monetization_on,
                    label: '${quest.rewardPoint} P',
                    color: Colors.amber,
                  ),
                if (quest.rewardExp > 0)
                  _RewardBadge(
                    icon: Icons.bolt,
                    label: '${quest.rewardExp} EXP',
                    color: Colors.blue,
                  ),
                if (quest.rewardBadgeId != null)
                  const _RewardBadge(
                    icon: Icons.verified,
                    label: '뱃지 획득',
                    color: Colors.orange,
                  ),
                if (quest.rewardTitleId != null)
                  const _RewardBadge(
                    icon: Icons.title,
                    label: '칭호 획득',
                    color: Colors.purple,
                  ),
                if (quest.rewardItemId != null)
                  const _RewardBadge(
                    icon: Icons.card_giftcard,
                    label: '아이템 획득',
                    color: Colors.pink,
                  ),
              ],
            ),
            // 완료되었으나 수령하지 않은 경우 보상 받기 버튼 표시
            if (isCompleted && !isClaimed) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await ref.read(questProvider.notifier).claimReward(quest.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? '보상이 지급되었습니다!' : '보상 수령에 실패했습니다.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('보상 받기', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'MEAL':
        return Colors.orange;
      case 'SOCIAL':
        return Colors.blue;
      case 'GROWTH':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _RewardBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RewardBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
