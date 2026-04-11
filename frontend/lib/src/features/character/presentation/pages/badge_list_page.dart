import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/models/badge_model.dart';
import '../widgets/badge_grid_item.dart';
import '../widgets/badge_progress_banner.dart';

final _badgeListProvider = Provider<List<BadgeModel>>((ref) => mockBadges);

class BadgeListPage extends ConsumerWidget {
  const BadgeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: GradientScaffold(
        appBar: AppBar(
          title: const Text('뱃지'),
          bottom: const TabBar(
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            indicatorWeight: 2.5,
            tabs: [
              Tab(text: '전체'),
              Tab(text: '식사'),
              Tab(text: '출석'),
              Tab(text: '소셜'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BadgeTabContent(category: 'all'),
            _BadgeTabContent(category: 'meal'),
            _BadgeTabContent(category: 'attendance'),
            _BadgeTabContent(category: 'social'),
          ],
        ),
      ),
    );
  }
}

class _BadgeTabContent extends ConsumerWidget {
  final String category;

  const _BadgeTabContent({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBadges = ref.watch(_badgeListProvider);
    final badges = category == 'all'
        ? allBadges
        : allBadges.where((b) => b.category == category).toList();

    if (badges.isEmpty) {
      return const _EmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        BadgeProgressBanner(badges: badges),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.82,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) => BadgeGridItem(badge: badges[index]),
        ),
      ],
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
          Icon(
            Icons.military_tech_outlined,
            size: 64,
            color: AppColors.iconDisabled,
          ),
          SizedBox(height: 16),
          Text(
            '해당 뱃지가 없어요',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            '다른 카테고리를 확인해보세요',
            style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
