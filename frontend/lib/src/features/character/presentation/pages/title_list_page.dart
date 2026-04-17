import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/collection_states.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/models/title_model.dart';
import '../providers/title_provider.dart';

class TitleListPage extends ConsumerWidget {
  const TitleListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titlesAsync = ref.watch(titleListProvider);

    return GradientScaffold(
      appBar: AppBar(title: const Text('칭호')),
      body: titlesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => CollectionErrorState(onRetry: () => ref.invalidate(titleListProvider)),
        data: (titles) {
          if (titles.isEmpty) {
            return const CollectionEmptyState(
              icon: Icons.workspace_premium,
              title: '아직 칭호가 없어요',
              subtitle: '다양한 도전을 달성하면 칭호를 얻을 수 있어요',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: titles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _TitleCard(
              title: titles[i],
              onEquip: () => _handleEquip(context, ref, titles[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleEquip(BuildContext context, WidgetRef ref, TitleModel title) async {
    final repo = ref.read(titleRepositoryProvider);
    try {
      if (title.isEquipped) {
        await repo.equipTitle(null);
      } else {
        await repo.equipTitle(title.id);
      }
      ref.invalidate(titleListProvider);
    } catch (e) {
      debugPrint('[TitleListPage] equipTitle error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('처리 중 오류가 발생했어요')),
        );
      }
    }
  }
}

class _TitleCard extends StatelessWidget {
  final TitleModel title;
  final VoidCallback onEquip;

  const _TitleCard({required this.title, required this.onEquip});

  @override
  Widget build(BuildContext context) {
    final acquired = title.acquired;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: title.isEquipped
            ? Border.all(color: AppColors.orange.withValues(alpha: 0.5), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // 칭호 아이콘
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: acquired
                  ? AppColors.softPeach
                  : AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.workspace_premium,
              size: 26,
              color: acquired ? AppColors.orange : AppColors.iconDisabled,
            ),
          ),
          const SizedBox(width: 14),
          // 칭호 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: acquired ? AppColors.textPrimary : AppColors.textTertiary,
                      ),
                    ),
                    if (title.isEquipped) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.softPeach,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '장착 중',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  title.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                if (acquired && title.achievedAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('yyyy.MM.dd').format(title.achievedAt!.toLocal()),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 장착 버튼
          if (acquired)
            TextButton(
              onPressed: onEquip,
              style: TextButton.styleFrom(
                foregroundColor: title.isEquipped ? AppColors.textSecondary : AppColors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(title.isEquipped ? '해제' : '장착'),
            ),
        ],
      ),
    );
  }
}

