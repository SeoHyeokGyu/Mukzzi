import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../providers/admin_provider.dart';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  @override
  void initState() {
    super.initState();
    // 페이지 진입 시 스케줄 목록 로드
    Future.microtask(() => ref.read(adminProvider.notifier).loadSchedules());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final state = ref.watch(adminProvider);

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('관리자'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: state.isLoading
                ? null
                : () => ref.read(adminProvider.notifier).loadSchedules(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminProvider.notifier).loadSchedules(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── 영양소 데이터 수집 ──
            _SectionLabel(label: '영양소 데이터 수집', tokens: tokens),
            const SizedBox(height: 10),
            _SeedStatusCard(tokens: tokens),
            const SizedBox(height: 20),

            // ── 스케줄 관리 ──
            _SectionLabel(label: '스케줄 관리', tokens: tokens),
            const SizedBox(height: 10),
            if (state.isLoading && state.schedules.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.error != null && state.schedules.isEmpty)
              _ErrorCard(message: state.error!, tokens: tokens)
            else
              _ScheduleList(schedules: state.schedules, tokens: tokens),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 영양소 수집 카드
// ─────────────────────────────────────────

class _SeedStatusCard extends ConsumerWidget {
  final AppColorTokens tokens;
  const _SeedStatusCard({required this.tokens});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminProvider);
    final seedStatus = state.seedStatus;

    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_download_outlined, size: 20, color: tokens.textSub),
              const SizedBox(width: 10),
              Text(
                '식약처/USDA 영양소 수집',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
              const Spacer(),
              if (seedStatus != null) _SeedStateBadge(state: seedStatus.state),
            ],
          ),

          if (seedStatus != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _InfoRow(
              label: '마지막 수집',
              value: seedStatus.startedAt != null
                  ? _formatDateTime(seedStatus.startedAt!)
                  : '기록 없음',
              tokens: tokens,
            ),
            if (seedStatus.endedAt != null)
              _InfoRow(
                label: '완료 시각',
                value: _formatDateTime(seedStatus.endedAt!),
                tokens: tokens,
              ),
            if (seedStatus.state == 'DONE' || seedStatus.state == 'FAILED') ...[
              _InfoRow(
                label: '추가된 항목',
                value: '${seedStatus.inserted}건',
                tokens: tokens,
              ),
              _InfoRow(
                label: '스킵',
                value: '${seedStatus.skipped}건',
                tokens: tokens,
              ),
            ],
            if (seedStatus.error != null && seedStatus.error!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  seedStatus.error!,
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
          ],

          const SizedBox(height: 16),

          // 즉시 수집 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (state.isSeeding || seedStatus?.state == 'RUNNING')
                  ? null
                  : () => _showSeedDialog(context, ref),
              icon: state.isSeeding
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.play_arrow_outlined, size: 18),
              label: Text(state.isSeeding ? '수집 중...' : '지금 수집 실행'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showSeedDialog(BuildContext context, WidgetRef ref) {
    String source = 'all';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('영양소 데이터 수집'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('수집 소스를 선택하세요.', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('전체')),
                  ButtonSegment(value: 'mfds', label: Text('식약처')),
                  ButtonSegment(value: 'usda', label: Text('USDA')),
                ],
                selected: {source},
                onSelectionChanged: (sel) => setState(() => source = sel.first),
                showSelectedIcon: false,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(adminProvider.notifier).runSeedNow(source: source);
              },
              child: const Text('수집 시작'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 스케줄 목록
// ─────────────────────────────────────────

class _ScheduleList extends ConsumerWidget {
  final List<ScheduleStatus> schedules;
  final AppColorTokens tokens;

  const _ScheduleList({required this.schedules, required this.tokens});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (schedules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('등록된 스케줄이 없습니다.', style: TextStyle(color: tokens.textMuted)),
        ),
      );
    }

    return BentoCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(schedules.length, (i) {
          final schedule = schedules[i];
          return Column(
            children: [
              _ScheduleItem(
                schedule: schedule,
                tokens: tokens,
                onToggle: (enabled) => ref
                    .read(adminProvider.notifier)
                    .toggleSchedule(schedule.key, enabled),
                onRunNow: () => _confirmRunNow(context, ref, schedule),
              ),
              if (i < schedules.length - 1) const Divider(height: 1, indent: 16),
            ],
          );
        }),
      ),
    );
  }

  void _confirmRunNow(BuildContext context, WidgetRef ref, ScheduleStatus schedule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('즉시 실행'),
        content: Text('"${schedule.name}"을(를) 지금 바로 실행할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(adminProvider.notifier).runScheduleNow(schedule.key);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${schedule.name} 실행을 요청했습니다.')),
              );
            },
            child: const Text('실행'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  final ScheduleStatus schedule;
  final AppColorTokens tokens;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRunNow;

  const _ScheduleItem({
    required this.schedule,
    required this.tokens,
    required this.onToggle,
    required this.onRunNow,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: schedule.enabled
                            ? tokens.textPrimary
                            : tokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schedule.spec,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // 즉시 실행 버튼
              IconButton(
                icon: Icon(Icons.play_circle_outline, color: tokens.primary, size: 22),
                tooltip: '즉시 실행',
                onPressed: onRunNow,
                visualDensity: VisualDensity.compact,
              ),
              // 토글 스위치
              Switch(
                value: schedule.enabled,
                onChanged: onToggle,
                thumbColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                      ? tokens.primary
                      : null,
                ),
                trackColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                      ? tokens.primaryBg
                      : null,
                ),
              ),
            ],
          ),
          if (schedule.nextRun != null && schedule.enabled) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 12, color: tokens.textMuted),
                const SizedBox(width: 4),
                Text(
                  '다음 실행: ${_formatDateTime(schedule.nextRun!)}',
                  style: TextStyle(fontSize: 12, color: tokens.textMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────
// 공통 위젯
// ─────────────────────────────────────────

class _SeedStateBadge extends StatelessWidget {
  final String state;
  const _SeedStateBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      'RUNNING' => ('수집 중', Colors.blue),
      'DONE' => ('완료', Colors.green),
      'FAILED' => ('실패', Colors.red),
      _ => ('대기', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final AppColorTokens tokens;

  const _InfoRow({required this.label, required this.value, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: tokens.textMuted)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, color: tokens.textSub)),
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
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: tokens.textSub,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final AppColorTokens tokens;

  const _ErrorCard({required this.message, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}