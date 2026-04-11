import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../character/domain/models/badge_model.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 프로필 헤더
          _ProfileHeader(),
          const SizedBox(height: 20),

          // 뱃지
          _SectionLabel(label: '뱃지'),
          const SizedBox(height: 10),
          _BadgeEntry(onTap: () => context.push('/profile/badges')),
          const SizedBox(height: 20),

          // 식사 목표
          _SectionLabel(label: '식사 목표'),
          const SizedBox(height: 10),
          BentoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsItem(
                  icon: Icons.local_fire_department_outlined,
                  label: '일일 칼로리 목표',
                  value: '2,000 kcal',
                  onTap: () {},
                ),
                const _Divider(),
                _SettingsItem(
                  icon: Icons.egg_alt_outlined,
                  label: '단백질 목표',
                  value: '60 g',
                  onTap: () {},
                ),
                const _Divider(),
                _SettingsItem(
                  icon: Icons.grain_outlined,
                  label: '탄수화물 목표',
                  value: '300 g',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 알림 설정
          _SectionLabel(label: '알림'),
          const SizedBox(height: 10),
          BentoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: const [
                _ToggleItem(
                  icon: Icons.restaurant_outlined,
                  label: '식사 알림',
                  initialValue: true,
                ),
                _Divider(),
                _ToggleItem(
                  icon: Icons.people_outlined,
                  label: '소셜 알림',
                  initialValue: true,
                ),
                _Divider(),
                _ToggleItem(
                  icon: Icons.military_tech_outlined,
                  label: '뱃지 획득 알림',
                  initialValue: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 계정
          _SectionLabel(label: '계정'),
          const SizedBox(height: 10),
          BentoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsItem(
                  icon: Icons.person_outline,
                  label: '닉네임 변경',
                  onTap: () {},
                ),
                const _Divider(),
                _SettingsItem(
                  icon: Icons.logout,
                  label: '로그아웃',
                  valueColor: AppColors.orange,
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/auth');
            },
            child: const Text(
              '로그아웃',
              style: TextStyle(color: AppColors.orange),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.softPeach,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 36,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '먹찌 유저',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '부화 단계 · 7일 연속 기록 중',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeEntry extends StatelessWidget {
  final VoidCallback onTap;

  const _BadgeEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unlockedCount = mockBadges.where((b) => b.isUnlocked).length;
    final totalCount = mockBadges.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.softPeach,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.military_tech,
                    size: 24,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '보유 뱃지',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$unlockedCount / $totalCount개 획득',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.value,
    this.valueColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? AppColors.textSecondary,
                  ),
                ),
              if (value == null)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool initialValue;

  const _ToggleItem({
    required this.icon,
    required this.label,
    required this.initialValue,
  });

  @override
  State<_ToggleItem> createState() => _ToggleItemState();
}

class _ToggleItemState extends State<_ToggleItem> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(widget.icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: _value,
            onChanged: (v) => setState(() => _value = v),
            activeColor: AppColors.orange,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 54,
      endIndent: 0,
    );
  }
}
