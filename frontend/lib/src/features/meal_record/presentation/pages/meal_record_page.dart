import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/common_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../../quest/data/models/quest_model.dart';
import '../../../quest/presentation/providers/quest_provider.dart';
import '../../data/models/meal_model.dart';
import '../../data/models/menu_model.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/repositories/preference_repository.dart';
import '../providers/favorite_provider.dart';
import '../widgets/menu_search_field.dart';

// ─────────────────────────────────────────
// Providers
// ─────────────────────────────────────────

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(ref.watch(apiClientProvider));
});

final preferenceRepositoryProvider = Provider<PreferenceRepository>((ref) {
  return PreferenceRepository(ref.watch(apiClientProvider));
});

// --- Create ---

class MealCreateState {
  final bool isLoading;
  final String? error;
  final MealRecord? created;
  final MealSideEffects? sideEffects;

  const MealCreateState({
    this.isLoading = false,
    this.error,
    this.created,
    this.sideEffects,
  });

  MealCreateState copyWith({
    bool? isLoading,
    String? error,
    MealRecord? created,
    MealSideEffects? sideEffects,
    bool clearError = false,
    bool clearCreated = false,
  }) =>
      MealCreateState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        created: clearCreated ? null : created ?? this.created,
        sideEffects: sideEffects ?? this.sideEffects,
      );
}

class MealCreateNotifier extends StateNotifier<MealCreateState> {
  final MealRepository _repo;
  final Ref _ref;

  MealCreateNotifier(this._repo, this._ref) : super(const MealCreateState());

