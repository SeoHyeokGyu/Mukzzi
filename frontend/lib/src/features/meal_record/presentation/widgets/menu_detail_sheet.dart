import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/common_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../character/domain/models/mastery_model.dart';
import '../../../character/presentation/providers/mastery_provider.dart';
import '../../data/models/menu_model.dart';
import '../../data/repositories/menu_repository.dart';
import '../../data/repositories/preference_repository.dart';
import '../providers/favorite_provider.dart';

// ── 메뉴 상세 조회 provider ──
final menuDetailProvider = FutureProvider.family<MenuModel?, String>((ref, menuId) async {
  final repo = MenuRepository(ref.watch(apiClientProvider));
  return repo.findById(menuId);
});

// ── 마스터리 단건 조회 provider ──
final masteryDetailProvider = FutureProvider.family<MasteryModel?, String>((ref, menuId) async {
  return ref.watch(masteryRepositoryProvider).findByMenuId(menuId);
});

// ── 선호도 로컬 상태 provider ──
final preferenceStateProvider = StateProvider.family<String?, String>((ref, menuId) {
  final menuAsync = ref.read(menuDetailProvider(menuId));
  return menuAsync.valueOrNull?.preference;
});

class MenuDetailSheet extends ConsumerWidget {
  final String menuId;
  final MasteryModel? initialMastery; // 이미 마스터리 정보가 있는 경우 최적화용

  const MenuDetailSheet({
    super.key,
    required this.menuId,
    this.initialMastery,
  });

  static void show(BuildContext context, String menuId, {MasteryModel? initialMastery}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MenuDetailSheet(menuId: menuId, initialMastery: initialMastery),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuDetailProvider(menuId));
    final masteryAsync = ref.watch(masteryDetailProvider(menuId));
    
    final isInFavList = ref.watch(
      favoriteListProvider.select((s) => s.favorites.any((f) => f.menu.id == menuId)),
    );
    final apiIsFav = menuAsync.valueOrNull?.isFavorite ?? false;
    final isFav = isInFavList || apiIsFav;
    
    final preference = ref.watch(preferenceStateProvider(menuId));
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: tokens.divider,
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
            data: (menu) {
              if (menu == null) return const Padding(padding: EdgeInsets.all(40), child: Text('존재하지 않는 메뉴입니다'));
              
              return masteryAsync.when(
                loading: () => const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                error: (_, __) => _buildContent(context, ref, menu, null, isFav, preference, tokens),
                data: (mastery) => _buildContent(context, ref, menu, mastery ?? initialMastery, isFav, preference, tokens),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, 
    WidgetRef ref, 
    MenuModel menu, 
    MasteryModel? mastery, 
    bool isFav, 
    String? preference, 
    AppColorTokens tokens
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      menu.category,
                      style: TextStyle(fontSize: 13, color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
              if (mastery != null) _GradeChip(grade: mastery.grade),
            ],
          ),
          const SizedBox(height: 16),

          _NutritionRow(menu: menu, tokens: tokens),
          const SizedBox(height: 16),

          if (mastery != null) ...[
            _MasteryStats(mastery: mastery, tokens: tokens),
            const SizedBox(height: 20),
          ] else ...[
             Text('아직 기록이 없는 메뉴예요. 첫 식사를 기록해보세요!', 
                style: TextStyle(fontSize: 13, color: tokens.textMuted)),
             const SizedBox(height: 20),
          ],

          const Divider(),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: isFav ? Icons.star : Icons.star_border,
                  label: isFav ? '즐겨찾기 해제' : '즐겨찾기',
                  color: Colors.amber,
                  active: isFav,
                  onTap: () async {
                    await ref.read(favoriteListProvider.notifier).toggle(menu);
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
                  onTap: () => _handlePreference(context, ref, menu.id, 'LIKE', preference),
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
                  onTap: () => _handlePreference(context, ref, menu.id, 'DISLIKE', preference),
                  tokens: tokens,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handlePreference(
      BuildContext context,
      WidgetRef ref,
      String menuId,
      String value,
      String? current,
  ) async {
    final prefRepo = PreferenceRepository(ref.read(apiClientProvider));
    final notifier = ref.read(preferenceStateProvider(menuId).notifier);

    try {
      if (current == value) {
        await prefRepo.remove(menuId);
        notifier.state = null;
      } else {
        await prefRepo.set(menuId, value);
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
// 서브 위젯들 (MasteryListPage에서 재사용하거나 추출)
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
          _NutritionItem(label: '칼로리', value: '${menu.defaultCalories.toStringAsFixed(0)}kcal', tokens: tokens),
          _NutritionItem(label: '탄수', value: '${menu.defaultCarbs.toStringAsFixed(0)}g', tokens: tokens),
          _NutritionItem(label: '단백', value: '${menu.defaultProtein.toStringAsFixed(0)}g', tokens: tokens),
          _NutritionItem(label: '지방', value: '${menu.defaultFat.toStringAsFixed(0)}g', tokens: tokens),
        ],
      ),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  final String label;
  final String value;
  final AppColorTokens tokens;
  const _NutritionItem({required this.label, required this.value, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tokens.textPrimary)),
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
        _StatItem(label: '섭취 횟수', value: '${mastery.eatCount}회', tokens: tokens),
        const SizedBox(width: 24),
        _StatItem(label: '첫 섭취', value: DateFormat('yy.MM.dd').format(mastery.firstEatenAt.toLocal()), tokens: tokens),
        const SizedBox(width: 24),
        _StatItem(label: '마지막', value: DateFormat('yy.MM.dd').format(mastery.lastEatenAt.toLocal()), tokens: tokens),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final AppColorTokens tokens;
  const _StatItem({required this.label, required this.value, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: tokens.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
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
          border: Border.all(color: active ? color.withValues(alpha: 0.4) : Colors.transparent),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: active ? color : tokens.textMuted),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? color : tokens.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  final String grade;
  const _GradeChip({required this.grade});

  Color _colorOf(BuildContext context) {
    switch (grade) {
      case 'MASTER':  return AppColors.masterGold;
      case 'ARTISAN': return AppColors.orange;
      case 'MANIA':   return AppColors.peach;
      default:        return Theme.of(context).extension<AppColorTokens>()!.textSub;
    }
  }

  String get _label {
    switch (grade) {
      case 'MASTER':  return '마스터';
      case 'ARTISAN': return '장인';
      case 'MANIA':   return '매니아';
      default:        return '입문';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorOf(context);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(_label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }
}
