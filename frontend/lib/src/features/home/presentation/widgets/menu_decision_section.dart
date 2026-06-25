import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/bento_card.dart';
import 'package:mukzzi/src/features/meal_record/data/models/menu_model.dart';
import 'package:mukzzi/src/features/meal_record/presentation/providers/roulette_provider.dart';
import 'package:mukzzi/src/features/meal_record/presentation/providers/recommendation_provider.dart';

// ─────────────────────────────────────────
// 상수
// ─────────────────────────────────────────

const _weatherTags = [
  ('맑음', 'SUNNY'),
  ('흐림', 'CLOUDY'),
  ('비/눈', 'RAINY'),
  ('더움', 'HOT'),
  ('추움', 'COLD'),
];

const _moodTags = [
  ('기분좋음', 'GOOD'),
  ('피곤함', 'TIRED'),
  ('스트레스', 'STRESSED'),
  ('입맛없음', 'HUNGRY'),
  ('든든하게', 'EXCITED'),
];

String _categoryLabel(String category) {
  const map = {
    'KOREAN': '한식',
    'CHINESE': '중식',
    'JAPANESE': '일식',
    'WESTERN': '양식',
    'SNACK': '분식',
    'CAFE': '카페',
    'OTHER': '기타',
  };
  return map[category] ?? category;
}

// ─────────────────────────────────────────
// 진입점 위젯 — StatefulWidget으로 변경
// ─────────────────────────────────────────

class MenuDecisionSection extends ConsumerStatefulWidget {
  const MenuDecisionSection({super.key});

  @override
  ConsumerState<MenuDecisionSection> createState() => _MenuDecisionSectionState();
}

class _MenuDecisionSectionState extends ConsumerState<MenuDecisionSection> {

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final filterExpanded = ref.watch(filterExpandedProvider);

