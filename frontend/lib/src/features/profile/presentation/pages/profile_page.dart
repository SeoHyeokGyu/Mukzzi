import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../providers/user_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    if (userState.user == null && !userState.isLoading && userState.error == null) {
      Future.microtask(() => ref.read(userProvider.notifier).fetchMe());
    }

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/profile/settings'),
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
                    _ProfileHeader(
                      username: userState.user?.username ?? '먹찌 유저',
                      nickname: userState.user?.nickname ?? '부화 단계',
                      onEditTap: () => context.push('/profile/edit'),
                      // TODO: (cjkang) 캐릭터 API 연동 후 실제 값으로 교체
                      streakDays: null,
                      totalMeals: null,
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel(label: '컬렉션'),
                    const SizedBox(height: 10),
                    BentoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _MenuItem(
                            icon: Icons.military_tech,
                            label: '뱃지',
                            onTap: () => context.push('/profile/badges'),
                          ),
                          const _Divider(),
                          _MenuItem(
                            icon: Icons.workspace_premium,
                            label: '칭호',
                            onTap: () => context.push('/profile/titles'),
                          ),
                          const _Divider(),
                          _MenuItem(
                            icon: Icons.card_giftcard,
                            label: '보상 아이템',
                            onTap: () => context.push('/profile/rewards'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
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
          Text(error, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
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
  final int? streakDays;
  final int? totalMeals;

  const _ProfileHeader({
    required this.username,
    required this.nickname,
    required this.onEditTap,
    this.streakDays,
    this.totalMeals,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.softPeach,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.egg_outlined, size: 34, color: AppColors.orange),
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
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '프로필 편집',
                onPressed: onEditTap,
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '연속 기록',
                  value: streakDays != null ? '$streakDays일' : '–',
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.divider),
              Expanded(
                child: _StatItem(
                  label: '누적 기록',
                  value: totalMeals != null ? '$totalMeals끼' : '–',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.orange,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, required this.onTap});

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
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 54);
  }
}