  Future<bool> submit(CreateMealRequest request) async {
    state = state.copyWith(isLoading: true, clearError: true, clearCreated: true);
    try {
      final result = await _repo.create(request);
      state = state.copyWith(
        isLoading: false,
        created: result.meal,
        sideEffects: result.sideEffects,
      );

      // 퀘스트 정보 갱신
      _ref.read(questProvider.notifier).fetchQuests();

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final mealCreateProvider =
StateNotifierProvider.autoDispose<MealCreateNotifier, MealCreateState>(
      (ref) => MealCreateNotifier(ref.watch(mealRepositoryProvider), ref),
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
  MenuModel? _initialMenu;
  Map<String, dynamic>? _lastExtra;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _menuController = TextEditingController();
    _selectedMealType = MealTypeHelper.fromHour(TimeOfDay.now().hour);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;

    if (extra != null && extra != _lastExtra) {
      _lastExtra = extra;
      final menuName = extra['menuName'] as String?;
      final menuId = extra['menuId'] as String?;
      if (menuName != null) {
        _menuController.text = menuName;
        setState(() {
          _initialMenu = menuId != null
              ? MenuModel(
            id: menuId,
            name: menuName,
            category: extra['category'] as String? ?? 'KOREAN',
            source: '',
            defaultCalories: (extra['calories'] as num?)?.toDouble() ?? 0,
            defaultCarbs: (extra['carbs'] as num?)?.toDouble() ?? 0,
            defaultProtein: (extra['protein'] as num?)?.toDouble() ?? 0,
            defaultFat: (extra['fat'] as num?)?.toDouble() ?? 0,
            defaultFiber: 0,
            defaultVitaminScore: 0,
          )
              : null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tabController.animateTo(0);
        });
      }
    }
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
            initialMenu: _initialMenu,
            selectedMealType: _selectedMealType,
            onMealTypeChanged: (v) => setState(() => _selectedMealType = v),
            onSaved: () {
              ref.read(mealListProvider.notifier).refresh();
              _tabController.animateTo(1);
              _menuController.clear();
              setState(() => _initialMenu = null);
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
  final MenuModel? initialMenu;
  final MealType selectedMealType;
  final ValueChanged<MealType> onMealTypeChanged;
  final VoidCallback onSaved;

  const _MealInputTab({
    required this.menuController,
    this.initialMenu,
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
  String? _selectedPreference;
  bool _wantFavorite = false;
  MenuModel? _selectedMenu;

  @override
  void initState() {
    super.initState();
    // 룰렛/필터에서 넘어온 메뉴 초기값 세팅
    if (widget.initialMenu != null) {
      _selectedMenu = widget.initialMenu;
      _wantFavorite = false;
    }
  }

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

  void _showSideEffectsOverlay(MealSideEffects? sideEffects) {
    if (sideEffects == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SideEffectsBottomSheet(sideEffects: sideEffects),
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
      final savedMenu = _selectedMenu;
      if (savedMenu != null) {
        final isFav = ref.read(favoriteListProvider).isFavorite(savedMenu.id);
        if (_wantFavorite != isFav) {
          try {
            await ref.read(favoriteListProvider.notifier).toggle(savedMenu);
          } catch (_) {}
        }

        if (_selectedPreference != null) {
          try {
            await ref
                .read(preferenceRepositoryProvider)
                .set(savedMenu.id, _selectedPreference!);
          } catch (_) {}
        }
      }

      final sideEffects = ref.read(mealCreateProvider).sideEffects;
      if (sideEffects != null && mounted) {
        _showSideEffectsOverlay(sideEffects);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('식사 기록이 저장되었습니다')),
        );
      }

      setState(() {
        _selectedMenu = null;
        _servingSize = 1.0;
        _selectedWeather = null;
        _selectedMood = null;
        _selectedPreference = null;
        _wantFavorite = false;
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
          _PhotoArea(tokens: tokens),
          const SizedBox(height: 16),

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
            onMenuSelected: (menu) => setState(() {
              _selectedMenu = menu;
              _wantFavorite = menu != null
                  ? ref.read(favoriteListProvider).isFavorite(menu.id)
                  : false;
            }),
          ),

          if (_selectedMenu != null) ...[
            const SizedBox(height: 8),
            _FoodItemRow(
              menu: _selectedMenu!,
              servingSize: _servingSize,
              isFavorite: _wantFavorite,
              onFavoriteToggle: () => setState(() => _wantFavorite = !_wantFavorite),
              onDecrement: () => setState(() {
                _servingSize = (_servingSize - 0.5).clamp(0.5, 10.0);
              }),
              onIncrement: () => setState(() {
                _servingSize = (_servingSize + 0.5).clamp(0.5, 10.0);
              }),
              onServingChanged: (val) => setState(() => _servingSize = val),
              tokens: tokens,
            ),
            const SizedBox(height: 12),
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
                            text: (_selectedMenu!.defaultCalories * _servingSize).toStringAsFixed(0),
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
            selectedPreference: _selectedPreference,
            onPreferenceChanged: (v) => setState(() => _selectedPreference = v),
            hasMenu: _selectedMenu != null,
            warning: warning,
            tokens: tokens,
          ),
          const SizedBox(height: 20),

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

class _FoodItemRow extends StatelessWidget {
  final MenuModel menu;
  final double servingSize;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<double> onServingChanged;
  final AppColorTokens tokens;

  const _FoodItemRow({
    required this.menu,
    required this.servingSize,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onDecrement,
    required this.onIncrement,
    required this.onServingChanged,
    required this.tokens,
  });

  void _showServingInputDialog(BuildContext context) {
    final controller = TextEditingController(text: servingSize.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('수량 직접 입력'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                suffix: Text('인분'),
                hintText: '예: 1.5',
              ),
            ),
            const SizedBox(height: 12),
            // 빠른 선택 칩
            Wrap(
              spacing: 8,
              children: [0.5, 1.0, 1.5, 2.0, 3.0].map((v) {
                return ActionChip(
                  label: Text('${v}인분'),
                  onPressed: () {
                    controller.text = v.toStringAsFixed(1);
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val >= 0.5 && val <= 10.0) {
                onServingChanged(val);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('0.5 ~ 10 사이로 입력해주세요')),
                );
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(tokens.rCard),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: onFavoriteToggle,
              child: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                size: 22,
                color: isFavorite ? Colors.amber : tokens.textMuted,
              ),
            ),
            const SizedBox(width: 10),
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
                  // 숫자 탭 시 직접 입력 다이얼로그
                  GestureDetector(
                    onTap: () => _showServingInputDialog(context),
                    child: SizedBox(
                      width: 40,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            servingSize.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: tokens.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '탭',
                            style: TextStyle(fontSize: 8, color: tokens.textMuted),
                          ),
                        ],
                      ),
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
  final String? selectedPreference;
  final ValueChanged<String?> onPreferenceChanged;
  final bool hasMenu;
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
    required this.selectedPreference,
    required this.onPreferenceChanged,
    required this.hasMenu,
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
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('날씨 / 기분 / 선호도', style: TextStyle(fontSize: 12, color: t.textMuted, fontWeight: FontWeight.w500)),
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
              child: Column(
                children: [
                  Row(
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
                  if (widget.hasMenu) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PreferenceButton(
                            label: '👍 좋아요',
                            value: 'LIKE',
                            selected: widget.selectedPreference == 'LIKE',
                            tokens: t,
                            onTap: () => widget.onPreferenceChanged(
                              widget.selectedPreference == 'LIKE' ? null : 'LIKE',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PreferenceButton(
                            label: '👎 싫어요',
                            value: 'DISLIKE',
                            selected: widget.selectedPreference == 'DISLIKE',
                            tokens: t,
                            onTap: () => widget.onPreferenceChanged(
                              widget.selectedPreference == 'DISLIKE' ? null : 'DISLIKE',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreferenceButton extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final AppColorTokens tokens;
  final VoidCallback onTap;

  const _PreferenceButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.tokens,
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
          color: selected ? tokens.primary : tokens.listItemBg,
          borderRadius: BorderRadius.circular(tokens.rItem),
          border: selected
              ? null
              : Border.all(color: tokens.primary.withValues(alpha: 0.15)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : tokens.textSub,
          ),
          textAlign: TextAlign.center,
        ),
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
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerListItem(),
        ),
      );
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
            child: Text(label, style: TextStyle(color: tokens.textMuted)),
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
              style: TextStyle(fontSize: 13, color: tokens.textMuted)),
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

class _SideEffectsBottomSheet extends StatelessWidget {
  final MealSideEffects sideEffects;

  const _SideEffectsBottomSheet({required this.sideEffects});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: tokens.textMuted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '기록 완료!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '+${sideEffects.expGained} XP 획득',
            style: TextStyle(fontSize: 14, color: tokens.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (sideEffects.questsProgressed.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '퀘스트 진행도',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ...sideEffects.questsProgressed.map((q) => _QuestProgressOverlayItem(q: q, tokens: tokens)),
            const SizedBox(height: 12),
          ],
          if (sideEffects.grantedTitle != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.primaryBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('새로운 칭호 획득!', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                        Text(sideEffects.grantedTitle!.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestProgressOverlayItem extends StatelessWidget {
  final QuestProgressInfoModel q;
  final AppColorTokens tokens;

  const _QuestProgressOverlayItem({required this.q, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(q.questType, style: const TextStyle(fontSize: 12)),
              Text('${q.progress} / ${q.target}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: q.progress / q.target,
              minHeight: 4,
              backgroundColor: tokens.primaryBg,
              valueColor: AlwaysStoppedAnimation<Color>(q.completed ? Colors.green : tokens.primary),
            ),
          ),
        ],
      ),
    );
  }
}