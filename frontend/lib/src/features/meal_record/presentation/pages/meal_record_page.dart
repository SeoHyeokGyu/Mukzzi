import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

import '../../../../core/providers/common_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../character/domain/models/badge_model.dart';
import '../../../character/presentation/providers/character_provider.dart';
import '../../../quest/data/models/quest_model.dart';
import '../../../quest/domain/entities/quest.dart';
import '../../../quest/presentation/providers/quest_provider.dart';
import '../../data/models/meal_model.dart';
import '../../data/models/menu_model.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/repositories/preference_repository.dart';
import '../widgets/menu_search_field.dart';
import '../providers/favorite_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mukzzi/src/features/ai/presentation/providers/ai_provider.dart';

// ─────────────────────────────────────────
// Providers
// ─────────────────────────────────────────

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(ref.watch(apiClientProvider));
});

final preferenceRepositoryProvider = Provider<PreferenceRepository>((ref) {
  return PreferenceRepository(ref.watch(apiClientProvider));
});

final mealListProvider =
    StateNotifierProvider<MealListNotifier, MealListState>((ref) {
  return MealListNotifier(ref.watch(mealRepositoryProvider));
});

class MealListState {
  final List<MealRecord> records;
  final bool isLoading;
  final bool hasNext;
  final String? nextCursor;
  final String? error;

  MealListState({
    this.records = const [],
    this.isLoading = false,
    this.hasNext = true,
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
        error: clearError ? null : (error ?? this.error),
      );
}

class MealListNotifier extends StateNotifier<MealListState> {
  final MealRepository _repo;
  MealListNotifier(this._repo) : super(MealListState());

  Future<void> fetch({bool refresh = false}) async {
    if (state.isLoading || (!refresh && !state.hasNext)) return;

    state = state.copyWith(isLoading: true);
    try {
      final result = await _repo.findAll(MealListFilter(
        cursor: refresh ? null : state.nextCursor,
        limit: 20,
      ));

      state = state.copyWith(
        records: refresh ? result.meals : [...state.records, ...result.meals],
        isLoading: false,
        hasNext: result.hasNext,
        nextCursor: result.nextCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void refresh() => fetch(refresh: true);

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = state.copyWith(
      records: state.records.where((r) => r.id != id).toList(),
    );
  }
}

final mealCreateProvider =
    StateNotifierProvider<MealCreateNotifier, MealCreateState>((ref) {
  return MealCreateNotifier(ref.watch(mealRepositoryProvider));
});

class MealCreateState {
  final bool isLoading;
  final String? error;
  final MealSideEffects? sideEffects;

  MealCreateState({this.isLoading = false, this.error, this.sideEffects});

  MealCreateState copyWith({
    bool? isLoading,
    String? error,
    MealSideEffects? sideEffects,
    bool clearError = false,
  }) =>
      MealCreateState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        sideEffects: sideEffects ?? this.sideEffects,
      );
}

class MealCreateNotifier extends StateNotifier<MealCreateState> {
  final MealRepository _repo;
  MealCreateNotifier(this._repo) : super(MealCreateState());

