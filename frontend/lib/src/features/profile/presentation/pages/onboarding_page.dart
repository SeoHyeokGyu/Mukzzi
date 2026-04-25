import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/onboarding_request.dart';
import '../providers/user_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _activityLevel = 'MODERATE';
  String _goal = 'MAINTAIN';
  final _mukzziNameController = TextEditingController();
  int _bodyType = 0;
  int _muscle = 0;
  int _skinTone = 0;
  int _expression = 0;

  @override
  void initState() {
    super.initState();
    _heightController.addListener(_updateState);
    _weightController.addListener(_updateState);
    _mukzziNameController.addListener(_updateState);
  }

  void _updateState() => setState(() {});

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _mukzziNameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool get _isCurrentStepValid {
    if (_currentStep == 0) {
      final h = double.tryParse(_heightController.text) ?? 0;
      final w = double.tryParse(_weightController.text) ?? 0;
      return h > 0 && w > 0;
    }
    if (_currentStep == 2) {
      return _mukzziNameController.text.trim().isNotEmpty;
    }
    return true;
  }

  void _nextStep() {
    if (!_isCurrentStepValid) return;
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  Future<void> _submit() async {
    final request = OnboardingRequest(
      mukzziName: _mukzziNameController.text.trim(),
      height: double.parse(_heightController.text),
      weight: double.parse(_weightController.text),
      activityLevel: _activityLevel,
      goal: _goal,
      bodyType: _bodyType,
      muscle: _muscle,
      skinTone: _skinTone,
      expression: _expression,
    );
    final success = await ref.read(userProvider.notifier).onboarding(request);
    if (success && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final isLoading = ref.watch(userProvider).isLoading;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return GradientScaffold(
      appBar: AppBar(
        title: Text('${_currentStep + 1} / 3', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tokens.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 8.0, bottom: bottomPadding > 0 ? 8.0 : 24.0),
        child: Column(
          children: [
            _buildProgressIndicator(tokens),
            const SizedBox(height: 24),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildScrollableStep(_buildPhysicalStep(tokens)),
                  _buildScrollableStep(_buildGoalStep(tokens)),
                  _buildScrollableStep(_buildCharacterStep(tokens)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildNavigationButtons(isLoading, tokens),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableStep(Widget child) => ScrollConfiguration(behavior: const ScrollBehavior().copyWith(overscroll: false), child: SingleChildScrollView(child: child));

  Widget _buildNavigationButtons(bool isLoading, AppColorTokens tokens) {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: isLoading ? null : _prevStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: tokens.textMuted.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  foregroundColor: tokens.textPrimary,
                ),
                child: const Text('이전', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: AppGradientButton(
            label: _currentStep == 2 ? '먹찌와 시작하기' : '다음',
            onPressed: _nextStep,
            isLoading: isLoading,
            isDisabled: !_isCurrentStepValid,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(AppColorTokens tokens) {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isActive ? tokens.primary : tokens.textMuted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPhysicalStep(AppColorTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('기본 신체 정보', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tokens.textPrimary)),
        const SizedBox(height: 8),
        Text('권장 섭취량 계산을 위해 필요합니다.', style: TextStyle(fontSize: 14, color: tokens.textSub)),
        const SizedBox(height: 32),
        _buildTextField(tokens, controller: _heightController, label: '키', suffix: 'cm', icon: Icons.height),
        const SizedBox(height: 20),
        _buildTextField(tokens, controller: _weightController, label: '몸무게', suffix: 'kg', icon: Icons.monitor_weight_outlined),
        const SizedBox(height: 32),
        Text('평소 활동량', style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 16),
        _buildActivityLevelSelector(tokens),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTextField(AppColorTokens tokens, {required TextEditingController controller, required String label, required String suffix, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.textMuted.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: tokens.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          icon: Icon(icon, color: tokens.textSub, size: 22),
          labelText: label,
          labelStyle: TextStyle(color: tokens.textSub),
          suffixText: suffix,
          suffixStyle: TextStyle(color: tokens.textSub),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildActivityLevelSelector(AppColorTokens tokens) {
    final levels = [
      {'id': 'LOW', 'label': '거의 없음', 'desc': '주로 앉아서 생활'},
      {'id': 'MODERATE', 'label': '보통', 'desc': '주 1~3회 가벼운 운동'},
      {'id': 'HIGH', 'label': '활동적', 'desc': '주 3~5회 강한 운동'},
      {'id': 'VERY_HIGH', 'label': '매우 활동적', 'desc': '선수급 활동량'},
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: levels.map((level) {
        final isSelected = _activityLevel == level['id'];
        return GestureDetector(
          onTap: () => setState(() => _activityLevel = level['id'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 48 - 10) / 2,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? tokens.primaryBg : tokens.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? tokens.primary : tokens.textMuted.withValues(alpha: 0.1), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(level['label']!, style: TextStyle(color: isSelected ? tokens.primary : tokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(level['desc']!, style: TextStyle(color: isSelected ? tokens.primary.withValues(alpha: 0.7) : tokens.textSub, fontSize: 12)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalStep(AppColorTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('나의 목표 선택', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tokens.textPrimary)),
        const SizedBox(height: 8),
        Text('목표에 따라 영양 목표가 설정됩니다.', style: TextStyle(fontSize: 14, color: tokens.textSub)),
        const SizedBox(height: 32),
        _buildGoalCard(tokens, 'DIET', '다이어트', '체중 감량을 위한 식단', Icons.spa_outlined),
        const SizedBox(height: 12),
        _buildGoalCard(tokens, 'MAINTAIN', '유지', '현재 건강 상태 유지', Icons.balance),
        const SizedBox(height: 12),
        _buildGoalCard(tokens, 'BULK', '벌크업', '근육량 및 체격 증가', Icons.fitness_center),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGoalCard(AppColorTokens tokens, String value, String title, String subtitle, IconData icon) {
    final isSelected = _goal == value;
    return GestureDetector(
      onTap: () => setState(() => _goal = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? tokens.primaryBg : tokens.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? tokens.primary : tokens.textMuted.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isSelected ? tokens.primary.withValues(alpha: 0.1) : tokens.textMuted.withValues(alpha: 0.05), shape: BoxShape.circle),
              child: Icon(icon, color: isSelected ? tokens.primary : tokens.textSub, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isSelected ? tokens.primary : tokens.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: isSelected ? tokens.primary.withValues(alpha: 0.7) : tokens.textSub)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: tokens.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterStep(AppColorTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('내 먹찌 탄생', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tokens.textPrimary)),
        const SizedBox(height: 8),
        Text('함께할 먹찌의 이름과 초기 모습을 정해주세요.', style: TextStyle(fontSize: 14, color: tokens.textSub)),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(color: tokens.primaryBg, shape: BoxShape.circle, border: Border.all(color: tokens.primary.withValues(alpha: 0.2), width: 2)),
                child: Icon(Icons.face_retouching_natural, size: 70, color: tokens.primary),
              ),
              const SizedBox(height: 24),
              _buildNameField(tokens),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildCustomizer(tokens, '체형', _bodyType, (v) => setState(() => _bodyType = v)),
        _buildCustomizer(tokens, '근육량', _muscle, (v) => setState(() => _muscle = v)),
        _buildCustomizer(tokens, '피부색', _skinTone, (v) => setState(() => _skinTone = v)),
        _buildCustomizer(tokens, '표정', _expression, (v) => setState(() => _expression = v)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildNameField(AppColorTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.textMuted.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _mukzziNameController,
        style: TextStyle(color: tokens.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: '먹찌 이름 입력',
          hintStyle: TextStyle(color: tokens.textMuted),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCustomizer(AppColorTokens tokens, String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.w500)),
              Text('Lv.$value', style: TextStyle(color: tokens.textSub, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(6, (index) {
              final isSelected = index == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(index),
                  child: Container(
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? tokens.primary : tokens.card,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isSelected ? tokens.primary : tokens.textMuted.withValues(alpha: 0.1)),
                    ),
                    child: Center(
                      child: Text('$index', style: TextStyle(color: isSelected ? Colors.white : tokens.textSub, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
