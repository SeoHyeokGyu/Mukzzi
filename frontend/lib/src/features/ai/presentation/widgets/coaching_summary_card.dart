import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/bento_card.dart';
import 'package:mukzzi/src/features/ai/presentation/providers/ai_provider.dart';

class CoachingSummaryCard extends ConsumerWidget {
  final String? date; // yyyy-MM-dd

  const CoachingSummaryCard({super.key, this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final coachingAsync = ref.watch(nutritionCoachingProvider(date ?? todayStr));

    return BentoCard(
      borderRadius: BorderRadius.circular(tokens.rCard),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.health_and_safety, color: tokens.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'AI 영양 코칭',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: tokens.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => ref.invalidate(nutritionCoachingProvider(date ?? todayStr)),
                visualDensity: VisualDensity.compact,
                color: tokens.textMuted,
                tooltip: '다시 코칭받기',
              ),
            ],
          ),
          const SizedBox(height: 16),
          coachingAsync.when(
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: tokens.primary, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${data.score}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: tokens.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        data.summary,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (data.tips.isNotEmpty) ...[
                  Text(
                    '💡 내일을 위한 팁',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: tokens.textSub,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...data.tips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(color: tokens.textMuted)),
                            Expanded(
                              child: Text(
                                tip,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tokens.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ]
              ],
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) => Text(
              err.toString(),
              style: TextStyle(color: tokens.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
