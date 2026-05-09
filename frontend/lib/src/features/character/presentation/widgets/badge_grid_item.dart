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
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    
    return Opacity(
      opacity: badge.isUnlocked ? 1.0 : 0.8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.rItem),
        child: Material(
          color: tokens.card,
          child: InkWell(
            onTap: () => BadgeDetailBottomSheet.show(context, badge),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(tokens.rItem),
                border: Border.all(
                  color: badge.isUnlocked
                      ? tokens.primary.withValues(alpha: 0.4)
                      : tokens.primary.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: badge.isUnlocked
                          ? tokens.primary.withValues(alpha: 0.12)
                          : tokens.listItemBg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      badge.iconData,
                      size: 24,
                      color: badge.isUnlocked
                          ? tokens.primary
                          : tokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: badge.isUnlocked
                          ? tokens.textPrimary
                          : tokens.textSub,
                      fontWeight: badge.isUnlocked
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _buildProgressOrDate(tokens),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressOrDate(AppColorTokens tokens) {
    if (badge.isUnlocked && badge.unlockedAt != null) {
      final date = DateTime.tryParse(badge.unlockedAt!);
      final formatted = date != null
          ? DateFormat('MM.dd').format(date.toLocal())
          : '';

      return Text(
        '$formatted 획득',
        style: TextStyle(fontSize: 9, color: tokens.primary, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      );
    }

    // 진행도 표시 (미획득 시)
    if (badge.target > 0) {
      final double progressValue = (badge.progress / badge.target).clamp(0.0, 1.0);
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              width: 40,
              height: 3,
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: tokens.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(tokens.primary.withValues(alpha: 0.6)),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${badge.progress}/${badge.target}',
            style: TextStyle(fontSize: 8, color: tokens.textMuted, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return Icon(
      Icons.lock_outline,
      size: 10,
      color: tokens.textMuted,
    );
  }
}
