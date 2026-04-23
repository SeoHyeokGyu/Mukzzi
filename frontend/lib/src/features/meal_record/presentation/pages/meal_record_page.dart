// lib/src/features/meal_record/presentation/pages/meal_record_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/common_providers.dart';
import '../providers/favorite_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../data/models/meal_model.dart';
import '../../data/models/menu_model.dart';
import '../../data/repositories/meal_repository.dart';
import '../widgets/menu_search_field.dart';

// ─────────────────────────────────────────
// Providers
// ─────────────────────────────────────────

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(ref.watch(apiClientProvider));
});

// --- Create ---

class MealCreateState {
  final bool isLoading;
  final String? error;
  final MealRecord? created;
  final GrantedTitleInfo? grantedTitle;

  const MealCreateState({this.isLoading = false, this.error, this.created, this.grantedTitle});

  MealCreateState copyWith({
    bool? isLoading,
    String? error,
    MealRecord? created,
    GrantedTitleInfo? grantedTitle,
    bool clearError = false,
    bool clearCreated = false,
  }) =>
      MealCreateState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        created: clearCreated ? null : created ?? this.created,
        grantedTitle: grantedTitle ?? this.grantedTitle,
      );
}

class MealCreateNotifier extends StateNotifier<MealCreateState> {
  final MealRepository _repo;

  MealCreateNotifier(this._repo) : super(const MealCreateState());

