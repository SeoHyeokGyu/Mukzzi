import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../data/models/meal_model.dart';
import '../../../meal_record/presentation/pages/meal_record_page.dart';

// ─────────────────────────────────────────
// Provider
// ─────────────────────────────────────────

// 월별 식사 기록 캐시 (key: 'yyyy-MM')
final calendarMealsProvider = FutureProvider.family<List<MealRecord>, String>((ref, monthKey) async {
  final repo = ref.watch(mealRepositoryProvider);
  // 해당 월의 첫날~마지막날 범위로 조회
  final parts = monthKey.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final firstDay = DateTime(year, month, 1);
  final lastDay = DateTime(year, month + 1, 0);

  final filter = MealListFilter(
    startDate: DateFormat('yyyy-MM-dd').format(firstDay),
    endDate: DateFormat('yyyy-MM-dd').format(lastDay),
    limit: 200,
  );

  final result = await repo.findAll(filter);
  return result.meals;
});

// ─────────────────────────────────────────
// Page
// ─────────────────────────────────────────

class MealCalendarPage extends ConsumerStatefulWidget {
  const MealCalendarPage({super.key});

  @override
  ConsumerState<MealCalendarPage> createState() => _MealCalendarPageState();
}

class _MealCalendarPageState extends ConsumerState<MealCalendarPage> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;

  String get _monthKey => DateFormat('yyyy-MM').format(_focusedMonth);

  void _prevMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    _selectedDay = null;
  });

  void _nextMonth() {
    final now = DateTime.now();
    if (_focusedMonth.year == now.year && _focusedMonth.month == now.month) return;
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final mealsAsync = ref.watch(calendarMealsProvider(_monthKey));

    return GradientScaffold(
      appBar: AppBar(title: const Text('먹부림 캘린더')),
      body: mealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: tokens.textMuted),
              const SizedBox(height: 12),
              const Text('불러오지 못했어요'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(calendarMealsProvider(_monthKey)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (meals) {
          // 날짜별 식사 그룹핑
          final mealsByDate = <String, List<MealRecord>>{};
          for (final m in meals) {
            final key = DateFormat('yyyy-MM-dd').format(m.recordedAt.toLocal());
            mealsByDate.putIfAbsent(key, () => []).add(m);
          }

          final selectedKey = _selectedDay != null
              ? DateFormat('yyyy-MM-dd').format(_selectedDay!)
              : null;
          final selectedMeals = selectedKey != null ? (mealsByDate[selectedKey] ?? <MealRecord>[]) : <MealRecord>[];

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── 월 네비게이션 ──
                _MonthHeader(
                  focusedMonth: _focusedMonth,
                  onPrev: _prevMonth,
                  onNext: _nextMonth,
                  tokens: tokens,
                ),
              
                // ── 요일 헤더 ──
                _WeekdayRow(tokens: tokens),
              
                // ── 달력 그리드 ──
                _CalendarGrid(
                  focusedMonth: _focusedMonth,
                  mealsByDate: mealsByDate,
                  selectedDay: _selectedDay,
                  onDayTap: (day) => setState(() {
                    _selectedDay = _selectedDay != null &&
                        DateFormat('yyyy-MM-dd').format(_selectedDay!) ==
                            DateFormat('yyyy-MM-dd').format(day)
                        ? null
                        : day;
                  }),
                  tokens: tokens,
                ),
              
                const Divider(height: 1),
              
                // ── 선택된 날 식사 목록 ──
                _selectedDay == null
                    ? _CalendarSummary(mealsByDate: mealsByDate, tokens: tokens)
                    : _DayMealList(
                  day: _selectedDay!,
                  meals: selectedMeals,
                  tokens: tokens,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────
// 월 네비게이션 헤더
// ─────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  final DateTime focusedMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final AppColorTokens tokens;

  const _MonthHeader({
    required this.focusedMonth,
    required this.onPrev,
    required this.onNext,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = focusedMonth.year == now.year && focusedMonth.month == now.month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: Icon(Icons.chevron_left, color: tokens.textPrimary),
          ),
          Text(
            DateFormat('yyyy년 MM월').format(focusedMonth),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
          IconButton(
            onPressed: isCurrentMonth ? null : onNext,
            icon: Icon(
              Icons.chevron_right,
              color: isCurrentMonth ? tokens.textMuted : tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 요일 헤더
// ─────────────────────────────────────────

class _WeekdayRow extends StatelessWidget {
  final AppColorTokens tokens;
  const _WeekdayRow({required this.tokens});

  @override
  Widget build(BuildContext context) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: weekdays.asMap().entries.map((e) {
          final color = e.key == 0
              ? Colors.red.shade300
              : e.key == 6
              ? Colors.blue.shade300
              : tokens.textMuted;
          return Expanded(
            child: Center(
              child: Text(
                e.value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 달력 그리드
// ─────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final Map<String, List<MealRecord>> mealsByDate;
  final DateTime? selectedDay;
  final void Function(DateTime) onDayTap;
  final AppColorTokens tokens;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.mealsByDate,
    required this.selectedDay,
    required this.onDayTap,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=일, 1=월, ...
    final today = DateTime.now();

    final cells = <Widget>[];

    // 앞 빈 칸
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(focusedMonth.year, focusedMonth.month, day);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final meals = mealsByDate[dateKey] ?? [];
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      final isSelected = selectedDay != null &&
          selectedDay!.year == date.year &&
          selectedDay!.month == date.month &&
          selectedDay!.day == date.day;
      final isFuture = date.isAfter(today);

      cells.add(
        GestureDetector(
          onTap: isFuture ? null : () => onDayTap(date),
          child: _DayCell(
            day: day,
            meals: meals,
            isToday: isToday,
            isSelected: isSelected,
            isFuture: isFuture,
            weekday: date.weekday % 7,
            tokens: tokens,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.0,
        children: cells,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final List<MealRecord> meals;
  final bool isToday;
  final bool isSelected;
  final bool isFuture;
  final int weekday; // 0=일, 6=토
  final AppColorTokens tokens;

  const _DayCell({
    required this.day,
    required this.meals,
    required this.isToday,
    required this.isSelected,
    required this.isFuture,
    required this.weekday,
    required this.tokens,
  });

  Color get _textColor {
    if (isFuture) return tokens.textMuted.withValues(alpha: 0.4);
    if (weekday == 0) return Colors.red.shade300;
    if (weekday == 6) return Colors.blue.shade300;
    return tokens.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected
            ? tokens.primary
            : isToday
            ? tokens.primaryBg
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected ? Colors.white : _textColor,
            ),
          ),
          const SizedBox(height: 3),
          // 식사 도트
          if (!isFuture)
            _MealDots(meals: meals, isSelected: isSelected, tokens: tokens),
        ],
      ),
    );
  }
}

class _MealDots extends StatelessWidget {
  final List<MealRecord> meals;
  final bool isSelected;
  final AppColorTokens tokens;

  const _MealDots({required this.meals, required this.isSelected, required this.tokens});

  @override
  Widget build(BuildContext context) {
    if (meals.isEmpty) return const SizedBox(height: 6);

    // 최대 3개 도트
    final count = meals.length.clamp(0, 3);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) => Container(
        width: 4,
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : tokens.primary,
          shape: BoxShape.circle,
        ),
      )),
    );
  }
}

// ─────────────────────────────────────────
// 날짜 미선택 시 월간 요약
// ─────────────────────────────────────────

class _CalendarSummary extends StatelessWidget {
  final Map<String, List<MealRecord>> mealsByDate;
  final AppColorTokens tokens;

  const _CalendarSummary({required this.mealsByDate, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final totalDays = mealsByDate.length;
    final totalMeals = mealsByDate.values.fold(0, (sum, list) => sum + list.length);

    if (totalMeals == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 48, color: tokens.textMuted),
              const SizedBox(height: 12),
              Text('이번 달 기록이 없어요', style: TextStyle(color: tokens.textSub)),
              const SizedBox(height: 4),
              Text('날짜를 탭하면 상세 기록을 볼 수 있어요',
                  style: TextStyle(fontSize: 12, color: tokens.textMuted)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이번 달 요약',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tokens.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.calendar_today,
                  label: '기록한 날',
                  value: '$totalDays일',
                  tokens: tokens,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.restaurant,
                  label: '총 식사',
                  value: '$totalMeals끼',
                  tokens: tokens,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.show_chart,
                  label: '하루 평균',
                  value: totalDays > 0
                      ? '${(totalMeals / totalDays).toStringAsFixed(1)}끼'
                      : '-',
                  tokens: tokens,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('날짜를 탭하면 상세 기록을 볼 수 있어요',
              style: TextStyle(fontSize: 12, color: tokens.textMuted)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppColorTokens tokens;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: tokens.primaryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: tokens.primary),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tokens.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: tokens.textMuted)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 선택된 날 식사 목록
// ─────────────────────────────────────────

class _DayMealList extends StatelessWidget {
  final DateTime day;
  final List<MealRecord> meals;
  final AppColorTokens tokens;

  const _DayMealList({
    required this.day,
    required this.meals,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('M월 d일 (E)', 'ko').format(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Text(dateStr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tokens.textPrimary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${meals.length}끼',
                    style: TextStyle(fontSize: 12, color: tokens.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        if (meals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.no_meals, size: 40, color: tokens.textMuted),
                  const SizedBox(height: 8),
                  Text('기록된 식사가 없어요', style: TextStyle(color: tokens.textMuted, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: meals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _MealItem(meal: meals[i], tokens: tokens),
          ),
      ],
    );
  }
}

class _MealItem extends StatelessWidget {
  final MealRecord meal;
  final AppColorTokens tokens;

  const _MealItem({required this.meal, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final mealType = MealTypeHelper.fromString(meal.mealType);
    final timeStr = DateFormat('HH:mm').format(meal.recordedAt.toLocal());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.listItemBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.primaryBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(mealType.icon, color: tokens.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.menuName,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
                const SizedBox(height: 2),
                Text('${mealType.label} · $timeStr · ${meal.servingSize.toStringAsFixed(1)}인분',
                    style: TextStyle(fontSize: 11, color: tokens.textMuted)),
              ],
            ),
          ),
          if (meal.calories != null)
            Text('${meal.calories!.toStringAsFixed(0)}kcal',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.primary)),
        ],
      ),
    );
  }
}