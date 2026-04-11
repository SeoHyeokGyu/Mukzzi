import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/badge_model.dart';
import 'badge_detail_bottom_sheet.dart';

class BadgeGridItem extends StatelessWidget {
  final BadgeModel badge;

  const BadgeGridItem({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: badge.isUnlocked ? 1.0 : 0.6,
      child: GestureDetector(
        onTap: () => BadgeDetailBottomSheet.show(context, badge),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: badge.isUnlocked
                  ? AppColors.orange.withValues(alpha: 0.4)
                  : AppColors.divider,
              width: 1,
            ),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 아이콘 래퍼
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: badge.isUnlocked
                      ? AppColors.softPeach
                      : const Color(0xFF1A1A22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  badge.iconData,
                  size: 28,
                  color: badge.isUnlocked
                      ? AppColors.orange
                      : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),

              // 뱃지 이름
              Text(
                badge.name,
                style: TextStyle(
                  fontSize: 11,
                  color: badge.isUnlocked
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: badge.isUnlocked
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // 획득일 또는 잠금 표시
              _buildSubtitle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    if (badge.isUnlocked && badge.unlockedAt != null) {
      final date = DateTime.tryParse(badge.unlockedAt!);
      final formatted = date != null
          ? DateFormat('MM.dd').format(date.toLocal())
          : '';

      return Text(
        '$formatted 획득',
        style: const TextStyle(fontSize: 9, color: AppColors.peach),
        textAlign: TextAlign.center,
      );
    }

    return const Icon(
      Icons.lock_outline,
      size: 10,
      color: AppColors.textTertiary,
    );
  }
}
