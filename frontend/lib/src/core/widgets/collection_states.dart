import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 도감 목록이 비어있을 때 표시하는 공통 위젯
class CollectionEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const CollectionEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.iconDisabled),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

/// 도감 목록 로드 실패 시 표시하는 공통 위젯
class CollectionErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const CollectionErrorState({super.key, required this.onRetry});

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
