import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../providers/user_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../character/presentation/providers/title_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // build() 밖에서 한 번만 호출 — 동시 다발적 중복 호출 방지
    Future.microtask(() {
      if (!mounted) return;
      final userState = ref.read(userProvider);
      if (userState.user == null && !userState.isLoading) {
        ref.read(userProvider.notifier).fetchMe();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final userState = ref.watch(userProvider);

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
              ? _buildErrorState(context, tokens, userState.error!)
              : _ProfileBody(userState: userState, tokens: tokens),
    );
  }

  Widget _buildErrorState(BuildContext context, AppColorTokens tokens, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: tokens.primary),
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

class _ProfileBody extends ConsumerWidget {
  final UserState userState;
  final AppColorTokens tokens;

  const _ProfileBody({required this.userState, required this.tokens});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final ns = userState.user?.notificationSettings ?? const {'meal': true, 'social': true, 'badge': true};
    final allOn = ns['meal'] == true && ns['social'] == true && ns['badge'] == true;
    final notifDetail = allOn ? '켜짐' : '일부 꺼짐';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProfileHeader(
          nickname: userState.user?.nickname ?? '먹찌 유저',
          username: userState.user?.username ?? '',
          onEditTap: () => context.push('/profile/edit'),
          tokens: tokens,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: statsAsync.when(
                data: (s) => _StatTile(label: '총 식사', value: s.totalMeals.toString(), sub: '회', tokens: tokens),
                loading: () => _StatTile(label: '총 식사', value: '–', sub: '회', tokens: tokens),
                error: (_, __) => _StatTile(label: '총 식사', value: '–', sub: '회', tokens: tokens),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: statsAsync.when(
                data: (s) => _StatTile(label: '연속 기록', value: s.streakDays.toString(), sub: '일', tokens: tokens),
                loading: () => _StatTile(label: '연속 기록', value: '–', sub: '일', tokens: tokens),
                error: (_, __) => _StatTile(label: '연속 기록', value: '–', sub: '일', tokens: tokens),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: statsAsync.when(
                data: (s) => _StatTile(label: '뱃지', value: s.badgeCount.toString(), sub: '개', tokens: tokens),
                loading: () => _StatTile(label: '뱃지', value: '–', sub: '개', tokens: tokens),
                error: (_, __) => _StatTile(label: '뱃지', value: '–', sub: '개', tokens: tokens),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: '계정', tokens: tokens),
        const SizedBox(height: 8),
        BentoCard(
          borderRadius: BorderRadius.circular(tokens.rCard),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _MenuItem(
                icon: Icons.person_outline,
                label: '프로필 편집',
                onTap: () => context.push('/profile/edit'),
                tokens: tokens,
              ),
              _Divider(tokens: tokens),
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: '알림 설정',
                detail: notifDetail,
                onTap: () => context.push('/profile/settings'),
                tokens: tokens,
              ),
              _Divider(tokens: tokens),
              _MenuItem(
                icon: Icons.emoji_events_outlined,
                label: '나의 기록',
                onTap: () => context.push('/profile/badges'),
                tokens: tokens,
              ),
              _Divider(tokens: tokens),
              _MenuItem(
                icon: Icons.bar_chart_outlined,
                label: '통계 리포트',
                onTap: () => ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('준비 중입니다'))),
                tokens: tokens,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: '앱', tokens: tokens),
        const SizedBox(height: 8),
        BentoCard(
          borderRadius: BorderRadius.circular(tokens.rCard),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _MenuItem(
                icon: Icons.settings_outlined,
                label: '환경설정',
                onTap: () => context.push('/profile/settings'),
                tokens: tokens,
                secondary: true,
              ),
              _Divider(tokens: tokens),
              _MenuItem(
                icon: Icons.people_outline,
                label: '친구 초대',
                onTap: () => ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('준비 중입니다'))),
                tokens: tokens,
                secondary: true,
              ),
              _Divider(tokens: tokens),
              _MenuItem(
                icon: Icons.logout,
                label: '로그아웃',
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text('로그아웃 하시겠어요?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(authProvider.notifier).logout();
                          context.go('/auth');
                        },
                        child: Text('로그아웃', style: TextStyle(color: tokens.primary)),
                      ),
                    ],
                  ),
                ),
                tokens: tokens,
                secondary: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final String nickname;
  final String username;
  final VoidCallback onEditTap;
  final AppColorTokens tokens;

  const _ProfileHeader({
    required this.nickname,
    required this.username,
    required this.onEditTap,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = nickname.isNotEmpty ? nickname[0] : '?';
    final equippedTitle = ref.watch(equippedTitleProvider).maybeWhen(
      data: (t) => t?.name,
      orElse: () => null,
    );

    return BentoCard(
      borderRadius: BorderRadius.circular(tokens.rCard),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: tokens.primaryBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: tokens.primary,
                ),
              ),
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
                        color: tokens.textPrimary,
                      ),
                ),
                if (equippedTitle != null) ...[
                  const SizedBox(height: 3),
                  _Badge(label: equippedTitle, color: tokens.primary, tokens: tokens),
                ],
                const SizedBox(height: 2),
                Text(
                  username,
                  style: TextStyle(fontSize: 12, color: tokens.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '프로필 편집',
            onPressed: onEditTap,
            icon: Icon(Icons.edit_outlined, size: 20, color: tokens.textMuted),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final AppColorTokens tokens;

  const _StatTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      borderRadius: BorderRadius.circular(tokens.rCard),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
                ),
              ),
              TextSpan(
                text: ' $sub',
                style: TextStyle(fontSize: 11, color: tokens.textMuted),
              ),
            ]),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: tokens.textSub)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final AppColorTokens tokens;

  const _SectionLabel({required this.label, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: tokens.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback onTap;
  final AppColorTokens tokens;
  final bool secondary;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tokens,
    this.detail,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: secondary ? tokens.listItemBg : tokens.primaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: secondary ? tokens.textSub : tokens.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: tokens.textPrimary)),
              ),
              if (detail != null) ...[
                Text(detail!, style: TextStyle(fontSize: 12, color: tokens.textMuted)),
                const SizedBox(width: 4),
              ],
              Icon(Icons.arrow_forward_ios, size: 14, color: tokens.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final AppColorTokens tokens;
  const _Divider({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 60,
      color: tokens.primary.withValues(alpha: 0.08),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final AppColorTokens tokens;

  const _Badge({
    required this.label,
    required this.color,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
