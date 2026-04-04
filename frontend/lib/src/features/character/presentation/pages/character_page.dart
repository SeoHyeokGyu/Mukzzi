import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/bento_card.dart';

class CharacterPage extends StatefulWidget {
  const CharacterPage({super.key});

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> {
  String _selectedAppearance = 'current';

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('먹찌')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 현재 캐릭터 섹션
            BentoCard(
              child: Column(
                children: [
                  // 캐릭터 이미지
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('먹찌 애니메이션 (Rive)'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 캐릭터 이름
                  Text(
                    '우리 먹찌',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // 진화 단계
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.softPeach,
                          const Color(0xFFFFE4D0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '부화 단계 (EGG)',
                      style: TextStyle(color: AppColors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 파츠 정보
            Text(
              '파츠 조합',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _PartCard(
                  icon: '🍖',
                  label: '체형',
                  value: '보통',
                ),
                _PartCard(
                  icon: '💪',
                  label: '근육',
                  value: '보통',
                ),
                _PartCard(
                  icon: '🌤',
                  label: '피부색',
                  value: '건강',
                ),
                _PartCard(
                  icon: '😊',
                  label: '표정',
                  value: '기분좋음',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 장착 아이템
            Text(
              '장착 중',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            BentoCard(
              child: Column(
                children: [
                  _EquipmentItem(
                    label: '배경',
                    value: '빈 방',
                    onTap: () {},
                  ),
                  const Divider(),
                  _EquipmentItem(
                    label: '악세서리',
                    value: '없음',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 도감
            Text(
              '달성한 외형',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('외형이 변경되었습니다')),
                    );
                  },
                  child: BentoCard(
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Text(
                        '외형\n${index + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PartCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _PartCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _EquipmentItem({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
