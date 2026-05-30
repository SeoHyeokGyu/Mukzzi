import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/bento_card.dart';
import 'package:mukzzi/src/features/ai/presentation/providers/ai_provider.dart';

class RecommendationCard extends ConsumerWidget {
  final String mealType;

  const RecommendationCard({super.key, this.mealType = 'LUNCH'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final recommendationAsync = ref.watch(recommendMealProvider(mealType));

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
                  Icon(Icons.auto_awesome, color: tokens.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'AI 식단 추천',
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
                onPressed: () => ref.invalidate(recommendMealProvider(mealType)),
                visualDensity: VisualDensity.compact,
                color: tokens.textMuted,
                tooltip: '다른 추천 받기',
              ),
            ],
          ),
          const SizedBox(height: 12),
          recommendationAsync.when(
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.reasoning,
                  style: TextStyle(fontSize: 13, color: tokens.textSub),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.recommendations.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = data.recommendations[index];
                      return GestureDetector(
                        onTap: () {
                          context.go('/meal-record', extra: {
                            'initialMenuName': item.menuName,
                            'initialCategory': item.category,
                            'initialCalories': item.calories,
                          });
                        },
                        child: Container(
                          width: 140,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tokens.primaryBg.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tokens.primaryBg),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.menuName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.calories} kcal',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tokens.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  item.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: tokens.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
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
              style: TextStyle(color: tokens.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
