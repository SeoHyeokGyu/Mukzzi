import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/badge_model.dart';

class BadgeDetailBottomSheet extends StatelessWidget {
  final BadgeModel badge;
  final ScrollController? scrollController;

  const BadgeDetailBottomSheet({
    super.key,
    required this.badge,
    this.scrollController,
  });

  static void show(BuildContext context, BadgeModel badge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (context, scrollController) => BadgeDetailBottomSheet(
          badge: badge,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 32 + bottomPadding),
          child: Column(
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 24),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 아이콘 영역
              _buildIcon(),
              const SizedBox(height: 16),

              // 뱃지 이름
              Text(
                badge.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // 설명
              Text(
                badge.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 달성 조건 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 18,
                      color: AppColors.orange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '달성 조건',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            badge.condition,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 획득일 / 미획득
              _buildUnlockStatus(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (badge.isUnlocked) {
      return Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.softPeach,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(badge.iconData, size: 44, color: AppColors.orange),
      );
    }

    return Stack(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(badge.iconData, size: 44, color: AppColors.textTertiary),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockStatus() {
    if (badge.isUnlocked && badge.unlockedAt != null) {
      final date = DateTime.tryParse(badge.unlockedAt!);
      final formatted = date != null
          ? DateFormat('yyyy.MM.dd').format(date.toLocal())
          : badge.unlockedAt!;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.orange),
          const SizedBox(width: 6),
          Text(
            '$formatted 획득',
            style: const TextStyle(fontSize: 13, color: AppColors.peach),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        '아직 달성하지 못했어요',
        style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
        textAlign: TextAlign.center,
      ),
    );
  }
}
