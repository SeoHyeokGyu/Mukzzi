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
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
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
                  Text(
                    '뱃지 달성 현황',
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.textSub,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$unlocked',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: tokens.primary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        TextSpan(
                          text: ' / $total',
                          style: TextStyle(
                            fontSize: 18,
                            color: tokens.textSub,
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
                  color: tokens.primaryBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.military_tech,
                  size: 32,
                  color: tokens.primary,
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
                style: TextStyle(
                  fontSize: 11,
                  color: tokens.textSub,
                ),
              ),
              Text(
                percentLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: tokens.primarySoft,
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
