import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/common_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/collection_states.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/models/mastery_model.dart';
import '../providers/mastery_provider.dart';
import '../../../meal_record/data/models/menu_model.dart';
import '../../../meal_record/data/repositories/menu_repository.dart';
import '../../../meal_record/data/repositories/preference_repository.dart';
import '../../../meal_record/presentation/providers/favorite_provider.dart';

// ── 메뉴 상세 조회 provider ──

final _menuDetailProvider =
FutureProvider.family<MenuModel?, String>((ref, menuId) async {
  final repo = MenuRepository(ref.watch(apiClientProvider));
  return repo.findById(menuId);
});

// ── 선호도 로컬 상태 provider (menuId별, 초기값은 API 응답으로 세팅) ──

final _preferenceStateProvider =
StateProvider.family<String?, String>((ref, menuId) {
  // _menuDetailProvider가 이미 로드된 경우 초기값으로 사용
  final menuAsync = ref.read(_menuDetailProvider(menuId));
  return menuAsync.valueOrNull?.preference;
});

// ─────────────────────────────────────────
// Page
// ─────────────────────────────────────────

class MasteryListPage extends ConsumerWidget {
  const MasteryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masteryAsync = ref.watch(masteryListProvider);

    return GradientScaffold(
      appBar: AppBar(title: const Text('마스터리 도감')),
      body: masteryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => CollectionErrorState(
            onRetry: () => ref.invalidate(masteryListProvider)),
        data: (masteries) {
          if (masteries.isEmpty) {
            return const CollectionEmptyState(
              icon: Icons.restaurant_menu,
              title: '아직 마스터리가 없어요',
              subtitle: '식사를 기록하면 마스터리가 쌓여요',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: masteries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _MasteryCard(
              mastery: masteries[i],
              onTap: () => _showMenuDetail(context, masteries[i]),
            ),
          );
        },
      ),
    );
  }

  void _showMenuDetail(BuildContext context, MasteryModel mastery) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MenuDetailSheet(mastery: mastery),
    );
  }
}

// ─────────────────────────────────────────
// 메뉴 상세 바텀시트
// ─────────────────────────────────────────

class _MenuDetailSheet extends ConsumerWidget {
  final MasteryModel mastery;