  Future<bool> submit(CreateMealRequest request) async {
    state =
        state.copyWith(isLoading: true, clearError: true, sideEffects: null);
    try {
      final result = await _repo.create(request);
      state = state.copyWith(isLoading: false, sideEffects: result.sideEffects);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

// ─────────────────────────────────────────
// MealRecordPage
// ─────────────────────────────────────────

class MealRecordPage extends ConsumerStatefulWidget {
  final String? initialMenuId;
  final String? initialMenuName;
  final String? initialCategory;
  final double? initialCalories;
  final double? initialCarbs;
  final double? initialProtein;
  final double? initialFat;

  const MealRecordPage({
    super.key,
    this.initialMenuId,
    this.initialMenuName,
    this.initialCategory,
    this.initialCalories,
    this.initialCarbs,
    this.initialProtein,
    this.initialFat,
  });

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
  void dispose() {
    _tabController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MealRecordPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMenuName != null &&
        widget.initialMenuName != oldWidget.initialMenuName) {
      _processInitialMenu();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _processInitialMenu();
  }

  void _processInitialMenu() {
    if (widget.initialMenuName != null) {
      final currentExtra = {
        'id': widget.initialMenuId,
        'name': widget.initialMenuName,
      };
      if (_lastExtra != null &&
          _lastExtra!['id'] == currentExtra['id'] &&
          _lastExtra!['name'] == currentExtra['name']) {
        return;
      }
      _lastExtra = currentExtra;

      _menuController.text = widget.initialMenuName!;
      _initialMenu = MenuModel(
        id: widget.initialMenuId ?? '',
        name: widget.initialMenuName!,
        category: widget.initialCategory ?? 'OTHER',
        defaultCalories: widget.initialCalories ?? 0,
        defaultCarbs: widget.initialCarbs ?? 0,
        defaultProtein: widget.initialProtein ?? 0,
        defaultFat: widget.initialFat ?? 0,
        defaultFiber: 0,
        defaultVitaminScore: 0,
        source: 'manual',
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('식사 기록'),
        actions: [
          IconButton(
            tooltip: '먹부림 캘린더',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => context.push('/meal-record/calendar'),
          ),
          IconButton(
            tooltip: '먹부림 도감',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => context.push('/meal-record/masteries'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor:
              Theme.of(context).extension<AppColorTokens>()!.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
            tabController: _tabController,
            menuController: _menuController,
            initialMenu: _initialMenu,
            selectedMealType: _selectedMealType,
            onMealTypeChanged: (v) => setState(() => _selectedMealType = v),
            onSaved: () {
              ref.read(mealListProvider.notifier).refresh();
              ref.read(questProvider.notifier).fetchQuests();
              ref.invalidate(characterProvider);
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
  final TabController tabController;
  final TextEditingController menuController;
  final MenuModel? initialMenu;
  final MealType selectedMealType;
  final ValueChanged<MealType> onMealTypeChanged;
  final VoidCallback onSaved;

  const _MealInputTab({
    required this.tabController,
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
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _submitKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _tutorialStarted = false;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double _servingSize = 1.0;
  String? _selectedWeather;
  String? _selectedMood;
  bool _wantFavorite = false;
  MenuModel? _selectedMenu;

  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isUploadingImage = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      ref.read(analyzeMealProvider.notifier).reset();
      setState(() {
        _selectedImage = file;
        _imageBytes = bytes;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabChanged);
    widget.menuController.addListener(_onMenuTextChanged);
    if (widget.initialMenu != null) {
      _selectedMenu = widget.initialMenu;
      _wantFavorite = false;
    }
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    widget.menuController.removeListener(_onMenuTextChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onMenuTextChanged() {
    if (mounted) setState(() {});
  }

  void _scrollToSubmit() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  void _onTabChanged() {
    if (widget.tabController.index == 0) {
      final quests = ref.read(questProvider).quests;
      if (quests.isNotEmpty) {
        _checkTutorial(quests);
      }
    }
  }

  void _checkTutorial(List<Quest> quests) {
    if (_tutorialStarted) return;
    if (widget.tabController.index != 0) return;

    final hasTutorialQuest = quests.any(
      (q) =>
          q.code == 'TUTORIAL_FIRST_MEAL' && q.status == QuestStatus.progress,
    );

    if (hasTutorialQuest) {
      _tutorialStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && widget.tabController.index == 0) {
            ShowcaseView.get().startShowCase([_searchKey, _submitKey]);
          }
        });
      });
    }
  }

  String? _getMealTypeMismatchWarning() {
    final expected = MealTypeHelper.fromHour(_selectedTime.hour);
    if (expected == widget.selectedMealType) return null;
    const labels = {
      MealType.breakfast: '아침 (06:00~10:59)',
      MealType.lunch: '점심 (12:00~13:59)',
      MealType.dinner: '저녁 (18:00~21:59)',
      MealType.snack: '간식 (그 외)',
    };
    return '현재 시간은 ${labels[expected]}입니다. 계속할까요?';
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

    final isManual = _selectedMenu == null || _selectedMenu?.id == 'ai-analyzed';
    MealNutritionPayload? nutritionPayload;
    if (isManual && _selectedMenu != null && _selectedMenu!.id == 'ai-analyzed') {
      nutritionPayload = MealNutritionPayload(
        calories: _selectedMenu!.defaultCalories,
        carbs: _selectedMenu!.defaultCarbs,
        protein: _selectedMenu!.defaultProtein,
        fat: _selectedMenu!.defaultFat,
        fiber: _selectedMenu!.defaultFiber,
        sodium: 0, // TODO: 모델에서 나트륨 정보 제공 시 업데이트
        vitaminScore: _selectedMenu!.defaultVitaminScore,
      );
    }

    String? imageUrl = ref.read(analyzeMealProvider).imageUrl;
    if (_selectedImage != null && imageUrl == null) {
      setState(() {
        _isUploadingImage = true;
      });
      try {
        imageUrl = await ref.read(aiRepositoryProvider).uploadImage(_selectedImage!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이미지 업로드 실패: $e')),
          );
        }
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }
      setState(() {
        _isUploadingImage = false;
      });
    }

    final request = CreateMealRequest(
      menuId: isManual ? null : _selectedMenu?.id,
      menuName: menuName,
      category: _selectedMenu?.category ?? 'OTHER',
      mealType: widget.selectedMealType.apiValue,
      servingSize: _servingSize,
      recordedAt: recordedAt,
      isManual: isManual,
      weatherTag: _selectedWeather,
      moodTag: _selectedMood,
      imageUrl: imageUrl,
      friendTags: [],
      nutrition: nutritionPayload,
    );

    final success = await ref.read(mealCreateProvider.notifier).submit(request);
    if (success && mounted) {
      if (_wantFavorite && _selectedMenu != null) {
        ref.read(favoriteListProvider.notifier).toggle(_selectedMenu!);
      }

      final sideEffects = ref.read(mealCreateProvider).sideEffects;
      if (sideEffects != null && mounted) {
        if (_tutorialStarted) {
          ShowcaseView.get().dismiss();
        }
        _showSideEffectsOverlay(sideEffects);
      } else if (mounted) {
        if (_tutorialStarted) {
          ShowcaseView.get().dismiss();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('식사 기록이 저장되었습니다')),
        );
      }
      widget.onSaved();
    }
  }

  void _showSideEffectsOverlay(MealSideEffects sideEffects) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            const SizedBox.expand(),
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {}, // 바텀시트 내부 클릭 시 닫히지 않도록
                child: _SideEffectsBottomSheet(sideEffects: sideEffects),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoArea(AppColorTokens tokens) {
    final aiState = ref.watch(analyzeMealProvider);

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: tokens.listItemBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(tokens.rCard),
        border: Border.all(
          color: tokens.primary.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.rCard - 1.5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_imageBytes != null) ...[
              Image.memory(
                _imageBytes!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(color: Colors.black.withValues(alpha: 0.3)),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  radius: 16,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    onPressed: aiState.isLoading
                        ? null
                        : () {
                            setState(() {
                              _selectedImage = null;
                              _imageBytes = null;
                            });
                            ref.read(analyzeMealProvider.notifier).reset();
                          },
                  ),
                ),
              ),
              if (aiState.isLoading) ...[
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Gemini가 이미지를 분석중입니다...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ] else if (aiState.data != null) ...[
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '분석 완료: ${aiState.data!.menuName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Positioned(
                  bottom: 12,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.psychology, size: 18),
                    label: const Text('Gemini AI로 분석하기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      await ref.read(analyzeMealProvider.notifier).analyzeImage(_selectedImage!);
                      final state = ref.read(analyzeMealProvider);
                      if (state.data != null) {
                        final result = state.data!;
                        setState(() {
                          _selectedMenu = MenuModel(
                            id: 'ai-analyzed',
                            name: result.menuName,
                            category: result.category,
                            defaultCalories: result.calories,
                            defaultCarbs: result.carbs,
                            defaultProtein: result.protein,
                            defaultFat: result.fat,
                            defaultFiber: result.fiber,
                            defaultVitaminScore: result.vitaminScore,
                            source: 'ai',
                          );
                          widget.menuController.text = result.menuName;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${result.menuName} (으)로 분석되었습니다!')),
                          );
                        }
                      } else if (state.error != null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('분석 실패: ${state.error}')),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ] else ...[
              InkWell(
                onTap: _pickImage,
                child: SizedBox.expand(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: tokens.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '음식 사진을 추가해보세요',
                        style: TextStyle(
                          color: tokens.textSub,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '(사진을 첨부하고 AI 분석을 수동으로 요청할 수 있습니다)',
                        style: TextStyle(
                          color: tokens.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(mealCreateProvider);
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final warning = _getMealTypeMismatchWarning();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhotoArea(tokens),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('감지된 음식',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary)),
              Text('직접 입력',
                  style: TextStyle(
                      fontSize: 12,
                      color: tokens.primary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Showcase(
            key: _searchKey,
            title: '음식 검색',
            description: '오늘 드신 음식을 검색하거나 직접 입력해보세요.',
            disableDefaultTargetGestures: true,
            child: MenuSearchField(
              controller: widget.menuController,
              onMenuSelected: (menu) {
                setState(() {
                  _selectedMenu = menu;
                  _wantFavorite = menu != null
                      ? ref.read(favoriteListProvider).isFavorite(menu.id)
                      : false;
                });
                if (menu != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _scrollToSubmit();
                      Future.delayed(const Duration(milliseconds: 600), () {
                        if (mounted) {
                          ShowcaseView.get().next();
                        }
                      });
                    }
                  });
                }
              },
            ),
          ),
          if (_selectedMenu != null) ...[
            const SizedBox(height: 8),
            _FoodItemRow(
              menu: _selectedMenu!,
              tokens: tokens,
              onClear: () => setState(() {
                _selectedMenu = null;
                widget.menuController.clear();
              }),
            ),
          ],
          const SizedBox(height: 24),
          Text('식사 시간',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary)),
          const SizedBox(height: 10),
          _InternalMealTypeSelector(
            selectedType: widget.selectedMealType,
            onChanged: widget.onMealTypeChanged,
            warning: warning,
            tokens: tokens,
          ),
          const SizedBox(height: 12),
          _DateTimePicker(
            date: _selectedDate,
            time: _selectedTime,
            onDateChanged: (d) => setState(() => _selectedDate = d),
            onTimeChanged: (t) => setState(() => _selectedTime = t),
            tokens: tokens,
          ),
          const SizedBox(height: 24),
          Text('기록 디테일',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary)),
          const SizedBox(height: 10),
          _PortionControl(
            servingSize: _servingSize,
            onChanged: (v) => setState(() => _servingSize = v),
            tokens: tokens,
          ),
          const SizedBox(height: 16),
          _TagsArea(
            selectedWeather: _selectedWeather,
            selectedMood: _selectedMood,
            onWeatherChanged: (v) => setState(() => _selectedWeather = v),
            onMoodChanged: (v) => setState(() => _selectedMood = v),
            tokens: tokens,
          ),
          const SizedBox(height: 16),
          _FavoriteToggle(
            value: _wantFavorite,
            onChanged: (v) => setState(() => _wantFavorite = v),
            tokens: tokens,
          ),
          const SizedBox(height: 20),
          Showcase(
            key: _submitKey,
            title: '기록 완료',
            description: '모두 입력했다면 먹찌에게 음식을 주세요! 먹찌가 성장합니다.',
            disableDefaultTargetGestures: true,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(tokens.rCard)),
                  elevation: 0,
                ),
                onPressed: (createState.isLoading ||
                        _isUploadingImage ||
                        widget.menuController.text.trim().isEmpty)
                    ? null
                    : _submit,
                child: (createState.isLoading || _isUploadingImage)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite,
                              size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text('먹찌에게 주기',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text('+XP',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InternalMealTypeSelector extends StatelessWidget {
  final MealType selectedType;
  final ValueChanged<MealType> onChanged;
  final String? warning;
  final AppColorTokens tokens;

  const _InternalMealTypeSelector({
    required this.selectedType,
    required this.onChanged,
    this.warning,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: MealType.values.map((type) {
            final isSelected = selectedType == type;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(type.label),
                  selected: isSelected,
                  showCheckmark: false,
                  onSelected: (val) => val ? onChanged(type) : null,
                ),
              ),
            );
          }).toList(),
        ),
        if (warning != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(warning!,
                style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }
}

// Legacy _PhotoArea removed

class _FoodItemRow extends StatelessWidget {
  final MenuModel menu;
  final AppColorTokens tokens;
  final VoidCallback onClear;

  const _FoodItemRow(
      {required this.menu, required this.tokens, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: BorderRadius.circular(tokens.rItem),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: tokens.primaryBg,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.restaurant_menu, color: tokens.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(menu.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text('${menu.defaultCalories.toInt()} kcal',
                    style: TextStyle(fontSize: 11, color: tokens.textMuted)),
              ],
            ),
          ),
          IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 18),
              visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  final DateTime date;
  final TimeOfDay time;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final AppColorTokens tokens;

  const _DateTimePicker(
      {required this.date,
      required this.time,
      required this.onDateChanged,
      required this.onTimeChanged,
      required this.tokens});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy.MM.dd').format(date);
    final timeStr = time.format(context);

    return Row(
      children: [
        Expanded(
          child: _PickerTile(
            icon: Icons.calendar_today_outlined,
            label: dateStr,
            onTap: () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now());
              if (d != null) onDateChanged(d);
            },
            tokens: tokens,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PickerTile(
            icon: Icons.access_time,
            label: timeStr,
            onTap: () async {
              final t =
                  await showTimePicker(context: context, initialTime: time);
              if (t != null) onTimeChanged(t);
            },
            tokens: tokens,
          ),
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppColorTokens tokens;

  const _PickerTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.tokens});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.rItem),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
            color: tokens.listItemBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(tokens.rItem)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: tokens.textMuted),
            const SizedBox(width: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _PortionControl extends StatelessWidget {
  final double servingSize;
  final ValueChanged<double> onChanged;
  final AppColorTokens tokens;

  const _PortionControl(
      {required this.servingSize,
      required this.onChanged,
      required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: tokens.listItemBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(tokens.rItem)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('분량',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${servingSize.toStringAsFixed(1)} 인분',
                  style: TextStyle(
                      color: tokens.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          Slider(
              value: servingSize,
              min: 0.5,
              max: 3.0,
              divisions: 5,
              activeColor: tokens.primary,
              inactiveColor: tokens.primary.withValues(alpha: 0.1),
              onChanged: onChanged),
        ],
      ),
    );
  }
}

class _TagsArea extends StatelessWidget {
  final String? selectedWeather;
  final String? selectedMood;
  final ValueChanged<String?> onWeatherChanged;
  final ValueChanged<String?> onMoodChanged;
  final AppColorTokens tokens;

  const _TagsArea(
      {this.selectedWeather,
      this.selectedMood,
      required this.onWeatherChanged,
      required this.onMoodChanged,
      required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TagRow(
            title: '날씨',
            options: const ['SUNNY', 'CLOUDY', 'RAINY', 'HOT', 'COLD'],
            selected: selectedWeather,
            onChanged: onWeatherChanged,
            tokens: tokens),
        const SizedBox(height: 10),
        _TagRow(
            title: '기분',
            options: const ['GOOD', 'TIRED', 'STRESSED', 'HUNGRY', 'EXCITED'],
            selected: selectedMood,
            onChanged: onMoodChanged,
            tokens: tokens),
      ],
    );
  }
}

class _TagRow extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final AppColorTokens tokens;

  const _TagRow(
      {required this.title,
      required this.options,
      required this.selected,
      required this.onChanged,
      required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: 36,
            child: Text(title,
                style: TextStyle(fontSize: 12, color: tokens.textMuted))),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((opt) {
                final isSelected = selected == opt;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(opt, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (val) => onChanged(val ? opt : null),
                    selectedColor: tokens.primary.withValues(alpha: 0.2),
                    backgroundColor: tokens.listItemBg.withValues(alpha: 0.5),
                    labelStyle: TextStyle(
                        color: isSelected ? tokens.primary : tokens.textSub,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal),
                    padding: EdgeInsets.zero,
                    side: BorderSide(
                        color: isSelected
                            ? tokens.primary.withValues(alpha: 0.5)
                            : Colors.transparent),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoriteToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColorTokens tokens;

  const _FavoriteToggle(
      {required this.value, required this.onChanged, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
          color: tokens.listItemBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(tokens.rItem)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('내 즐겨찾기에 추가',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected) ? tokens.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealListTab extends ConsumerStatefulWidget {
  final VoidCallback onAddTap;
  const _MealListTab({required this.onAddTap});

  @override
  ConsumerState<_MealListTab> createState() => _MealListTabState();
}

class _MealListTabState extends ConsumerState<_MealListTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(mealListProvider.notifier).fetch(refresh: true));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(mealListProvider.notifier).fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealListProvider);
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    if (state.isLoading && state.records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_outlined,
                size: 64, color: tokens.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('아직 기록된 식사가 없어요',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: widget.onAddTap,
                style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.primary,
                    foregroundColor: Colors.white),
                child: const Text('첫 식사 기록하기')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.read(mealListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.records.length + (state.hasNext ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.records.length) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator()));
          }
          final meal = state.records[index];
          return _MealListItem(meal: meal, tokens: tokens);
        },
      ),
    );
  }
}

class _MealListItem extends ConsumerWidget {
  final MealRecord meal;
  final AppColorTokens tokens;

  const _MealListItem({required this.meal, required this.tokens});

  void _showImageDialog(BuildContext context, String imageUrl, String menuName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.grey[900]!.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image_outlined, color: Colors.redAccent, size: 48),
                            SizedBox(height: 16),
                            Text(
                              '이미지를 불러올 수 없습니다.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  menuName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref) {
    final mealType = MealTypeHelper.fromString(meal.mealType);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final tokens = Theme.of(ctx).extension<AppColorTokens>()!;
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                // 핸들
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: tokens.textMuted.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // 헤더: 끼니 배지 + 음식명
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: tokens.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(mealType.icon, size: 13, color: tokens.primary),
                          const SizedBox(width: 4),
                          Text(
                            mealType.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: tokens.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        meal.menuName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('M월 d일 HH:mm').format(meal.recordedAt),
                  style: TextStyle(fontSize: 12, color: tokens.textMuted),
                ),

                // 이미지
                if (meal.imageUrl != null) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showImageDialog(context, meal.imageUrl!, meal.menuName);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        meal.imageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 180,
                          color: tokens.listItemBg,
                          child: Icon(Icons.image_not_supported_outlined,
                              color: tokens.textMuted),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                Divider(color: tokens.textMuted.withValues(alpha: 0.1)),
                const SizedBox(height: 16),

                // 영양소 그리드
                Text(
                  '영양 정보',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tokens.textSub,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    _NutrientTile(label: '칼로리', value: meal.calories, unit: 'kcal', tokens: tokens, highlight: true),
                    _NutrientTile(label: '탄수화물', value: meal.carbs, unit: 'g', tokens: tokens),
                    _NutrientTile(label: '단백질', value: meal.protein, unit: 'g', tokens: tokens),
                    _NutrientTile(label: '지방', value: meal.fat, unit: 'g', tokens: tokens),
                  ],
                ),

                // 별점
                if (meal.rating != null) ...[
                  const SizedBox(height: 16),
                  Divider(color: tokens.textMuted.withValues(alpha: 0.1)),
                  const SizedBox(height: 12),
                  Text(
                    '평점',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tokens.textSub,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < meal.rating! ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 22,
                        color: i < meal.rating!
                            ? const Color(0xFFFFCC33)
                            : tokens.textMuted.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ],

                // 메모 / 리뷰
                if (meal.review != null && meal.review!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(color: tokens.textMuted.withValues(alpha: 0.1)),
                  const SizedBox(height: 12),
                  Text(
                    '메모',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tokens.textSub,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.listItemBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      meal.review!,
                      style: TextStyle(fontSize: 14, color: tokens.textSub, height: 1.5),
                    ),
                  ),
                ],

                // 날씨 / 기분 태그
                if (meal.weatherTag != null || meal.moodTag != null) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (meal.weatherTag != null)
                        _TagChip(label: meal.weatherTag!, tokens: tokens),
                      if (meal.moodTag != null)
                        _TagChip(label: meal.moodTag!, tokens: tokens),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
                Divider(color: tokens.textMuted.withValues(alpha: 0.1)),
                const SizedBox(height: 12),

                // 삭제 버튼
                TextButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: ctx,
                      builder: (dCtx) => AlertDialog(
                        title: const Text('식사 기록 삭제'),
                        content: Text('"${meal.menuName}" 기록을 삭제할까요?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dCtx, false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dCtx, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                            ),
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && ctx.mounted) {
                      Navigator.pop(ctx);
                      await ref.read(mealListProvider.notifier).delete(meal.id);
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  label: const Text('이 기록 삭제', style: TextStyle(color: Colors.redAccent)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = DateFormat('HH:mm').format(meal.recordedAt);
    final dateStr = DateFormat('M월 d일').format(meal.recordedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BentoCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(tokens.rCard),
        onTap: () => _showDetailSheet(context, ref),
        child: Row(
          children: [
            if (meal.imageUrl != null)
              GestureDetector(
                onTap: () => _showImageDialog(context, meal.imageUrl!, meal.menuName),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Tooltip(
                    message: '사진 크게 보기',
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          meal.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: tokens.listItemBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.restaurant,
                                color: tokens.primary.withValues(alpha: 0.5),
                              ),
                            );
                          },
                        )),
                  ),
                ),
              )
            else
              Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      color: tokens.listItemBg,
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.restaurant,
                      color: tokens.primary.withValues(alpha: 0.5))),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(meal.menuName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                      '$dateStr $timeStr · ${meal.calories?.toInt() ?? 0} kcal',
                      style: TextStyle(fontSize: 12, color: tokens.textMuted))
                ])),
            Icon(Icons.arrow_forward_ios, size: 14, color: tokens.textMuted),
          ],
        ),
      ),
    );
  }
}