  Future<bool> submit(CreateMealRequest request) async {
    state = state.copyWith(isLoading: true, clearError: true, clearCreated: true);
    try {
      final result = await _repo.create(request);
      state = state.copyWith(
        isLoading: false,
        created: result.meal,
        grantedTitle: result.grantedTitle,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final mealCreateProvider =
StateNotifierProvider.autoDispose<MealCreateNotifier, MealCreateState>(
      (ref) => MealCreateNotifier(ref.watch(mealRepositoryProvider)),
);

// --- List ---

class MealListState {
  final List<MealRecord> records;
  final bool isLoading;
  final bool hasNext;
  final String? nextCursor;
  final String? error;

  const MealListState({
    this.records = const [],
    this.isLoading = false,
    this.hasNext = false,
    this.nextCursor,
    this.error,
  });

  MealListState copyWith({
    List<MealRecord>? records,
    bool? isLoading,
    bool? hasNext,
    String? nextCursor,
    String? error,
    bool clearError = false,
  }) =>
      MealListState(
        records: records ?? this.records,
        isLoading: isLoading ?? this.isLoading,
        hasNext: hasNext ?? this.hasNext,
        nextCursor: nextCursor ?? this.nextCursor,
        error: clearError ? null : error ?? this.error,
      );
}

class MealListNotifier extends StateNotifier<MealListState> {
  final MealRepository _repo;

  MealListNotifier(this._repo) : super(const MealListState()) {
    load();
  }

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.findAll(const MealListFilter());
      state = state.copyWith(
        records: result.meals,
        isLoading: false,
        hasNext: result.hasNext,
        nextCursor: result.nextCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasNext || state.isLoading || state.nextCursor == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repo.findAll(MealListFilter(cursor: state.nextCursor));
      state = state.copyWith(
        records: [...state.records, ...result.meals],
        isLoading: false,
        hasNext: result.hasNext,
        nextCursor: result.nextCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repo.delete(id);
      state = state.copyWith(
        records: state.records.where((r) => r.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void refresh() {
    state = const MealListState();
    load();
  }
}

final mealListProvider =
StateNotifierProvider<MealListNotifier, MealListState>(
      (ref) => MealListNotifier(ref.watch(mealRepositoryProvider)),
);

// ─────────────────────────────────────────
// Page
// ─────────────────────────────────────────

class MealRecordPage extends ConsumerStatefulWidget {
  const MealRecordPage({super.key});

  @override
  ConsumerState<MealRecordPage> createState() => _MealRecordPageState();
}

class _MealRecordPageState extends ConsumerState<MealRecordPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _menuController;
  late MealType _selectedMealType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _menuController = TextEditingController();
    _selectedMealType = MealTypeHelper.fromHour(TimeOfDay.now().hour);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('식사 기록'),
        actions: [
          IconButton(
            tooltip: '먹부림 도감',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => context.push('/meal-record/masteries'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '기록 추가'),
            Tab(text: '기록 목록'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MealInputTab(
            menuController: _menuController,
            selectedMealType: _selectedMealType,
            onMealTypeChanged: (v) => setState(() => _selectedMealType = v),
            onSaved: () {
              ref.read(mealListProvider.notifier).refresh();
              _tabController.animateTo(1);
              _menuController.clear();
            },
          ),
          _MealListTab(onAddTap: () => _tabController.animateTo(0)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 기록 추가 탭
// ─────────────────────────────────────────

class _MealInputTab extends ConsumerStatefulWidget {
  final TextEditingController menuController;
  final MealType selectedMealType;
  final ValueChanged<MealType> onMealTypeChanged;
  final VoidCallback onSaved;

  const _MealInputTab({
    required this.menuController,
    required this.selectedMealType,
    required this.onMealTypeChanged,
    required this.onSaved,
  });

  @override
  ConsumerState<_MealInputTab> createState() => _MealInputTabState();
}

class _MealInputTabState extends ConsumerState<_MealInputTab> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double _servingSize = 1.0;
  String? _selectedWeather;
  String? _selectedMood;
  MenuModel? _selectedMenu;

  String? _getMealTypeMismatchWarning() {
    final expected = MealTypeHelper.fromHour(_selectedTime.hour);
    if (expected == widget.selectedMealType) return null;
    const labels = {
      MealType.breakfast: '아침 (06:00~10:59)',
      MealType.lunch: '점심 (12:00~13:59)',
      MealType.dinner: '저녁 (18:00~21:59)',
      MealType.snack: '간식',
    };
    return '선택한 시간은 ${labels[expected]} 시간대예요';
  }

  void _showTitleAcquiredSnackBar(GrantedTitleInfo title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emoji_events_outlined, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '칭호 획득: ${title.name}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    final menuName = widget.menuController.text.trim();
    if (menuName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메뉴명을 입력해주세요')),
      );
      return;
    }

    final recordedAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final request = CreateMealRequest(
      menuId: _selectedMenu?.id,
      menuName: menuName,
      category: _selectedMenu?.category ?? '기타',
      mealType: widget.selectedMealType.apiValue,
      servingSize: _servingSize,
      recordedAt: recordedAt,
      isManual: _selectedMenu == null,
      weatherTag: _selectedWeather,
      moodTag: _selectedMood,
    );

    final success = await ref.read(mealCreateProvider.notifier).submit(request);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('식사 기록이 저장되었습니다')),
      );
      final grantedTitle = ref.read(mealCreateProvider).grantedTitle;
      if (grantedTitle != null && mounted) {
        _showTitleAcquiredSnackBar(grantedTitle);
      }
      setState(() {
        _selectedMenu = null;
        _servingSize = 1.0;
        _selectedWeather = null;
        _selectedMood = null;
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
      });
      widget.onSaved();
    } else {
      final error = ref.read(mealCreateProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? '저장에 실패했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(mealCreateProvider);
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final warning = _getMealTypeMismatchWarning();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 식사 사진 영역 ──
          _PhotoArea(tokens: tokens),
          const SizedBox(height: 16),

          // ── 음식 검색 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('감지된 음식', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tokens.textPrimary)),
              Text('직접 입력', style: TextStyle(fontSize: 12, color: tokens.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          MenuSearchField(
            controller: widget.menuController,
            onMenuSelected: (menu) => setState(() => _selectedMenu = menu),
          ),

          // ── 선택된 음식 아이템 리스트 ──
          if (_selectedMenu != null) ...[
            const SizedBox(height: 8),
            _FoodItemRow(
              menu: _selectedMenu!,
              servingSize: _servingSize,
              onDecrement: () => setState(() {
                _servingSize = (_servingSize - 0.5).clamp(0.5, 3.0);
              }),
              onIncrement: () => setState(() {
                _servingSize = (_servingSize + 0.5).clamp(0.5, 3.0);
              }),
              tokens: tokens,
            ),
            const SizedBox(height: 12),
            // ── 칼로리 요약 ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: tokens.primaryBg,
                borderRadius: BorderRadius.circular(tokens.rCard),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('총 칼로리', style: TextStyle(fontSize: 11, color: tokens.textSub, height: 1.4)),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: '${(_selectedMenu!.defaultCalories * _servingSize).toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: tokens.textPrimary),
                          ),
                          TextSpan(
                            text: ' kcal',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tokens.textSub),
                          ),
                        ]),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _MacroStat(label: '탄수', value: '${(_selectedMenu!.defaultCarbs * _servingSize).toStringAsFixed(0)}g', tokens: tokens),
                      const SizedBox(width: 14),
                      _MacroStat(label: '단백', value: '${(_selectedMenu!.defaultProtein * _servingSize).toStringAsFixed(0)}g', tokens: tokens),
                      const SizedBox(width: 14),
                      _MacroStat(label: '지방', value: '${(_selectedMenu!.defaultFat * _servingSize).toStringAsFixed(0)}g', tokens: tokens),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // ── 식사 옵션 (접을 수 있는 보조 설정) ──
          _MealOptionsSection(
            selectedMealType: widget.selectedMealType,
            onMealTypeChanged: widget.onMealTypeChanged,
            selectedDate: _selectedDate,
            selectedTime: _selectedTime,
            onDateChanged: (d) => setState(() => _selectedDate = d),
            onTimeChanged: (t) => setState(() => _selectedTime = t),
            selectedWeather: _selectedWeather,
            onWeatherChanged: (v) => setState(() => _selectedWeather = v),
            selectedMood: _selectedMood,
            onMoodChanged: (v) => setState(() => _selectedMood = v),
            warning: warning,
            tokens: tokens,
          ),
          const SizedBox(height: 20),

          // ── 저장 버튼 ──
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: tokens.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.rCard)),
                elevation: 0,
              ),
              onPressed: createState.isLoading ? null : _submit,
              child: createState.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text('먹찌에게 주기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text('+XP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PhotoArea extends StatelessWidget {
  final AppColorTokens tokens;
  const _PhotoArea({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(tokens.rCard),
        border: Border.all(color: tokens.primary.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: tokens.primaryBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_outlined, color: tokens.primary, size: 26),
                ),
                const SizedBox(height: 10),
                Text('사진으로 음식 분석', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
                const SizedBox(height: 4),
                Text('촬영하거나 갤러리에서 선택하세요', style: TextStyle(fontSize: 12, color: tokens.textMuted)),
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: tokens.primaryBg,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: tokens.primary),
                  const SizedBox(width: 4),
                  Text('AI 분석', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tokens.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodItemRow extends ConsumerWidget {
  final MenuModel menu;
  final double servingSize;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final AppColorTokens tokens;

  const _FoodItemRow({
    required this.menu,
    required this.servingSize,
    required this.onDecrement,
    required this.onIncrement,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(
      favoriteListProvider.select((s) => s.isFavorite(menu.id)),
    );

    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(tokens.rCard),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // 즐겨찾기 토글
            GestureDetector(
              onTap: () =>
                  ref.read(favoriteListProvider.notifier).toggle(menu),
              child: Icon(
                isFav ? Icons.star : Icons.star_border,
                size: 22,
                color: isFav ? Colors.amber : tokens.textMuted,
              ),
            ),
            const SizedBox(width: 10),
            // 메뉴명 + 인분/칼로리
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${servingSize.toStringAsFixed(1)}인분 · '
                        '${(menu.defaultCalories * servingSize).toStringAsFixed(0)} kcal',
                    style: TextStyle(fontSize: 11, color: tokens.textMuted),
                  ),
                ],
              ),
            ),
            // 인분 조절
            Container(
              decoration: BoxDecoration(
                color: tokens.listItemBg,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onDecrement,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: tokens.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.remove, size: 14, color: tokens.textSub),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      servingSize.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  GestureDetector(
                    onTap: onIncrement,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: tokens.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  final String label;
  final String value;
  final AppColorTokens tokens;

  const _MacroStat({required this.label, required this.value, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tokens.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: tokens.textSub)),
      ],
    );
  }
}

class _MealOptionsSection extends StatefulWidget {
  final MealType selectedMealType;
  final ValueChanged<MealType> onMealTypeChanged;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final String? selectedWeather;
  final ValueChanged<String?> onWeatherChanged;
  final String? selectedMood;
  final ValueChanged<String?> onMoodChanged;
  final String? warning;
  final AppColorTokens tokens;

  const _MealOptionsSection({
    required this.selectedMealType,
    required this.onMealTypeChanged,
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.selectedWeather,
    required this.onWeatherChanged,
    required this.selectedMood,
    required this.onMoodChanged,
    required this.warning,
    required this.tokens,
  });

  @override
  State<_MealOptionsSection> createState() => _MealOptionsSectionState();
}

class _MealOptionsSectionState extends State<_MealOptionsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.rCard),
      ),
      child: Column(
        children: [
          // 식사 종류 + 시간 (항상 노출)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              children: [
                Row(
                  children: MealType.values.map((type) {
                    final selected = type == widget.selectedMealType;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onMealTypeChanged(type),
                        child: Container(
                          margin: EdgeInsets.only(right: type != MealType.values.last ? 6 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? t.primary : t.listItemBg,
                            borderRadius: BorderRadius.circular(t.rItem),
                          ),
                          child: Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : t.textSub,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: widget.selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) widget.onDateChanged(picked);
                        },
                        child: Text(
                          '${widget.selectedDate.month}/${widget.selectedDate.day}',
                          style: TextStyle(fontSize: 13, color: t.textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: widget.selectedTime,
                          );
                          if (picked != null) widget.onTimeChanged(picked);
                        },
                        child: Text(
                          '${widget.selectedTime.hour.toString().padLeft(2, '0')}:${widget.selectedTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 13, color: t.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.warning != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 13, color: t.textMuted),
                      const SizedBox(width: 4),
                      Text(widget.warning!, style: TextStyle(fontSize: 11, color: t.textMuted)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // 더보기 토글 (날씨/기분)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('날씨 / 기분', style: TextStyle(fontSize: 12, color: t.textMuted, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: t.textMuted),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: t.primary.withValues(alpha: 0.08)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownMenu<String>(
                      label: const Text('날씨'),
                      initialSelection: widget.selectedWeather,
                      expandedInsets: EdgeInsets.zero,
                      onSelected: widget.onWeatherChanged,
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'SUNNY', label: '☀️ 맑음'),
                        DropdownMenuEntry(value: 'CLOUDY', label: '☁️ 흐림'),
                        DropdownMenuEntry(value: 'RAINY', label: '🌧️ 비'),
                        DropdownMenuEntry(value: 'SNOWY', label: '❄️ 눈'),
                        DropdownMenuEntry(value: 'HOT', label: '🥵 더움'),
                        DropdownMenuEntry(value: 'COLD', label: '🥶 추움'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownMenu<String>(
                      label: const Text('기분'),
                      initialSelection: widget.selectedMood,
                      expandedInsets: EdgeInsets.zero,
                      onSelected: widget.onMoodChanged,
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'GOOD', label: '😊 좋음'),
                        DropdownMenuEntry(value: 'TIRED', label: '😴 피곤'),
                        DropdownMenuEntry(value: 'STRESSED', label: '😤 스트레스'),
                        DropdownMenuEntry(value: 'HUNGRY', label: '😋 배고픔'),
                        DropdownMenuEntry(value: 'EXCITED', label: '🤩 설렘'),
                        DropdownMenuEntry(value: 'NORMAL', label: '😐 보통'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 기록 목록 탭
// ─────────────────────────────────────────

class _MealListTab extends ConsumerStatefulWidget {
  final VoidCallback? onAddTap;

  const _MealListTab({this.onAddTap});

  @override
  ConsumerState<_MealListTab> createState() => _MealListTabState();
}

class _MealListTabState extends ConsumerState<_MealListTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(mealListProvider.notifier).loadMore();
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(mealListProvider);

    if (listState.isLoading && listState.records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (listState.error != null && listState.records.isEmpty) {
      final tokens = Theme.of(context).extension<AppColorTokens>()!;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: tokens.primary),
            const SizedBox(height: 12),
            Text(listState.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: tokens.textSub)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(mealListProvider.notifier).refresh(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (listState.records.isEmpty) {
      return _EmptyState(
        icon: Icons.restaurant_outlined,
        message: '아직 기록된 식사가 없어요',
        sub: '첫 번째 식사를 기록해보세요',
        actionLabel: '기록 추가',
        onAction: widget.onAddTap,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.read(mealListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: listState.records.length + (listState.hasNext ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == listState.records.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final record = listState.records[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BentoCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: _MealTypeIcon(mealType: record.mealType),
                title: Text(record.menuName),
                subtitle: Text(
                  '${MealTypeHelper.fromString(record.mealType).label} · ${_formatDate(record.recordedAt)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (record.calories != null)
                      Text(
                        '${record.calories!.toStringAsFixed(0)}kcal',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    Text(
                      '${record.servingSize.toStringAsFixed(1)}인분',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).extension<AppColorTokens>()!.textMuted),
                    ),
                  ],
                ),
                onTap: () => _showDetailDialog(context, record),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDetailDialog(BuildContext context, MealRecord record) {
    final mealType = MealTypeHelper.fromString(record.mealType);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(record.menuName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: '식사 종류', value: mealType.label),
            _DetailRow(label: '기록 시간', value: _formatDate(record.recordedAt)),
            _DetailRow(
                label: '인분',
                value: '${record.servingSize.toStringAsFixed(1)}인분'),
            if (record.calories != null)
              _DetailRow(
                  label: '칼로리',
                  value: '${record.calories!.toStringAsFixed(0)}kcal'),
            if (record.carbs != null)
              _DetailRow(
                  label: '탄수화물',
                  value: '${record.carbs!.toStringAsFixed(1)}g'),
            if (record.protein != null)
              _DetailRow(
                  label: '단백질',
                  value: '${record.protein!.toStringAsFixed(1)}g'),
            if (record.fat != null)
              _DetailRow(
                  label: '지방',
                  value: '${record.fat!.toStringAsFixed(1)}g'),
            if (record.weatherTag != null)
              _DetailRow(label: '날씨', value: record.weatherTag!),
            if (record.moodTag != null)
              _DetailRow(label: '기분', value: record.moodTag!),
            if (record.review != null && record.review!.isNotEmpty)
              _DetailRow(label: '메모', value: record.review!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: ctx,
                builder: (confirmCtx) => AlertDialog(
                  title: const Text('식사 기록 삭제'),
                  content: Text('${record.menuName} 기록을 삭제하시겠어요?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(confirmCtx, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(confirmCtx, true),
                      child: const Text('삭제', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true && ctx.mounted) {
                Navigator.pop(ctx);
                ref.read(mealListProvider.notifier).delete(record.id);
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 공통 위젯
// ─────────────────────────────────────────

class _MealTypeIcon extends StatelessWidget {
  final String mealType;
  const _MealTypeIcon({required this.mealType});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final type = MealTypeHelper.fromString(mealType);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: tokens.primaryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(type.icon, color: tokens.primary, size: 22),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: TextStyle(color: tokens.textMuted)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.sub,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: tokens.textMuted),
          const SizedBox(height: 16),
          Text(message,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: tokens.textSub)),
          const SizedBox(height: 6),
          Text(sub,
              style: TextStyle(
                  fontSize: 13, color: tokens.textMuted)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}