import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/models/mastery_model.dart';
import '../providers/mastery_provider.dart';

class MasteryListPage extends ConsumerWidget {
  const MasteryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masteryAsync = ref.watch(masteryListProvider);

    return GradientScaffold(
      appBar: AppBar(title: const Text('먹부림 도감')),
      body: masteryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorState(onRetry: () => ref.invalidate(masteryListProvider)),
        data: (masteries) {
          if (masteries.isEmpty) return const _EmptyState();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: masteries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _MasteryCard(mastery: masteries[i]),
          );
        },
      ),
    );
  }
}

class _MasteryCard extends StatelessWidget {
  final MasteryModel mastery;
  const _MasteryCard({required this.mastery});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          // 등급 뱃지
          _GradeChip(grade: mastery.grade),
          const SizedBox(width: 14),
          // 메뉴 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mastery.menuName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mastery.menuCategory,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // 섭취 횟수 + 날짜
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${mastery.eatCount}회',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MM.dd').format(mastery.lastEatenAt.toLocal()),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  final String grade;
  const _GradeChip({required this.grade});

  Color get _color {
    switch (grade) {
      case 'MASTER':
        return const Color(0xFFFFD700);
      case 'ARTISAN':
        return AppColors.orange;
      case 'MANIA':
        return AppColors.peach;
      default:
        return AppColors.textTertiary;
    }
  }

  String get _label {
    switch (grade) {
      case 'MASTER':
        return '마스터';
      case 'ARTISAN':
        return '장인';
      case 'MANIA':
        return '매니아';
      default:
        return '입문';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          _label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _color,
          ),
        ),
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
          Icon(Icons.restaurant_menu, size: 64, color: AppColors.iconDisabled),
          SizedBox(height: 16),
          Text('아직 마스터리가 없어요', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          SizedBox(height: 8),
          Text('식사를 기록하면 마스터리가 쌓여요', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
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
