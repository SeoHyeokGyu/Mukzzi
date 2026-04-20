import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CollectionEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const CollectionEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final iconColor = tokens?.textMuted ?? AppColors.iconDisabled;
    final titleColor = tokens?.textSub ?? AppColors.textSecondary;
    final subtitleColor = tokens?.textMuted ?? AppColors.textTertiary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: iconColor),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 16, color: titleColor)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 14, color: subtitleColor)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class CollectionErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const CollectionErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final iconColor = tokens?.textMuted ?? AppColors.textTertiary;
    final textColor = tokens?.textSub ?? AppColors.textSecondary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: iconColor),
          const SizedBox(height: 16),
          Text('불러오지 못했어요', style: TextStyle(color: textColor)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