  const _MenuDetailSheet({required this.mastery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(_menuDetailProvider(mastery.menuId));
    // favoriteListProvider(limit=50)에 없으면 API 응답의 isFavorite으로 보완
    final isInFavList = ref.watch(
      favoriteListProvider.select((s) => s.favorites.any((f) => f.menu.id == mastery.menuId)),
    );
    final apiIsFav = ref.watch(_menuDetailProvider(mastery.menuId))
        .valueOrNull?.isFavorite ?? false;
    final isFav = isInFavList || apiIsFav;
    final preference = ref.watch(_preferenceStateProvider(mastery.menuId));
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          menuAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(40),
              child: Text('메뉴 정보를 불러오지 못했어요'),
            ),
            data: (menu) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 메뉴명 + 등급
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mastery.menuName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: tokens.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mastery.menuCategory,
                              style: TextStyle(
                                  fontSize: 13, color: tokens.textMuted),
                            ),
                          ],
                        ),
                      ),
                      _GradeChip(grade: mastery.grade),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 영양 정보
                  if (menu != null) ...[
                    _NutritionRow(menu: menu, tokens: tokens),
                    const SizedBox(height: 16),
                  ],

                  // 마스터리 통계
                  _MasteryStats(mastery: mastery, tokens: tokens),
                  const SizedBox(height: 20),

                  const Divider(),
                  const SizedBox(height: 16),

                  // 즐겨찾기 + 좋아요 + 싫어요
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: isFav ? Icons.star : Icons.star_border,
                          label: isFav ? '즐겨찾기 해제' : '즐겨찾기',
                          color: Colors.amber,
                          active: isFav,
                          onTap: () async {
                            if (menu == null) return;
                            await ref
                                .read(favoriteListProvider.notifier)
                                .toggle(MenuModel(
                              id: mastery.menuId,
                              name: mastery.menuName,
                              category: mastery.menuCategory,
                              source: menu.source,
                              defaultCalories: menu.defaultCalories,
                              defaultCarbs: menu.defaultCarbs,
                              defaultProtein: menu.defaultProtein,
                              defaultFat: menu.defaultFat,
                              defaultFiber: menu.defaultFiber,
                              defaultVitaminScore: menu.defaultVitaminScore,
                            ));
                          },
                          tokens: tokens,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.thumb_up_outlined,
                          label: '좋아요',
                          color: tokens.primary,
                          active: preference == 'LIKE',
                          onTap: () => _handlePreference(
                              context, ref, menu, 'LIKE', preference),
                          tokens: tokens,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.thumb_down_outlined,
                          label: '싫어요',
                          color: tokens.textSub,
                          active: preference == 'DISLIKE',
                          onTap: () => _handlePreference(
                              context, ref, menu, 'DISLIKE', preference),
                          tokens: tokens,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePreference(
      BuildContext context,
      WidgetRef ref,
      MenuModel? menu,
      String value,
      String? current,
      ) async {
    if (menu == null) return;
    final prefRepo = PreferenceRepository(ref.read(apiClientProvider));
    final notifier =
    ref.read(_preferenceStateProvider(mastery.menuId).notifier);

    try {
      if (current == value) {
        // 같은 값 다시 누르면 삭제
        await prefRepo.remove(mastery.menuId);
        notifier.state = null;
      } else {
        await prefRepo.set(mastery.menuId, value);
        notifier.state = value;
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('처리 중 오류가 발생했어요')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────
// 서브 위젯
// ─────────────────────────────────────────

class _NutritionRow extends StatelessWidget {
  final MenuModel menu;
  final AppColorTokens tokens;

  const _NutritionRow({required this.menu, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.primaryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NutritionItem(
              label: '칼로리',
              value: '${menu.defaultCalories.toStringAsFixed(0)}kcal',
              tokens: tokens),
          _NutritionItem(
              label: '탄수',
              value: '${menu.defaultCarbs.toStringAsFixed(0)}g',
              tokens: tokens),
          _NutritionItem(
              label: '단백',
              value: '${menu.defaultProtein.toStringAsFixed(0)}g',
              tokens: tokens),
          _NutritionItem(
              label: '지방',
              value: '${menu.defaultFat.toStringAsFixed(0)}g',
              tokens: tokens),
        ],
      ),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  final String label;
  final String value;
  final AppColorTokens tokens;

  const _NutritionItem(
      {required this.label, required this.value, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: tokens.textMuted)),
      ],
    );
  }
}

class _MasteryStats extends StatelessWidget {
  final MasteryModel mastery;
  final AppColorTokens tokens;

  const _MasteryStats({required this.mastery, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
            label: '섭취 횟수',
            value: '${mastery.eatCount}회',
            tokens: tokens),
        const SizedBox(width: 24),
        _StatItem(
            label: '첫 섭취',
            value: DateFormat('yy.MM.dd').format(mastery.firstEatenAt.toLocal()),
            tokens: tokens),
        const SizedBox(width: 24),
        _StatItem(
            label: '마지막',
            value: DateFormat('yy.MM.dd').format(mastery.lastEatenAt.toLocal()),
            tokens: tokens),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final AppColorTokens tokens;

  const _StatItem(
      {required this.label, required this.value, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: tokens.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  final AppColorTokens tokens;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.12) : tokens.listItemBg,
          borderRadius: BorderRadius.circular(tokens.rItem),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: active ? color : tokens.textMuted),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? color : tokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasteryCard extends StatelessWidget {
  final MasteryModel mastery;
  final VoidCallback onTap;

  const _MasteryCard({required this.mastery, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            _GradeChip(grade: mastery.grade),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mastery.menuName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mastery.menuCategory,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${mastery.eatCount}회',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MM.dd').format(mastery.lastEatenAt.toLocal()),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  final String grade;
  const _GradeChip({required this.grade});

  Color get _color {
    switch (grade) {
      case 'MASTER':
        return AppColors.masterGold;
      case 'ARTISAN':
        return AppColors.orange;
      case 'MANIA':
        return AppColors.peach;
      default:
        return AppColors.textTertiary;
    }
  }

  String get _label {
    switch (grade) {
      case 'MASTER':
        return '마스터';
      case 'ARTISAN':
        return '장인';
      case 'MANIA':
        return '매니아';
      default:
        return '입문';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          _label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _color,
          ),
        ),
      ),
    );
  }
}