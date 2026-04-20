// lib/src/features/meal_record/presentation/pages/meal_record_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/common_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/app_button.dart';
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

  const MealCreateState({this.isLoading = false, this.error, this.created});

  MealCreateState copyWith({
    bool? isLoading,
    String? error,
    MealRecord? created,
    bool clearError = false,
    bool clearCreated = false,
  }) =>
      MealCreateState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        created: clearCreated ? null : created ?? this.created,
      );
}

class MealCreateNotifier extends StateNotifier<MealCreateState> {
  final MealRepository _repo;

  MealCreateNotifier(this._repo) : super(const MealCreateState());

  Future<bool> submit(CreateMealRequest request) async {
    state = state.copyWith(isLoading: true, clearError: true, clearCreated: true);
    try {
      final record = await _repo.create(request);
      state = state.copyWith(isLoading: false, created: record);
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
      menuId: _selectedMenu != null ? int.tryParse(_selectedMenu!.id) : null,
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
        const SnackBar(content: Text('식사 기록이 저장되었습니다 🎉')),
      );
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
    final warning = _getMealTypeMismatchWarning();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 메뉴 검색 ──
          Text('메뉴명', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          MenuSearchField(
            controller: widget.menuController,
            onMenuSelected: (menu) => setState(() => _selectedMenu = menu),
          ),

          // 선택된 메뉴 영양 미리보기
          if (_selectedMenu != null) ...[
            const SizedBox(height: 8),
            _NutritionPreview(menu: _selectedMenu!, servingSize: _servingSize),
          ],
          const SizedBox(height: 24),

          // ── 식사 종류 ──
          Text('식사 종류', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<MealType>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 15),
              selectedBackgroundColor: Theme.of(context).extension<AppColorTokens>()!.primary,
              selectedForegroundColor: Colors.white,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.comfortable,
            ),
            segments: MealType.values
                .map((t) => ButtonSegment(label: Text(t.label), value: t))
                .toList(),
            selected: {widget.selectedMealType},
            onSelectionChanged: (s) => widget.onMealTypeChanged(s.first),
          ),
          const SizedBox(height: 24),

          // ── 식사 시간 ──
          Text('식사 시간', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Text(
                    '${_selectedDate.year}-'
                        '${_selectedDate.month.toString().padLeft(2, '0')}-'
                        '${_selectedDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (picked != null) setState(() => _selectedTime = picked);
                  },
                  child: Text(
                    '${_selectedTime.hour.toString().padLeft(2, '0')}:'
                        '${_selectedTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ],
          ),
          if (warning != null) ...[
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final tokens = Theme.of(context).extension<AppColorTokens>()!;
              return Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: tokens.textMuted),
                  const SizedBox(width: 4),
                  Text(warning,
                      style: TextStyle(
                          fontSize: 12, color: tokens.textMuted)),
                ],
              );
            }),
          ],
          const SizedBox(height: 24),

          // ── 인분 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('인분', style: Theme.of(context).textTheme.titleMedium),
              Builder(builder: (context) {
                final tokens = Theme.of(context).extension<AppColorTokens>()!;
                return Text(
                  '${_servingSize.toStringAsFixed(1)}인분',
                  style: TextStyle(
                      color: tokens.primary, fontWeight: FontWeight.w600),
                );
              }),
            ],
          ),
          Slider(
            value: _servingSize,
            min: 0.5,
            max: 1.5,
            divisions: 2,
            label: '${_servingSize.toStringAsFixed(1)}인분',
            onChanged: (v) => setState(() => _servingSize = v),
          ),
          const SizedBox(height: 24),

          // ── 날씨 / 기분 ──
          Row(
            children: [
              Text('날씨 / 기분',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              Text('선택사항',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).extension<AppColorTokens>()!.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('날씨',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    DropdownMenu<String>(
                      initialSelection: _selectedWeather,
                      expandedInsets: EdgeInsets.zero,
                      onSelected: (v) => setState(() => _selectedWeather = v),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'SUNNY', label: '☀️ 맑음'),
                        DropdownMenuEntry(value: 'CLOUDY', label: '☁️ 흐림'),
                        DropdownMenuEntry(value: 'RAINY', label: '🌧️ 비'),
                        DropdownMenuEntry(value: 'SNOWY', label: '❄️ 눈'),
                        DropdownMenuEntry(value: 'WINDY', label: '💨 바람'),
                        DropdownMenuEntry(value: 'HOT', label: '🥵 더움'),
                        DropdownMenuEntry(value: 'COLD', label: '🥶 추움'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('기분',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    DropdownMenu<String>(
                      initialSelection: _selectedMood,
                      expandedInsets: EdgeInsets.zero,
                      onSelected: (v) => setState(() => _selectedMood = v),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'GOOD', label: '😊 좋음'),
                        DropdownMenuEntry(value: 'TIRED', label: '😴 피곤'),
                        DropdownMenuEntry(
                            value: 'STRESSED', label: '😤 스트레스'),
                        DropdownMenuEntry(value: 'HUNGRY', label: '😋 배고픔'),
                        DropdownMenuEntry(value: 'EXCITED', label: '🤩 설렘'),
                        DropdownMenuEntry(value: 'SAD', label: '😢 우울'),
                        DropdownMenuEntry(value: 'NORMAL', label: '😐 보통'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── 저장 버튼 ──
          AppGradientButton(
            label: '기록 저장',
            isLoading: createState.isLoading,
            onPressed: () { _submit(); },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 영양정보 미리보기
// ─────────────────────────────────────────

class _NutritionPreview extends StatelessWidget {
  final MenuModel menu;
  final double servingSize;

  const _NutritionPreview({required this.menu, required this.servingSize});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
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
              value: '${(menu.defaultCalories * servingSize).toStringAsFixed(0)}kcal'),
          _NutritionItem(
              label: '탄수화물',
              value: '${(menu.defaultCarbs * servingSize).toStringAsFixed(1)}g'),
          _NutritionItem(
              label: '단백질',
              value: '${(menu.defaultProtein * servingSize).toStringAsFixed(1)}g'),
          _NutritionItem(
              label: '지방',
              value: '${(menu.defaultFat * servingSize).toStringAsFixed(1)}g'),
        ],
      ),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  final String label;
  final String value;

  const _NutritionItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: tokens.primary)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: tokens.textMuted)),
      ],
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