import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/menu_model.dart';
import '../providers/menu_search_provider.dart';

// 카테고리별 기본 영양소 (백엔드 categoryNutritionDefaults와 동일)
const _categoryDefaults = {
  'KOREAN':   {'calories': 500.0, 'carbs': 65.0, 'protein': 20.0, 'fat': 15.0, 'fiber': 4.0},
  'CHINESE':  {'calories': 550.0, 'carbs': 60.0, 'protein': 18.0, 'fat': 22.0, 'fiber': 3.0},
  'JAPANESE': {'calories': 450.0, 'carbs': 55.0, 'protein': 22.0, 'fat': 14.0, 'fiber': 3.0},
  'WESTERN':  {'calories': 600.0, 'carbs': 50.0, 'protein': 25.0, 'fat': 28.0, 'fiber': 4.0},
  'SNACK':    {'calories': 350.0, 'carbs': 45.0, 'protein': 8.0,  'fat': 16.0, 'fiber': 1.0},
  'CAFE':     {'calories': 300.0, 'carbs': 40.0, 'protein': 6.0,  'fat': 14.0, 'fiber': 1.0},
  'OTHER':    {'calories': 500.0, 'carbs': 55.0, 'protein': 18.0, 'fat': 18.0, 'fiber': 3.0},
};

const _categoryLabels = {
  'KOREAN':   '🍚 한식',
  'CHINESE':  '🥢 중식',
  'JAPANESE': '🍱 일식',
  'WESTERN':  '🍝 양식',
  'SNACK':    '🍿 스낵',
  'CAFE':     '☕ 카페',
  'OTHER':    '🍽️ 기타',
};

class MenuRegisterSheet extends ConsumerStatefulWidget {
  final String initialName;
  final void Function(MenuModel menu) onRegistered;

  const MenuRegisterSheet({
    super.key,
    required this.initialName,
    required this.onRegistered,
  });

  static Future<void> show(
      BuildContext context,
      String initialName,
      void Function(MenuModel menu) onRegistered,
      ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MenuRegisterSheet(
        initialName: initialName,
        onRegistered: onRegistered,
      ),
    );
  }

  @override
  ConsumerState<MenuRegisterSheet> createState() => _MenuRegisterSheetState();
}

class _MenuRegisterSheetState extends ConsumerState<MenuRegisterSheet> {
  late final TextEditingController _nameController;
  String _selectedCategory = 'KOREAN';
  bool _customNutrition = false;
  bool _isLoading = false;

  // 영양소 직접 입력 컨트롤러
  late final TextEditingController _caloriesCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _fatCtrl;
  late final TextEditingController _fiberCtrl;

  Map<String, double> get _defaults => {
    for (final e in _categoryDefaults[_selectedCategory]!.entries)
      e.key: e.value,
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _initNutritionControllers('KOREAN');
  }

  void _initNutritionControllers(String category) {
    final d = _categoryDefaults[category]!;
    _caloriesCtrl = TextEditingController(text: d['calories']!.toStringAsFixed(0));
    _carbsCtrl    = TextEditingController(text: d['carbs']!.toStringAsFixed(0));
    _proteinCtrl  = TextEditingController(text: d['protein']!.toStringAsFixed(0));
    _fatCtrl      = TextEditingController(text: d['fat']!.toStringAsFixed(0));
    _fiberCtrl    = TextEditingController(text: d['fiber']!.toStringAsFixed(0));
  }

  void _onCategoryChanged(String category) {
    final d = _categoryDefaults[category]!;
    setState(() {
      _selectedCategory = category;
      // 직접 수정 안 했으면 추정값 자동 갱신
      if (!_customNutrition) {
        _caloriesCtrl.text = d['calories']!.toStringAsFixed(0);
        _carbsCtrl.text    = d['carbs']!.toStringAsFixed(0);
        _proteinCtrl.text  = d['protein']!.toStringAsFixed(0);
        _fatCtrl.text      = d['fat']!.toStringAsFixed(0);
        _fiberCtrl.text    = d['fiber']!.toStringAsFixed(0);
      }
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메뉴명을 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final menu = await ref.read(menuRepositoryProvider).create(
        name: name,
        category: _selectedCategory,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onRegistered(menu);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('등록 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesCtrl.dispose();
    _carbsCtrl.dispose();
    _proteinCtrl.dispose();
    _fatCtrl.dispose();
    _fiberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text('새 메뉴 등록',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: tokens.textPrimary),
              ),
              const SizedBox(height: 4),
              Text('검색에 없는 메뉴를 직접 등록해요',
                style: TextStyle(fontSize: 13, color: tokens.textMuted),
              ),
              const SizedBox(height: 20),

              // ── 메뉴명 ──
              Text('메뉴명', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSub)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '예: 순두부찌개',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // ── 카테고리 ──
              Text('카테고리', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSub)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categoryLabels.entries.map((e) {
                  final selected = _selectedCategory == e.key;
                  return GestureDetector(
                    onTap: () => _onCategoryChanged(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? tokens.primary : tokens.primaryBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : tokens.primary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── 영양소 추정값 미리보기 ──
              Row(
                children: [
                  Text('영양소 추정값', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSub)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _customNutrition = !_customNutrition),
                    child: Text(
                      _customNutrition ? '추정값으로 되돌리기' : '직접 입력',
                      style: TextStyle(fontSize: 12, color: tokens.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (!_customNutrition)
              // 추정값 미리보기 카드
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: tokens.primaryBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('카테고리 평균 추정값',
                              style: TextStyle(fontSize: 11, color: tokens.textMuted)),
                          Text('자동 적용됩니다',
                              style: TextStyle(fontSize: 11, color: tokens.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _NutritionPreview(label: '칼로리', value: '${_defaults['calories']!.toStringAsFixed(0)}kcal', tokens: tokens),
                          _NutritionPreview(label: '탄수', value: '${_defaults['carbs']!.toStringAsFixed(0)}g', tokens: tokens),
                          _NutritionPreview(label: '단백', value: '${_defaults['protein']!.toStringAsFixed(0)}g', tokens: tokens),
                          _NutritionPreview(label: '지방', value: '${_defaults['fat']!.toStringAsFixed(0)}g', tokens: tokens),
                          _NutritionPreview(label: '식이섬유', value: '${_defaults['fiber']!.toStringAsFixed(0)}g', tokens: tokens),
                        ],
                      ),
                    ],
                  ),
                )
              else
              // 직접 입력 필드
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _NutritionField(label: '칼로리(kcal)', controller: _caloriesCtrl, tokens: tokens)),
                        const SizedBox(width: 8),
                        Expanded(child: _NutritionField(label: '탄수화물(g)', controller: _carbsCtrl, tokens: tokens)),
                        const SizedBox(width: 8),
                        Expanded(child: _NutritionField(label: '단백질(g)', controller: _proteinCtrl, tokens: tokens)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _NutritionField(label: '지방(g)', controller: _fatCtrl, tokens: tokens)),
                        const SizedBox(width: 8),
                        Expanded(child: _NutritionField(label: '식이섬유(g)', controller: _fiberCtrl, tokens: tokens)),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // ── 등록 버튼 ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('등록하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionPreview extends StatelessWidget {
  final String label;
  final String value;
  final AppColorTokens tokens;

  const _NutritionPreview({required this.label, required this.value, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tokens.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: tokens.textMuted)),
      ],
    );
  }
}

class _NutritionField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final AppColorTokens tokens;

  const _NutritionField({required this.label, required this.controller, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 11, color: tokens.textMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}