class _SideEffectsBottomSheet extends StatelessWidget {
  final MealSideEffects sideEffects;

  const _SideEffectsBottomSheet({required this.sideEffects});

  Widget _buildSectionHeader(
      String title, IconData icon, AppColorTokens tokens) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Icon(icon, size: 16, color: tokens.textMuted),
          const SizedBox(width: 6),
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: tokens.textMuted,
                  letterSpacing: -0.2))
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: tokens.textMuted.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('기록 완료!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('+${sideEffects.expGained} XP 획득',
                style: TextStyle(
                    fontSize: 15,
                    color: tokens.primary,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            if (sideEffects.questsProgressed.isNotEmpty ||
                (sideEffects.grantedBadges.isNotEmpty)) ...[
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('이번 식사로 얻은 성과',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800))),
              const SizedBox(height: 16),
              if (sideEffects.questsProgressed
                  .any((q) => q.questType.toUpperCase() == 'DAILY')) ...[
                _buildSectionHeader('오늘의 목표', Icons.today_rounded, tokens),
                ...sideEffects.questsProgressed
                    .where((q) => q.questType.toUpperCase() == 'DAILY')
                    .map(
                        (q) => _QuestProgressOverlayItem(q: q, tokens: tokens)),
                const SizedBox(height: 12)
              ],
              if (sideEffects.questsProgressed
                  .any((q) => q.questType.toUpperCase() == 'WEEKLY')) ...[
                _buildSectionHeader(
                    '이번 주 도전', Icons.date_range_rounded, tokens),
                ...sideEffects.questsProgressed
                    .where((q) => q.questType.toUpperCase() == 'WEEKLY')
                    .map(
                        (q) => _QuestProgressOverlayItem(q: q, tokens: tokens)),
                const SizedBox(height: 12)
              ],
              if (sideEffects.grantedBadges.isNotEmpty) ...[
                _buildSectionHeader(
                    '새로운 뱃지', Icons.military_tech_rounded, tokens),
                ...sideEffects.grantedBadges
                    .map((b) => _BadgeOverlayItem(badge: b, tokens: tokens)),
                const SizedBox(height: 12)
              ],
            ],
            if (sideEffects.grantedTitle != null) ...[
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: tokens.primary.withValues(alpha: 0.3))),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.stars,
                            color: Colors.orange, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('새로운 칭호 획득!',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w900)),
                          Text(sideEffects.grantedTitle!.name,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800))
                        ]))
                  ])),
              const SizedBox(height: 24)
            ],
            SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    child: const Text('확인',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)))),
          ],
        ),
      ),
    );
  }
}

