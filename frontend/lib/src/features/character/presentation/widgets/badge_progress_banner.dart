import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/gradient_progress_bar.dart';
import '../../domain/models/badge_model.dart';

class BadgeProgressBanner extends StatelessWidget {
  final List<BadgeModel> badges;

  const BadgeProgressBanner({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    final total = badges.length;
    final unlocked = badges.where((b) => b.isUnlocked).length;
    final percent = total > 0 ? unlocked / total : 0.0;
    final percentLabel = '${(percent * 100).round()}%';

    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '뱃지 달성 현황',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$unlocked',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        TextSpan(
                          text: ' / $total',
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.softPeach,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.military_tech,
                  size: 32,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GradientProgressBar(value: percent, height: 8),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 $total개 중 $unlocked개 획득',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                percentLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.peach,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