    return BentoCard(
      borderRadius: BorderRadius.circular(tokens.rCard),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 레이블
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tokens.primaryBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '메뉴 추천',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tokens.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '오늘 뭐 먹지?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '룰렛, 상황별 필터, 또는 내 취향 기반으로 골라드려요',
            style: TextStyle(fontSize: 11, color: tokens.textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: _RouletteButton()),
              const SizedBox(width: 6),
              Expanded(
                child: _FilterToggleButton(
                  tokens: tokens,
                  expanded: filterExpanded,
                  onTap: () {
                    if (!filterExpanded) {
                      ref.read(rouletteProvider.notifier).reset();
                      ref.read(recommendationExpandedProvider.notifier).state = false;
                    }
                    ref.read(filterExpandedProvider.notifier).state = !filterExpanded;
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _RecommendToggleButton(
                  tokens: tokens,
                  expanded: ref.watch(recommendationExpandedProvider),
                  onTap: () {
                    final recExpanded = ref.read(recommendationExpandedProvider);
                    if (!recExpanded) {
                      ref.read(rouletteProvider.notifier).reset();
                      ref.read(filterExpandedProvider.notifier).state = false;
                      // 펼칠 때 자동으로 fetch
                      ref.read(recommendationProvider.notifier).fetch();
                    } else {
                      ref.read(recommendationProvider.notifier).reset();
                    }
                    ref.read(recommendationExpandedProvider.notifier).state = !recExpanded;
                  },
                ),
              ),
            ],
          ),
          const _RouletteResult(),
          _FilterSection(
            expanded: filterExpanded,
            tokens: tokens,
          ),
          _RecommendSection(
            expanded: ref.watch(recommendationExpandedProvider),
            tokens: tokens,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 룰렛 버튼
// ─────────────────────────────────────────

class _RouletteButton extends ConsumerWidget {
  const _RouletteButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final isSpinning = ref.watch(rouletteProvider.select((s) => s.isSpinning));
    final hasResult = ref.watch(rouletteProvider.select((s) => s.result != null));

    final isActive = isSpinning || hasResult;

    return GestureDetector(
      onTap: isSpinning
          ? null
          : () {
        ref.read(filterExpandedProvider.notifier).state = false;
        ref.read(recommendationExpandedProvider.notifier).state = false;
        ref.read(recommendationProvider.notifier).reset();
        ref.read(rouletteProvider.notifier).spin();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? tokens.primary : tokens.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(tokens.rItem),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSpinning ? Icons.hourglass_top : Icons.casino_outlined,
              color: isActive ? Colors.white : tokens.primary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isSpinning ? '돌리는 중...' : '랜덤 룰렛',
              style: TextStyle(
                color: isActive ? Colors.white : tokens.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 필터 토글 버튼 — StatelessWidget으로 단순화
// ─────────────────────────────────────────

class _FilterToggleButton extends StatelessWidget {
  final AppColorTokens tokens;
  final bool expanded;
  final VoidCallback onTap;

  const _FilterToggleButton({
    required this.tokens,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: expanded ? tokens.primary : tokens.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(tokens.rItem),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune, color: expanded ? Colors.white : tokens.primary, size: 16),
            const SizedBox(width: 6),
            Text(
              '상황별 필터',
              style: TextStyle(
                color: expanded ? Colors.white : tokens.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 슬롯머신 룰렛 결과
// ─────────────────────────────────────────

class _RouletteResult extends ConsumerStatefulWidget {
  const _RouletteResult();

  @override
  ConsumerState<_RouletteResult> createState() => _RouletteResultState();
}

class _RouletteResultState extends ConsumerState<_RouletteResult>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _wasSpinning = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(rouletteProvider.notifier).onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final state = ref.watch(rouletteProvider);

    if (state.isSpinning && !_wasSpinning) {
      _ctrl.forward(from: 0);
    }
    _wasSpinning = state.isSpinning;

    if (state.result == null && !state.isSpinning && state.pendingResult == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 14),
        _SlotWidget(
          anim: _anim,
          isSpinning: state.isSpinning,
          result: state.result,
          candidates: state.candidates,
          tokens: tokens,
        ),
        if (state.result != null) ...[
          const SizedBox(height: 12),
          _ResultCard(
            menu: state.result!,
            reason: state.reason,
            tokens: tokens,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────
// 슬롯 위젯
// ─────────────────────────────────────────

class _SlotWidget extends AnimatedWidget {
  final bool isSpinning;
  final MenuModel? result;
  final List<MenuModel> candidates;
  final AppColorTokens tokens;

  const _SlotWidget({
    required Animation<double> anim,
    required this.isSpinning,
    required this.result,
    required this.candidates,
    required this.tokens,
  }) : super(listenable: anim);

  Animation<double> get _anim => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    const itemH = 56.0;
    const visibleH = 168.0;
    const totalItems = 30;

    final names = candidates.isNotEmpty
        ? candidates.map((m) => m.name).toList()
        : (result != null ? [result!.name] : ['...']);

    const maxScroll = (totalItems - 1.5) * itemH;
    final scrollOffset = _anim.value * maxScroll;

    final resultIdx = result != null
        ? names.indexWhere((n) => n == result!.name)
        : -1;

    final double displayOffset;
    if (!isSpinning && result != null && resultIdx >= 0) {
      final loopCount = (totalItems / names.length).floor() - 1;
      displayOffset = (loopCount * names.length + resultIdx) * itemH;
    } else {
      displayOffset = scrollOffset;
    }

    // names.length가 0이면 나누기 오류 방지
    final loopLen = names.isEmpty ? 1 : names.length;
    final trackTop = -(displayOffset % (itemH * loopLen)) + itemH;

    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.rItem),
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        height: visibleH,
        child: ColoredBox(
          color: tokens.listItemBg,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                top: trackTop,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(totalItems, (i) {
                    final name = names[i % loopLen];
                    final isCurrent = !isSpinning && result != null && name == result!.name;
                    return SizedBox(
                      height: itemH,
                      child: Center(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: isCurrent ? 20 : 15,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                            color: isCurrent ? tokens.primary : tokens.textMuted,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // 상단 페이드
              Positioned(
                top: 0, left: 0, right: 0, height: 56,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          tokens.card,
                          tokens.card.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 하단 페이드
              Positioned(
                bottom: 0, left: 0, right: 0, height: 56,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          tokens.card,
                          tokens.card.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 중앙 하이라이트
              Positioned(
                top: visibleH / 2 - itemH / 2,
                left: 0, right: 0, height: itemH,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(color: tokens.primary, width: 1.5),
                      ),
                      color: tokens.primary.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 결과 카드
// ─────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final MenuModel menu;
  final String reason;
  final AppColorTokens tokens;

  const _ResultCard({
    required this.menu,
    required this.reason,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.primaryBg,
        borderRadius: BorderRadius.circular(tokens.rItem),
        border: Border.all(color: tokens.primary.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reason,
                      style: TextStyle(fontSize: 12, color: tokens.textSub),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _categoryLabel(menu.category),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MetaItem(label: '칼로리', value: '${menu.defaultCalories.toInt()}kcal', tokens: tokens),
              const SizedBox(width: 16),
              _MetaItem(label: '탄수', value: '${menu.defaultCarbs.toInt()}g', tokens: tokens),
              const SizedBox(width: 16),
              _MetaItem(label: '단백', value: '${menu.defaultProtein.toInt()}g', tokens: tokens),
              const SizedBox(width: 16),
              _MetaItem(label: '지방', value: '${menu.defaultFat.toInt()}g', tokens: tokens),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: '바로 기록하기',
                  isPrimary: true,
                  tokens: tokens,
                  onTap: () => context.go(
                    '/meal-record',
                    extra: {
                      'menuId': menu.id,
                      'menuName': menu.name,
                      'category': menu.category,
                      'calories': menu.defaultCalories,
                      'carbs': menu.defaultCarbs,
                      'protein': menu.defaultProtein,
                      'fat': menu.defaultFat,
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Consumer(
                  builder: (ctx, ref, _) => _ActionButton(
                    label: '다시 돌리기',
                    isPrimary: false,
                    tokens: tokens,
                    onTap: () => ref.read(rouletteProvider.notifier).spin(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  final AppColorTokens tokens;

  const _MetaItem({
    required this.label,
    required this.value,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: tokens.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final AppColorTokens tokens;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? tokens.primary : tokens.listItemBg,
          borderRadius: BorderRadius.circular(tokens.rItem),
          border: isPrimary
              ? null
              : Border.all(color: tokens.primary.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPrimary ? Colors.white : tokens.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 상황별 필터 섹션
// ─────────────────────────────────────────

class _FilterSection extends ConsumerWidget {
  final bool expanded;
  final AppColorTokens tokens;

  const _FilterSection({
    required this.expanded,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(menuFilterProvider);

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: !expanded
          ? const SizedBox.shrink()
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Text(
            '날씨',
            style: TextStyle(fontSize: 12, color: tokens.textMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _weatherTags.map((tag) {
              final selected = filterState.selectedWeathers.contains(tag.$2);
              return _TagChip(
                label: tag.$1,
                selected: selected,
                onTap: () => ref.read(menuFilterProvider.notifier).toggleWeather(tag.$2),
                tokens: tokens,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            '기분',
            style: TextStyle(fontSize: 12, color: tokens.textMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _moodTags.map((tag) {
              final selected = filterState.selectedMoods.contains(tag.$2);
              return _TagChip(
                label: tag.$1,
                selected: selected,
                onTap: () => ref.read(menuFilterProvider.notifier).toggleMood(tag.$2),
                tokens: tokens,
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: filterState.isLoading
                  ? null
                  : () => ref.read(menuFilterProvider.notifier).fetch(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: filterState.isLoading ? tokens.listItemBg : tokens.primary,
                  borderRadius: BorderRadius.circular(tokens.rItem),
                ),
                child: Center(
                  child: filterState.isLoading
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.primary,
                    ),
                  )
                      : const Text(
                    '추천 메뉴 보기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (filterState.error != null) ...[
            const SizedBox(height: 8),
            Text(
              '추천 중 오류가 발생했어요',
              style: TextStyle(fontSize: 12, color: tokens.textMuted),
            ),
          ],
          if (filterState.results.isNotEmpty) ...[
            const SizedBox(height: 12),
            _FilterResults(
              results: filterState.results,
              source: filterState.source,
              tokens: tokens,
            ),
          ],
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppColorTokens tokens;

  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? tokens.primaryBg : tokens.listItemBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? tokens.primary.withValues(alpha: 0.5)
                : tokens.primary.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? tokens.primary : tokens.textSub,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 필터 결과 목록
// ─────────────────────────────────────────

class _FilterResults extends StatelessWidget {
  final List<MenuModel> results;
  final String source;
  final AppColorTokens tokens;

  const _FilterResults({
    required this.results,
    required this.source,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '추천 메뉴',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tokens.textSub,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: tokens.primaryBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                source == 'personal' ? '내 기록 기반' : '전체 기반',
                style: TextStyle(fontSize: 10, color: tokens.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...results.map(
              (menu) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.listItemBg,
                borderRadius: BorderRadius.circular(tokens.rItem),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menu.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Text(
                          '${_categoryLabel(menu.category)} · ${menu.defaultCalories.toInt()}kcal',
                          style: TextStyle(fontSize: 11, color: tokens.textMuted),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go(
                      '/meal-record',
                      extra: {
                        'menuId': menu.id,
                        'menuName': menu.name,
                        'category': menu.category,
                        'calories': menu.defaultCalories,
                        'carbs': menu.defaultCarbs,
                        'protein': menu.defaultProtein,
                        'fat': menu.defaultFat,
                      },
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: tokens.primaryBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '기록',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// ─────────────────────────────────────────
// 선호도 추천 토글 버튼
// ─────────────────────────────────────────

class _RecommendToggleButton extends StatelessWidget {
  final AppColorTokens tokens;
  final bool expanded;
  final VoidCallback onTap;

  const _RecommendToggleButton({
    required this.tokens,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: expanded ? tokens.primary : tokens.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(tokens.rItem),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, color: expanded ? Colors.white : tokens.primary, size: 14),
            const SizedBox(width: 4),
            Text(
              '취향 추천',
              style: TextStyle(
                color: expanded ? Colors.white : tokens.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 선호도 추천 섹션
// ─────────────────────────────────────────

class _RecommendSection extends ConsumerWidget {
  final bool expanded;
  final AppColorTokens tokens;

  const _RecommendSection({
    required this.expanded,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recommendationProvider);

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: !expanded
          ? const SizedBox.shrink()
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '취향 기반 추천',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tokens.textSub,
                ),
              ),
              const SizedBox(width: 6),
              if (!state.isLoading && state.menus.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: tokens.primaryBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    state.isPersonal ? '내 기록 기반' : '인기 메뉴',
                    style: TextStyle(fontSize: 10, color: tokens.textMuted),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: state.isLoading
                    ? null
                    : () => ref.read(recommendationProvider.notifier).fetch(),
                child: Icon(Icons.refresh, size: 16, color: tokens.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: tokens.primary,
                  ),
                ),
              ),
            )
          else if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '추천 중 오류가 발생했어요',
                style: TextStyle(fontSize: 12, color: tokens.textMuted),
              ),
            )
          else
            ...state.menus.take(5).map(
                  (menu) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: tokens.listItemBg,
                    borderRadius:
                    BorderRadius.circular(tokens.rItem),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              menu.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: tokens.textPrimary,
                              ),
                            ),
                            Text(
                              '${_categoryLabel(menu.category)} · ${menu.defaultCalories.toInt()}kcal',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: tokens.textMuted),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(
                          '/meal-record',
                          extra: {
                            'menuId': menu.id,
                            'menuName': menu.name,
                            'category': menu.category,
                            'calories': menu.defaultCalories,
                            'carbs': menu.defaultCarbs,
                            'protein': menu.defaultProtein,
                            'fat': menu.defaultFat,
                          },
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: tokens.primaryBg,
                            borderRadius:
                            BorderRadius.circular(8),
                          ),
                          child: Text(
                            '기록',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tokens.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
