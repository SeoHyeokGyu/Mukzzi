import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/user_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('준비 중입니다')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    // 유저 정보가 없으면 가져오기
    if (userState.user == null && !userState.isLoading && userState.error == null) {
      Future.microtask(() => ref.read(userProvider.notifier).fetchMe());
    }

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: userState.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : userState.error != null && userState.user == null
          ? _buildErrorState(ref, userState.error!)
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 프로필 헤더
          _ProfileHeader(
            username: userState.user?.username ?? '먹찌 유저',
            nickname: userState.user?.nickname ?? '부화 단계',
            onEditTap: () => context.push('/home/profile/edit'),
          ),
          const SizedBox(height: 20),

          // 컬렉션
          const _SectionLabel(label: '컬렉션'),
          const SizedBox(height: 10),
          BentoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsItem(
                  icon: Icons.military_tech,
                  label: '뱃지',
                  onTap: () => context.push('/home/profile/badges'),
                ),
                const _Divider(),
                _SettingsItem(
                  icon: Icons.workspace_premium,
                  label: '칭호',
                  onTap: () => context.push('/home/profile/titles'),
                ),
                const _Divider(),
                _SettingsItem(
                  icon: Icons.card_giftcard,
                  label: '보상 아이템',
                  onTap: () => context.push('/home/profile/rewards'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 식사 목표
          const _SectionLabel(label: '식사 목표'),
          const SizedBox(height: 10),
          BentoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsItem(
                  icon: Icons.local_fire_department_outlined,
                  label: '일일 칼로리 목표',
                  value: '2,000 kcal',
                  onTap: () => _showComingSoon(context),
                ),
                const _Divider(),
                _SettingsItem(
                  icon: Icons.egg_alt_outlined,
                  label: '단백질 목표',
                  value: '60 g',
                  onTap: () => _showComingSoon(context),
                ),
                const _Divider(),
                _SettingsItem(
                  icon: Icons.grain_outlined,
                  label: '탄수화물 목표',
                  value: '300 g',
                  onTap: () => _showComingSoon(context),
                ),
                const _Divider(),
                _SettingsItem(
                  icon: Icons.opacity_outlined,
                  label: '지방 목표',
                  value: '60 g',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 알림 설정
          const _SectionLabel(label: '알림'),
          const SizedBox(height: 10),
          const BentoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
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
          const _SectionLabel(label: '계정'),
          const SizedBox(height: 10),
          BentoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsItem(
                  icon: Icons.person_outline,
                  label: '프로필 설정',
                  onTap: () => context.push('/home/profile/edit'),
                ),
                const _Divider(),
                _SettingsItem(
                  icon: Icons.logout,
                  label: '로그아웃',
                  valueColor: AppColors.orange,
                  onTap: () => _showLogoutDialog(context, ref),
                ),
                const _Divider(),
                _SettingsItem(
                  icon: Icons.person_remove_outlined,
                  label: '회원 탈퇴',
                  valueColor: AppColors.textTertiary,
                  onTap: () => _showDeleteAccountDialog(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('정말로 탈퇴하시겠습니까?\n모든 기록이 삭제되며 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final user = ref.read(userProvider).user;
              if (user != null) {
                final success = await ref.read(userProvider.notifier).deleteAccount();
                if (success && context.mounted) {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    GoRouter.of(context).go('/auth');
                  }
                }
              }
            },
            child: const Text(
              '탈퇴하기',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
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
              ref.read(authProvider.notifier).logout();
              GoRouter.of(context).go('/auth');
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

  Widget _buildErrorState(WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(userProvider.notifier).fetchMe(),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String username;
  final String nickname;
  final VoidCallback onEditTap;

  const _ProfileHeader({
    required this.username,
    required this.nickname,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.softPeach,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.egg_outlined,
              size: 34,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEditTap,
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
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.orange
                  : null,
            ),
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.softPeach
                  : null,
            ),
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
