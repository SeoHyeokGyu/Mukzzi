import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:rive/rive.dart' hide LinearGradient; // mukzzi.riv 추가 시 활성화
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/bento_card.dart';

class CharacterPage extends StatelessWidget {
  const CharacterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('내 캐릭터')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 현재 캐릭터 섹션
            BentoCard(
              child: Column(
                children: [
                  // 캐릭터 애니메이션 영역
                  // assets/animations/mukzzi.riv 파일 추가 시 RiveAnimation.asset()으로 교체
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 250,
                      color: AppColors.softPeach,
                      child: const _CharacterPlaceholder(),
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
                      color: AppColors.softPeach,
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
              children: const [
                _PartCard(
                  icon: Icons.person_outline,
                  label: '체형',
                  value: '보통',
                ),
                _PartCard(
                  icon: Icons.fitness_center,
                  label: '근육',
                  value: '보통',
                ),
                _PartCard(
                  icon: Icons.palette_outlined,
                  label: '피부색',
                  value: '건강',
                ),
                _PartCard(
                  icon: Icons.sentiment_satisfied_outlined,
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

            // 메뉴 기록
            Text(
              '먹부림 기록',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            BentoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _EquipmentItem(
                    label: '마스터리 도감',
                    value: '',
                    onTap: () => context.push('/character/masteries'),
                  ),
                  const Divider(),
                  _EquipmentItem(
                    label: '먹찌 도감',
                    value: '',
                    onTap: () => context.push('/character/collection'),
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
                return Semantics(
                  label: '외형 ${index + 1} 선택',
                  button: true,
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('외형이 변경되었습니다')),
                      );
                    },
                    child: BentoCard(
                      borderRadius: BorderRadius.circular(12),
                      padding: EdgeInsets.zero,
                      child: Center(
                        child: Text(
                          '외형\n${index + 1}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
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
  final IconData icon;
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
          Icon(icon, size: 32, color: AppColors.orange),
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

// assets/animations/mukzzi.riv 파일 추가 전까지 사용하는 플레이스홀더
// 추후 RiveAnimation.asset('assets/animations/mukzzi.riv') 으로 교체
class _CharacterPlaceholder extends StatelessWidget {
  const _CharacterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.softPeach,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.egg_outlined, size: 52, color: AppColors.orange),
          ),
          const SizedBox(height: 16),
          const Text(
            '부화 중...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
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

