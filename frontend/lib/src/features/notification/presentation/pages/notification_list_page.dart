import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/gradient_scaffold.dart';
import 'package:mukzzi/src/core/widgets/collection_states.dart';
import 'package:mukzzi/src/features/notification/presentation/providers/notification_provider.dart';
import 'package:mukzzi/src/features/notification/data/models/notification_model.dart';

class NotificationListPage extends ConsumerWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: state.unreadCount > 0
                ? Padding(
                    key: const ValueKey('mark-all-read'),
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton(
                      onPressed: () => notifier.markAllAsRead(),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context)
                            .extension<AppColorTokens>()!
                            .primary,
                      ),
                      child: const Text(
                        '전체 읽음',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('mark-all-empty')),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.fetchNotifications(),
        child: state.isLoading && state.notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.notifications.isEmpty
                ? const CollectionEmptyState(
                    icon: Icons.notifications_none_outlined,
                    title: '알림이 없어요',
                    subtitle: '새로운 소식이 오면 알려드릴게요',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final n = state.notifications[index];
                      return _NotificationItem(
                        notification: n,
                        onTap: () {
                          // 1. 읽음 처리
                          if (!n.isRead) notifier.markAsRead(n.id);

                          // 2. 관련 페이지로 이동 (Navigator 키 충돌 방지를 위해 go 사용)
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              context.go(n.navigationPath);
                            }
                          });
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.rItem),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? tokens.listItemBg : tokens.card,
          borderRadius: BorderRadius.circular(tokens.rItem),
          border: Border.all(
            color: notification.isRead
                ? tokens.textMuted.withValues(alpha: 0.12)
                : tokens.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: notification.isRead ? 0.0 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(tokens),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: notification.isRead
                                ? tokens.textSub
                                : tokens.textPrimary,
                          ),
                          child: Text(notification.title),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                            fontSize: 11,
                            color: tokens.textMuted,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 13,
                      color: notification.isRead
                          ? tokens.textMuted
                          : tokens.textSub,
                      height: 1.5,
                    ),
                    child: Text(notification.content),
                  ),
                ],
              ),
            ),
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: notification.isRead ? 0.0 : 1.0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: notification.isRead ? 0.0 : 1.0,
                child: Container(
                  key: const ValueKey('notif-unread-dot'),
                  margin: const EdgeInsets.only(left: 10, top: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: tokens.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: tokens.primary.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(AppColorTokens tokens) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.friendRequest:
      case NotificationType.friendAccepted:
        icon = Icons.person_add_rounded;
        color = Colors.blue;
        break;
      case NotificationType.nudge:
        icon = Icons.favorite_rounded;
        color = Colors.pink;
        break;
      case NotificationType.guestbook:
        icon = Icons.chat_bubble_rounded;
        color = Colors.green;
        break;
      case NotificationType.levelUp:
        icon = Icons.auto_awesome_rounded;
        color = Colors.amber;
        break;
      case NotificationType.badgeAcquired:
        icon = Icons.military_tech_rounded;
        color = tokens.primary;
        break;
      case NotificationType.questCompleted:
        icon = Icons.emoji_events_rounded;
        color = tokens.primary;
        break;
      case NotificationType.mealTag:
        icon = Icons.restaurant_rounded;
        color = Colors.deepPurple;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = tokens.textSub;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time.toLocal());

    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return DateFormat('MM.dd').format(time.toLocal());
  }
}
