import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/app_button.dart';

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
          // 기록 추가 탭
          _MealInputTab(
            menuController: _menuController,
            selectedMealType: _selectedMealType,
            onMealTypeChanged: (value) {
              setState(() => _selectedMealType = value!);
            },
          ),
          // 기록 목록 탭
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜/시간 선택
          Text(
            '식사 시간',
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Text(
                    '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
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
                    if (picked != null) {
                      setState(() => _selectedTime = picked);
                    }
                  },
                  child: Text(
                      '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 식사 타입
          Text(
            '식사 종류',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
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

          // 메뉴 입력
          Text(
            '메뉴명',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.menuController,
            decoration: InputDecoration(
              hintText: '예: 김치찌개',
              prefixIcon: const Icon(Icons.restaurant_menu),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 인분 선택
          Text(
            '인분 (${_servingSize.toStringAsFixed(1)}인분)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Slider(
            value: _servingSize,
            min: 0.5,
            max: 3.0,
            divisions: 5,
            label: '${_servingSize.toStringAsFixed(1)}인분',
            onChanged: (value) {
              setState(() => _servingSize = value);
            },
          ),
          const SizedBox(height: 24),

          // 날씨/기분
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('날씨', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedWeather,
                      items: const [
                        DropdownMenuItem(value: 'SUNNY', child: Text('☀️ 맑음')),
                        DropdownMenuItem(value: 'CLOUDY', child: Text('☁️ 흐림')),
                        DropdownMenuItem(value: 'RAINY', child: Text('🌧️ 비')),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedWeather = value),
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
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedMood,
                      items: const [
                        DropdownMenuItem(value: 'HAPPY', child: Text('😊 좋음')),
                        DropdownMenuItem(value: 'TIRED', child: Text('😴 피곤')),
                        DropdownMenuItem(
                            value: 'STRESSED', child: Text('😤 스트레스')),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedMood = value),
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

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BentoCard(
            child: ListTile(
              leading: _getMealIcon(index),
              title: Text(_getMealName(index)),
              subtitle: Text(
                  '${DateTime.now().subtract(Duration(days: index)).toString().split('.')[0]}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${(index + 1) * 320}kcal'),
                  const SizedBox(height: 4),
                  Text(
                    'Lv.${(index % 3) + 1}',
                    style: const TextStyle(fontSize: 12, color: AppColors.orange),
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

  Widget _getMealIcon(int index) {
    final icons = ['🍜', '🍲', '🍱', '🍛', '🥘', '🍲', '🍜', '🍱', '🍛', '🥘'];
    return Text(icons[index % icons.length], style: const TextStyle(fontSize: 28));
  }

  String _getMealName(int index) {
    final names = ['김치찌개', '부대찌개', '도시락', '카레', '파에야', '스튜', '국밥', '한정식', '카레', '해물탕'];
    return names[index % names.length];
  }
}
