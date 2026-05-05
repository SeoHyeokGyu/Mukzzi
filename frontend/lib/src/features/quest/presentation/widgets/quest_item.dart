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
                  const Text(
                    '수령 완료',
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                  )
                else if (isCompleted)
                  const Text(
                    '완료!',
                    style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 8),
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
