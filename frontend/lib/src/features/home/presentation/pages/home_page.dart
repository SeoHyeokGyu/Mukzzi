import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('먹찌'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 캐릭터 섹션
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 캐릭터 이미지 자리
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('먹찌 (Coming Soon)'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 캐릭터 정보
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _CharacterStat(label: '레벨', value: '1'),
                        _CharacterStat(label: '경험치', value: '0/100'),
                        _CharacterStat(label: '상태', value: 'NORMAL'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 오늘의 식사 현황
            Text(
              '오늘의 식사 현황',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _MealProgress(
                      label: '칼로리',
                      current: 1200,
                      target: 2000,
                      unit: 'kcal',
                    ),
                    const SizedBox(height: 16),
                    _MealProgress(
                      label: '단백질',
                      current: 45,
                      target: 60,
                      unit: 'g',
                    ),
                    const SizedBox(height: 16),
                    _MealProgress(
                      label: '탄수화물',
                      current: 150,
                      target: 300,
                      unit: 'g',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 빠른 액션
            Text(
              '다음 단계',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('메뉴 선택'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('식사 기록'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 최근 식사
            Text(
              '최근 식사 기록',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.restaurant),
                    title: Text('식사 ${index + 1}'),
                    subtitle: const Text('오늘 12:30'),
                    trailing: const Text('320kcal'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              // 홈은 현재 페이지이므로 그냥 유지
              break;
            case 1:
              context.pushNamed('meal-record');
              break;
            case 2:
              context.pushNamed('character');
              break;
            case 3:
              context.pushNamed('social');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: '식사'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: '먹찌'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: '소셜'),
        ],
      ),
    );
  }
}

class _CharacterStat extends StatelessWidget {
  final String label;
  final String value;

  const _CharacterStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _MealProgress extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final String unit;

  const _MealProgress({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (current / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$current / $target $unit'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      ],
    );
  }
}
