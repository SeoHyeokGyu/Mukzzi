import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/collection_states.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/models/mastery_model.dart';
import '../providers/mastery_provider.dart';
import '../../../meal_record/presentation/widgets/menu_detail_sheet.dart';

// ─────────────────────────────────────────
// Page
// ─────────────────────────────────────────

class MasteryListPage extends ConsumerWidget {
  const MasteryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masteryAsync = ref.watch(masteryListProvider);

    return GradientScaffold(
      appBar: AppBar(title: const Text('마스터리 도감')),
      body: masteryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => CollectionErrorState(
            onRetry: () => ref.invalidate(masteryListProvider)),
        data: (masteries) {
          if (masteries.isEmpty) {
            return const CollectionEmptyState(
              icon: Icons.restaurant_menu,
              title: '아직 마스터리가 없어요',
              subtitle: '식사를 기록하면 마스터리가 쌓여요',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: masteries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _MasteryCard(
              mastery: masteries[i],
              onTap: () => MenuDetailSheet.show(context, masteries[i].menuId, initialMastery: masteries[i]),
            ),
          );
        },
      ),
    );
  }
}

class _MasteryCard extends StatelessWidget {
  final MasteryModel mastery;
  final VoidCallback onTap;

  const _MasteryCard({required this.mastery, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            _GradeIcon(grade: mastery.grade),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mastery.menuName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mastery.menuCategory,
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${mastery.eatCount}회',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MM.dd').format(mastery.lastEatenAt.toLocal()),
                  style: TextStyle(
                    fontSize: 11,
                    color: tokens.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: tokens.textMuted),
          ],
        ),
      ),
    );
  }
}

class _GradeIcon extends StatelessWidget {
  final String grade;
  const _GradeIcon({required this.grade});

  Color _colorOf(BuildContext context) {
    switch (grade) {
      case 'MASTER':  return AppColors.masterGold;
      case 'ARTISAN': return AppColors.orange;
      case 'MANIA':   return AppColors.peach;
      default:        return Theme.of(context).extension<AppColorTokens>()!.textSub;
    }
  }

  String get _label {
    switch (grade) {
      case 'MASTER':  return '마스터';
      case 'ARTISAN': return '장인';
      case 'MANIA':   return '매니아';
      default:        return '입문';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorOf(context);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          _label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