class _BadgeOverlayItem extends StatelessWidget {
  final BadgeModel badge;
  final AppColorTokens tokens;
  const _BadgeOverlayItem({required this.badge, required this.tokens});
  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: tokens.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.primary.withValues(alpha: 0.2))),
        child: Row(children: [
          const Icon(Icons.verified_rounded, color: Colors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(badge.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14))),
          const Text('획득!',
              style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12))
        ]));
  }
}

class _QuestProgressOverlayItem extends StatelessWidget {
  final QuestProgressInfoModel q;
  final AppColorTokens tokens;
  const _QuestProgressOverlayItem({required this.q, required this.tokens});
  String _getLocalizedType(String type) {
    switch (type.toUpperCase()) {
      case 'DAILY':
        return '일일';
      case 'WEEKLY':
        return '주간';
      case 'ACHIEVEMENT':
        return '업적';
      default:
        return '퀘스트';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: tokens.listItemBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: tokens.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(_getLocalizedType(q.questType),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: tokens.primary))),
            const SizedBox(width: 8),
            Expanded(
                child: Text(q.questTitle,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            Text('${q.progress}/${q.target}',
                style: TextStyle(
                    fontSize: 12,
                    color: tokens.textSub,
                    fontWeight: FontWeight.w500))
          ]),
          const SizedBox(height: 8),
          ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                  value: q.target > 0 ? q.progress / q.target : 0,
                  minHeight: 4,
                  backgroundColor: tokens.primaryBg,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      q.completed ? Colors.green : tokens.primary)))
        ]));
  }
}

// ─────────────────────────────────────────
// 식사 상세 시트 헬퍼 위젯
// ─────────────────────────────────────────

class _NutrientTile extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;
  final AppColorTokens tokens;
  final bool highlight;

  const _NutrientTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.tokens,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? tokens.primary.withValues(alpha: 0.08)
            : tokens.listItemBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: highlight ? tokens.primary : tokens.textMuted,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value != null ? '${value!.toStringAsFixed(1)} $unit' : '-',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: highlight ? tokens.primary : tokens.textSub,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final AppColorTokens tokens;

  const _TagChip({required this.label, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.listItemBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tokens.textMuted.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: tokens.textSub),
      ),
    );
  }
}
