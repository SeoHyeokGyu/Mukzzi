import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/collection_states.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/models/badge_model.dart';
import '../providers/badge_provider.dart';
import '../widgets/badge_grid_item.dart';
import '../widgets/badge_progress_banner.dart';

class BadgeListPage extends ConsumerWidget {
  const BadgeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(badgeListProvider);

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
        body: badgesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => CollectionErrorState(onRetry: () => ref.invalidate(badgeListProvider)),
          data: (badges) => TabBarView(
            children: [
              _BadgeTabContent(badges: badges, category: 'all'),
              _BadgeTabContent(badges: badges, category: 'meal'),
              _BadgeTabContent(badges: badges, category: 'attendance'),
              _BadgeTabContent(badges: badges, category: 'social'),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeTabContent extends StatelessWidget {
  final List<BadgeModel> badges;
  final String category;

  const _BadgeTabContent({required this.badges, required this.category});

  @override
  Widget build(BuildContext context) {
    final filtered = category == 'all'
        ? badges
        : badges.where((b) => b.category == category).toList();

    if (filtered.isEmpty) {
      return const CollectionEmptyState(
        icon: Icons.military_tech_outlined,
        title: '해당 뱃지가 없어요',
        subtitle: '다른 카테고리를 확인해보세요',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        BadgeProgressBanner(badges: filtered),
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
          itemCount: filtered.length,
          itemBuilder: (context, index) => BadgeGridItem(badge: filtered[index]),
        ),
      ],
    );
  }
}

