import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/user_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('준비 중입니다')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final userState = ref.watch(userProvider);
    final ns = userState.user?.notificationSettings ?? const {'meal': true, 'social': true, 'badge': true};
    final isAdmin = userState.user?.isAdmin ?? false;

    return GradientScaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 테마
          const _SectionLabel(label: '테마'),
          const SizedBox(height: 10),
          const _ThemeToggle(),
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
                  value: '미설정',
                  onTap: () => _showComingSoon(context),
                ),
                const _Divider(),
                _SettingsItem(
                  icon: Icons.egg_alt_outlined,
                  label: '단백질 목표',
                  value: '미설정',
                  onTap: () => _showComingSoon(context),
                ),
                const _Divider(),
                _SettingsItem(
                  icon: Icons.grain_outlined,
                  label: '탄수화물 목표',
                  value: '미설정',
                  onTap: () => _showComingSoon(context),
                ),
                const _Divider(),
                _SettingsItem(
                  icon: Icons.opacity_outlined,
                  label: '지방 목표',
                  value: '미설정',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 알림
          const _SectionLabel(label: '알림'),
          const SizedBox(height: 10),
          BentoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ToggleItem(
                  icon: Icons.restaurant_outlined,
                  label: '식사 알림',
                  value: ns['meal'] ?? true,
                  onChanged: (v) {
                    final updated = Map<String, bool>.from(ns)..['meal'] = v;
                    ref.read(userProvider.notifier).updateNotificationSettings(updated);
                  },
                ),
                const _Divider(),
                _ToggleItem(
                  icon: Icons.people_outlined,
                  label: '소셜 알림',
                  value: ns['social'] ?? true,
                  onChanged: (v) {
                    final updated = Map<String, bool>.from(ns)..['social'] = v;
                    ref.read(userProvider.notifier).updateNotificationSettings(updated);
                  },
                ),
                const _Divider(),
                _ToggleItem(
                  icon: Icons.military_tech_outlined,
                  label: '뱃지 획득 알림',
                  value: ns['badge'] ?? true,
                  onChanged: (v) {
                    final updated = Map<String, bool>.from(ns)..['badge'] = v;
                    ref.read(userProvider.notifier).updateNotificationSettings(updated);
                  },
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
                  icon: Icons.logout,
                  label: '로그아웃',
                  onTap: () => _showLogoutDialog(context, ref, tokens),
                ),
                const _Divider(),
                _SettingsItem(
                  icon: Icons.person_remove_outlined,
                  label: '회원 탈퇴',
                  valueColor: Colors.red.withValues(alpha: 0.7),
                  onTap: () => _showDeleteAccountDialog(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 앱 정보
          const _SectionLabel(label: '앱 정보'),
          const SizedBox(height: 10),
          BentoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  label: '개인정보처리방침',
                  onTap: () => context.push('/profile/settings/privacy'),
                ),
                const _Divider(),
                _SettingsItem(
                  icon: Icons.description_outlined,
                  label: '이용약관',
                  onTap: () => context.push('/profile/settings/terms'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── 관리자 섹션 (관리자 계정에만 노출) ──
          if (isAdmin) ...[
            const _SectionLabel(label: '관리자'),
            const SizedBox(height: 10),
            BentoCard(
              padding: EdgeInsets.zero,
              child: _SettingsItem(
                icon: Icons.admin_panel_settings_outlined,
                label: '스케줄 및 데이터 관리',
                onTap: () => context.push('/profile/settings/admin'),
              ),
            ),
            const SizedBox(height: 20),
          ],

          Center(
            child: Text(
              'v${AppConstants.appVersion}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).extension<AppColorTokens>()!.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref, AppColorTokens tokens) {
    showDialog(
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
              GoRouter.of(context).go('/auth');
            },
            child: Text(
              '로그아웃',
              style: TextStyle(color: tokens.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _DeleteAccountDialog(ref: ref),
    );
  }
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _DeleteAccountDialog({required this.ref});

  @override
  ConsumerState<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('회원 탈퇴'),
      content: const Text('정말로 탈퇴하시겠습니까?\n모든 기록이 삭제되며 복구할 수 없습니다.'),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () async {
            setState(() => _isLoading = true);
            final success = await ref.read(userProvider.notifier).deleteAccount();
            if (!mounted) return;
            if (success) {
              if (context.mounted) Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) GoRouter.of(context).go('/auth');
            } else {
              setState(() => _isLoading = false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('탈퇴 처리 중 오류가 발생했습니다')),
                );
              }
            }
          },
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('탈퇴하기', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final themeMode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);

    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 20, color: tokens.textSub),
              const SizedBox(width: 14),
              Expanded(
                child: Text('테마 설정', style: TextStyle(fontSize: 15, color: tokens.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('라이트'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('다크'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('시스템'),
                  icon: Icon(Icons.settings_suggest_outlined),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (sel) => notifier.setThemeMode(sel.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                textStyle: WidgetStatePropertyAll(
                  TextStyle(fontSize: 13, color: tokens.textPrimary),
                ),
              ),
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
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: tokens.textSub,
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
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: valueColor ?? tokens.textSub),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 15, color: valueColor ?? tokens.textPrimary),
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: TextStyle(fontSize: 14, color: tokens.textSub),
                ),
              if (value == null)
                Icon(Icons.arrow_forward_ios, size: 14, color: tokens.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: tokens.textSub),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: tokens.textPrimary),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected) ? tokens.primary : null,
            ),
            trackColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected) ? tokens.primaryBg : null,
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
    return const Divider(height: 1, indent: 54);
  }
}