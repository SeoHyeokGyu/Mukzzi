import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/menu_search_field.dart';

class MealRecordPage extends StatefulWidget {
  const MealRecordPage({super.key});

  @override
  State<MealRecordPage> createState() => _MealRecordPageState();
}

class _MealRecordPageState extends State<MealRecordPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _menuController;
  String _selectedMealType = 'BREAKFAST';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _menuController = TextEditingController();
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
            onMealTypeChanged: (value) {
              setState(() => _selectedMealType = value!);
            },
          ),
          const _MealListTab(),
        ],
      ),
    );
  }
}

class _MealInputTab extends StatefulWidget {
  final TextEditingController menuController;
  final String selectedMealType;
  final Function(String?) onMealTypeChanged;

  const _MealInputTab({
    required this.menuController,
    required this.selectedMealType,
    required this.onMealTypeChanged,
  });

  @override
  State<_MealInputTab> createState() => _MealInputTabState();
}

class _MealInputTabState extends State<_MealInputTab> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double _servingSize = 1.0;
  String? _selectedWeather;
  String? _selectedMood;

  /// 시간대에 맞는 식사 종류 반환
  /// - 아침: 06:00 ~ 10:59
  /// - 점심: 12:00 ~ 13:59
  /// - 저녁: 18:00 ~ 21:59
  /// - 간식: 나머지
  String _expectedMealType(TimeOfDay time) {
    final h = time.hour;
    if (h >= 6 && h <= 10) return 'BREAKFAST';
    if (h >= 12 && h <= 13) return 'LUNCH';
    if (h >= 18 && h <= 21) return 'DINNER';
    return 'SNACK';
  }

  String? _getMealTypeMismatchWarning() {
    final expected = _expectedMealType(_selectedTime);
    if (expected == widget.selectedMealType) return null;

    const labels = {
      'BREAKFAST': '아침 (06:00~10:59)',
      'LUNCH': '점심 (12:00~13:59)',
      'DINNER': '저녁 (18:00~21:59)',
      'SNACK': '간식',
    };
    return '선택한 시간은 ${labels[expected]} 시간대예요';
  }

  @override
  Widget build(BuildContext context) {
    final warning = _getMealTypeMismatchWarning();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메뉴 검색
          Text('메뉴명', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          MenuSearchField(
            controller: widget.menuController,
            onMenuSelected: (menu) {
              // TODO: Handle menu selection
            },
          ),
          const SizedBox(height: 24),

          // 식사 타입
          Text('식사 종류', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 15),
              selectedBackgroundColor: AppColors.orange,
              selectedForegroundColor: Colors.white,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.comfortable,
            ),
            segments: const [
              ButtonSegment(label: Text('아침'), value: 'BREAKFAST'),
              ButtonSegment(label: Text('점심'), value: 'LUNCH'),
              ButtonSegment(label: Text('저녁'), value: 'DINNER'),
              ButtonSegment(label: Text('간식'), value: 'SNACK'),
            ],
            selected: {widget.selectedMealType},
            onSelectionChanged: (newSelection) {
              widget.onMealTypeChanged(newSelection.first);
            },
          ),
          const SizedBox(height: 24),

          // 날짜/시간 선택
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
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
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
                    '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ],
          ),
          if (warning != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  warning,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),

          // 인분 선택
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('인분', style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${_servingSize.toStringAsFixed(1)}인분',
                style: const TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: _servingSize,
            min: 0.5,
            max: 3.0,
            divisions: 5,
            label: '${_servingSize.toStringAsFixed(1)}인분',
            onChanged: (value) => setState(() => _servingSize = value),
          ),
          const SizedBox(height: 24),

          // 날씨/기분
          Row(
            children: [
              Text('날씨 / 기분', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              const Text(
                '선택사항',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('날씨', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    DropdownMenu<String>(
                      initialSelection: _selectedWeather,
                      expandedInsets: EdgeInsets.zero,
                      hintText: '선택',
                      onSelected: (value) =>
                          setState(() => _selectedWeather = value),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'SUNNY', label: '맑음'),
                        DropdownMenuEntry(value: 'CLOUDY', label: '흐림'),
                        DropdownMenuEntry(value: 'RAINY', label: '비'),
                        DropdownMenuEntry(value: 'SNOWY', label: '눈'),
                        DropdownMenuEntry(value: 'WINDY', label: '바람'),
                        DropdownMenuEntry(value: 'HOT', label: '더움'),
                        DropdownMenuEntry(value: 'COLD', label: '추움'),
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
                    Text('기분', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    DropdownMenu<String>(
                      initialSelection: _selectedMood,
                      expandedInsets: EdgeInsets.zero,
                      hintText: '선택',
                      onSelected: (value) =>
                          setState(() => _selectedMood = value),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'GOOD', label: '좋음'),
                        DropdownMenuEntry(value: 'TIRED', label: '피곤'),
                        DropdownMenuEntry(value: 'STRESSED', label: '스트레스'),
                        DropdownMenuEntry(value: 'HUNGRY', label: '배고픔'),
                        DropdownMenuEntry(value: 'EXCITED', label: '설렘'),
                        DropdownMenuEntry(value: 'SAD', label: '우울'),
                        DropdownMenuEntry(value: 'NORMAL', label: '보통'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 저장 버튼
          AppGradientButton(
            label: '기록 저장',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('식사 기록이 저장되었습니다')),
              );
              widget.menuController.clear();
            },
          ),
        ],
      ),
    );
  }
}

class _MealListTab extends StatelessWidget {
  const _MealListTab();

  static const int _itemCount = 10;

  @override
  Widget build(BuildContext context) {
    if (_itemCount == 0) {
      return const _EmptyState(
        icon: Icons.restaurant_outlined,
        message: '아직 기록된 식사가 없어요',
        sub: '첫 번째 식사를 기록해보세요',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BentoCard(
            child: ListTile(
              leading: _getMealIcon(),
              title: Text(_getMealName(index)),
              subtitle: Text(
                _formatDate(DateTime.now().subtract(Duration(days: index))),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${(index + 1) * 320}kcal'),
                  const SizedBox(height: 4),
                  Text(
                    'Lv.${(index % 3) + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(_getMealName(index)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('칼로리: ${(index + 1) * 320}kcal'),
                        const SizedBox(height: 8),
                        Text('인분: ${(index % 3) + 1}인분'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('수정'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('삭제'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('닫기'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  Widget _getMealIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.softPeach,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.restaurant, color: AppColors.orange, size: 22),
    );
  }

  String _getMealName(int index) {
    const names = ['김치찌개', '부대찌개', '도시락', '카레', '파에야', '스튜', '국밥', '한정식', '카레', '해물탕'];
    return names[index % names.length];
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}