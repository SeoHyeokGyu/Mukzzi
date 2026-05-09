import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/features/quest/presentation/providers/quest_provider.dart';
import 'package:mukzzi/src/features/quest/presentation/widgets/quest_item.dart';
import '../../../../core/widgets/collection_states.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/models/badge_model.dart';
import '../providers/badge_provider.dart';
import '../widgets/badge_grid_item.dart';
import '../widgets/badge_progress_banner.dart';

class BadgeListPage extends ConsumerStatefulWidget {
  const BadgeListPage({super.key});

  @override
  ConsumerState<BadgeListPage> createState() => _BadgeListPageState();
}

class _BadgeListPageState extends ConsumerState<BadgeListPage> {
  String _selectedBadgeCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final badgesAsync = ref.watch(badgeListProvider);
    final achievementQuests = ref.watch(achievementQuestsProvider);

    return DefaultTabController(
      length: 2,
      child: GradientScaffold(
        appBar: AppBar(
          title: const Text('나의 기록'),
          bottom: TabBar(
            indicatorColor: tokens.primary,
            labelColor: tokens.primary,
            unselectedLabelColor: tokens.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: '업적'),
              Tab(text: '뱃지'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. 업적 탭
            _buildAchievementTab(achievementQuests),
            
            // 2. 뱃지 탭
            badgesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => CollectionErrorState(onRetry: () => ref.invalidate(badgeListProvider)),
              data: (badges) => _buildBadgeTab(badges, tokens),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementTab(List<dynamic> quests) {
    if (quests.isEmpty) {
      return const CollectionEmptyState(
        icon: Icons.stars_rounded,
        title: '진행 중인 업적이 없어요',
        subtitle: '다양한 활동을 통해 업적을 쌓아보세요',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        return QuestItem(quest: quests[index]);
      },
    );
  }

  Widget _buildBadgeTab(List<BadgeModel> badges, AppColorTokens tokens) {
    final filtered = _selectedBadgeCategory == 'all'
        ? badges
        : badges.where((b) => b.category == _selectedBadgeCategory).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        BadgeProgressBanner(badges: badges),
        const SizedBox(height: 20),
        
        // 카테고리 필터 칩
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _CategoryChip(
                label: '전체',
                isSelected: _selectedBadgeCategory == 'all',
                onSelected: () => setState(() => _selectedBadgeCategory = 'all'),
                tokens: tokens,
              ),
              const SizedBox(width: 8),
              _CategoryChip(
                label: '식사',
                isSelected: _selectedBadgeCategory == 'meal',
                onSelected: () => setState(() => _selectedBadgeCategory = 'meal'),
                tokens: tokens,
              ),
              const SizedBox(width: 8),
              _CategoryChip(
                label: '출석',
                isSelected: _selectedBadgeCategory == 'attendance',
                onSelected: () => setState(() => _selectedBadgeCategory = 'attendance'),
                tokens: tokens,
              ),
              const SizedBox(width: 8),
              _CategoryChip(
                label: '소셜',
                isSelected: _selectedBadgeCategory == 'social',
                onSelected: () => setState(() => _selectedBadgeCategory = 'social'),
                tokens: tokens,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CollectionEmptyState(
              icon: Icons.military_tech_outlined,
              title: '해당 뱃지가 없어요',
              subtitle: '다른 카테고리를 확인해보세요',
            ),
          )
        else
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final AppColorTokens tokens;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: tokens.listItemBg,
      selectedColor: tokens.primary.withValues(alpha: 0.2),
      checkmarkColor: tokens.primary,
      labelStyle: TextStyle(
        color: isSelected ? tokens.primary : tokens.textSub,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? tokens.primary.withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
    );
  }
}
